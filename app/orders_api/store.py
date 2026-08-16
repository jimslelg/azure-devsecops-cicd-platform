"""In-memory order store.

Deliberately trivial: the workload exists to exercise the delivery platform
(build, scan, deploy, smoke test, rollback), not to model a domain. The store
is process-local, so multi-replica deployments serve independent data — fine
for a demo API, and called out in the docs as a known limitation.
"""

import threading
import uuid
from typing import Dict, List, Optional


class OrderNotFoundError(KeyError):
    pass


class OrderStore:
    def __init__(self) -> None:
        self._orders: Dict[str, dict] = {}
        self._lock = threading.Lock()

    def create(self, item: str, quantity: int, unit_price: float) -> dict:
        order = {
            "id": str(uuid.uuid4()),
            "item": item,
            "quantity": quantity,
            "unit_price": unit_price,
            "total": round(quantity * unit_price, 2),
            "status": "created",
        }
        with self._lock:
            self._orders[order["id"]] = order
        return order

    def get(self, order_id: str) -> dict:
        with self._lock:
            order = self._orders.get(order_id)
        if order is None:
            raise OrderNotFoundError(order_id)
        return order

    def list(self, status: Optional[str] = None) -> List[dict]:
        with self._lock:
            orders = list(self._orders.values())
        if status is not None:
            orders = [o for o in orders if o["status"] == status]
        return orders

    def cancel(self, order_id: str) -> dict:
        with self._lock:
            order = self._orders.get(order_id)
            if order is None:
                raise OrderNotFoundError(order_id)
            order["status"] = "cancelled"
        return order

    def clear(self) -> None:
        with self._lock:
            self._orders.clear()
