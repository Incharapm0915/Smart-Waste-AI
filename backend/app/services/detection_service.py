"""
Object Detection Service
Uses Hugging Face DETR model (free tier) or falls back to rule-based detection.
"""
import io
import re
import logging
from datetime import datetime, timedelta
from typing import List, Optional
from PIL import Image

logger = logging.getLogger(__name__)


_FOOD_CATEGORIES = {
    'milk': ('Dairy', '🥛', 7),
    'yogurt': ('Dairy', '🍦', 14),
    'cheese': ('Dairy', '🧀', 30),
    'butter': ('Dairy', '🧈', 30),
    'cream': ('Dairy', '🥛', 7),
    'egg': ('Dairy', '🥚', 21),
    'chicken': ('Meat', '🥩', 3),
    'beef': ('Meat', '🥩', 3),
    'pork': ('Meat', '🥩', 3),
    'fish': ('Seafood', '🐟', 2),
    'salmon': ('Seafood', '🐟', 2),
    'shrimp': ('Seafood', '🦐', 2),
    'apple': ('Fruits', '🍎', 14),
    'banana': ('Fruits', '🍌', 5),
    'orange': ('Fruits', '🍊', 14),
    'berry': ('Fruits', '🍓', 5),
    'grape': ('Fruits', '🍇', 7),
    'spinach': ('Vegetables', '🥬', 7),
    'lettuce': ('Vegetables', '🥬', 5),
    'carrot': ('Vegetables', '🥕', 14),
    'tomato': ('Vegetables', '🍅', 7),
    'onion': ('Vegetables', '🧅', 30),
    'garlic': ('Vegetables', '🧄', 30),
    'potato': ('Vegetables', '🥔', 30),
    'bread': ('Bakery', '🍞', 5),
    'bagel': ('Bakery', '🥯', 3),
    'pasta': ('Grains', '🍝', 365),
    'rice': ('Grains', '🍚', 365),
    'cereal': ('Grains', '🥣', 180),
    'juice': ('Beverages', '🧃', 7),
    'soda': ('Beverages', '🥤', 180),
    'water': ('Beverages', '💧', 365),
    'ketchup': ('Condiments', '🫙', 180),
    'sauce': ('Condiments', '🫙', 90),
    'oil': ('Condiments', '🫙', 365),
    'chips': ('Snacks', '🍿', 60),
    'cookie': ('Snacks', '🍪', 30),
    'chocolate': ('Snacks', '🍫', 180),
    'ice cream': ('Frozen', '🍦', 90),
    'frozen': ('Frozen', '🧊', 90),
}


def _estimate_category(label: str) -> tuple:
    """Map a detected object label to food category, emoji, shelf life."""
    label_lower = label.lower()
    for key, (cat, emoji, days) in _FOOD_CATEGORIES.items():
        if key in label_lower:
            return cat, emoji, days
    return 'Other', '🥫', 30


def _default_expiry(days: int) -> str:
    expiry = datetime.now() + timedelta(days=days)
    return expiry.date().isoformat()


class DetectionService:
    def __init__(self):
        self._model = None
        self._processor = None
        self._model_loaded = False

    def _load_model(self):
        """Lazy-load the HuggingFace DETR model."""
        if self._model_loaded:
            return
        try:
            from transformers import DetrImageProcessor, DetrForObjectDetection
            import torch
            self._processor = DetrImageProcessor.from_pretrained(
                "facebook/detr-resnet-50", revision="no_timm"
            )
            self._model = DetrForObjectDetection.from_pretrained(
                "facebook/detr-resnet-50", revision="no_timm"
            )
            self._model.eval()
            self._model_loaded = True
            logger.info("DETR model loaded successfully")
        except Exception as e:
            logger.warning(f"Could not load DETR model: {e}. Using rule-based fallback.")
            self._model_loaded = False

    async def detect_items(
        self,
        image_bytes: bytes,
        ocr_text: str = "",
    ) -> List[dict]:
        """
        Detect food items from image.
        Tries HuggingFace DETR first, falls back to OCR-based heuristics.
        """
        results = []

        # Try ML model first
        try:
            self._load_model()
            if self._model_loaded:
                results = await self._detect_with_model(image_bytes)
        except Exception as e:
            logger.warning(f"ML detection failed: {e}")

        # Augment with OCR-based detection
        ocr_items = self._detect_from_ocr_text(ocr_text)
        seen_names = {r['name'].lower() for r in results}
        for item in ocr_items:
            if item['name'].lower() not in seen_names:
                results.append(item)
                seen_names.add(item['name'].lower())

        # If nothing found, return a generic item
        if not results:
            results = [self._fallback_item()]

        return results

    async def _detect_with_model(self, image_bytes: bytes) -> List[dict]:
        import torch
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        inputs = self._processor(images=image, return_tensors="pt")
        with torch.no_grad():
            outputs = self._model(**inputs)

        target_sizes = torch.tensor([image.size[::-1]])
        results_raw = self._processor.post_process_object_detection(
            outputs, target_sizes=target_sizes, threshold=0.7
        )[0]

        items = []
        seen = set()
        for score, label_id in zip(
            results_raw["scores"], results_raw["labels"]
        ):
            label = self._model.config.id2label[label_id.item()]
            conf = round(score.item(), 3)
            if label in seen:
                continue
            seen.add(label)

            cat, emoji, days = _estimate_category(label)
            items.append({
                "name": label.replace("_", " ").title(),
                "category": cat,
                "emoji": emoji,
                "expiry_date": _default_expiry(days),
                "confidence": conf,
                "quantity": 1.0,
                "unit": "pcs",
            })

        return items

    def _detect_from_ocr_text(self, text: str) -> List[dict]:
        """Use OCR text to infer food items by keyword matching."""
        if not text:
            return []
        items = []
        text_lower = text.lower()
        for keyword, (cat, emoji, days) in _FOOD_CATEGORIES.items():
            if keyword in text_lower:
                items.append({
                    "name": keyword.title(),
                    "category": cat,
                    "emoji": emoji,
                    "expiry_date": _default_expiry(days),
                    "confidence": 0.72,
                    "quantity": 1.0,
                    "unit": "pcs",
                })
        return items[:5]

    def _fallback_item(self) -> dict:
        return {
            "name": "Food Item",
            "category": "Other",
            "emoji": "🥫",
            "expiry_date": _default_expiry(30),
            "confidence": 0.5,
            "quantity": 1.0,
            "unit": "pcs",
        }


_detection_service = DetectionService()


async def detect_food_items(image_bytes: bytes, ocr_text: str = "") -> List[dict]:
    return await _detection_service.detect_items(image_bytes, ocr_text)
