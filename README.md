# NSDF NEX-GDDP-CMIP6 Dashboard

Interactive dashboard for the NASA NEX-GDDP-CMIP6 downscaled climate projections,
streamed with [OpenVisus](https://github.com/sci-visus/OpenVisus) from the NSDF
atlantis server.

The dashboard is published as a Docker image. Everything below runs that image;
you do not need to clone this repository or install Python.

| | |
| --- | --- |
| Image | `ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard` ([package page](https://github.com/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard/pkgs/container/nsdf-nex-gddp-cmip6-dashboard)) |
| Tags | `latest` (newest build of `main`) and `X.Y.Z` (releases) |
| Platform | `linux/amd64` (runs under emulation on Apple Silicon and other ARM hosts) |
| Port | `12347` |
| Dashboard URL | `http://<host>:12347/nex-gddp-cmip6` |

## Run with Docker

You need [Docker](https://docs.docker.com/get-docker/).

```bash
docker run -d --name nex-gddp-cmip6 -p 12347:12347 ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard:latest
```

Open <http://localhost:12347/nex-gddp-cmip6>. The first load can take a minute while
data is fetched. Stop and remove it with `docker rm -f nex-gddp-cmip6`.

## Defaults and how to change them

The image saves a default for everything, so it runs with no arguments. Pass
only what you want to change; everything else keeps its default.

| Setting | Default | Change it with |
| --- | --- | --- |
| Address | `0.0.0.0` | `--address <ip>`, or `-e ADDRESS=<ip>` |
| Port | `12347` | `--port <port>`, or `-e PORT=<port>` |
| Dataset | `https://atlantis.sci.utah.edu/mod_visus?dataset=nex-gddp-cmip6` | `--args <dataset>`, the dataset as the first argument, or `-e DATASET=<dataset>` |

Arguments go after the image name. For example, to serve on port 9000 (publish
the same port with `-p`):

```bash
docker run -d --name nex-gddp-cmip6 -p 9000:9000 ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard:latest --port 9000
```

A dataset can be an OpenVisus `.idx` URL or path, or a JSON scene list. For local
files, mount their directory at `/data`:

```bash
docker run -d --name nex-gddp-cmip6 -p 12347:12347 \
  -v /path/to/datasets:/data:ro \
  ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard:latest \
  --args /data/my-dataset/visus.idx
```

Any other [`panel serve` option](https://panel.holoviz.org/how_to/server/commandline.html)
is passed through, e.g. `--num-procs 4` or `--prefix /nex-gddp-cmip6`.

| Environment variable | Default | Meaning |
| --- | --- | --- |
| `BOKEH_ALLOW_WS_ORIGIN` | `*` | Host names browsers may use to reach the dashboard, comma-separated. Set it to your public host name in production |
| `VISUS_CACHE` | `/var/cache/visus` | Where OpenVisus caches downloaded data. Mount a volume there to keep it across restarts |

## Run with Docker Compose

Save this as `docker-compose.yml` (the same file is in this repository), then run
`docker compose up -d`:

```yaml
# NSDF NEX-GDDP-CMIP6 Dashboard: run `docker compose up -d`, then open http://localhost:12347/nex-gddp-cmip6
services:
  nex-gddp-cmip6:
    image: ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard:latest
    platform: linux/amd64
    restart: unless-stopped
    ports:
      - "12347:12347"
    # Defaults are saved in the image. To override one, e.g. the dataset:
    # command: ["--args", "/data/my-dataset/visus.idx"]
    volumes:
      - cache:/var/cache/visus

volumes:
  cache:
```

## Run on Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nex-gddp-cmip6
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nex-gddp-cmip6
  template:
    metadata:
      labels:
        app: nex-gddp-cmip6
    spec:
      containers:
        - name: nex-gddp-cmip6
          image: ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard:latest
          # Defaults are saved in the image; override any of them with args, e.g.
          # args: ["--port", "12347", "--args", "/data/my-dataset/visus.idx"]
          ports:
            - containerPort: 12347
---
apiVersion: v1
kind: Service
metadata:
  name: nex-gddp-cmip6
spec:
  selector:
    app: nex-gddp-cmip6
  ports:
    - port: 12347
      targetPort: 12347
```

- Route your Ingress path `/nex-gddp-cmip6` to the Service. The page also loads its
  JavaScript from `/static/`, so route that too, or start the dashboard with
  `--prefix /<path>` and route only that prefix. The ingress controller must
  allow WebSocket upgrades.
- Keep `replicas: 1`, or enable session affinity: each browser session lives in
  one pod.
- Add probes as you need, e.g. a `tcpSocket` probe on port `12347`.

## Update to the newest image

Docker keeps using the image already on your machine, so pull first:

```bash
docker pull ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard:latest
docker rm -f nex-gddp-cmip6
```

Then run the same `docker run` command again. With Compose, run
`docker compose pull && docker compose up -d`. To stay on a fixed release instead
of `latest`, use one of the version tags on the [package page](https://github.com/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard/pkgs/container/nsdf-nex-gddp-cmip6-dashboard).

## Troubleshooting

- **Nothing answers on the port**: the port in `-p` must match the port the
  dashboard listens on (`12347` unless you passed `--port`).
  `docker logs nex-gddp-cmip6` shows it, e.g.
  `Bokeh app running at: http://0.0.0.0:12347/nex-gddp-cmip6`.
- **Warning: `requested image's platform (linux/amd64) does not match`**:
  harmless on Apple Silicon and other ARM machines. OpenVisus has no Linux ARM
  build, so the image runs under emulation, which is slower. Add
  `--platform linux/amd64` to hide the warning. On ARM Linux without Docker
  Desktop, enable emulation once with
  `docker run --privileged --rm tonistiigi/binfmt --install amd64`.
- **Page loads but stays blank**: the browser's WebSocket connection is being
  refused. Behind a proxy or ingress, allow WebSocket upgrades and set
  `BOKEH_ALLOW_WS_ORIGIN` to the host name in the address bar.

## For maintainers

[`.github/workflows/docker.yml`](.github/workflows/docker.yml) builds the image,
starts it twice (with no arguments, and with only `--port`), loads the dashboard
page each time, and fails if the dashboard logs an error. Only then is the image
published:

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
docker run --rm -p 12347:12347 nsdf-nex-gddp-cmip6-dashboard
```

The defaults live in the `ENV` block of the [`Dockerfile`](Dockerfile), and
[`docker-entrypoint.sh`](docker-entrypoint.sh) fills them in. The image runs this
repository's own copy of openvisuspy (from [aashishpanta0/openvpy-cmip6-public](https://github.com/aashishpanta0/openvpy-cmip6-public), branch `main`); the dashboard itself is
in [`src/openvisuspy/dashboards/`](src/openvisuspy/dashboards). For notebooks, local Python installs, and other dashboards, see
[openvisuspy](https://github.com/sci-visus/openvisuspy).
