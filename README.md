# nut-docker

A minimal Docker image for [NUT (Network UPS Tools)](https://networkupstools.org/).

## Build locally

```bash
docker build -t nut:local .
```

## Run example

```bash
docker run --rm -p 3493:3493 nut:local
```

This image auto-creates minimal defaults on startup:

- `/etc/nut/upsd.conf` with `LISTEN 0.0.0.0 3493`
- `/etc/nut/nut.conf` with `MODE=netserver`

Mount your own `/etc/nut` to provide production configs.

## GitHub Actions publish

The workflow publishes to:

- Docker Hub: `DOCKERHUB_USERNAME/nut`
- GitHub Container Registry: `ghcr.io/<owner>/nut`

Required repository secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
