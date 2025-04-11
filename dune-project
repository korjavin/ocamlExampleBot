(lang dune 2.9)
(name ocamlexamplebot)
(generate_opam_files true)

(source (github korjavin/ocamlExampleBot))
(license MIT)
(authors "korjavin")
(maintainers "korjavin")

(package
 (name ocamlexamplebot)
 (synopsis "Telegram bot written in OCaml")
 (description "A Telegram bot that interacts with an OpenAI-compatible LLM API")
 (depends
  (ocaml (>= 4.13.0))
  dune
  cohttp
  cohttp-lwt-unix
  lwt
  yojson
  ppx_deriving_yojson
  logs
  fmt
  cmdliner))