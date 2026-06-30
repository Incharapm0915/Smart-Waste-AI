"""
Groq AI Service
Handles all LLM calls: recipe generation, shopping suggestions, waste analysis.
"""
import json
import logging
import uuid
from datetime import datetime, date, timedelta
from typing import List, Optional
from groq import AsyncGroq
from tenacity import retry, stop_after_attempt, wait_exponential
from ..core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

_client: Optional[AsyncGroq] = None


def _get_client() -> AsyncGroq:
    global _client
    if _client is None:
        _client = AsyncGroq(api_key=settings.groq_api_key)
    return _client


def _today_str() -> str:
    return date.today().isoformat()


@retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=4))
async def generate_recipes(
    ingredients: List[str],
    dietary_preferences: List[str] = [],
    max_cook_time: Optional[int] = None,
    servings: int = 2,
) -> List[dict]:
    """
    Generate recipe suggestions using Groq LLM.
    Returns list of structured recipe dicts.
    """
    if not settings.groq_api_key:
        logger.warning("No Groq API key — returning mock recipes")
        return _mock_recipes(ingredients)

    diet_str = f"Dietary restrictions: {', '.join(dietary_preferences)}." if dietary_preferences else ""
    time_str = f"Max cook time: {max_cook_time} minutes." if max_cook_time else ""

    prompt = f"""You are a professional chef AI. Generate 3 practical, delicious recipes using these ingredients:
{chr(10).join(f'- {i}' for i in ingredients)}

{diet_str}
{time_str}
Servings: {servings}
Today's date: {_today_str()}

IMPORTANT: Prioritize ingredients that expire soonest. Make recipes realistic and achievable.

Return ONLY valid JSON with this exact structure:
{{
  "recipes": [
    {{
      "id": "unique-id",
      "name": "Recipe Name",
      "description": "One sentence description",
      "emoji": "🍝",
      "cuisine": "Italian",
      "difficulty": "Easy",
      "cook_time_minutes": 25,
      "servings": {servings},
      "ingredients": ["ingredient 1 with quantity", "ingredient 2 with quantity"],
      "steps": ["Step 1", "Step 2", "Step 3"],
      "required_items": ["item from inventory"],
      "expiry_urgency": 2,
      "nutrition": {{
        "calories": 450,
        "protein": 30,
        "carbs": 45,
        "fat": 15
      }}
    }}
  ]
}}

expiry_urgency: 0=no urgency, 1=use within week, 2=use within 3 days, 3=use today"""

    try:
        client = _get_client()
        response = await client.chat.completions.create(
            model=settings.groq_model,
            messages=[
                {
                    "role": "system",
                    "content": "You are a professional culinary AI. Always return valid, parseable JSON. No markdown, no explanation.",
                },
                {"role": "user", "content": prompt},
            ],
            temperature=0.7,
            max_tokens=2000,
            response_format={"type": "json_object"},
        )
        content = response.choices[0].message.content
        data = json.loads(content)
        recipes = data.get("recipes", [])
        for r in recipes:
            if "id" not in r or not r["id"]:
                r["id"] = str(uuid.uuid4())
        return recipes
    except Exception as e:
        logger.error(f"Groq recipe generation failed: {e}")
        return _mock_recipes(ingredients)


@retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=4))
async def generate_shopping_suggestions(
    current_inventory: List[str],
    expiring_items: List[str],
    past_purchases: List[str] = [],
) -> List[dict]:
    """
    Generate personalized shopping recommendations.
    """
    if not settings.groq_api_key:
        return _mock_shopping()

    prompt = f"""You are a smart grocery assistant. Suggest what to buy based on:

Current inventory: {', '.join(current_inventory) if current_inventory else 'empty'}
Items expiring soon: {', '.join(expiring_items) if expiring_items else 'none'}
Past purchases: {', '.join(past_purchases[:10]) if past_purchases else 'none'}
Today: {_today_str()}

Generate 5-7 smart shopping suggestions. Consider:
1. Items running low or expired
2. Ingredients for common recipes with current inventory
3. Items to complement expiring ingredients
4. Nutritionally balanced choices

Return ONLY valid JSON:
{{
  "suggestions": [
    {{
      "name": "Item name",
      "emoji": "🥛",
      "category": "Dairy",
      "estimated_cost": 3.99,
      "reason": "Short reason why to buy this",
      "priority": 1
    }}
  ]
}}

priority: 1=high (buy today), 2=medium (this week), 3=low (nice to have)"""

    try:
        client = _get_client()
        response = await client.chat.completions.create(
            model=settings.groq_model,
            messages=[
                {
                    "role": "system",
                    "content": "You are a smart grocery AI. Return valid JSON only.",
                },
                {"role": "user", "content": prompt},
            ],
            temperature=0.5,
            max_tokens=1000,
            response_format={"type": "json_object"},
        )
        content = response.choices[0].message.content
        data = json.loads(content)
        return data.get("suggestions", [])
    except Exception as e:
        logger.error(f"Groq shopping suggestions failed: {e}")
        return _mock_shopping()


@retry(stop=stop_after_attempt(2), wait=wait_exponential(min=1, max=3))
async def generate_waste_insights(
    waste_percentage: float,
    top_wasted: List[str],
    period_days: int = 30,
) -> List[str]:
    """Generate personalized waste reduction recommendations."""
    if not settings.groq_api_key:
        return _mock_recommendations(waste_percentage)

    prompt = f"""A user wastes {waste_percentage:.1f}% of their food over {period_days} days.
Most wasted categories: {', '.join(top_wasted)}.

Generate 3 specific, actionable recommendations to reduce their food waste.
Keep each under 15 words. Be specific and practical.

Return ONLY valid JSON:
{{"recommendations": ["tip 1", "tip 2", "tip 3"]}}"""

    try:
        client = _get_client()
        response = await client.chat.completions.create(
            model=settings.groq_fast_model,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.6,
            max_tokens=300,
            response_format={"type": "json_object"},
        )
        data = json.loads(response.choices[0].message.content)
        return data.get("recommendations", [])
    except Exception as e:
        logger.error(f"Groq insights failed: {e}")
        return _mock_recommendations(waste_percentage)


# ─── Mock fallbacks ────────────────────────────────────────────────────────────

def _mock_recipes(ingredients: List[str]) -> List[dict]:
    return [
        {
            "id": str(uuid.uuid4()),
            "name": f"Quick {ingredients[0].title()} Dish" if ingredients else "Simple Meal",
            "description": "A quick and delicious meal using your available ingredients.",
            "emoji": "🍳",
            "cuisine": "International",
            "difficulty": "Easy",
            "cook_time_minutes": 20,
            "servings": 2,
            "ingredients": ingredients[:6] if ingredients else ["Any ingredients"],
            "steps": [
                "Prepare all ingredients.",
                "Cook over medium heat.",
                "Season to taste.",
                "Serve hot.",
            ],
            "required_items": ingredients[:2] if ingredients else [],
            "expiry_urgency": 1,
            "nutrition": {"calories": 380, "protein": 28, "carbs": 35, "fat": 12},
        }
    ]


def _mock_shopping() -> List[dict]:
    return [
        {"name": "Whole Milk", "emoji": "🥛", "category": "Dairy",
         "estimated_cost": 3.99, "reason": "Low in inventory", "priority": 1},
        {"name": "Fresh Spinach", "emoji": "🥬", "category": "Vegetables",
         "estimated_cost": 2.49, "reason": "Great for salads and recipes", "priority": 2},
        {"name": "Chicken Breast", "emoji": "🥩", "category": "Meat",
         "estimated_cost": 8.99, "reason": "Versatile protein source", "priority": 1},
    ]


def _mock_recommendations(waste_pct: float) -> List[str]:
    if waste_pct > 30:
        return [
            "Use meal planning to buy only what you need",
            "Store dairy in the coldest part of your fridge",
            "Freeze meat before its expiry date",
        ]
    return [
        "Great job! Try batch cooking to use expiring veggies",
        "Store herbs in water like flowers to extend life",
        "Check inventory before shopping to avoid duplicates",
    ]
