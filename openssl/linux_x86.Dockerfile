ARG OPENSSL_VERSION="3.0.1" 

FROM alpine:latest AS buildenv
LABEL maintainer="madnuttah"

ARG OPENSSL_VERSION

ENV OPENSSL_VERSION=${OPENSSL_VERSION} \
  OPENSSL_SHA256="c311ad853353bce796edad01a862c50a8a587f62e7e2100ef465ab53ec9b06d1 " \
  OPENSSL_DOWNLOAD_URL="https://www.openssl.org/source/openssl" \
  OPENSSL_PGP="8657ABB260F056B1E5190839D9C4D26D0E604491"

WORKDIR /tmp/src

RUN set -xe; \
  apk --update --no-cache add \
  ca-certificates \
  gnupg \
  curl \
  binutils \
  file && \
  apk --update --no-cache add --virtual .build-deps \
    build-base \
    perl \
    libidn2-dev \
    libevent-dev \
    linux-headers \
    apk-tools && \
    curl -sSL "${OPENSSL_DOWNLOAD_URL}"-"{$OPENSSL_VERSION}".tar.gz -o openssl.tar.gz && \
    echo "${OPENSSL_SHA256} ./openssl.tar.gz" | sha256sum -c - && \
    curl -L "${OPENSSL_DOWNLOAD_URL}"-"${OPENSSL_VERSION}".tar.gz.asc -o openssl.tar.gz.asc && \
    GNUPGHOME="$(mktemp -d)" && \
    export GNUPGHOME && \
    gpg --no-tty --keyserver keys.openpgp.org --recv-keys "${OPENSSL_PGP}" && \
    gpg --batch --verify openssl.tar.gz.asc openssl.tar.gz && \
    tar xzf openssl.tar.gz && \
    cd openssl-"${OPENSSL_VERSION}" && \
	env CPPFLAGS='-arch i386' \
      LDFLAGS='-arch i386' && \
    ./Configure \
      linux-generic32 \
      -m32 \
      no-weak-ssl-ciphers \
      no-ssl3 \
      no-err \
      shared \
      -DOPENSSL_NO_HEARTBEATS \
      -fstack-protector-strong \
      --prefix=/usr/local/openssl \
      --openssldir=/usr/local/openssl \
      --libdir=/usr/local/openssl/lib && \
  make && \
  make install_sw && \
  apk del --no-cache .build-deps && \
  pkill -9 gpg-agent && \
  pkill -9 dirmngr && \
  rm -rf \
    /usr/share/man \
    /usr/share/docs \
    /tmp/* \
    /var/tmp/* \
    /var/log/* 
