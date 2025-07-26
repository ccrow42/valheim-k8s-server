FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends bash jq curl python3 ffmpeg gettext-base && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
COPY words.txt .
COPY notify_discord.sh /usr/local/bin
COPY update_youtube_channels.sh /usr/local/bin
RUN chmod +x /usr/local/bin/notify_discord.sh
RUN curl -k -LO "https://dl.k8s.io/release/$(curl -k -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN mv kubectl /usr/local/bin
RUN curl -k -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
RUN chmod a+rx /usr/local/bin/yt-dlp
RUN chmod +x /usr/local/bin/kubectl

# Set bash as default shell
SHELL ["/bin/bash", "-c"]