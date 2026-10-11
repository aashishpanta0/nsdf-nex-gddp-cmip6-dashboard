# NSDF NEX-GDDP-CMIP6 Dashboard

Interactive dashboard for the NASA NEX-GDDP-CMIP6 downscaled climate projections,
streamed with [OpenVisus](https://github.com/sci-visus/OpenVisus) from the NSDF
atlantis server.

The dashboard ships as a ready-to-run Docker image. You do not need to clone
this repository or install Python; everything below uses the published image.

| | |
| --- | --- |
| Image | `ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard` ([package page](https://github.com/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard/pkgs/container/nsdf-nex-gddp-cmip6-dashboard)) |
| Tags | `latest` (newest build of `main`) and `X.Y.Z` (releases) |
| Platform | `linux/amd64` (runs under emulation on Apple Silicon and other ARM hosts) |
| Container port | `8080` |
| Dashboard URL | `http://<host>:<port>/` (redirects to `/nex-gddp-cmip6`) |

## Quick start

You need [Docker](https://docs.docker.com/get-docker/) (Docker Desktop or Docker Engine).

```bash
docker run -d --name nsdf-nex-gddp-cmip6 -p 12347:8080 ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard:latest
```

Open <http://localhost:12347/>. The first load can take a minute while data is fetched.

When you are done, stop and remove it with `docker rm -f nsdf-nex-gddp-cmip6`.

## Deploy on a server

Both options restart the dashboard automatically and keep downloaded data in a
named volume.

### Option A: `docker run`

```bash
docker run -d --name nsdf-nex-gddp-cmip6 --restart unless-stopped \
  -p 12347:8080 \
  -v nsdf-nex-gddp-cmip6-cache:/var/cache/visus \
  ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard:latest
```

### Option B: Docker Compose

Save this as `docker-compose.yml` (the same file is in this repository), then run
`docker compose up -d`:

```yaml
# NSDF NEX-GDDP-CMIP6 Dashboard: run `docker compose up -d`, then open http://localhost:12347/
# Every setting is optional; see "Configuration" in the README.
services:
  nsdf-nex-gddp-cmip6:
    image: ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard:latest
    platform: linux/amd64
    restart: unless-stopped
    ports:
      - "12347:8080"
    environment:
      BOKEH_ALLOW_WS_ORIGIN: "*"  # on a server, set to the public hostname
      # DATASET: /data/my-dataset/visus.idx
    volumes:
      - cache:/var/cache/visus
      # - ./data:/data:ro

volumes:
  cache:
```

Either way the dashboard is at `http://<server>:12347/`. To serve it under a
hostname, see [Behind a reverse proxy](#behind-a-reverse-proxy).

## Configuration

The image has working defaults for everything. To change one, add
`-e NAME=value` to `docker run`, or set it under `environment:` in Compose.

| Variable | Default | Description |
| --- | --- | --- |
| `DATASET` | `https://atlantis.sci.utah.edu/mod_visus?dataset=nex-gddp-cmip6` | What the dashboard opens: an OpenVisus `.idx` URL or path, or a JSON scene list |
| `BOKEH_ALLOW_WS_ORIGIN` | `*` (any) | Host name(s) browsers use to reach the dashboard, comma-separated, e.g. `dashboards.example.org`. Set this on public servers |
| `PORT` | `8080` | Port the server listens on inside the container. Change it only with `--network host` |

| Container path | Purpose |
| --- | --- |
| `/var/cache/visus` | Cache of downloaded data. Mount a named volume to keep it across restarts |
| `/data` | Empty mount point for your own datasets |

Arguments after the image name are passed to
[`panel serve`](https://panel.holoviz.org/how_to/server/commandline.html), for
example `--num-procs 4` or `--prefix /dashboards`.

### Use your own dataset

Mount the directory that holds it at `/data` and point `DATASET` at it:

```bash
docker run -d --name nsdf-nex-gddp-cmip6 -p 12347:8080 \
  -v /path/to/datasets:/data:ro \
  -e DATASET=/data/my-dataset/visus.idx \
  ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard:latest
```

A remote dataset needs no mount: `-e DATASET='https://example.org/path/visus.idx'`.

### Behind a reverse proxy

The dashboard uses WebSockets, so the proxy must forward the upgrade headers.
With nginx:

```nginx
location / {
    proxy_pass http://127.0.0.1:12347;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_read_timeout 1h;
}
```

Publish the port on localhost only (`-p 127.0.0.1:12347:8080`) so the dashboard
is reachable only through the proxy, and set
`-e BOKEH_ALLOW_WS_ORIGIN=<your hostname>`.

## Manage a running dashboard

| Task | `docker run` | Docker Compose |
| --- | --- | --- |
| Follow logs | `docker logs -f nsdf-nex-gddp-cmip6` | `docker compose logs -f` |
| Status and health | `docker ps -f name=nsdf-nex-gddp-cmip6` | `docker compose ps` |
| Stop and remove | `docker rm -f nsdf-nex-gddp-cmip6` | `docker compose down` |
| Delete the data cache | `docker volume rm nsdf-nex-gddp-cmip6-cache` | `docker compose down --volumes` |

### Update to the newest image

Docker keeps using the image already on your machine, so pull first:

```bash
docker pull ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard:latest
docker rm -f nsdf-nex-gddp-cmip6
```

Then start it again with the same `docker run` command. With Compose, run
`docker compose pull && docker compose up -d`.

To stay on a fixed release instead of `latest`, use one of the version tags
listed on the [package page](https://github.com/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard/pkgs/container/nsdf-nex-gddp-cmip6-dashboard), e.g. `:1.0.0`.

## Troubleshooting

- **Warning: `requested image's platform (linux/amd64) does not match`**:
  harmless on Apple Silicon and other ARM machines. OpenVisus has no Linux ARM
  build, so the image runs under emulation, which is slower. Add
  `--platform linux/amd64` to hide the warning. On ARM Linux without Docker
  Desktop, enable emulation once with
  `docker run --privileged --rm tonistiigi/binfmt --install amd64`.
- **Port already in use**: change the left-hand number of `-p`, e.g.
  `-p 9000:8080`, then open `http://localhost:9000/`.
- **Page loads but stays blank**: the browser's WebSocket connection is being
  refused. Behind a proxy, check the upgrade headers above and that
  `BOKEH_ALLOW_WS_ORIGIN` matches the hostname in the address bar.
- **Still running an old version**: `docker run` does not fetch a newer
  `latest` by itself; follow [Update to the newest image](#update-to-the-newest-image).

## For maintainers

[`.github/workflows/docker.yml`](.github/workflows/docker.yml) builds the image,
starts it, loads the dashboard page, and fails if the dashboard logs an error.
Only then is the image published:

| Event | Published tags |
| --- | --- |
| Push to `main` | `latest` |
| Push a `vX.Y.Z` tag | `X.Y.Z` |
| Pull request | none (build and test only) |

```bash
git tag v1.0.0
git push origin v1.0.0
```

To build and run it locally:

```bash
docker build --platform linux/amd64 -t nsdf-nex-gddp-cmip6-dashboard .
docker run --rm -p 12347:8080 nsdf-nex-gddp-cmip6-dashboard
```

The image runs this repository's own copy of openvisuspy (from [aashishpanta0/openvpy-cmip6-public](https://github.com/aashishpanta0/openvpy-cmip6-public), branch `main`); the
dashboard itself is in [`src/openvisuspy/dashboards/`](src/openvisuspy/dashboards). For notebooks, local Python installs, and
other dashboards, see [openvisuspy](https://github.com/sci-visus/openvisuspy).
