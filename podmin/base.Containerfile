FROM quay.io/bootc-devel/fedora-bootc-44-minimal:latest
ARG SSH_USER=user
ARG SSH_PUBKEY_FILE=authorized_keys

COPY <<EOF /etc/dnf/dnf.conf
[main]
tsflags=nodocs
install_weak_deps=False
EOF

RUN <<EORUN
dnf install -y openssh-server shadow-utils sudo
dnf clean all
rm -rf /var/cache/* /var/lib/dnf /var/log/dnf5.log /run/dnf
EORUN

COPY <<EOF /usr/lib/composefs/setup-root-conf.toml
[etc]
mount = "transient"
EOF

COPY <<EOF /usr/lib/bootc/config.d/00-update-repo.toml
[bootc.image]
source = "quay.io/mikucat0309/podmin:latest"
EOF

# -------- SSH --------

RUN install -d -m 0750 /var/lib/ssh/hostkeys
RUN install -d -m 0755 /etc/ssh/sshd_config.d
RUN install -d -m 0755 /usr/share/ssh/keys
COPY <<EOF /etc/ssh/sshd_config.d/90-bootc.conf
PermitRootLogin no
PasswordAuthentication no
HostKey /var/lib/ssh/hostkeys/ssh_host_rsa_key
HostKey /var/lib/ssh/hostkeys/ssh_host_ecdsa_key
HostKey /var/lib/ssh/hostkeys/ssh_host_ed25519_key
AuthorizedKeysFile /usr/share/ssh/keys/%u.authorized_keys
EOF
COPY <<EOF /usr/lib/systemd/system/sshd-hostkeys.service
[Unit]
Description=Generate sshd host keys
ConditionPathExists=!/var/lib/ssh/hostkeys/ssh_host_ed25519_key
After=local-fs.target
Before=sshd.service

[Service]
Type=oneshot
ExecStart=/usr/bin/install -d -m 0750 /var/lib/ssh/hostkeys
ExecStart=/usr/bin/ssh-keygen -A -f /var/lib/ssh/hostkeys
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF
RUN systemctl enable sshd-hostkeys.service

COPY <<EOF /etc/selinux/targeted/contexts/files/file_contexts.local
/var/lib/ssh/hostkeys(/.*)?   system_u:object_r:ssh_home_t:s0
/usr/share/ssh/keys(/.*)?   system_u:object_r:ssh_home_t:s0
EOF
RUN restorecon -R /var/lib/ssh/hostkeys /usr/share/ssh/keys

COPY <<EOF /usr/lib/tmpfiles.d/30-ssh-dirs.conf
d /var/db/sudo 0700 root root - -
d /var/db/sudo/lectured 0700 root root - -
d /var/lib/ssh 0755 root root - -
d /var/lib/ssh/hostkeys 0750 root root - -
EOF

# -------- User --------

RUN install -d -m 0700 /var/home/${SSH_USER}
COPY <<EOF /usr/lib/sysusers.d/30-${SSH_USER}.conf
u ${SSH_USER} - - /var/home/${SSH_USER} /usr/bin/bash
m ${SSH_USER} wheel
EOF
COPY --chmod=440 <<EOF /etc/sudoers.d/30-${SSH_USER}
${SSH_USER} ALL=(ALL) NOPASSWD: ALL
EOF
COPY <<EOF /usr/lib/tmpfiles.d/30-${SSH_USER}.conf
z /var/home/${SSH_USER} 0700 ${SSH_USER} ${SSH_USER} - -
EOF
ADD --chmod=644 ${SSH_PUBKEY_FILE} /usr/share/ssh/keys/${SSH_USER}.authorized_keys

RUN bootc container lint
LABEL containers.bootc=1
LABEL ostree.bootable=1
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
