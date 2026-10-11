# NSDF NEX-GDDP-CMIP6 Dashboard

Docker packaging of the NEX-GDDP-CMIP6 Panel dashboard. The image is published
to `ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard` on every push to `main`
(tag `latest`, plus a `sha-<commit>` tag per build).

For local (non-Docker) installation, notebooks, and other dashboards, see the
original [openvisuspy](https://github.com/sci-visus/openvisuspy) repository.

## Requirements

- Docker with Compose v2 (`docker compose version`)
- Git
- An x86_64 (amd64) machine, or an ARM machine that can emulate amd64
  (Docker Desktop on Apple Silicon/Windows does this automatically; on ARM Linux
  install QEMU with `docker run --privileged --rm tonistiigi/binfmt --install amd64`).
  The image is amd64-only because OpenVisus publishes no Linux ARM wheels.

## Run the published image (recommended)

1. Clone the repository:

   ```sh
   git clone https://github.com/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard.git
   cd nsdf-nex-gddp-cmip6-dashboard
   ```

2. Create your local settings file (edit it if you need a different port):

   ```sh
   cp .env.example .env
   ```

3. Pull the latest image:

   ```sh
   docker compose pull
   ```

4. Start the dashboard in the background:

   ```sh
   docker compose up -d
   ```

5. Open <http://localhost:12347/nex-gddp-cmip6> in your browser.

6. Stop it when you are done:

   ```sh
   docker compose down
   ```

### Update to a newer image

Compose keeps using the image it already has, so pull before restarting:

```sh
docker compose pull
docker compose up -d
```

## Build the image yourself

Follow steps 1–2 above, then:

```sh
docker compose up --build -d
```

This builds from the local `Dockerfile` and tags the result as
`NEX_GDDP_CMIP6_IMAGE`. Run `docker compose pull` later to switch back to the
published image.

## Check on it

```sh
docker compose ps            # is it running, and on which port
docker compose logs -f       # follow the logs (Ctrl+C to stop following)
docker compose config        # the resolved ports and command
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

After changing `.env`, apply it with `docker compose up -d`. For example, setting
`NEX_GDDP_CMIP6_PORT=8080` serves the dashboard at
<http://localhost:8080/nex-gddp-cmip6>.

The dashboard keeps a data cache in a Docker volume. To remove it as well:
`docker compose down --volumes`.

## Docker without Compose

```sh
docker pull --platform linux/amd64 ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard:latest
docker run --rm --platform linux/amd64 -p 127.0.0.1:12347:12347 \
    ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard:latest \
    --address 0.0.0.0 --port 12347 \
    --args "https://atlantis.sci.utah.edu/mod_visus?dataset=nex-gddp-cmip6"
```

Then open <http://localhost:12347/nex-gddp-cmip6>; press Ctrl+C to stop.

## Troubleshooting

- `no matching manifest for linux/arm64 ... not found` (or "latest not found")
  on an ARM machine: add `--platform linux/amd64` to `docker pull`/`docker run`.
  Compose already does this via `NEX_GDDP_CMIP6_PLATFORM`.
