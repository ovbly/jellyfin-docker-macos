ARG VERSION=latest

FROM debian:stable-slim AS rffmpeg
ARG RFFMPEG_REMOTE_USER

RUN apt-get update && apt-get install -y \
    wget \
    && rm -rf /var/lib/apt/lists/*
RUN wget https://raw.githubusercontent.com/joshuaboniface/rffmpeg/master/rffmpeg -O /opt/rffmpeg
RUN chmod +x /opt/rffmpeg

COPY rffmpeg.yml /opt/
RUN sed -i "s/#user: jellyfin/user: ${RFFMPEG_REMOTE_USER}/g" /opt/rffmpeg.yml

FROM jellyfin/jellyfin:${VERSION}

RUN mkdir -p /root/.ssh

VOLUME /root/.ssh
VOLUME /var/folders/media
VOLUME /tmp/jellyfin
VOLUME /config

RUN apt-get update && apt-get install -y \
    openssh-client python3-click python3-yaml wget \
    && rm -rf /var/lib/apt/lists/*
COPY --from=rffmpeg /opt/rffmpeg /usr/local/bin/
COPY --from=rffmpeg /opt/rffmpeg.yml /etc/rffmpeg/
RUN ln -s /usr/local/bin/rffmpeg /opt/ffmpeg && \
    ln -s /usr/local/bin/rffmpeg /opt/ffprobe
RUN rffmpeg init -y && rffmpeg add host.docker.internal

RUN mkdir -p /var/log/jellyfin

ENTRYPOINT ["./jellyfin/jellyfin", \
    "--datadir", "/config", \
    "--cachedir", "/tmp/jellyfin", \
    "--logdir", "/var/log/jellyfin", \
    "--ffmpeg", "/opt/ffmpeg"]
