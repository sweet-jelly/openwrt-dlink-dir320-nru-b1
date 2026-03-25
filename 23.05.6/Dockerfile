# ===============================
# Stage 1: Build environment
# ===============================
FROM openwrt-base:latest

# LABEL maintainer="you@example.com"
LABEL description="OpenWrt 23.05.6 build environment for D-Link DIR-320 NRU B1 (RT5350F, MIPS24KEc)"

ENV GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
# ENV TZ=Etc/UTC

# -------------------------------
# 4. Prepare feeds
# -------------------------------
WORKDIR /openwrt
USER builder

RUN git checkout v23.05.6
RUN ./scripts/feeds update packages luci routing
RUN ./scripts/feeds install -a

COPY *.patch /tmp/mypatches/
RUN git apply -v --allow-empty /tmp/mypatches/* && \
    git config user.name sweet1jelly && \
    git config user.email "sweet1jelly@yandex.ru" && \
    git add --all && git commit -m "apply gcc 14 compatibility patches"

COPY --chown=builder:builder .config /openwrt/.config
COPY --chown=builder:builder build-squashfs /openwrt/

# # COPY --from=builder /home/builder/openwrt/bin/targets /output/
# RUN find . -type f ! -name '*.bin' ! -name '*.img' ! -name '*.gz' ! -name '*.tar' -delete

# CMD ["bash", "/openwrt/build-squashfs"]
CMD ["bash"]
