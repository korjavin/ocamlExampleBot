FROM ocaml/opam:debian-12-ocaml-4.14

# Install system dependencies
RUN sudo apt-get update && sudo apt-get install -y \
    libssl-dev \
    pkg-config \
    m4 \
    libgmp-dev \
    && sudo rm -rf /var/lib/apt/lists/*

# Set up working directory with proper permissions
WORKDIR /home/opam/app

# Copy project files and fix permissions
COPY --chown=opam:opam . .

# Install dependencies
RUN opam update && \
    opam install dune cohttp cohttp-lwt-unix lwt yojson ppx_deriving_yojson logs fmt cmdliner

# Build the project
RUN opam exec -- dune build

# Set the entry point
ENTRYPOINT ["opam", "exec", "--", "dune", "exec", "src/bot.exe"]