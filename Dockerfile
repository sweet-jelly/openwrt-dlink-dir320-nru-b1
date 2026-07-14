# ===============================
# Stage 1: Build environment
# ===============================
FROM debian:13-slim

LABEL description="OpenWrt build environment base image for D-Link DIR-320 NRU B1 (RT5350F, MIPS24KEc)"

ARG TOOLCHAIN_LINK

ARG BUILDER_UID
ARG BUILDER_GID

ARG OPENWRT_TARGET
ENV OPENWRT_TARGET="$OPENWRT_TARGET"

ARG OPENWRT_VERSION
ENV OPENWRT_VERSION="$OPENWRT_VERSION"

ARG TOOLCHAIN_FILENAME
ENV TOOLCHAIN_FILENAME="$TOOLCHAIN_FILENAME"
ENV TOOLCHAIN_FILE_PATH="/tmp/$TOOLCHAIN_FILENAME"

ENV DEBIAN_FRONTEND=noninteractive

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
    mkdir /openwrt && chown -R builder:builder /openwrt && chmod -R 0777 /openwrt

USER builder:$BUILDER_GID
WORKDIR /openwrt

RUN git clone --filter=blob:none https://github.com/openwrt/openwrt/ /openwrt
RUN git checkout "v$OPENWRT_VERSION"

RUN ./scripts/feeds update packages luci routing
RUN ./scripts/feeds install -a

RUN wget "$TOOLCHAIN_LINK" -O "$TOOLCHAIN_FILE_PATH"

COPY --from=openwrt *.patch /tmp/mypatches/
RUN git apply -v --allow-empty /tmp/mypatches/* && \
    git config user.name sweet1jelly && \
    git config user.email "sweet1jelly@yandex.ru" && \
    git add --all && git commit -m "apply custom patches"

RUN mkdir -p /openwrt/build_scripts
COPY --from=openwrt --chown=builder:builder .config /openwrt/.config
COPY --from=openwrt --chown=builder:builder files /openwrt/files
COPY --from=scripts --chown=builder:builder * /openwrt/build_scripts/

# # COPY --from=builder /home/builder/openwrt/bin/targets /output/
# RUN find . -type f ! -name '*.bin' ! -name '*.img' ! -name '*.gz' ! -name '*.tar' -delete

# CMD ["bash", "/openwrt/build-squashfs"]
CMD [ "bash", "./build_scripts/build_squashfs" ]
