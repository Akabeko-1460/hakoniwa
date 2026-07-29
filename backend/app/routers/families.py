"""家族（=1つのアカウント）の作成と確認。"""
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..db import Family, FamilySettings, get_session, now_ms
from ..schemas import FamilyCreate, FamilyCredentials, FamilyInfo
from ..security import current_family, hash_token, issue_token, new_id

router = APIRouter(prefix="/api/families", tags=["families"])


@router.post("", response_model=FamilyCredentials, status_code=201)
def create_family(
    payload: FamilyCreate, session: Session = Depends(get_session)
) -> FamilyCredentials:
    """新しい家族を作り、以後の認証に使うトークンを返す。

    トークンはこのレスポンスでしか受け取れない。端末側で保管すること。
    """
    token = issue_token()
    family = Family(
        id=new_id(),
        name=payload.name,
        token_hash=hash_token(token),
        created_at=now_ms(),
    )
    session.add(family)
    session.add(FamilySettings(family_id=family.id, updated_at=now_ms()))
    session.commit()
    return FamilyCredentials(family_id=family.id, name=family.name, token=token)


@router.get("/me", response_model=FamilyInfo)
def whoami(family: Family = Depends(current_family)) -> FamilyInfo:
    return FamilyInfo(
        family_id=family.id, name=family.name, created_at=family.created_at
    )
