import pytest
from fastapi.testclient import TestClient

from orders_api.main import app, store

client = TestClient(app)


@pytest.fixture(autouse=True)
def clean_store():
    store.clear()
    yield
    store.clear()


def create_order(item="widget", quantity=3, unit_price=9.99):
    return client.post(
        "/api/v1/orders",
        json={"item": item, "quantity": quantity, "unit_price": unit_price},
    )


def test_create_order_computes_total():
    response = create_order(quantity=3, unit_price=9.99)
    assert response.status_code == 201
    body = response.json()
    assert body["total"] == 29.97
    assert body["status"] == "created"
    assert body["id"]


def test_create_order_rejects_invalid_quantity():
    response = create_order(quantity=0)
    assert response.status_code == 422


def test_create_order_rejects_negative_price():
    response = create_order(unit_price=-1)
    assert response.status_code == 422


def test_create_order_rejects_empty_item():
    response = create_order(item="")
    assert response.status_code == 422


def test_get_order_roundtrip():
    order_id = create_order().json()["id"]
    response = client.get(f"/api/v1/orders/{order_id}")
    assert response.status_code == 200
    assert response.json()["id"] == order_id


def test_get_missing_order_returns_404():
    response = client.get("/api/v1/orders/does-not-exist")
    assert response.status_code == 404


def test_list_orders():
    create_order(item="a")
    create_order(item="b")
    response = client.get("/api/v1/orders")
    assert response.status_code == 200
    assert len(response.json()) == 2


def test_list_orders_filters_by_status():
    order_id = create_order(item="a").json()["id"]
    create_order(item="b")
    client.post(f"/api/v1/orders/{order_id}/cancel")

    cancelled = client.get("/api/v1/orders", params={"status": "cancelled"}).json()
    created = client.get("/api/v1/orders", params={"status": "created"}).json()
    assert [o["id"] for o in cancelled] == [order_id]
    assert len(created) == 1


def test_cancel_order():
    order_id = create_order().json()["id"]
    response = client.post(f"/api/v1/orders/{order_id}/cancel")
    assert response.status_code == 200
    assert response.json()["status"] == "cancelled"


def test_cancel_missing_order_returns_404():
    response = client.post("/api/v1/orders/does-not-exist/cancel")
    assert response.status_code == 404
