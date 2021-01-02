## Buildstage ##
FROM ghcr.io/linuxserver/deluge:latest as buildstage

# copy local files
COPY root/ /root-layer/

RUN /root-layer/build.sh && rm /root-layer/build.sh

## Single layer deployed image ##
FROM scratch

LABEL maintainer="darkip"

# Add files from buildstage
COPY --from=buildstage /root-layer/ /
