# stage 1 - generate a recipe
FROM rust as planner
WORKDIR /app
RUN cargo install cargo-chef
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# stage 2 - build our dependencies
FROM rust as cacher
WORKDIR /app
RUN cargo install cargo-chef
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

# stage 3

# Use the latest version of the Rust base image
FROM rust as builder

COPY . /app

# Set the working directory in the container to /my
WORKDIR /app

# Copy dependencies
COPY --from=cacher /app/target/ target
COPY --from=cacher /usr/local/cargo /usr/local/cargo

# Build the Rust app
RUN cargo build --release

FROM ubuntu

ARG DATABASE_URL
ENV DATABASE_URL=$DATABASE_URL

RUN if [ -z "$DATABASE_URL" ]; then echo "DATABASE_URL is not set"; exit 1; fi

COPY --from=builder /app/target/release/effective-octo-memory /app/effective-octo-memory

WORKDIR /app

CMD ["./effective-octo-memory"]