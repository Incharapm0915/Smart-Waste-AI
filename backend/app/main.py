"""
Smart Waste AI — FastAPI Backend
Production-ready API for food management, AI detection, and waste reduction.
"""
import logging
import time
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from .api.routes import image, recipes, shopping, analytics, inventory
from .core.config import get_settings
from .core.firebase_config import init_firebase

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup / shutdown lifecycle."""
    logger.info(f"Starting {settings.app_name} v{settings.app_version}")
    init_firebase()
    logger.info("Firebase initialized")
    yield
    logger.info("Shutting down...")


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="AI-powered food management & waste reduction backend",
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
    lifespan=lifespan,
)

# ─── Middleware ────────────────────────────────────────────────────────────────

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["*"],
)


@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start = time.monotonic()
    response = await call_next(request)
    elapsed = round((time.monotonic() - start) * 1000, 2)
    response.headers["X-Process-Time-Ms"] = str(elapsed)
    return response


@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info(f"{request.method} {request.url.path}")
    try:
        response = await call_next(request)
        return response
    except Exception as e:
        logger.error(f"Unhandled error: {e}")
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal server error"},
        )


# ─── Exception Handlers ───────────────────────────────────────────────────────

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"success": False, "detail": exc.detail},
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"success": False, "detail": "Internal server error"},
    )


# ─── Routers ──────────────────────────────────────────────────────────────────

API_V1 = "/api/v1"

app.include_router(image.router, prefix=API_V1)
app.include_router(recipes.router, prefix=API_V1)
app.include_router(shopping.router, prefix=API_V1)
app.include_router(analytics.router, prefix=API_V1)
app.include_router(inventory.router, prefix=API_V1)


# ─── Health Check ─────────────────────────────────────────────────────────────

@app.get("/", tags=["health"])
async def root():
    return {
        "service": settings.app_name,
        "version": settings.app_version,
        "status": "healthy",
    }


@app.get("/health", tags=["health"])
async def health_check():
    from .core.firebase_config import get_db
    db = get_db()
    return {
        "status": "healthy",
        "firebase": "connected" if db else "demo_mode",
        "groq": "configured" if settings.groq_api_key else "not_configured",
        "version": settings.app_version,
    }
