# NSDF NEX-GDDP-CMIP6 Dashboard, served as "nex-gddp-cmip6" (ghcr.io/aashishpanta0/nsdf-nex-gddp-cmip6-dashboard).
# Defaults (address, port 12347, dataset) are saved below, so the image runs
# with no arguments; each one can be overridden at run time (see README.md).

# Build stage: install the Python dependencies into a virtualenv.
FROM python:3.12-slim-bookworm AS build

# OpenVisus ships Linux wheels for x86_64 only, so the image is linux/amd64.
# OpenVisusNoGui is OpenVisus without the Qt viewer, which the dashboard never uses.
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir --no-warn-script-location --only-binary=:all: \
        panel bokeh param numpy requests xmltodict colorcet \
        ipywidgets ipywidgets-bokeh ipykernel OpenVisusNoGui \
        httpx nest_asyncio \
    && /opt/venv/bin/pip uninstall -y pip

# Runtime stage: only the virtualenv and the dashboard code.
FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/opt/venv/bin:$PATH \
    PYTHONPATH=/opt/openvisuspy/src \
    BOKEH_ALLOW_WS_ORIGIN=* \
    VISUS_CACHE=/var/cache/visus \
    DASHBOARD_APP=/opt/openvisuspy/nex-gddp-cmip6 \
    ADDRESS=0.0.0.0 \
    PORT=12347 \
    DATASET="https://atlantis.sci.utah.edu/mod_visus?dataset=nex-gddp-cmip6"

COPY --from=build /opt/venv /opt/venv
COPY src /opt/openvisuspy/src
COPY src/openvisuspy/dashboards /opt/openvisuspy/nex-gddp-cmip6
COPY --chmod=0755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# The cache is writable by any user, since Kubernetes may run the container
# under an arbitrary UID.
RUN python -c "import OpenVisus, openvisuspy" \
    && test -f "$DASHBOARD_APP/main.py" \
    && useradd --create-home --uid 10001 dashboard \
    && mkdir -p /var/cache/visus /data \
    && chown dashboard:dashboard /var/cache/visus /data \
    && chmod 1777 /var/cache/visus

WORKDIR /opt/openvisuspy
USER dashboard
EXPOSE 12347

ENTRYPOINT ["docker-entrypoint.sh"]
