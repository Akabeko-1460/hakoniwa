"""思い出のモノの CRUD。配置（pos）の更新もここ。"""
from __future__ import annotations

import json

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..db import Child, Family, Item, get_session, now_ms
from ..schemas import ItemIn, ItemOut, ItemPatch, RoomPos
from ..security import current_family, new_id

router = APIRouter(prefix="/api/items", tags=["items"])

# 新しい順に並べるときの季節の重み（同じ年のなかで冬がいちばん新しい）
SEASON_ORDER = {"春": 0, "夏": 1, "秋": 2, "冬": 3}


def _get(session: Session, family: Family, item_id: str) -> Item:
    row = session.scalar(
        select(Item).where(
            Item.id == item_id,
            Item.family_id == family.id,
            Item.deleted.is_(False),
        )
    )
    if row is None:
        raise HTTPException(status_code=404, detail="その思い出は見つかりません")
    return row


@router.get("", response_model=list[ItemOut])
def list_items(
    child_id: str | None = Query(default=None, alias="childId"),
    q: str | None = Query(default=None, description="名まえ・メモの部分一致"),
    family: Family = Depends(current_family),
    session: Session = Depends(get_session),
) -> list[ItemOut]:
    """タイムライン用に新しい順（年 → 季節 → 登録順）で返す。"""
    stmt = select(Item).where(Item.family_id == family.id, Item.deleted.is_(False))
    if child_id:
        stmt = stmt.where(Item.child_id == child_id)
    rows = list(session.scalars(stmt))
    if q:
        needle = q.strip()
        rows = [r for r in rows if needle in r.name or needle in r.memo]
    rows.sort(
        key=lambda r: (r.year, SEASON_ORDER.get(r.season, 0), r.created_at),
        reverse=True,
    )
    return [ItemOut.of(r) for r in rows]


@router.post("", response_model=ItemOut, status_code=201)
def create_item(
    payload: ItemIn,
    family: Family = Depends(current_family),
    session: Session = Depends(get_session),
) -> ItemOut:
    child = session.scalar(
        select(Child).where(
            Child.id == payload.child_id,
            Child.family_id == family.id,
            Child.deleted.is_(False),
        )
    )
    if child is None:
        raise HTTPException(status_code=404, detail="その子どもは見つかりません")

    ts = now_ms()
    row = Item(
        id=payload.id or new_id(),
        family_id=family.id,
        child_id=payload.child_id,
        name=payload.name,
        year=payload.year,
        season=payload.season,
        memo=payload.memo,
        frames_json=json.dumps(payload.frames, ensure_ascii=False),
        photos_json=json.dumps(payload.photos, ensure_ascii=False),
        voice_uri=payload.voice.uri if payload.voice else None,
        voice_duration=payload.voice.duration_sec if payload.voice else 0,
        pos_x=payload.pos.x if payload.pos else None,
        pos_z=payload.pos.z if payload.pos else None,
        tone=payload.tone,
        created_at=payload.created_at or ts,
        updated_at=ts,
    )
    if session.get(Item, (family.id, row.id)) is not None:
        raise HTTPException(status_code=409, detail="そのIDはすでに使われています")
    session.add(row)
    session.commit()
    return ItemOut.of(row)


@router.patch("/{item_id}", response_model=ItemOut)
def update_item(
    item_id: str,
    payload: ItemPatch,
    family: Family = Depends(current_family),
    session: Session = Depends(get_session),
) -> ItemOut:
    row = _get(session, family, item_id)
    data = payload.model_dump(exclude_unset=True)

    if "pos" in data:
        pos = payload.pos
        row.pos_x = pos.x if pos else None
        row.pos_z = pos.z if pos else None
        data.pop("pos")
    if "voice" in data:
        voice = payload.voice
        row.voice_uri = voice.uri if voice else None
        row.voice_duration = voice.duration_sec if voice else 0
        data.pop("voice")
    if "photos" in data:
        row.photos_json = json.dumps(data.pop("photos"), ensure_ascii=False)

    for field, value in data.items():
        setattr(row, field, value)
    row.updated_at = now_ms()
    session.commit()
    return ItemOut.of(row)


@router.put("/{item_id}/pos", response_model=ItemOut)
def place_item(
    item_id: str,
    pos: RoomPos,
    family: Family = Depends(current_family),
    session: Session = Depends(get_session),
) -> ItemOut:
    """ハコニワの床にモノを置く（配置機能）。"""
    row = _get(session, family, item_id)
    row.pos_x = pos.x
    row.pos_z = pos.z
    row.updated_at = now_ms()
    session.commit()
    return ItemOut.of(row)


@router.delete("/{item_id}", status_code=204)
def delete_item(
    item_id: str,
    family: Family = Depends(current_family),
    session: Session = Depends(get_session),
) -> None:
    row = _get(session, family, item_id)
    row.deleted = True
    row.updated_at = now_ms()
    session.commit()
