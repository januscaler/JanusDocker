ARG PLATFORM=linux/arm64
FROM --platform=${PLATFORM} alpine:3.20

LABEL maintainer="shivansh talwar <shivanshtalwar0@gmail.com>"
LABEL description="Provides an Alpine image with Janus Gateway dependencies"

# ── System packages (Janus required + optional deps via apk) ─────────────────
# Required: GLib, zlib, pkg-config, Jansson, libconfig, OpenSSL, libmicrohttpd,
#           nanomsg, libcurl, libopus, Lua, Duktape
# Optional plugin deps covered here: libogg (also built from source below), opus
ENV BUILD_DEPS=" \
    build-base \
    autoconf automake libtool \
    cmake ninja meson \
    linux-headers \
    bash curl wget git unzip zip ca-certificates sudo \
    pkgconfig \
    openssl-dev \
    jansson-dev \
    glib-dev glib-static \
    libffi-dev \
    libmicrohttpd-dev \
    opus-dev \
    flex bison \
    lua-dev \
    duktape-dev \
    python3 python3-dev py3-pip py3-setuptools py3-wheel \
    ffmpeg ffmpeg-dev ffmpeg-libs \
    zlib-dev \
    graphviz doxygen \
    libconfig-dev libconfig-static \
    nanomsg-dev \
    curl-dev \
    nginx \
    nodejs npm"

RUN apk update && apk upgrade && \
    apk add --no-cache $BUILD_DEPS

# Build workspace
RUN mkdir -p /builds

# ── paho.mqtt.c (latest — Janus README: clone latest for MQTT support) ───────
# CMake + PAHO_HIGH_PERFORMANCE avoids musl/Alpine Heap.h free() macro conflict.
RUN cd /builds && \
    git clone --depth 1 https://github.com/eclipse-paho/paho.mqtt.c.git && \
    cd paho.mqtt.c && \
    cmake -B build -S . \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DPAHO_BUILD_SHARED=TRUE \
        -DPAHO_WITH_SSL=TRUE \
        -DPAHO_HIGH_PERFORMANCE=TRUE \
        -DPAHO_ENABLE_TESTING=FALSE && \
    cmake --build build --target install && \
    rm -rf /builds/paho.mqtt.c

# ── rabbitmq-c (latest master — Janus README recommends latest from git) ─────
RUN cd /builds && \
    git clone --depth 1 https://github.com/alanxz/rabbitmq-c && \
    cd rabbitmq-c && \
    git submodule init && \
    git submodule update && \
    cmake -B build -S . \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DBUILD_SHARED_LIBS=ON && \
    cmake --build build --target install && \
    rm -rf /builds/rabbitmq-c

# ── libnice (master — Janus README: always compile master, distro pkgs broken) 
# libnice-dev is intentionally excluded from BUILD_DEPS to prevent conflicts.
RUN cd /builds && \
    git clone --depth 1 https://gitlab.freedesktop.org/libnice/libnice && \
    cd libnice && \
    meson setup build --prefix=/usr && \
    ninja -C build && \
    ninja -C build install && \
    rm -rf /builds/libnice

# ── libsrtp v2.8.0 (Janus README: 2.x recommended, --enable-openssl required) 
RUN cd /builds && \
    wget https://github.com/cisco/libsrtp/archive/v2.8.0.tar.gz && \
    tar xfv v2.8.0.tar.gz && \
    cd libsrtp-2.8.0 && \
    ./configure --prefix=/usr --enable-openssl && \
    make shared_library && make install && \
    rm -rf /builds/v2.8.0.tar.gz /builds/libsrtp-2.8.0

# ── usrsctp (latest master — Janus README recommended configure flags) ───────
RUN cd /builds && \
    git clone --depth 1 https://github.com/sctplab/usrsctp && \
    cd usrsctp && \
    ./bootstrap && \
    ./configure --prefix=/usr \
        --disable-programs \
        --disable-inet \
        --disable-inet6 && \
    make && make install && \
    rm -rf /builds/usrsctp

# ── libwebsockets v4.3-stable (Janus README recommended stable branch) ──────
RUN cd /builds && \
    git clone --branch v4.3-stable --depth 1 \
        https://github.com/warmcat/libwebsockets.git && \
    cd libwebsockets && \
    cmake -B build -S . \
        -DLWS_MAX_SMP=1 \
        -DLWS_WITHOUT_EXTENSIONS=0 \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_C_FLAGS="-fpic" && \
    cmake --build build --target install && \
    rm -rf /builds/libwebsockets

# ── libogg v1.3.6 (latest stable — needed for post-processing / recordings) ─
RUN cd /builds && \
    wget https://github.com/xiph/ogg/releases/download/v1.3.6/libogg-1.3.6.tar.gz && \
    tar xfv libogg-1.3.6.tar.gz && \
    cd libogg-1.3.6 && \
    ./configure --prefix=/usr && make && make install && \
    rm -rf /builds/libogg-1.3.6.tar.gz /builds/libogg-1.3.6

# ── sofia-sip v1.13.17 (latest — Janus SIP plugin dependency) ────────────────
RUN cd /builds && \
    git clone --depth 1 --branch v1.13.17 \
        https://github.com/freeswitch/sofia-sip.git && \
    cd sofia-sip && \
    sh autogen.sh && \
    ./configure --prefix=/usr && \
    make && make install && \
    rm -rf /builds/sofia-sip

# ── Janus Gateway v1.4.1 (latest stable tag) ─────────────────────────────────
RUN cd /builds && \
    wget https://github.com/meetecho/janus-gateway/archive/refs/tags/v1.4.1.zip && \
    unzip v1.4.1.zip && \
    cd janus-gateway-1.4.1 && \
    sh autogen.sh && \
    ./configure \
        --prefix=/opt/janus-tools \
        --enable-post-processing && \
    make && make install && \
    make configs && \
    rm -rf /builds/v1.4.1.zip /builds/janus-gateway-1.4.1

ENV PATH="/opt/janus-tools/bin:$PATH"
