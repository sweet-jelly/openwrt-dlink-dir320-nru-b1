# ===============================
# Stage 1: Build environment
# ===============================
FROM debian:13

LABEL description="OpenWrt build environment base image for D-Link DIR-320 NRU B1 (RT5350F, MIPS24KEc)"

ARG TOOLCHAIN_LINK

ARG BUILDER_UID
ARG BUILDER_GID

ARG OPENWRT_TARGET
ENV OPENWRT_TARGET="$OPENWRT_TARGET"

ARG OPENWRT_VERSION
ENV OPENWRT_VERSION="$OPENWRT_VERSION"

ENV TOOLCHAIN_DIR=/openwrt/external_toolchain
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
    bc \
    binutils-gold \
    bison \
    build-essential \
    ca-certificates \
    ccache \
    ecj \
    fastjar \
    file \
    flex \
    g++ \
    gawk \
    gcc-arm* \
    gettext \
    git \
    help2man \
    libbsd-dev \
    libelf-dev \
    liblzma-dev \
    libncurses-dev \
    libssl-dev \
    m4 \
    mtd-utils \
    meson \
    mold \
    ninja-build \
    pbzip2 \
    pigz \
    pkg-config \
    python3-dev \
    python3-setuptools \
    rsync \
    subversion \
    swig \
    texinfo \
    time \
    u-boot-tools \
    unzip \
    wget \
    xsltproc \
    xxd \
    zlib1g-dev \
    zstd \
    curl \
    sudo \
    nano \
    tree \
    xclip


RUN groupadd -g $BUILDER_GID -f builder && \
    useradd -g $BUILDER_GID -u $BUILDER_UID builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder && chmod 0440 /etc/sudoers.d/builder && \
    mkdir /openwrt && chown -R builder:builder /openwrt && chmod -R 0777 /openwrt

USER builder:$BUILDER_GID
WORKDIR /openwrt

RUN git clone --filter=blob:none https://github.com/openwrt/openwrt/ /openwrt && \
    git checkout "v$OPENWRT_VERSION"

RUN ./scripts/feeds update -a && \
    ./scripts/feeds install -a

RUN mkdir -p "$TOOLCHAIN_DIR" && \
    wget "$TOOLCHAIN_LINK" -O /tmp/toolchain && \
    tar -xvf /tmp/toolchain -C "$TOOLCHAIN_DIR" && \
    rm -f /tmp/toolchain

COPY --from=openwrt *.patch /tmp/mypatches/
RUN git apply -v --allow-empty /tmp/mypatches/* && \
    git config user.name sweet1jelly && \
    git config user.email "sweet1jelly@yandex.ru" && \
    git add --all && git commit -m "apply custom patches"

RUN mkdir -p /openwrt/build_scripts
COPY --from=openwrt --chown=builder:builder .config /openwrt/.config
COPY --from=scripts --chown=builder:builder * /openwrt/build_scripts/

RUN ./build_scripts/setup_external_toolchain && \
    echo "CONFIG_BUILD_ALL_HOST_TOOLS=y" >> .config && \
    make -j$(nproc) tools/install || make tools/install V=sc

CMD [ "bash", "./build_scripts/build_squashfs" ]
