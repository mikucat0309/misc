FROM alpine:3.24

RUN <<EOF
apk add --no-cache nut util-linux-misc
mkdir -p /var/run/nut
chmod 700 /var/run/nut
chown nut:nut /var/run/nut
EOF

COPY <<EOF /etc/nut/ups.conf
[myups]
  driver = usbhid-ups
  port = auto
  vendorid = 0764
  productid = 0601
EOF

COPY <<EOF /etc/nut/upsd.users
[admin]
  password = password
  upsmon primary
  actions = SET
  instcmds = ALL
EOF

COPY <<EOF /etc/nut/upsmon.conf
MINSUPPLIES 1
MONITOR myups@localhost 1 admin password primary
SHUTDOWNCMD "dbus-send --print-reply --system --dest=org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager.PowerOff boolean:true"
EOF

COPY --chmod=755 run.sh /run.sh
ENV PATH="$PATH:/usr/lib/nut"
CMD [ "/run.sh" ]
