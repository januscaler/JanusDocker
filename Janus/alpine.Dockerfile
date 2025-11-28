ARG architecture=x86_64
FROM shivanshtalwar0/januscoredeps-alpine

LABEL maintainer="shivansh talwar <shivanshtalwar0@gmail.com>"
LABEL description="Provides an image with Janus Gateway"

RUN echo "reload s"	    

RUN cd ~ \
    && git clone https://github.com/meetecho/janus-gateway.git \
    && cd janus-gateway \
    && sh autogen.sh \
    && ./configure --prefix=/opt/janus  \
    && make \
    && make install \
    && make configs
COPY conf/*.jcfg /opt/janus/etc/janus/
EXPOSE 7088 8088 8188 8089 7188
EXPOSE 10000-10200/udp
CMD /opt/janus/bin/janus
