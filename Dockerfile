FROM python:3.12-slim-bookworm AS builder

# Only the packages the Panel dashboard needs at runtime (see src/openvisuspy);
# the ipywidgets stack backs pn.extension("ipywidgets") in dashboards/main.py.
# Binary wheels only, so no compiler toolchain is needed in either stage.
RUN python -m venv /opt/venv \
    && /opt/venv/bin/python -m pip install --no-cache-dir --no-warn-script-location --only-binary=:all: \
        panel bokeh param numpy colorcet requests xmltodict httpx nest_asyncio \
        ipywidgets ipywidgets-bokeh ipykernel OpenVisusNoGui \
    && /opt/venv/bin/python -m pip uninstall -y pip \
    && find /opt/venv -depth -type d -name __pycache__ -exec rm -rf {} +

FROM python:3.12-slim-bookworm AS runtime

# Listen address and port are supplied at runtime (see docker-compose.yml).
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/opt/openvpy/src \
    PATH=/opt/venv/bin:$PATH \
    BOKEH_ALLOW_WS_ORIGIN=* \
    VISUS_CACHE=/var/cache/visus

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/venv /opt/venv
COPY src /opt/openvpy/src

RUN python -c "import OpenVisus, openvisuspy, panel.io.ipywidget" \
    && test -f /opt/openvpy/src/openvisuspy/dashboards/main.py

RUN useradd --create-home --uid 10001 dashboard \
    && ln -s /opt/openvpy/src/openvisuspy/dashboards /opt/openvpy/nex-gddp-cmip6 \
    && mkdir -p /var/cache/visus \
    && chown dashboard:dashboard /var/cache/visus

WORKDIR /opt/openvpy
USER dashboard

ENTRYPOINT ["python", "-m", "panel", "serve", "nex-gddp-cmip6"]
CMD ["--args", "https://atlantis.sci.utah.edu/mod_visus?dataset=nex-gddp-cmip6"]
