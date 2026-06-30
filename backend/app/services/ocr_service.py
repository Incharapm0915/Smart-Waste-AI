"""
OCR Service — Expiry Date Extraction using Tesseract
Processes food package images and extracts expiry/best-before dates.
"""
import re
import io
import logging
from datetime import datetime, date
from typing import Optional, List, Tuple
from PIL import Image, ImageFilter, ImageEnhance
from ..core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

try:
    import pytesseract
    if settings.tesseract_path:
        pytesseract.pytesseract.tesseract_cmd = settings.tesseract_path
    _OCR_AVAILABLE = True
except Exception as e:
    logger.warning(f"pytesseract not available: {e}. OCR will return empty results.")
    pytesseract = None
    _OCR_AVAILABLE = False

# Common date formats found on food packaging
_DATE_PATTERNS = [
    # MM/DD/YYYY or DD/MM/YYYY
    r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})\b',
    # DD MMM YYYY (e.g. 15 JUN 2025)
    r'\b(\d{1,2})\s*(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\s*(\d{2,4})\b',
    # MMM DD YYYY (e.g. JUN 15 2025)
    r'\b(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\s*(\d{1,2})\s*(\d{2,4})\b',
    # YYYY-MM-DD
    r'\b(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})\b',
    # MM/YYYY (best before month/year)
    r'\b(\d{1,2})[/](\d{4})\b',
]

_MONTH_MAP = {
    'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4,
    'MAY': 5, 'JUN': 6, 'JUL': 7, 'AUG': 8,
    'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
}

_EXPIRY_KEYWORDS = [
    'EXP', 'EXPIRY', 'EXPIRATION', 'EXPIRES', 'BEST BEFORE',
    'BB', 'USE BY', 'SELL BY', 'BBD', 'BEST BY', 'USE BEFORE',
    'BEST BEFORE END',
]


def preprocess_image(image: Image.Image) -> Image.Image:
    """Apply image preprocessing to improve OCR accuracy."""
    if image.mode != 'RGB':
        image = image.convert('RGB')

    # Resize for better OCR
    w, h = image.size
    scale = max(1.5, 1200 / max(w, h))
    image = image.resize((int(w * scale), int(h * scale)), Image.LANCZOS)

    # Grayscale
    gray = image.convert('L')

    # Enhance contrast
    enhancer = ImageEnhance.Contrast(gray)
    gray = enhancer.enhance(2.0)

    # Sharpen
    gray = gray.filter(ImageFilter.SHARPEN)
    gray = gray.filter(ImageFilter.SHARPEN)

    return gray


def extract_text(image: Image.Image) -> str:
    """Run Tesseract OCR on image."""
    if not _OCR_AVAILABLE or pytesseract is None:
        return ""
    try:
        processed = preprocess_image(image)
        config = '--oem 3 --psm 6 -c tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789/-.:'
        text = pytesseract.image_to_string(processed, config=config)
        return text.upper().strip()
    except Exception as e:
        logger.warning(f"OCR extraction failed: {e}")
        return ""


def parse_date_string(raw: str) -> Optional[date]:
    """Try to parse a raw date string into a Python date."""
    raw = raw.strip().upper()

    # YYYY-MM-DD
    m = re.match(r'^(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})$', raw)
    if m:
        try:
            return date(int(m.group(1)), int(m.group(2)), int(m.group(3)))
        except ValueError:
            pass

    # DD/MM/YYYY or MM/DD/YYYY
    m = re.match(r'^(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})$', raw)
    if m:
        d1, d2, y = int(m.group(1)), int(m.group(2)), int(m.group(3))
        if y < 100:
            y += 2000
        try:
            # Try DD/MM/YYYY first (global standard)
            if 1 <= d1 <= 31 and 1 <= d2 <= 12:
                return date(y, d2, d1)
        except ValueError:
            pass
        try:
            if 1 <= d2 <= 31 and 1 <= d1 <= 12:
                return date(y, d1, d2)
        except ValueError:
            pass

    # DD MMM YYYY
    m = re.match(r'^(\d{1,2})\s*(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\s*(\d{2,4})$', raw)
    if m:
        d, mo, y = int(m.group(1)), _MONTH_MAP[m.group(2)], int(m.group(3))
        if y < 100:
            y += 2000
        try:
            return date(y, mo, d)
        except ValueError:
            pass

    # MMM DD YYYY
    m = re.match(r'^(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\s*(\d{1,2})\s*(\d{2,4})$', raw)
    if m:
        mo, d, y = _MONTH_MAP[m.group(1)], int(m.group(2)), int(m.group(3))
        if y < 100:
            y += 2000
        try:
            return date(y, mo, d)
        except ValueError:
            pass

    # MM/YYYY (set day to last of month)
    m = re.match(r'^(\d{1,2})[/](\d{4})$', raw)
    if m:
        mo, y = int(m.group(1)), int(m.group(2))
        try:
            import calendar
            last_day = calendar.monthrange(y, mo)[1]
            return date(y, mo, last_day)
        except ValueError:
            pass

    return None


def extract_expiry_dates(text: str) -> Tuple[List[str], Optional[str]]:
    """
    Extract all date strings from OCR text and find the most likely expiry date.
    Returns (all_date_strings, best_expiry_date_iso).
    """
    today = date.today()
    candidate_dates: List[date] = []
    raw_date_strings: List[str] = []

    # Prioritize lines near expiry keywords
    lines = text.split('\n')
    priority_lines: List[str] = []
    normal_lines: List[str] = []

    for line in lines:
        has_keyword = any(kw in line for kw in _EXPIRY_KEYWORDS)
        if has_keyword:
            priority_lines.append(line)
        else:
            normal_lines.append(line)

    all_lines = priority_lines + normal_lines

    for line in all_lines:
        for pattern in _DATE_PATTERNS:
            for match in re.finditer(pattern, line, re.IGNORECASE):
                raw = match.group(0)
                raw_date_strings.append(raw)
                parsed = parse_date_string(raw)
                if parsed and parsed > today:
                    candidate_dates.append(parsed)

    # Best expiry = soonest future date (within 5 years)
    max_future = date(today.year + 5, today.month, today.day)
    valid = [d for d in candidate_dates if today < d < max_future]
    valid.sort()

    best = valid[0].isoformat() if valid else None
    return list(set(raw_date_strings)), best


async def process_image_for_ocr(image_bytes: bytes) -> dict:
    """Main entry point — process image bytes and return OCR results."""
    try:
        image = Image.open(io.BytesIO(image_bytes))
        raw_text = extract_text(image)
        raw_dates, best_date = extract_expiry_dates(raw_text)

        confidence = 0.9 if best_date else 0.4
        if not raw_text:
            confidence = 0.1

        return {
            "success": True,
            "raw_text": raw_text,
            "extracted_dates": raw_dates,
            "best_expiry_date": best_date,
            "confidence": confidence,
        }
    except Exception as e:
        logger.error(f"OCR processing error: {e}")
        return {
            "success": False,
            "raw_text": "",
            "extracted_dates": [],
            "best_expiry_date": None,
            "confidence": 0.0,
        }
