FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nut \
        nut-server \
        nut-client \
        dumb-init \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p /var/run/nut /var/state/nut /etc/nut/conf.d

VOLUME ["/etc/nut", "/var/run/nut", "/var/state/nut"]

EXPOSE 3493

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["upsd", "-D"]
