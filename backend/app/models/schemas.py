from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import date


# ─── Detection ────────────────────────────────────────────────────────────────

class DetectedItemSchema(BaseModel):
    name: str
    category: str
    emoji: str
    expiry_date: str  # ISO 8601: "2024-06-15"
    confidence: float = Field(ge=0, le=1)
    quantity: float = 1.0
    unit: str = "pcs"
    freshness_score: Optional[float] = None


class DetectionResponse(BaseModel):
    success: bool
    items: List[DetectedItemSchema]
    processing_time_ms: int
    item_count: int
    raw_ocr_text: Optional[str] = None


# ─── OCR ──────────────────────────────────────────────────────────────────────

class OcrResponse(BaseModel):
    success: bool
    raw_text: str
    extracted_dates: List[str]
    best_expiry_date: Optional[str] = None
    confidence: float


# ─── Recipes ──────────────────────────────────────────────────────────────────

class RecipeRequest(BaseModel):
    ingredients: List[str]
    dietary_preferences: List[str] = []
    max_cook_time: Optional[int] = None
    cuisine_type: Optional[str] = None
    servings: int = 2


class NutritionInfo(BaseModel):
    calories: int
    protein: int
    carbs: int
    fat: int


class RecipeSchema(BaseModel):
    id: str
    name: str
    description: str
    emoji: str
    cuisine: str
    difficulty: str
    cook_time_minutes: int
    servings: int
    ingredients: List[str]
    steps: List[str]
    required_items: List[str]
    expiry_urgency: int = Field(ge=0, le=3)
    nutrition: Optional[NutritionInfo] = None


class RecipesResponse(BaseModel):
    success: bool
    recipes: List[RecipeSchema]
    generated_at: str
    model_used: str


# ─── Shopping ─────────────────────────────────────────────────────────────────

class ShoppingRequest(BaseModel):
    user_id: str
    current_inventory: List[str]
    expiring_items: List[str]
    past_purchases: List[str] = []


class ShoppingItemSchema(BaseModel):
    name: str
    emoji: str
    category: str
    estimated_cost: float
    reason: str
    priority: int = Field(ge=1, le=3)


class ShoppingResponse(BaseModel):
    success: bool
    suggestions: List[ShoppingItemSchema]
    total_estimated_cost: float


# ─── Analytics ────────────────────────────────────────────────────────────────

class WasteReportRequest(BaseModel):
    user_id: str
    period_days: int = 30


class WasteReportResponse(BaseModel):
    success: bool
    period_days: int
    total_items_added: int
    items_consumed: int
    items_wasted: int
    waste_percentage: float
    money_saved: float
    money_wasted: float
    sustainability_score: int
    top_wasted_categories: List[str]
    recommendations: List[str]


# ─── Inventory ────────────────────────────────────────────────────────────────

class InventoryItemCreate(BaseModel):
    user_id: str
    name: str
    category: str
    emoji: str
    expiry_date: str
    quantity: float = 1.0
    unit: str = "pcs"


class InventoryItemResponse(BaseModel):
    id: str
    user_id: str
    name: str
    category: str
    emoji: str
    expiry_date: str
    quantity: float
    unit: str
    days_until_expiry: int
    status: str  # "safe" | "warning" | "critical" | "expired"
