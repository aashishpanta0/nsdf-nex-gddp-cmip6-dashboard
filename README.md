# NSDF NEX-GDDP-CMIP6 Dashboard

Docker packaging of the NEX-GDDP-CMIP6 Panel dashboard. The image is published
to `ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard` by
`.github/workflows/docker.yml` on pushes to `main` and on `v*` tags.

For local (non-Docker) installation, notebooks, and other dashboards, see the
original [openvisuspy](https://github.com/sci-visus/openvisuspy) repository.

## Quick start

```sh
cp .env.example .env
docker compose pull          # use the published image
docker compose up -d
```

Open <http://localhost:12347/nex-gddp-cmip6>.

To build the image locally instead of pulling it:

```sh
docker compose up --build -d
```

## Manage

```sh
docker compose ps            # status
docker compose logs -f       # logs
docker compose config        # resolved ports and command
docker compose down          # stop (add --volumes to drop the cache)
```

## Configuration (`.env`)

| Variable | Default | Purpose |
| --- | --- | --- |
| `NEX_GDDP_CMIP6_PORT` | `12347` | Host port and in-container listen port (same number) |
| `NEX_GDDP_CMIP6_BIND_ADDRESS` | `127.0.0.1` | Host interface to publish on; `0.0.0.0` exposes it on the network |
| `NEX_GDDP_CMIP6_LISTEN_ADDRESS` | `0.0.0.0` | In-container listen address; keep `0.0.0.0` |
| `NEX_GDDP_CMIP6_ALLOW_WS_ORIGIN` | `*` | Allowed WebSocket origin(s); set to your hostname in production |
| `NEX_GDDP_CMIP6_DATASET` | atlantis `nex-gddp-cmip6` | Dataset URL passed to the dashboard |
| `NEX_GDDP_CMIP6_IMAGE` | GHCR `:latest` | Image to pull, or tag for local builds |
| `NEX_GDDP_CMIP6_PLATFORM` | `linux/amd64` | Image platform |

Address and port are passed at runtime by Compose; none are baked into the image.

## Docker without Compose

```sh
docker run --rm -p 127.0.0.1:12347:12347 \
    ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard:latest \
    --address 0.0.0.0 --port 12347 \
    --args "https://atlantis.sci.utah.edu/mod_visus?dataset=nex-gddp-cmip6"
```
