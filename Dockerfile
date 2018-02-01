FROM ubuntu:16.04
USER root

#--- Update image and install tools packages
ARG DEBIAN_FRONTEND=noninteractive
ENV INIT_PACKAGES="ca-certificates apt-utils wget sudo" \
    TOOLS_PACKAGES="openssh-server openssl supervisor git-core s3cmd bash-completion curl unzip vim less mlocate nano silversearcher-ag colordiff" \
    NET_PACKAGES="net-tools iproute2 iputils-ping netcat dnsutils apt-transport-https tcpdump mtr-tiny" \
    DEV_PACKAGES="python-pip python-setuptools python-dev build-essential libxml2-dev libxslt1-dev libpq-dev libsqlite3-dev libmysqlclient-dev libssl-dev zlib1g-dev" 

RUN apt-get update && apt-get install -y --no-install-recommends ${INIT_PACKAGES} && \
    apt-get update && apt-get install -y --no-install-recommends ${TOOLS_PACKAGES} ${NET_PACKAGES} ${DEV_PACKAGES} && \
    apt-get upgrade -y && apt-get clean && apt-get autoremove -y && apt-get purge && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*


#--- Setup SSH access, secure root login (SSH login fix. Otherwise user is kicked off after login) and create user
ADD scripts/createusers.sh scripts/supervisord scripts/disable_ssh_password_auth /usr/local/bin/
ADD supervisord/sshd.conf /etc/supervisor/conf.d/
RUN echo "root:`date +%s | sha256sum | base64 | head -c 32 ; echo`" | chpasswd && \
    sed -i 's/PermitRootLogin without-password/PermitRootLogin no/g' /etc/ssh/sshd_config && \
    mkdir -p /var/run/sshd /var/log/supervisor && \
    chmod 755 /usr/local/bin/supervisord /usr/local/bin/disable_ssh_password_auth /usr/local/bin/createusers.sh && \
    sed -i 's/.*\[supervisord\].*/&\nnodaemon=true\nloglevel=debug/' /etc/supervisor/supervisord.conf && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    mkdir -p /data && chown root:users /data && \
    rm -fr /tmp/*

#--- Launch supervisord daemon
EXPOSE 22
CMD /usr/local/bin/supervisord
