open Lwt
open Cohttp
open Cohttp_lwt_unix
open Yojson.Safe.Util
open Types

let string_of_message_role = function
  | System -> "system"
  | User -> "user"
  | Assistant -> "assistant"

let message_to_yojson msg =
  `Assoc [
    ("role", `String (string_of_message_role msg.role));
    ("content", `String msg.content);
  ]

let request_to_yojson req =
  `Assoc [
    ("model", `String req.model);
    ("messages", `List (List.map message_to_yojson req.messages));
  ]

let extract_response_content json =
  try
    let choices = json |> member "choices" |> to_list in
    match choices with
    | [] -> 
        Logs.err (fun m -> m "No choices in LLM response");
        None
    | choice :: _ ->
        let message = choice |> member "message" in
        let content = message |> member "content" |> to_string_option in
        match content with
        | None -> 
            Logs.err (fun m -> m "No content in LLM response message");
            None
        | Some txt -> Some txt
  with e ->
    Logs.err (fun m -> m "Failed to parse LLM response: %s" (Printexc.to_string e));
    None

let chat ~base_url ~token ~model ~system_message ~user_message =
  Logs.info (fun m -> m "Sending request to LLM API");
  
  let messages = [
    { role = System; content = system_message };
    { role = User; content = user_message };
  ] in
  
  let req = { model; messages } in
  let json_body = request_to_yojson req in
  let body = Yojson.Safe.to_string json_body in
  
  let uri = Uri.of_string (Printf.sprintf "%s/v1/chat/completions" base_url) in
  let headers = Header.init ()
    |> fun h -> Header.add h "Content-Type" "application/json"
    |> fun h -> Header.add h "Authorization" ("Bearer " ^ token) in
  
  Lwt.catch
    (fun () ->
      Client.post ~headers ~body:(Cohttp_lwt.Body.of_string body) uri >>= fun (resp, body) ->
      let status = resp |> Response.status |> Code.code_of_status in
      body |> Cohttp_lwt.Body.to_string >|= fun body_str ->
      
      if status <> 200 then (
        Logs.err (fun m -> m "LLM API returned status %d: %s" status body_str);
        None
      ) else
        try
          let json = Yojson.Safe.from_string body_str in
          extract_response_content json
        with e ->
          Logs.err (fun m -> m "Failed to parse LLM response: %s" (Printexc.to_string e));
          None
    )
    (fun e ->
      Logs.err (fun m -> m "Exception while calling LLM API: %s" (Printexc.to_string e));
      return None
    )