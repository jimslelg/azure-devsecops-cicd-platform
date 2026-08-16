"""orders-api HTTP surface.

Endpoints the platform depends on:
  /healthz  — liveness probe (process is up)
  /readyz   — readiness probe (safe to receive traffic)
  /version  — smoke tests assert the deployed version matches the pipeline's
Everything under /api/v1 is the demo business surface.
"""

import os
from typing import List, Optional

from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, Field

from orders_api import __version__
from orders_api.store import OrderNotFoundError, OrderStore

app = FastAPI(title="orders-api", version=__version__)
store = OrderStore()


class OrderCreate(BaseModel):
    item: str = Field(min_length=1, max_length=200)
    quantity: int = Field(gt=0, le=1000)
    unit_price: float = Field(gt=0, le=1_000_000)


class Order(OrderCreate):
    id: str
    total: float
    status: str


@app.get("/healthz")
def healthz() -> dict:
    return {"status": "ok"}


@app.get("/readyz")
def readyz() -> dict:
    return {"status": "ready"}


@app.get("/version")
def version() -> dict:
    return {
        "version": __version__,
        "revision": os.environ.get("GIT_SHA", "unknown"),
        "environment": os.environ.get("APP_ENVIRONMENT", "local"),
    }


@app.post("/api/v1/orders", response_model=Order, status_code=201)
def create_order(payload: OrderCreate) -> dict:
    return store.create(payload.item, payload.quantity, payload.unit_price)


@app.get("/api/v1/orders", response_model=List[Order])
def list_orders(status: Optional[str] = Query(default=None)) -> list:
    return store.list(status=status)


@app.get("/api/v1/orders/{order_id}", response_model=Order)
def get_order(order_id: str) -> dict:
    try:
        return store.get(order_id)
    except OrderNotFoundError:
        raise HTTPException(status_code=404, detail="order not found")


@app.post("/api/v1/orders/{order_id}/cancel", response_model=Order)
def cancel_order(order_id: str) -> dict:
    try:
        return store.cancel(order_id)
    except OrderNotFoundError:
        raise HTTPException(status_code=404, detail="order not found")
