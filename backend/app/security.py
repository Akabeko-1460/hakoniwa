"""家族トークンによる認証。

`POST /api/families` で発行したトークンを `Authorization: Bearer <token>` で送る。
サーバーは SHA-256 のハッシュだけを保存し、平文は端末側にしか残らない。
"""
from __future__ import annotations

import hashlib
import secrets

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from .db import Family, get_session


def new_id(prefix: str = "") -> str:
    return prefix + secrets.token_hex(8)


def issue_token() -> str:
    return secrets.token_urlsafe(32)


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def current_family(
    authorization: str | None = Header(default=None),
    session: Session = Depends(get_session),
) -> Family:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="家族トークンが必要です（Authorization: Bearer <token>）",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = authorization.split(" ", 1)[1].strip()
    family = session.scalar(
        select(Family).where(Family.token_hash == hash_token(token))
    )
    if family is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="家族トークンが正しくありません",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return family
