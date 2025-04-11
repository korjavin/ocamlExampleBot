open Lwt
open Cohttp
open Cohttp_lwt_unix
open Yojson.Safe.Util
open Types

let api_endpoint token method_name =
  Printf.sprintf "https://api.telegram.org/bot%s/%s" token method_name

let updates_of_yojson_exn json =
  let open Yojson.Safe.Util in
  let ok = json |> member "ok" |> to_bool in
  if not ok then failwith "Telegram API request failed";
  let results = json |> member "result" |> to_list in
  match results with
  | [] -> None
  | _ ->
      Some (List.map (fun json_update ->
        match update_of_yojson json_update with
        | Ok update -> update
        | Error err -> failwith ("Failed to parse update: " ^ err)
      ) results)

let get_me token =
  let uri = Uri.of_string (api_endpoint token "getMe") in
  Logs.info (fun m -> m "Getting bot information...");
  Client.get uri >>= fun (resp, body) ->
  body |> Cohttp_lwt.Body.to_string >|= fun body_str ->
  try
    let json = Yojson.Safe.from_string body_str in
    let result = json |> member "result" in
    let id = result |> member "id" |> to_int in
    let is_bot = result |> member "is_bot" |> to_bool in
    let first_name = result |> member "first_name" |> to_string in
    let username = result |> member "username" |> to_string in
    Logs.info (fun m -> m "Bot info: @%s (%s), ID: %d" username first_name id);
    Some { id; is_bot; first_name; username }
  with exn ->
    Logs.err (fun m -> m "Failed to parse getMe response: %s" (Printexc.to_string exn));
    Logs.err (fun m -> m "Response body: %s" body_str);
    None

let get_updates token offset =
  let uri = Uri.of_string (Printf.sprintf "%s?offset=%d&timeout=10" (api_endpoint token "getUpdates") offset) in
  Client.get uri >>= fun (resp, body) ->
  body |> Cohttp_lwt.Body.to_string >|= fun body_str ->
  try
    let json = Yojson.Safe.from_string body_str in
    let ok = json |> member "ok" |> to_bool in
    if ok then
      let results = json |> member "result" |> to_list in
      Some (List.map update_of_yojson_exn results)
    else (
      Logs.err (fun m -> m "Failed to get updates: %s" body_str);
      None
    )
  with exn ->
    Logs.err (fun m -> m "Failed to parse getUpdates response: %s" (Printexc.to_string exn));
    None

let send_message token chat_id text ?reply_to_message_id () =
  let uri = Uri.of_string (api_endpoint token "sendMessage") in
  let message_params = [
    ("chat_id", `Int chat_id);
    ("text", `String text);
    ("parse_mode", `String "Markdown");
  ] in
  let message_params = match reply_to_message_id with
    | Some id -> ("reply_to_message_id", `Int id) :: message_params
    | None -> message_params
  in
  let body = `Assoc message_params |> Yojson.Safe.to_string in
  let headers = Header.init_with "Content-Type" "application/json" in
  
  Logs.info (fun m -> m "Sending message to chat %d" chat_id);
  Client.post ~headers ~body:(Cohttp_lwt.Body.of_string body) uri >>= fun (resp, body) ->
  body |> Cohttp_lwt.Body.to_string >|= fun body_str ->
  try
    let json = Yojson.Safe.from_string body_str in
    let ok = json |> member "ok" |> to_bool in
    if not ok then
      Logs.err (fun m -> m "Failed to send message: %s" body_str);
    ok
  with exn ->
    Logs.err (fun m -> m "Failed to parse sendMessage response: %s" (Printexc.to_string exn));
    false

let is_mentioned_in_text text bot_info =
  let username_mention = "@" ^ bot_info.username in
  let first_name_mention = bot_info.first_name in
  String.contains text username_mention || String.contains text first_name_mention

let is_mentioned message bot_info =
  match message.text with
  | None -> false
  | Some text -> is_mentioned_in_text text bot_info