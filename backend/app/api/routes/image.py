"""
Image Processing Routes
Handles food scanning: upload → OCR → detection → structured response → delete image.
"""
import io
import time
import logging
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Depends
from fastapi.responses import JSONResponse
from typing import Optional
from ...models.schemas import DetectionResponse
from ...services.ocr_service import process_image_for_ocr
from ...services.detection_service import detect_food_items
from ...core.config import get_settings

router = APIRouter(prefix="/detect", tags=["detection"])
logger = logging.getLogger(__name__)
settings = get_settings()

_ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/heic"}
_MAX_SIZE_BYTES = settings.max_image_size_mb * 1024 * 1024


async def _validate_image(file: UploadFile) -> bytes:
    """Validate and read image bytes. Image is NEVER stored permanently."""
    if file.content_type not in _ALLOWED_TYPES:
        raise HTTPException(
            status_code=415,
            detail=f"Unsupported image type: {file.content_type}",
        )
    image_bytes = await file.read()
    if len(image_bytes) > _MAX_SIZE_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"Image too large. Max size: {settings.max_image_size_mb}MB",
        )
    # Image bytes only live in memory, never written to disk
    return image_bytes


@router.post("", response_model=DetectionResponse)
async def detect_food(
    file: UploadFile = File(..., description="Food image — deleted after processing"),
    user_id: str = Form(default=""),
):
    """
    Full AI pipeline:
    1. Validate image (in-memory only)
    2. Run OCR for expiry dates
    3. Run object detection for food items
    4. Merge results
    5. Image bytes are discarded — never stored
    """
    start = time.monotonic()

    image_bytes = await _validate_image(file)

    # Step 1: OCR — extract expiry dates
    ocr_result = await process_image_for_ocr(image_bytes)
    ocr_text = ocr_result.get("raw_text", "")
    best_expiry = ocr_result.get("best_expiry_date")

    # Step 2: Object detection
    detected_items = await detect_food_items(image_bytes, ocr_text)

    # Step 3: Enrich detected items with OCR expiry if individual dates not found
    for item in detected_items:
        if best_expiry and item.get("expiry_date") is None:
            item["expiry_date"] = best_expiry

    # Step 4: Image bytes go out of scope here — Python GC will reclaim
    del image_bytes

    elapsed_ms = int((time.monotonic() - start) * 1000)

    return DetectionResponse(
        success=True,
        items=detected_items,
        processing_time_ms=elapsed_ms,
        item_count=len(detected_items),
        raw_ocr_text=ocr_text if settings.debug else None,
    )


@router.post("/ocr-only")
async def ocr_only(
    file: UploadFile = File(...),
):
    """Run OCR only, without object detection. Faster for expiry extraction."""
    image_bytes = await _validate_image(file)
    result = await process_image_for_ocr(image_bytes)
    del image_bytes
    return result
