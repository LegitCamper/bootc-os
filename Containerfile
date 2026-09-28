ARG FEDORA_VERSION=${FEDORA_VERSION}

FROM scratch AS ctx
COPY build-scripts /

FROM quay.io/fedora/fedora-bootc:${FEDORA_VERSION} AS base

# Split so that editing system-files/ (units, dotfiles, themes) does not
# invalidate the dnf work. `cache-from: type=gha` then hits on most pushes.
# Kept as two RUNs rather than one-per-script because /var is a per-RUN tmpfs:
# every extra layer boundary means dnf re-downloads repo metadata.

# Expensive and rarely-changing: repos, packages, fonts, kernel swap.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    bash -euxo pipefail -c '\
      /ctx/dnf.sh && \
      /ctx/packages.sh && \
      /ctx/customize.sh && \
      /ctx/kernel.sh \
    '

COPY system-files /

# services.sh enables units from system-files; initramfs.sh reads the SB cert.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=secret,id=sb_key \
    bash -euxo pipefail -c '\
      /ctx/check-dns.sh /etc/dnscrypt-proxy/dnscrypt-proxy.toml && \
      /ctx/services.sh && \
      /ctx/initramfs.sh && \
      /ctx/finish.sh  \
    '

RUN bootc container lint
