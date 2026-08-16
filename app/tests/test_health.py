from fastapi.testclient import TestClient

from orders_api import __version__
from orders_api.main import app

client = TestClient(app)


def test_healthz():
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_readyz():
    response = client.get("/readyz")
    assert response.status_code == 200
    assert response.json() == {"status": "ready"}


def test_version_reports_package_version():
    response = client.get("/version")
    assert response.status_code == 200
    body = response.json()
    assert body["version"] == __version__
    assert "revision" in body
    assert "environment" in body
