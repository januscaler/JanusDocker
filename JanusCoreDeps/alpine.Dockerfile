ARG PLATFORM=linux/arm64
FROM --platform=${PLATFORM} alpine:3.20

LABEL maintainer="shivansh talwar <shivanshtalwar0@gmail.com>"
LABEL description="Janus Gateway dependencies on Alpine 3.20"

ENV BUILD_DEPS=" \
    build-base \
    autoconf automake libtool \
    cmake ninja meson \
    linux-headers \
    bash curl wget git unzip zip ca-certificates \
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
    ffmpeg-libs ffmpeg ffmpeg-dev \
    zlib-dev \
    graphviz doxygen \
    libconfig-dev libconfig-static \
    nanomsg-dev \
    curl-dev"

RUN apk update && apk upgrade && \
    apk add --no-cache $BUILD_DEPS

WORKDIR /builds

############################################
# Build: paho.mqtt.c (latest)
############################################
RUN git clone --depth 1 https://github.com/eclipse-paho/paho.mqtt.c.git && \
    cd paho.mqtt.c && \
    cmake -B build -S . \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DPAHO_BUILD_SHARED=TRUE \
        -DPAHO_WITH_SSL=TRUE \
        -DPAHO_HIGH_PERFORMANCE=TRUE \
        -DPAHO_ENABLE_TESTING=FALSE && \
    cmake --build build --target install && \
    cd .. && rm -rf paho.mqtt.c

############################################
# Build: rabbitmq-c (latest master)
############################################
RUN git clone --depth 1 https://github.com/alanxz/rabbitmq-c && \
    cd rabbitmq-c && \
    git submodule init && git submodule update && \
    cmake -B build -S . \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DBUILD_SHARED_LIBS=ON && \
    cmake --build build --target install && \
    cd .. && rm -rf rabbitmq-c

############################################
# Build: libnice (master — Janus README recommendation)
############################################
RUN git clone --depth 1 https://gitlab.freedesktop.org/libnice/libnice && \
    cd libnice && \
    meson setup build --prefix=/usr && \
    ninja -C build && ninja -C build install && \
    cd .. && rm -rf libnice

############################################
# Build: libsrtp v2.8.0 (2.x recommended, --enable-openssl required)
############################################
RUN wget https://github.com/cisco/libsrtp/archive/v2.8.0.tar.gz && \
    tar xfv v2.8.0.tar.gz && \
    cd libsrtp-2.8.0 && \
    ./configure --prefix=/usr --enable-openssl && \
    make shared_library && make install && \
    cd .. && rm -rf v2.8.0.tar.gz libsrtp-2.8.0

############################################
# Build: usrsctp (latest master, Janus recommended flags)
############################################
RUN git clone --depth 1 https://github.com/sctplab/usrsctp && \
    cd usrsctp && \
    ./bootstrap && \
    ./configure --prefix=/usr \
        --disable-programs \
        --disable-inet \
        --disable-inet6 && \
    make && make install && \
    cd .. && rm -rf usrsctp

############################################
# Build: libwebsockets v4.3-stable (Janus README recommended)
############################################
RUN git clone --branch v4.3-stable --depth 1 \
        https://github.com/warmcat/libwebsockets.git && \
    cd libwebsockets && \
    cmake -B build -S . \
        -DLWS_MAX_SMP=1 \
        -DLWS_WITHOUT_EXTENSIONS=0 \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_C_FLAGS="-fpic" && \
    cmake --build build --target install && \
    cd .. && rm -rf libwebsockets

############################################
# Build: libogg v1.3.6 (latest stable)
############################################
RUN wget https://github.com/xiph/ogg/releases/download/v1.3.6/libogg-1.3.6.tar.gz && \
    tar xfv libogg-1.3.6.tar.gz && \
    cd libogg-1.3.6 && \
    ./configure --prefix=/usr && make && make install && \
    cd .. && rm -rf libogg-1.3.6.tar.gz libogg-1.3.6

############################################
# Build: sofia-sip v1.13.17 (latest)
############################################
RUN git clone --depth 1 --branch v1.13.17 \
        https://github.com/freeswitch/sofia-sip.git && \
    cd sofia-sip && \
    sh autogen.sh && \
    ./configure --prefix=/usr && \
    make && make install && \
    cd .. && rm -rf sofia-sip

############################################
# Build: Janus Gateway v1.4.1 (latest stable)
############################################
RUN wget https://github.com/meetecho/janus-gateway/archive/refs/tags/v1.4.1.zip && \
    unzip v1.4.1.zip && \
    cd janus-gateway-1.4.1 && \
    sh autogen.sh && \
    ./configure \
        --prefix=/opt/janus \
        --enable-post-processing && \
    make && make install && \
    make configs && \
    cd .. && rm -rf janus-gateway-1.4.1 v1.4.1.zip

ENV PATH="/opt/janus/bin:${PATH}"
