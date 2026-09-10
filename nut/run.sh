#!/usr/bin/env sh
set -e

usbhid-ups -u nut -a myups
upsd -u nut

exec /usr/sbin/upsmon -D
