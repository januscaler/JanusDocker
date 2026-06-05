ARG PLATFORM=linux/arm64
FROM --platform=${PLATFORM} alpine:3.20

LABEL maintainer="shivansh talwar <shivanshtalwar0@gmail.com>"
LABEL description="Provides an Alpine image with Janus Gateway dependencies"

# ── System packages ──────────────────────────────────────────────────────────
# Mapped from Ubuntu apt packages to Alpine apk packages
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
    libogg-dev \
    opus-dev \
    flex bison \
    lua-dev \
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

# ── paho.mqtt.c (latest master) ──────────────────────────────────────────────
# Note: Switched from `make` to `cmake`. Upstream requires CMake to properly 
# build shared libraries and link OpenSSL for Janus MQTT event handlers.
RUN cd /builds && \
    git clone https://github.com/eclipse/paho.mqtt.c.git && \
    cd paho.mqtt.c && \
    cmake -B build -S . -DCMAKE_INSTALL_PREFIX=/usr -DPAHO_BUILD_SHARED=TRUE -DPAHO_WITH_SSL=TRUE && \
    cmake --build build --target install && \
    rm -rf /builds/paho.mqtt.c

# ── rabbitmq-c (latest master — Janus README recommends latest) ──────────────
RUN cd /builds && \
    git clone https://github.com/alanxz/rabbitmq-c && \
    cd rabbitmq-c && \
    git submodule init && \
    git submodule update && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SHARED_LIBS=ON .. && \
    make && make install && \
    rm -rf /builds/rabbitmq-c

# ── libnice (always build master — distro package is known broken) ────────────
# Janus README: "we always recommend manually compiling the master version"
# Note: libnice-dev is intentionally excluded from BUILD_DEPS to prevent conflicts.
RUN cd /builds && \
    git clone https://gitlab.freedesktop.org/libnice/libnice && \
    cd libnice && \
    meson setup build --prefix=/usr && \
    ninja -C build && \
    ninja -C build install && \
    rm -rf /builds/libnice

# ── libsrtp 2.5.0 (latest stable, fixes several CVEs) ────────────────────────
RUN cd /builds && \
    wget https://github.com/cisco/libsrtp/archive/v2.5.0.tar.gz && \
    tar xfv v2.5.0.tar.gz && \
    cd libsrtp-2.5.0 && \
    ./configure --prefix=/usr --enable-openssl && \
    make shared_library && make install && \
    rm -rf /builds/v2.5.0.tar.gz /builds/libsrtp-2.5.0

# ── usrsctp (latest master — added recommended flags per upstream README) ──────
# --disable-programs --disable-inet --disable-inet6 reduce attack surface
RUN cd /builds && \
    git clone https://github.com/sctplab/usrsctp && \
    cd usrsctp && \
    ./bootstrap && \
    ./configure --prefix=/usr \
        --disable-programs \
        --disable-inet \
        --disable-inet6 && \
    make && make install && \
    rm -rf /builds/usrsctp

# ── libwebsockets v4.3-stable ────────────────────────────────────────────────
RUN cd /builds && \
    git clone --branch v4.3-stable --depth 1 \
        https://github.com/warmcat/libwebsockets.git && \
    cd libwebsockets && \
    mkdir build && cd build && \
    cmake \
        -DLWS_MAX_SMP=1 \
        -DLWS_WITHOUT_EXTENSIONS=0 \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_C_FLAGS="-fPIC" .. && \
    make && make install && \
    rm -rf /builds/libwebsockets

# ── libogg 1.3.5 (unchanged — still latest stable) ───────────────────────────
# Note: Added --prefix=/usr. Alpine's musl libc does not search /usr/local/lib 
# by default, which causes silent runtime linking failures.
RUN cd /builds && \
    wget https://downloads.xiph.org/releases/ogg/libogg-1.3.5.zip && \
    unzip libogg-1.3.5.zip && \
    cd libogg-1.3.5 && \
    ./configure --prefix=/usr && make && make install && \
    rm -rf /builds/libogg-1.3.5.zip /builds/libogg-1.3.5

# ── sofia-sip v1.13.17 (many SIP plugin fixes upstream) ──────────────────────
RUN cd /builds && \
    git clone https://github.com/freeswitch/sofia-sip.git && \
    cd sofia-sip && \
    git checkout v1.13.17 && \
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
