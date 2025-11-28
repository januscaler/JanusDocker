ARG PLATFORM=linux/arm64
FROM --platform=${PLATFORM} alpine:3.20

LABEL maintainer="shivansh talwar <shivanshtalwar0@gmail.com>"
LABEL description="Janus Gateway dependencies on Alpine 3.20"

ENV BUILD_DEPS="\
    build-base \
    autoconf automake libtool \
    cmake ninja \
    linux-headers \
    bash curl wget git unzip zip \
    pkgconfig \
    openssl-dev \
    jansson-dev \
    glib-dev \
    glib-static \
    libffi-dev \
    libmicrohttpd-dev \
    libogg-dev \
    opus-dev \
    cmake \
    flex bison \
    lua5.3-dev \
    python3 python3-dev py3-pip py3-setuptools py3-wheel \
    ffmpeg-libs \
    ffmpeg \
    zlib-dev \
    gnutls-dev \
    graphviz \
    glib-dev \
    libconfig-dev \
    libconfig-static \
    jansson-dev \
    cmake \
    meson \
    ninja \
    openssl-dev \
    libnice-dev \
    openssl-dev \
    zlib-dev \
    ffmpeg-dev \
"

RUN apk update && apk upgrade && \
    apk add --no-cache $BUILD_DEPS

WORKDIR /builds

############################################
# Build: paho.mqtt.c
############################################
RUN git -c http.sslVerify=False clone https://github.com/eclipse/paho.mqtt.c.git && \
    cd paho.mqtt.c && \
    cmake -Bbuild -H. -DPAHO_BUILD_SHARED=TRUE -DPAHO_WITH_SSL=TRUE && \
    cmake --build build/ --target install && \
    cd .. && rm -rf paho.mqtt.c

############################################
# Build: rabbitmq-c (requires gnutls on Alpine)
############################################
RUN git -c http.sslVerify=False clone https://github.com/alanxz/rabbitmq-c && \
    cd rabbitmq-c && \
    git submodule init && git submodule update && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SHARED_LIBS=ON .. && \
    make && make install && \
    cd ../.. && rm -rf rabbitmq-c

############################################
# Build: libnice
############################################
RUN git -c http.sslVerify=False clone https://gitlab.freedesktop.org/libnice/libnice && \
    cd libnice && \
    meson setup build --prefix=/usr && \
    ninja -C build && ninja -C build install && \
    cd .. && rm -rf libnice

############################################
# Build: libsrtp
############################################
RUN wget https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz && \
    tar xfv v2.2.0.tar.gz && \
    cd libsrtp-2.2.0 && \
    ./configure --prefix=/usr --enable-openssl && \
    make shared_library && make install && \
    cd .. && rm -rf v2.2.0.tar.gz libsrtp-2.2.0

############################################
# Build: usrsctp
############################################
RUN git -c http.sslVerify=False clone https://github.com/sctplab/usrsctp && \
    cd usrsctp && \
    ./bootstrap && \
    ./configure --prefix=/usr && \
    make && make install && \
    cd .. && rm -rf usrsctp

############################################
# Build: libwebsockets
############################################
RUN wget https://github.com/warmcat/libwebsockets/archive/refs/tags/v4.3.3.zip && \
    unzip v4.3.3.zip && \
    cd libwebsockets-4.3.3 && \
    mkdir build && cd build && \
    cmake -DLWS_MAX_SMP=1 \
          -DLWS_WITHOUT_EXTENSIONS=0 \
          -DCMAKE_INSTALL_PREFIX=/usr \
          -DCMAKE_C_FLAGS="-fPIC" .. && \
    make && make install && \
    cd ../.. && rm -rf libwebsockets-4.3.3 v4.3.3.zip

############################################
# Build: libogg 1.3.5 (already installed, but building source anyway)
############################################
RUN wget https://downloads.xiph.org/releases/ogg/libogg-1.3.5.zip && \
    unzip libogg-1.3.5.zip && \
    cd libogg-1.3.5 && \
    ./configure && make && make install && \
    cd .. && rm -rf libogg-1.3.5 libogg-1.3.5.zip

############################################
# Build: sofia-sip 1.13.2
############################################
RUN git -c http.sslVerify=False clone https://github.com/freeswitch/sofia-sip.git && \
    cd sofia-sip && \
    git checkout v1.13.2 && \
    sh autogen.sh && \
    ./configure && \
    make && make install && \
    cd .. && rm -rf sofia-sip

       
############################################
# Build: Janus Gateway 1.2.4
############################################
RUN wget https://github.com/meetecho/janus-gateway/archive/refs/tags/v1.3.3.zip && \
    unzip v1.3.3.zip && \
    cd janus-gateway-1.3.3 && \
    sh autogen.sh && \
    ./configure --prefix=/opt/janus-tools \
                --enable-post-processing \
                --enable-all-plugins \
                --enable-all-transports && \
    make && make install && \
    cd .. && rm -rf janus-gateway-1.3.3 v1.3.3.zip

ENV PATH="/opt/janus-tools/bin:${PATH}"
