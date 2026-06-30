"""
Recipe Routes — Groq-powered recipe generation.
"""
import logging
from datetime import datetime
from fastapi import APIRouter, HTTPException
from ...models.schemas import RecipeRequest, RecipesResponse
from ...services.groq_service import generate_recipes
from ...core.config import get_settings

router = APIRouter(prefix="/recipes", tags=["recipes"])
logger = logging.getLogger(__name__)
settings = get_settings()


@router.post("/generate", response_model=RecipesResponse)
async def generate_recipe_suggestions(body: RecipeRequest):
    """
    Generate AI-powered recipe suggestions using Groq LLM.
    Prioritizes ingredients expiring soonest.
    """
    if not body.ingredients:
        raise HTTPException(
            status_code=400,
            detail="At least one ingredient is required",
        )

    if len(body.ingredients) > 20:
        body.ingredients = body.ingredients[:20]

    try:
        recipes = await generate_recipes(
            ingredients=body.ingredients,
            dietary_preferences=body.dietary_preferences,
            max_cook_time=body.max_cook_time,
            servings=body.servings,
        )
        return RecipesResponse(
            success=True,
            recipes=recipes,
            generated_at=datetime.utcnow().isoformat(),
            model_used=settings.groq_model,
        )
    except Exception as e:
        logger.error(f"Recipe generation error: {e}")
        raise HTTPException(status_code=500, detail="Recipe generation failed")


@router.get("/meal-plan")
async def get_meal_plan(
    ingredients: str = "",
    days: int = 7,
):
    """Generate a weekly meal plan from available ingredients."""
    ingredient_list = [i.strip() for i in ingredients.split(",") if i.strip()]
    if not ingredient_list:
        raise HTTPException(status_code=400, detail="No ingredients provided")

    recipes = await generate_recipes(
        ingredients=ingredient_list,
        servings=2,
    )
    # Distribute across days
    plan = {}
    for i in range(min(days, len(recipes))):
        plan[f"day_{i + 1}"] = recipes[i] if i < len(recipes) else None

    return {
        "success": True,
        "days": days,
        "meal_plan": plan,
        "generated_at": datetime.utcnow().isoformat(),
    }
