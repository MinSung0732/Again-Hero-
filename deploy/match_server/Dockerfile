FROM debian:bookworm-slim AS engine
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip && rm -rf /var/lib/apt/lists/*
ARG GODOT_VERSION=4.5.1
ARG GODOT_SHA256=02ec53d1cc7dbb9cc6355393c61b9ab43d1244751a124f10248a4802830788cd
RUN curl --fail --location --retry 3 "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o /tmp/godot.zip \
 && echo "${GODOT_SHA256}  /tmp/godot.zip" | sha256sum -c - \
 && unzip /tmp/godot.zip -d /tmp/engine \
 && mv /tmp/engine/Godot_v${GODOT_VERSION}-stable_linux.x86_64 /usr/local/bin/godot
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/* \
 && useradd --create-home --uid 10001 game
COPY --from=engine /usr/local/bin/godot /usr/local/bin/godot
WORKDIR /game
COPY --chown=game:game . /game
USER game
RUN godot --headless --editor --import --path /game
ENV AGAIN_HERO_BIND=0.0.0.0 AGAIN_HERO_PORT=24840
EXPOSE 24840
CMD ["godot", "--headless", "--path", "/game", "--script", "res://src/online/server_main.gd"]
