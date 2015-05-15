#!/bin/bash
set -e

/setup.sh

exec supervisord -c /etc/supervisor/supervisord.conf
