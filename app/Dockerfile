# syntax=docker/dockerfile:1
# Base pinned by digest (python:3.12-slim-bookworm as of 2026-08-17): the tag
# is a human label; the digest is what Trivy scanned and what prod runs.
ARG BASE_IMAGE=python:3.12-slim-bookworm@sha256:a116514e19457bcb7af7efe9c3dd0b9b71e85b317694e7882a1c52aa15a78134

# --- build stage: resolve dependencies into wheels ---------------------------
FROM ${BASE_IMAGE} AS build

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip==24.2 \
    && pip wheel --no-cache-dir --wheel-dir /build/wheels -r requirements.txt

# --- runtime stage: minimal, non-root, no build tooling ----------------------
FROM ${BASE_IMAGE}

# Build metadata injected by the pipeline; surfaced at /version.
ARG GIT_SHA=unknown
ARG APP_VERSION=0.0.0
ENV GIT_SHA=${GIT_SHA} \
    APP_VERSION=${APP_VERSION} \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN groupadd --gid 10001 app \
    && useradd --uid 10001 --gid app --shell /usr/sbin/nologin --no-create-home app

WORKDIR /app

COPY --from=build /build/wheels /tmp/wheels
COPY requirements.txt .
RUN pip install --no-cache-dir --no-index --find-links=/tmp/wheels -r requirements.txt \
    && rm -rf /tmp/wheels

COPY VERSION .
COPY orders_api/ orders_api/

USER 10001:10001
EXPOSE 8000

# Liveness/readiness are Kubernetes probes (see the Helm chart); no Docker
# HEALTHCHECK so the container behaves identically in and out of the cluster.
CMD ["uvicorn", "orders_api.main:app", "--host", "0.0.0.0", "--port", "8000"]
