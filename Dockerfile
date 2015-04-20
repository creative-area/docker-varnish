FROM        ubuntu:15.04
MAINTAINER  CREATIVE AREA

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && apt-get install -y varnish

ADD default.vcl /etc/varnish/default.vcl

ENV VARNISH_PORT 80
ENV VARNISH_STORAGE_BACKEND malloc,100M

COPY setup.sh /setup.sh
COPY start.sh /start.sh
RUN chmod 0755 /start.sh /setup.sh

EXPOSE 80

CMD ["/start.sh"]
