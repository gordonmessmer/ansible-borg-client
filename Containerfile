# Use the official minimal or standard Fedora base image
FROM registry.fedoraproject.org/fedora:latest

# Install Python 3
RUN dnf -y install fuse-sshfs borgbackup --setopt=install_weak_deps=False && \
    dnf clean all

COPY roles/borgbackup/files/run-borg /root/run-borg

CMD ["/root/run-borg"]
