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
    libogg-dev \
    opus-dev \
    flex bison \
    lua-dev \
    python3 python3-dev py3-pip py3-setuptools py3-wheel \
    ffmpeg-libs ffmpeg ffmpeg-dev \
    zlib-dev \
    gnutls-dev \
    graphviz doxygen \
    libconfig-dev libconfig-static \
    nanomsg-dev \
    duktape-dev \
    curl-dev"

RUN apk update && apk upgrade && \
    apk add --no-cache $BUILD_DEPS

WORKDIR /builds

############################################
# Build: paho.mqtt.c
############################################
# Note: Using CMake as it is the officially supported build system for Paho C, 
# ensuring correct installation to /usr for Alpine's musl libc.
RUN git clone https://github.com/eclipse/paho.mqtt.c.git && \
    cd paho.mqtt.c && \
    cmake -B build -S . -DCMAKE_INSTALL_PREFIX=/usr -DPAHO_BUILD_SHARED=TRUE -DPAHO_WITH_SSL=TRUE && \
    cmake --build build --target install && \
    cd .. && rm -rf paho.mqtt.c

############################################
# Build: rabbitmq-c
############################################
RUN git clone https://github.com/alanxz/rabbitmq-c && \
    cd rabbitmq-c && \
    git submodule init && git submodule update && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SHARED_LIBS=ON .. && \
    make && make install && \
    cd ../.. && rm -rf rabbitmq-c

############################################
# Build: libnice
############################################
# Note: libnice-dev is intentionally excluded from BUILD_DEPS to prevent 
# conflicts with the master branch compilation as per Janus README.
RUN git clone https://gitlab.freedesktop.org/libnice/libnice && \
    cd libnice && \
    meson setup build --prefix=/usr && \
    ninja -C build && ninja -C build install && \
    cd .. && rm -rf libnice

############################################
# Build: libsrtp
############################################
# Note: --enable-openssl is strictly required by Janus for AES-GCM support.
RUN wget https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz && \
    tar xfv v2.2.0.tar.gz && \
    cd libsrtp-2.2.0 && \
    ./configure --prefix=/usr --enable-openssl && \
    make shared_library && make install && \
    cd .. && rm -rf v2.2.0.tar.gz libsrtp-2.2.0

############################################
# Build: usrsctp
############################################
RUN git clone https://github.com/sctplab/usrsctp && \
    cd usrsctp && \
    ./bootstrap && \
    ./configure --prefix=/usr --disable-programs --disable-inet --disable-inet6 && \
    make && make install && \
    cd .. && rm -rf usrsctp

############################################
# Build: libwebsockets
############################################
# Note: Cloning and checking out v4.3-stable as explicitly recommended by the Janus README.
RUN git clone https://github.com/warmcat/libwebsockets.git && \
    cd libwebsockets && \
    git checkout v4.3-stable && \
    mkdir build && cd build && \
    cmake -DLWS_MAX_SMP=1 \
          -DLWS_WITHOUT_EXTENSIONS=0 \
          -DCMAKE_INSTALL_PREFIX=/usr \
          -DCMAKE_C_FLAGS="-fPIC" .. && \
    make && make install && \
    cd ../.. && rm -rf libwebsockets

############################################
# Build: sofia-sip
############################################
RUN git clone https://github.com/freeswitch/sofia-sip.git && \
    cd sofia-sip && \
    git checkout v1.13.2 && \
    sh autogen.sh && \
    ./configure --prefix=/usr && \
    make && make install && \
    cd .. && rm -rf sofia-sip

############################################
# Build: Janus Gateway 1.4.1
############################################
# Note: Autodetects installed dependencies. 'make configs' is required per README 
# to generate the default .jcfg files.
RUN wget https://github.com/meetecho/janus-gateway/archive/refs/tags/v1.4.1.zip && \
    unzip v1.4.1.zip && \
    cd janus-gateway-1.4.1 && \
    sh autogen.sh && \
    ./configure --prefix=/opt/janus && \
    make && make install && \
    make configs && \
    cd .. && rm -rf janus-gateway-1.4.1 v1.4.1.zip

ENV PATH="/opt/janus/bin:${PATH}"
