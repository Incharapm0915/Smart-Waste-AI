"""
Inventory Management Routes
"""
import logging
from datetime import date
from typing import Optional
from fastapi import APIRouter, HTTPException, Query
from ...models.schemas import InventoryItemCreate, InventoryItemResponse
from ...core.firebase_config import get_db

router = APIRouter(prefix="/inventory", tags=["inventory"])
logger = logging.getLogger(__name__)


def _days_until_expiry(expiry_str: str) -> int:
    try:
        expiry = date.fromisoformat(expiry_str)
        return (expiry - date.today()).days
    except Exception:
        return 0


def _expiry_status(days: int) -> str:
    if days < 0:
        return "expired"
    if days <= 2:
        return "critical"
    if days <= 5:
        return "warning"
    return "safe"


@router.get("/{user_id}")
async def get_user_inventory(
    user_id: str,
    category: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    limit: int = Query(50, le=200),
):
    """Get all inventory items for a user."""
    db = get_db()
    if db is None:
        return {"success": True, "items": [], "total": 0}

    try:
        query = db.collection("inventory").where("userId", "==", user_id)
        if category:
            query = query.where("category", "==", category)
        docs = list(query.limit(limit).stream())
        items = []
        for doc in docs:
            data = doc.to_dict()
            expiry_str = data.get("expiryDate", "").isoformat() if hasattr(data.get("expiryDate"), "isoformat") else str(data.get("expiryDate", ""))
            days = _days_until_expiry(expiry_str)
            item_status = _expiry_status(days)
            if status and item_status != status:
                continue
            items.append({
                "id": doc.id,
                "name": data.get("name"),
                "category": data.get("category"),
                "emoji": data.get("emoji"),
                "expiry_date": expiry_str,
                "quantity": data.get("quantity", 1),
                "unit": data.get("unit", "pcs"),
                "days_until_expiry": days,
                "status": item_status,
            })
        return {"success": True, "items": items, "total": len(items)}
    except Exception as e:
        logger.error(f"Inventory fetch error: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch inventory")


@router.post("")
async def add_inventory_item(body: InventoryItemCreate):
    """Add a new item to inventory."""
    db = get_db()
    if db is None:
        return {"success": True, "id": "demo-id", "message": "Demo mode"}

    try:
        doc_ref = db.collection("inventory").add({
            "userId": body.user_id,
            "name": body.name,
            "category": body.category,
            "emoji": body.emoji,
            "expiryDate": date.fromisoformat(body.expiry_date),
            "quantity": body.quantity,
            "unit": body.unit,
            "isConsumed": False,
            "addedViaApi": True,
        })
        return {"success": True, "id": doc_ref[1].id}
    except Exception as e:
        logger.error(f"Item add error: {e}")
        raise HTTPException(status_code=500, detail="Failed to add item")


@router.delete("/{item_id}")
async def delete_inventory_item(item_id: str):
    """Delete an inventory item."""
    db = get_db()
    if db is None:
        return {"success": True}
    try:
        db.collection("inventory").document(item_id).delete()
        return {"success": True}
    except Exception as e:
        logger.error(f"Item delete error: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete item")


@router.patch("/{item_id}/consume")
async def mark_consumed(item_id: str):
    """Mark item as consumed."""
    db = get_db()
    if db is None:
        return {"success": True}
    try:
        from firebase_admin import firestore
        db.collection("inventory").document(item_id).update({
            "isConsumed": True,
            "consumedAt": firestore.SERVER_TIMESTAMP,
        })
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
