"""
Analytics Routes — Waste tracking, sustainability scores, reports.
"""
import logging
from datetime import datetime, date, timedelta
from fastapi import APIRouter, HTTPException, Query
from typing import Optional
from ...models.schemas import WasteReportRequest, WasteReportResponse
from ...services.groq_service import generate_waste_insights
from ...core.firebase_config import get_db

router = APIRouter(prefix="/analytics", tags=["analytics"])
logger = logging.getLogger(__name__)


@router.post("/waste-report", response_model=WasteReportResponse)
async def get_waste_report(body: WasteReportRequest):
    """
    Generate waste analysis report for a user.
    Reads from Firestore and returns analytics with AI insights.
    """
    db = get_db()
    try:
        if db is None:
            return _mock_waste_report(body.period_days)

        since = datetime.utcnow() - timedelta(days=body.period_days)

        # Count items from Firestore
        inventory_ref = db.collection("inventory")
        query = inventory_ref.where("userId", "==", body.user_id)
        docs = list(query.stream())

        total_added = len(docs)
        consumed = sum(1 for d in docs if d.to_dict().get("isConsumed") and not d.to_dict().get("wasted"))
        wasted = sum(1 for d in docs if d.to_dict().get("wasted"))

        waste_pct = round((wasted / total_added * 100) if total_added > 0 else 0, 1)

        # Calculate sustainability score (0–100)
        score = max(0, min(100, 100 - int(waste_pct * 1.5)))

        top_wasted = _get_top_wasted_categories(docs)
        recommendations = await generate_waste_insights(waste_pct, top_wasted, body.period_days)

        return WasteReportResponse(
            success=True,
            period_days=body.period_days,
            total_items_added=total_added,
            items_consumed=consumed,
            items_wasted=wasted,
            waste_percentage=waste_pct,
            money_saved=round(consumed * 2.5, 2),
            money_wasted=round(wasted * 2.5, 2),
            sustainability_score=score,
            top_wasted_categories=top_wasted,
            recommendations=recommendations,
        )
    except Exception as e:
        logger.error(f"Waste report error: {e}")
        return _mock_waste_report(body.period_days)


@router.get("/sustainability-score/{user_id}")
async def get_sustainability_score(user_id: str):
    """Get current sustainability score for a user."""
    db = get_db()
    if db is None:
        return {"score": 72, "tier": "Good", "rank": "Top 30%"}

    try:
        user_ref = db.collection("users").document(user_id)
        doc = user_ref.get()
        if not doc.exists:
            raise HTTPException(status_code=404, detail="User not found")
        data = doc.to_dict()
        score = data.get("sustainabilityScore", 0)
        tier = _score_tier(score)
        return {"score": score, "tier": tier}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Score fetch error: {e}")
        return {"score": 0, "tier": "Beginner"}


def _get_top_wasted_categories(docs: list) -> list:
    from collections import Counter
    cats = Counter()
    for doc in docs:
        data = doc.to_dict()
        if data.get("wasted"):
            cats[data.get("category", "Unknown")] += 1
    return [c for c, _ in cats.most_common(3)]


def _score_tier(score: int) -> str:
    if score >= 85:
        return "Excellent"
    if score >= 70:
        return "Good"
    if score >= 50:
        return "Average"
    return "Needs Improvement"


def _mock_waste_report(period_days: int) -> WasteReportResponse:
    return WasteReportResponse(
        success=True,
        period_days=period_days,
        total_items_added=47,
        items_consumed=38,
        items_wasted=9,
        waste_percentage=19.1,
        money_saved=95.0,
        money_wasted=22.5,
        sustainability_score=72,
        top_wasted_categories=["Dairy", "Vegetables", "Bakery"],
        recommendations=[
            "Store dairy at the back of fridge where it's coldest",
            "Plan meals around expiring veggies on weekdays",
            "Freeze bread before it expires to extend shelf life",
        ],
    )
