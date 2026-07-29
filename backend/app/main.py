"""ハコニワ API — Flutter アプリのクラウド保管・家族間同期。

起動:
    uvicorn app.main:app --reload --port 8000
"""
from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings
from .db import init_db
from .routers import children, families, items, media, sync


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    yield


app = FastAPI(
    title="ハコニワ API",
    version="1.0.0",
    description=(
        "子どもの大切なモノの3Dスキャン・思い出をクラウドに保管し、"
        "家族の端末どうしで同期するためのAPI。"
    ),
    lifespan=lifespan,
)

_settings = get_settings()
app.add_middleware(
    CORSMiddleware,
    allow_origins=_settings.cors_origin_list,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(families.router)
app.include_router(children.router)
app.include_router(items.router)
app.include_router(media.router)
app.include_router(sync.router)


@app.get("/api/health", tags=["health"])
def health() -> dict[str, str]:
    return {"status": "ok", "app": "hakoniwa"}
