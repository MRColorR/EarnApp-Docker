FROM ubuntu:24.04

LABEL maintainer="MRColorR"

ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

# Install systemd + other packages
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    apt-utils \
    locales \
    python3-pip \
    software-properties-common \
    rsyslog \
    systemd \
    systemd-cron \
    iproute2 \
    wget \
    curl \
    sudo \
    nano \
    dos2unix \
    iputils-ping \
    net-tools \
    htop \
    libatomic1 \
 && rm -Rf /var/lib/apt/lists/* \
 && rm -Rf /usr/share/doc \
 && rm -Rf /usr/share/man \
 && rm -rf /tmp/* /var/tmp/* \
 && rm -f /lib/systemd/system/multi-user.target.wants/* \
 && rm -f /etc/systemd/system/*.wants/* \
 && rm -f /lib/systemd/system/local-fs.target.wants/* \
 && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
 && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
 && rm -f /lib/systemd/system/basic.target.wants/* \
 && rm -f /lib/systemd/system/anaconda.target.wants/* \
 && rm -f /lib/systemd/system/plymouth* \
 && rm -f /lib/systemd/system/systemd-update-utmp* \
 && apt-get clean

RUN locale-gen en_US.UTF-8

WORKDIR /app

# (Optional) IP-check script
COPY src/myip.sh /usr/bin/myip
RUN dos2unix /usr/bin/myip && chmod +x /usr/bin/myip

# Our earnapp_entrypoint.sh that systemd will run
COPY src/earnapp_entrypoint.sh /usr/bin/earnapp_entrypoint.sh
RUN dos2unix /usr/bin/earnapp_entrypoint.sh && chmod +x /usr/bin/earnapp_entrypoint.sh

# Our systemd service unit that calls earnapp_entrypoint.sh
COPY src/installer.service /etc/systemd/system/installer.service
RUN dos2unix /etc/systemd/system/installer.service \
 && chmod 644 /etc/systemd/system/installer.service \
 && systemctl enable installer.service

# A small script that writes EARNAPP_UUID to /etc/earnapp/earnapp.conf,
# then execs /sbin/init so systemd can start as PID 1
COPY src/docker-init.sh /usr/local/bin/docker-init.sh
RUN dos2unix /usr/local/bin/docker-init.sh && chmod +x /usr/local/bin/docker-init.sh

# EarnApp uses /etc/earnapp for config
VOLUME [ "/etc/earnapp" ]
# cgroup mount for systemd
VOLUME [ "/sys/fs/cgroup" ]

# Use docker-init.sh as the entrypoint, which sets up environment and starts systemd
CMD ["/usr/local/bin/docker-init.sh"]
