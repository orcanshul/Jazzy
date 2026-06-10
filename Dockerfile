# Ubuntu
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies, FFmpeg, and Liquidsoap
RUN apt-get update && apt-get install -y \
    curl \
    ffmpeg \
    liquidsoap \
    && rm -rf /var/lib/apt/lists/*

#  Create a workspace directory within render / huggingface
WORKDIR /workspace

# Copy 
COPY . .

# perms required to run
RUN chmod +x /workspace/worker.sh

# port
EXPOSE 8080

# Liquidsoap gateway
CMD ["liquidsoap", "/workspace/gateway.liq"]