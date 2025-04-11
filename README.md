# OCaml Telegram Bot with OpenAI API Integration

A Telegram bot built with OCaml that communicates with an OpenAI-compatible API.

## Features

- Responds to messages that mention the bot
- Uses OpenAI-compatible API for generating responses
- Containerized with Docker
- CI/CD with GitHub Actions for automatic builds and pushes to GHCR

## Prerequisites

- Docker for running the bot
- Telegram Bot Token (obtain from [@BotFather](https://t.me/BotFather))
- OpenAI API Token or compatible API token

## Environment Variables

The bot requires the following environment variables:

- `TELEGRAM_TOKEN`: Your Telegram bot token from BotFather
- `OPENAI_TOKEN`: Your OpenAI API token or compatible API token
- `OPENAI_BASEURL`: Base URL for the OpenAI-compatible API (default: "https://api.openai.com")
- `OPENAI_MODEL`: Model to use for chat completions (default: "gpt-3.5-turbo")
- `SYSTEM_MSG`: System prompt for the AI (default: "You are a helpful assistant.")

## Running with Docker

### Using Prebuilt Image

```bash
docker run -e TELEGRAM_TOKEN=your_telegram_token \
           -e OPENAI_TOKEN=your_openai_token \
           -e OPENAI_BASEURL=https://api.openai.com \
           -e OPENAI_MODEL=gpt-3.5-turbo \
           -e SYSTEM_MSG="You are a helpful assistant." \
           ghcr.io/korjavin/ocamlexamplebot:latest
```

### Building Locally

Clone the repository:

```bash
git clone https://github.com/korjavin/ocamlExampleBot.git
cd ocamlExampleBot
```

Build the Docker image:

```bash
docker build -t ocamlexamplebot .
```

Run the bot:

```bash
docker run -e TELEGRAM_TOKEN=your_telegram_token \
           -e OPENAI_TOKEN=your_openai_token \
           -e OPENAI_BASEURL=https://api.openai.com \
           -e OPENAI_MODEL=gpt-3.5-turbo \
           -e SYSTEM_MSG="You are a helpful assistant." \
           ocamlexamplebot
```

## Using Podman

If you prefer using Podman instead of Docker:

```bash
podman build -t ocamlexamplebot .

podman run -e TELEGRAM_TOKEN=your_telegram_token \
           -e OPENAI_TOKEN=your_openai_token \
           -e OPENAI_BASEURL=https://api.openai.com \
           -e OPENAI_MODEL=gpt-3.5-turbo \
           -e SYSTEM_MSG="You are a helpful assistant." \
           ocamlexamplebot
```

## Development

### Project Structure

- `src/types.ml`: Type definitions for Telegram and OpenAI API
- `src/telegram.ml`: Telegram API client
- `src/llm_client.ml`: OpenAI-compatible API client
- `src/bot.ml`: Main bot implementation
- `src/dune`: Dune build configuration
- `dune-project`: Project configuration

### Building Locally (without Docker)

Ensure you have OCaml and OPAM installed:

```bash
opam install . --deps-only
dune build
dune exec src/bot.exe
```

## License

MIT