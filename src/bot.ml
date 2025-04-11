open Lwt
open Cohttp
open Cohttp_lwt_unix
open Types
open Telegram
open Llm_client

module StringMap = Map.Make(String)

let setup_logger () =
  Fmt_tty.setup_std_outputs ();
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Logs.Info)

let get_env_var name default =
  try Sys.getenv name
  with Not_found -> 
    Logs.info (fun m -> m "%s not set, using default value" name);
    default

let process_message token bot_info openai_baseurl openai_token openai_model system_msg message =
  match message.text with
  | None -> 
      Logs.info (fun m -> m "Message has no text, ignoring");
      send_message token message.chat.id "I don't see text" ~reply_to_message_id:message.message_id ()
  | Some text ->
      if is_mentioned message bot_info then
        let user_text = text in
        Logs.info (fun m -> m "Bot was mentioned in message: %s" user_text);
        
        chat ~base_url:openai_baseurl ~token:openai_token ~model:openai_model 
             ~system_message:system_msg ~user_message:user_text >>= function
        | None ->
            Logs.err (fun m -> m "Failed to get response from LLM API");
            send_message token message.chat.id "Sorry, I couldn't process your request." 
                        ~reply_to_message_id:message.message_id ()
        | Some response ->
            Logs.info (fun m -> m "Got response from LLM API: %s" (if String.length response > 50 then String.sub response 0 50 ^ "..." else response));
            send_message token message.chat.id response ~reply_to_message_id:message.message_id ()
      else
        Logs.debug (fun m -> m "Message didn't mention bot, ignoring");
        return true

let process_update token bot_info openai_baseurl openai_token openai_model system_msg update =
  match update.message with
  | None ->
      Logs.debug (fun m -> m "Update has no message, ignoring");
      return ()
  | Some message ->
      Logs.info (fun m -> m "Processing message from update %d" update.update_id);
      process_message token bot_info openai_baseurl openai_token openai_model system_msg message >|= fun _ -> ()

let rec poll_updates token bot_info openai_baseurl openai_token openai_model system_msg offset =
  Logs.debug (fun m -> m "Polling for updates with offset %d" offset);
  get_updates token offset >>= function
  | None ->
      Logs.err (fun m -> m "Failed to get updates");
      Lwt_unix.sleep 5.0 >>= fun () ->
      poll_updates token bot_info openai_baseurl openai_token openai_model system_msg offset
  | Some updates ->
      Logs.debug (fun m -> m "Got %d updates" (List.length updates));
      
      let process_all = Lwt_list.iter_s (process_update token bot_info openai_baseurl openai_token openai_model system_msg) updates in
      process_all updates >>= fun () ->
      
      let next_offset = match updates with
      | [] -> offset
      | _ -> 
          let last_update = List.fold_left (fun acc u -> if u.update_id > acc.update_id then u else acc) (List.hd updates) updates in
          last_update.update_id + 1
      in
      
      Lwt_unix.sleep 1.0 >>= fun () ->
      poll_updates token bot_info openai_baseurl openai_token openai_model system_msg next_offset

let run_bot telegram_token openai_baseurl openai_token openai_model system_msg =
  get_me telegram_token >>= function
  | None ->
      Logs.err (fun m -> m "Failed to get bot info");
      return ()
  | Some bot_info ->
      Logs.app (fun m -> m "Starting bot @%s" bot_info.username);
      poll_updates telegram_token bot_info openai_baseurl openai_token openai_model system_msg 0

let () =
  setup_logger ();
  Logs.app (fun m -> m "Starting Telegram bot...");
  
  let telegram_token = get_env_var "TELEGRAM_TOKEN" "" in
  let openai_baseurl = get_env_var "OPENAI_BASEURL" "https://api.openai.com" in
  let openai_token = get_env_var "OPENAI_TOKEN" "" in
  let openai_model = get_env_var "OPENAI_MODEL" "gpt-3.5-turbo" in
  let system_msg = get_env_var "SYSTEM_MSG" "You are a helpful assistant." in

  if telegram_token = "" then (
    Logs.err (fun m -> m "TELEGRAM_TOKEN is not set");
    exit 1
  );
  
  if openai_token = "" then (
    Logs.err (fun m -> m "OPENAI_TOKEN is not set");
    exit 1
  );
  
  Lwt_main.run (run_bot telegram_token openai_baseurl openai_token openai_model system_msg)