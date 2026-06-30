"""
Shopping Suggestions Routes
"""
import logging
from fastapi import APIRouter, HTTPException
from ...models.schemas import ShoppingRequest, ShoppingResponse
from ...services.groq_service import generate_shopping_suggestions

router = APIRouter(prefix="/shopping", tags=["shopping"])
logger = logging.getLogger(__name__)


@router.post("/suggest", response_model=ShoppingResponse)
async def get_shopping_suggestions(body: ShoppingRequest):
    """
    AI-powered shopping recommendations based on:
    - Current inventory
    - Expiring items
    - Past purchase patterns
    """
    try:
        suggestions = await generate_shopping_suggestions(
            current_inventory=body.current_inventory,
            expiring_items=body.expiring_items,
            past_purchases=body.past_purchases,
        )
        total_cost = sum(s.get("estimated_cost", 0) for s in suggestions)
        return ShoppingResponse(
            success=True,
            suggestions=suggestions,
            total_estimated_cost=round(total_cost, 2),
        )
    except Exception as e:
        logger.error(f"Shopping suggestion error: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate suggestions")
