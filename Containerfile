ARG FEDORA_VERSION=${FEDORA_VERSION}

FROM scratch AS ctx
COPY build-scripts /

FROM quay.io/fedora/fedora-bootc:${FEDORA_VERSION} AS base
# Fix for KeyError: 'vendor' image-builder
RUN mkdir -p /usr/lib/bootupd/updates \
    && cp -r /usr/lib/efi/*/*/* /usr/lib/bootupd/updates

COPY system-files /

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    bash -euxo pipefail -c '\
      /ctx/dnf.sh && \
      /ctx/packages.sh && \
      /ctx/kernel.sh && \
      /ctx/services.sh && \
      /ctx/initramfs.sh && \
      /ctx/finish.sh  \
    '

RUN bootc container lint

