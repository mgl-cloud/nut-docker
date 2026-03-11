FROM alpine:3.20 AS builder

ARG NUT_VERSION=2.8.4
ENV NUT_VERSION=${NUT_VERSION}

RUN apk add --no-cache \
    alpine-sdk \
    autoconf \
    automake \
    bash \
    curl \
    libtool \
    linux-headers \
    neon-dev \
    openssl-dev \
    libusb-dev \
    libmodbus-dev \
    avahi-dev \
    pkgconf

WORKDIR /tmp
RUN curl -fsSL -o nut.tar.gz \
    "https://github.com/networkupstools/nut/releases/download/v${NUT_VERSION}/nut-${NUT_VERSION}.tar.gz" \
    && tar -xzf nut.tar.gz \
    && cd "nut-${NUT_VERSION}" \
    && ./configure \
      --prefix=/usr \
      --sysconfdir=/etc/nut \
      --with-statepath=/var/state/nut \
      --with-altpidpath=/var/run/nut \
      --with-user=root \
      --with-group=root \
      --with-usb \
    && make -j"$(nproc)" \
    && make DESTDIR=/opt/nut-root install-strip

FROM alpine:3.20

RUN apk add --no-cache \
    bash \
    ca-certificates \
    libusb \
    neon \
    libmodbus \
    avahi-libs \
    tini

COPY --from=builder /opt/nut-root/ /
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p /var/run/nut /var/state/nut /etc/nut/conf.d

VOLUME ["/etc/nut", "/var/run/nut", "/var/state/nut"]

EXPOSE 3493

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["upsd", "-D"]
