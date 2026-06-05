ARG PLATFORM=linux/arm64
ARG UBUNTU_VERSION=24.04

FROM --platform=${PLATFORM} ubuntu:${UBUNTU_VERSION}

LABEL maintainer="shivansh talwar <shivanshtalwar0@gmail.com>"
LABEL description="Provides an image with Janus Gateway dependencies"

# ── System packages ──────────────────────────────────────────────────────────
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    curl gcc g++ make \
    build-essential \
    aptitude wget cmake ffmpeg \
    libavutil-dev libavcodec-dev libavformat-dev \
    nginx sudo git graphviz flex bison \
    libmicrohttpd-dev libjansson-dev \
    libssl-dev libsofia-sip-ua-dev libglib2.0-dev \
    libopus-dev libogg-dev libcurl4-openssl-dev liblua5.3-dev \
    python3 python3-pip python3-setuptools python3-wheel \
    ninja-build libconfig-dev pkg-config \
    libtool automake autoconf unzip zip doxygen graphviz \
    libnanomsg-dev && \
    apt-get autoremove -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ── meson (needed for libnice) ────────────────────────────────────────────────
RUN pip3 install meson --break-system-packages

# ── Node.js 20 ────────────────────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Build workspace
RUN mkdir -p /builds

# ── paho.mqtt.c (latest master — no versioned releases) ──────────────────────
RUN cd /builds && \
    git clone https://github.com/eclipse/paho.mqtt.c.git && \
    cd paho.mqtt.c && \
    make && make install && \
    rm -rf /builds/paho.mqtt.c

# ── rabbitmq-c (latest master — Janus README recommends latest) ──────────────
RUN cd /builds && \
    git clone https://github.com/alanxz/rabbitmq-c && \
    cd rabbitmq-c && \
    git submodule init && \
    git submodule update && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr .. && \
    make && make install && \
    rm -rf /builds/rabbitmq-c

# ── libnice (always build master — Ubuntu package is known broken) ────────────
# Janus README: "we always recommend manually compiling the master version"
RUN cd /builds && \
    git clone https://gitlab.freedesktop.org/libnice/libnice && \
    cd libnice && \
    meson --prefix=/usr build && \
    ninja -C build && \
    ninja -C build install && \
    rm -rf /builds/libnice

# ── libsrtp 2.5.0 (was 2.2.0 — latest stable, fixes several CVEs) ────────────
RUN cd /builds && \
    wget https://github.com/cisco/libsrtp/archive/v2.5.0.tar.gz && \
    tar xfv v2.5.0.tar.gz && \
    cd libsrtp-2.5.0 && \
    ./configure --prefix=/usr --enable-openssl && \
    make shared_library && make install && \
    rm -rf /builds/v2.5.0.tar.gz /builds/libsrtp-2.5.0

# ── usrsctp (latest master — added recommended flags per upstream README) ──────
# --disable-programs --disable-inet --disable-inet6 reduce attack surface
# and prevent assertion failures that caused the GLib int3 trap crash
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

# ── libwebsockets 4.3.3 (v4.3-stable is still current stable branch) ─────────
# Fetching from git v4.3-stable instead of a zip for latest patch commits
RUN cd /builds && \
    git clone --branch v4.3-stable --depth 1 \
        https://github.com/warmcat/libwebsockets.git && \
    cd libwebsockets && \
    mkdir build && cd build && \
    cmake \
        -DLWS_MAX_SMP=1 \
        -DLWS_WITHOUT_EXTENSIONS=0 \
        -DCMAKE_INSTALL_PREFIX:PATH=/usr \
        -DCMAKE_C_FLAGS="-fpic" .. && \
    make && make install && \
    rm -rf /builds/libwebsockets

# ── libogg 1.3.5 (unchanged — still latest stable) ───────────────────────────
RUN cd /builds && \
    wget https://downloads.xiph.org/releases/ogg/libogg-1.3.5.zip && \
    unzip libogg-1.3.5.zip && \
    cd libogg-1.3.5 && \
    ./configure && make && make install && \
    rm -rf /builds/libogg-1.3.5.zip /builds/libogg-1.3.5

# ── sofia-sip v1.13.17 (was v1.13.2 — many SIP plugin fixes upstream) ─────────
RUN cd /builds && \
    git clone https://github.com/freeswitch/sofia-sip.git && \
    cd sofia-sip && \
    git checkout v1.13.17 && \
    sh autogen.sh && \
    ./configure && \
    make && make install && \
    rm -rf /builds/sofia-sip

# ── Janus Gateway v1.4.0 (was v1.2.4 — latest stable tag) ────────────────────
RUN cd /builds && \
    wget https://github.com/meetecho/janus-gateway/archive/refs/tags/v1.4.0.zip && \
    unzip v1.4.0.zip && \
    cd janus-gateway-1.4.0 && \
    sh autogen.sh && \
    ./configure \
        --prefix=/opt/janus-tools \
        --enable-post-processing && \
    make && make install && \
    make configs && \
    rm -rf /builds/v1.4.0.zip /builds/janus-gateway-1.4.0

ENV PATH="$PATH:/opt/janus-tools/bin"
