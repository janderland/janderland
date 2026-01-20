FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    make \
    pandoc \
    default-jre-headless \
    graphviz \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install newer PlantUML that supports --dark-mode
RUN wget -q -O /usr/local/bin/plantuml.jar \
    https://github.com/plantuml/plantuml/releases/download/v1.2024.8/plantuml-1.2024.8.jar \
    && printf '#!/bin/sh\njava -jar /usr/local/bin/plantuml.jar "$@"\n' > /usr/local/bin/plantuml \
    && chmod +x /usr/local/bin/plantuml

WORKDIR /site
