# ---------- build stage ----------
FROM dart:stable AS build
WORKDIR /app

# Cache dependencies first
COPY pubspec.yaml ./
RUN dart pub get

# Compile a small native binary
COPY . .
RUN dart compile exe bin/server.dart -o server

# ---------- run stage ----------
FROM debian:stable-slim
# ca-certificates are REQUIRED — the server calls YouTube over HTTPS
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/server /app/server

# Render sets PORT automatically; 8080 is the local default
ENV PORT=8080
EXPOSE 8080

CMD ["/app/server"]
