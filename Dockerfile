FROM node:8.4

MAINTAINER Revin Roman <roman@rmrevin.com>

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

ONBUILD ARG _UID
ONBUILD ARG _GID

ONBUILD RUN groupmod -g $_GID www-data \
 && usermod -u $_UID -g $_GID -s /bin/bash www-data \
 && echo "    IdentityFile ~/.ssh/id_rsa" >> /etc/ssh/ssh_config

RUN mkdir -p /var/www/ \
 && mkdir -p /var/run/php/ \
 && mkdir -p /var/log/php/ \
 && mkdir -p /var/log/app/ \
 && chown www-data:www-data /var/www/

RUN set -xe \
 && apt-get update -qq \
 && apt-get install -y --no-install-recommends \
        apt-utils bash-completion ca-certificates net-tools ssh-client \
        gcc make rsync chrpath curl wget rsync git vim unzip bzip2 supervisor

ARG GOSU_VERSION=1.10
RUN set -xe \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

RUN set -xe \
 && npm install -g gulp webpack yarn bower phantomjs

COPY supervisor.d/ /etc/supervisor/

RUN rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
