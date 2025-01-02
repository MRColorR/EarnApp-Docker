FROM ubuntu:24.04

LABEL maintainer="MRColorR"

ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker

# Install dependencies, including Tini
RUN apt-get update \
    && apt-get install -y \
       wget \
       curl \
       dos2unix \
       iputils-ping \
       net-tools \
       htop \
       libatomic1 \
       tini \
       jq \
    && apt-get clean

# Copy optional IP-check script (myip.sh)
COPY src/myip.sh /usr/bin/myip
RUN dos2unix /usr/bin/myip && chmod +x /usr/bin/myip

# Copy our mock script into the container
COPY src/mock-hostnamectl.sh /usr/local/bin/mock-hostnamectl.sh
RUN dos2unix /usr/local/bin/mock-hostnamectl.sh \
    && chmod +x /usr/local/bin/mock-hostnamectl.sh \
    # Symlink it to /usr/bin/hostnamectl so that calls to hostnamectl use our mock
    && ln -s /usr/local/bin/mock-hostnamectl.sh /usr/bin/hostnamectl

# Optional: If you want to pre-seed the JSON, copy a default file in:
# COPY src/hostinfo.json /etc/mock-hostnamectl/hostinfo.json

# Copy our custom entrypoint script
COPY src/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy our systemctl mock script into the container
COPY src/mock-systemctl.sh /usr/local/bin/mock-systemctl.sh
RUN dos2unix /usr/local/bin/mock-systemctl.sh \
    && chmod +x /usr/local/bin/mock-systemctl.sh \
    && ln -s /usr/local/bin/mock-systemctl.sh /usr/bin/systemctl

# EarnApp data stored here; can be persisted across container restarts
VOLUME [ "/etc/earnapp" ]

# Use Tini as our entrypoint to handle signals/init correctly
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]

# We'll default to a command that starts EarnApp
# CMD ["bash", "-c", "earnapp start && sleep 5 && earnapp run"]
CMD ["bash", "-c", "earnapp status && sleep 600 && earnapp run"]

# Healthcheck if desired
HEALTHCHECK --interval=1m --timeout=10s --start-period=10s --retries=2 \
  CMD /usr/bin/myip && grep -q enabled /etc/earnapp/status && exit 0 || exit 1
