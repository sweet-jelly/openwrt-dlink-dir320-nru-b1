# ===============================
# Stage 1: Build environment
# ===============================
FROM debian:13-slim

LABEL description="OpenWrt build environment base image for D-Link DIR-320 NRU B1 (RT5350F, MIPS24KEc)"

ENV DEBIAN_FRONTEND=noninteractive
ENV TOOLCHAIN_LINK
ENV OPENWRT_VERSION
ENV BUILDER_UID
ENV BUILDER_GID

# ENV TZ=Etc/UTC

# --- Add bullseye repo for Python 2.7 ---
# RUN echo "deb http://archive.debian.org/debian bullseye main" > /etc/apt/sources.list.d/bullseye.list && \
#     apt-get -o Acquire::Check-Valid-Until=false update && \
#     apt-get install -y --no-install-recommends python2.7 && \
#     rm -f /etc/apt/sources.list.d/bullseye.list

# -------------------------------
# Install build dependencies
# -------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    build-essential \
    clang \
    flex \
    bison \
    g++ \
    gawk \
    gcc-multilib \
    g++-multilib \
    gettext \
    git \
    ca-certificates \
    libncurses5-dev \
    libssl-dev \
    m4 \
    python3-setuptools \
    rsync \
    swig \
    unzip \
    zlib1g-dev \
    file \
    wget \
    curl \
    sudo \
    nano \
    xclip

RUN groupadd -g $BUILDER_GID -f builder && \
    useradd -g $BUILDER_GID -u $BUILDER_UID builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder && chmod 0440 /etc/sudoers.d/builder && \
    mkdir -p /openwrt/build_scripts && chown -R builder:builder /openwrt && chmod -R 0777 /openwrt

USER builder
WORKDIR /openwrt

RUN git clone https://github.com/openwrt/openwrt/ .

RUN git checkout "v$OPENWRT_VERSION"
RUN ./scripts/feeds update packages luci routing
RUN ./scripts/feeds install -a

RUN wget "$TOOLCHAIN_LINK" -P /tmp/

COPY --from=openwrt *.patch /tmp/mypatches/
RUN git apply -v --allow-empty /tmp/mypatches/* && \
    git config user.name sweet1jelly && \
    git config user.email "sweet1jelly@yandex.ru" && \
    git add --all && git commit -m "apply custom patches"

COPY --from=openwrt --chown=builder:builder .config /openwrt/.config
COPY --from=openwrt --chown=builder:builder files /openwrt/files
COPY --from=scripts --chown=builder:builder * /openwrt/build_scripts/

# # COPY --from=builder /home/builder/openwrt/bin/targets /output/
# RUN find . -type f ! -name '*.bin' ! -name '*.img' ! -name '*.gz' ! -name '*.tar' -delete

# CMD ["bash", "/openwrt/build-squashfs"]
CMD [ "bash", "./build_scripts/build_squashfs" ]
