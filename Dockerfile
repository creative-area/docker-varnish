FROM ubuntu:14.04
MAINTAINER CREATIVE AREA

ENV DEBIAN_FRONTEND noninteractive
ENV VARNISH_PORT 80
ENV VARNISH_STORAGE_BACKEND malloc,100M
ENV VARNISHNCSA_LOGFORMAT %h %l %u %t "%r" %s %b "%{Referer}i" "%{User-agent}i"

RUN apt-get -qq update && apt-get install -y curl apt-transport-https supervisor

RUN sed -i 's/^\(\[supervisord\]\)$/\1\nnodaemon=true/' /etc/supervisor/supervisord.conf

RUN \
    curl -sL https://repo.varnish-cache.org/GPG-key.txt | apt-key add - && \
    echo "deb https://repo.varnish-cache.org/ubuntu/ trusty varnish-4.1" >> /etc/apt/sources.list.d/varnish-cache.list && \
    apt-get -qq update && \
    apt-get install -y varnish

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY default.vcl /etc/varnish/default.vcl

COPY setup.sh /setup.sh
COPY start.sh /start.sh
RUN chmod 0755 /start.sh /setup.sh

EXPOSE 80

CMD ["/start.sh"]
