# hadolint ignore=DL3007
FROM --platform=${BUILDPLATFORM} docker.io/alpine:latest AS build

# hadolint ignore=DL3018
RUN apk add --no-cache git make gcc libc-dev perl xz-dev

# hadolint ignore=DL3059
RUN mkdir -p /pxegit

WORKDIR /pxegit

# Not shallow clonning, see https://github.com/ipxe/ipxe/discussions/454#discussioncomment-1296930
RUN git clone https://github.com/ipxe/ipxe ipxe

# Enable HTTPS support in iPXE
# hadolint ignore=DL3059
RUN echo "#define DOWNLOAD_PROTO_HTTPS" >ipxe/src/config/local/general.h

WORKDIR /pxegit/ipxe/src

# NOTE For arm, might want to look into https://github.com/ipxe/ipxe/discussions/1308
RUN make bin-x86_64-efi/ipxe.efi

# Local artifact using `--output <local path>` flag
FROM scratch AS local-artifact

COPY --link --from=build /pxegit/ipxe/src/bin-x86_64-efi/ipxe.efi /
