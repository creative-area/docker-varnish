#!/bin/bash
set -e

/setup.sh

varnishd -f /etc/varnish/default.vcl -s ${VARNISH_STORAGE_BACKEND} -a 0.0.0.0:${VARNISH_PORT}
sleep 4
varnishlog
