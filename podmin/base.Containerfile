FROM quay.io/bootc-devel/fedora-bootc-44-minimal:latest

ARG SSH_USER=user
ARG SSH_PUBKEY_FILE=authorized_keys

COPY <<EOF /etc/dnf/dnf.conf
[main]
tsflags=nodocs
install_weak_deps=False
EOF

RUN <<EORUN
set -exuo pipefail
dnf install -y shadow-utils sudo NetworkManager cloud-init cloud-utils-growpart \
  iproute openssh-server podman
rm -rf /run/cloud-init
dnf clean all
rm -rf /var/cache/* /var/lib/dnf /var/log/dnf5.log /run/dnf
EORUN

# -------- Bootc --------

COPY <<EOF /usr/lib/composefs/setup-root-conf.toml
[etc]
mount = "transient"
EOF

# -------- Network Manager --------

COPY <<EOF /usr/lib/tmpfiles.d/99-network-manager-dirs.conf
d /var/lib/NetworkManager 0700 root root - -
EOF

# -------- Cloud-init --------

COPY <<EOF /etc/cloud/cloud.cfg.d/99-network-renderer.cfg
system_info:
  network:
    renderers: ['NetworkManager']
EOF

COPY <<EOF /etc/cloud/cloud.cfg.d/99-fallback-dhcp.cfg
network:
  config: disabled
  fallback:
    mode: dbus
EOF

COPY <<EOF /etc/cloud/cloud.cfg.d/99-disable-ssh-keygen.cfg
ssh_deletekeys: false
ssh_genkeytypes: []
EOF

COPY <<EOF /usr/lib/tmpfiles.d/99-cloud-init-dirs.conf
d /var/lib/cloud 0755 root root - -
EOF

# -------- SSH --------

RUN install -d -m 0755 /etc/ssh/sshd_config.d
RUN install -d -m 0755 /usr/share/ssh/keys
COPY <<EOF /etc/ssh/sshd_config.d/99-bootc.conf
PermitRootLogin no
PasswordAuthentication no
HostKey /var/lib/ssh/hostkeys/ssh_host_rsa_key
HostKey /var/lib/ssh/hostkeys/ssh_host_ecdsa_key
HostKey /var/lib/ssh/hostkeys/ssh_host_ed25519_key
AuthorizedKeysFile /usr/share/ssh/keys/%u.authorized_keys
EOF

COPY <<EOF /etc/systemd/system/sshd-keygen@.service.d/99-bootc.conf
[Unit]
ConditionPathExists=!/var/lib/ssh/hostkeys/ssh_host_%i_key

[Service]
ExecStart=
ExecStart=/usr/bin/ssh-keygen -q -t %i -f /var/lib/ssh/hostkeys/ssh_host_%i_key -C '' -N ''
EOF

COPY <<EOF /etc/selinux/targeted/contexts/files/file_contexts.local
/var/lib/ssh/hostkeys(/.*)?   system_u:object_r:ssh_home_t:s0
/usr/share/ssh/keys(/.*)?   system_u:object_r:ssh_home_t:s0
EOF

COPY <<EOF /usr/lib/tmpfiles.d/99-ssh-dirs.conf
d /var/db/sudo 0700 root root - -
d /var/db/sudo/lectured 0700 root root - -
d /var/lib/ssh 0755 root root - -
d /var/lib/ssh/hostkeys 0750 root root - -
EOF

# -------- User --------

COPY <<EOF /usr/lib/sysusers.d/99-${SSH_USER}.conf
u ${SSH_USER} - - /var/home/${SSH_USER} /usr/bin/bash
m ${SSH_USER} wheel
EOF

COPY --chmod=440 <<EOF /etc/sudoers.d/99-${SSH_USER}
${SSH_USER} ALL=(ALL) NOPASSWD: ALL
EOF

COPY <<EOF /usr/lib/tmpfiles.d/99-${SSH_USER}.conf
d /var/home/${SSH_USER} 0700 ${SSH_USER} ${SSH_USER} - -
z /var/home/${SSH_USER} 0700 ${SSH_USER} ${SSH_USER} - -
EOF

ADD --chmod=644 ${SSH_PUBKEY_FILE} /usr/share/ssh/keys/${SSH_USER}.authorized_keys

# -------- Cleanup --------

RUN find /usr/share/locale -mindepth 1 -maxdepth 1 -type d ! -name en ! -name en_US -exec rm -rf {} +
RUN rm -rf /usr/share/man
RUN rm -rf /usr/share/info
RUN rm -rf /usr/share/doc
RUN rm -rf /usr/share/licenses

RUN bootc container lint
LABEL containers.bootc=1
LABEL ostree.bootable=1
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
