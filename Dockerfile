FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install core networking binaries, FFmpeg toolkit, and Liquidsoap audio engine
RUN apt-get update && apt-get install -y \
    curl \
    ffmpeg \
    liquidsoap \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Pull codebase structure into container workspace
COPY . .

# Adjust user execution access bounds
RUN chmod +x /workspace/worker.sh

EXPOSE 8080

# Gateway startup defaults (Workers will override this signature dynamically)
CMD ["liquidsoap", "/workspace/gateway.liq"]