(* Types for Telegram API *)
type chat = {
  id : int;
  first_name : string option;
  username : string option;
} [@@deriving yojson]

type user = {
  id : int;
  is_bot : bool;
  first_name : string;
  username : string option;
} [@@deriving yojson]

type message_entity = {
  entity_type : string [@key "type"];
  offset : int;
  length : int;
  text : string option;
  user : user option;
} [@@deriving yojson]

type message = {
  message_id : int;
  from : user option;
  chat : chat;
  date : int;
  text : string option;
  entities : message_entity list option;
  reply_to_message : message option;
} [@@deriving yojson]

type update = {
  update_id : int;
  message : message option;
} [@@deriving yojson]

type webhook_response = {
  updates : update list;
} [@@deriving yojson]

type bot_info = {
  id : int;
  is_bot : bool;
  first_name : string;
  username : string;
}

(* Types for OpenAI API *)
type message_role = 
  | System
  | User
  | Assistant

type openai_message = {
  role : message_role;
  content : string;
}

type openai_request = {
  model : string;
  messages : openai_message list;
}

type openai_response_message = {
  content : string option;
}

type openai_response_choice = {
  message : openai_response_message;
}

type openai_response = {
  choices : openai_response_choice list;
}