"""設定・スナップショット・同期。

アプリはオフラインファーストで動くので、通信は
「ローカルDBを丸ごと送る（push）→ マージ結果を丸ごと受け取る（snapshot）」
の1往復にまとめている。競合は updatedAt の新しい方が勝つ（last-write-wins）。
"""
from __future__ import annotations

import json

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..db import Child, Family, FamilySettings, Item, get_session, now_ms
from ..schemas import (
    ChildOut,
    ItemOut,
    SettingsIn,
    SettingsOut,
    Snapshot,
    SyncPush,
)
from ..security import current_family, new_id

router = APIRouter(prefix="/api", tags=["sync"])


def _settings_row(session: Session, family: Family) -> FamilySettings:
    row = session.get(FamilySettings, family.id)
    if row is None:
        row = FamilySettings(family_id=family.id, updated_at=now_ms())
        session.add(row)
        session.commit()
    return row


def _settings_out(row: FamilySettings) -> SettingsOut:
    return SettingsOut(
        scan_target=row.scan_target,  # type: ignore[arg-type]
        backup=row.backup,
        notify=row.notify,
        onboarded=row.onboarded,
        updated_at=row.updated_at,
    )


def _snapshot(session: Session, family: Family) -> Snapshot:
    children = session.scalars(
        select(Child)
        .where(Child.family_id == family.id, Child.deleted.is_(False))
        .order_by(Child.created_at)
    ).all()
    items = session.scalars(
        select(Item)
        .where(Item.family_id == family.id, Item.deleted.is_(False))
        .order_by(Item.created_at)
    ).all()
    return Snapshot(
        server_time=now_ms(),
        children=[ChildOut.of(c) for c in children],
        items=[ItemOut.of(i) for i in items],
        settings=_settings_out(_settings_row(session, family)),
    )


@router.get("/settings", response_model=SettingsOut)
def read_settings(
    family: Family = Depends(current_family),
    session: Session = Depends(get_session),
) -> SettingsOut:
    return _settings_out(_settings_row(session, family))


@router.put("/settings", response_model=SettingsOut)
def write_settings(
    payload: SettingsIn,
    family: Family = Depends(current_family),
    session: Session = Depends(get_session),
) -> SettingsOut:
    row = _settings_row(session, family)
    row.scan_target = payload.scan_target
    row.backup = payload.backup
    row.notify = payload.notify
    row.onboarded = payload.onboarded
    row.updated_at = now_ms()
    session.commit()
    return _settings_out(row)


@router.get("/snapshot", response_model=Snapshot)
def read_snapshot(
    family: Family = Depends(current_family),
    session: Session = Depends(get_session),
) -> Snapshot:
    return _snapshot(session, family)


@router.post("/sync", response_model=Snapshot)
def sync(
    payload: SyncPush,
    family: Family = Depends(current_family),
    session: Session = Depends(get_session),
) -> Snapshot:
    ts = now_ms()

    for child in payload.children:
        cid = child.id or new_id()
        stamp = child.updated_at or ts
        row = session.get(Child, (family.id, cid))
        if row is None:
            session.add(
                Child(
                    id=cid,
                    family_id=family.id,
                    name=child.name,
                    age=child.age,
                    tone=child.tone,
                    created_at=child.created_at or ts,
                    updated_at=stamp,
                )
            )
            continue
        # 古い更新だけを無視する。同じ時刻なら送られてきた側を採る
        # （保存してすぐ配置すると updatedAt がミリ秒まで並びうるため、
        #   ここを <= にすると置いた場所が捨てられてしまう）
        if stamp < row.updated_at:
            continue
        row.name = child.name
        row.age = child.age
        row.tone = child.tone
        row.deleted = False
        row.updated_at = stamp

    for item in payload.items:
        iid = item.id or new_id()
        stamp = item.updated_at or ts
        row = session.get(Item, (family.id, iid))
        if row is None:
            session.add(
                Item(
                    id=iid,
                    family_id=family.id,
                    child_id=item.child_id,
                    name=item.name,
                    year=item.year,
                    season=item.season,
                    memo=item.memo,
                    frames_json=json.dumps(item.frames, ensure_ascii=False),
                    photos_json=json.dumps(item.photos, ensure_ascii=False),
                    voice_uri=item.voice.uri if item.voice else None,
                    voice_duration=item.voice.duration_sec if item.voice else 0,
                    pos_x=item.pos.x if item.pos else None,
                    pos_z=item.pos.z if item.pos else None,
                    tone=item.tone,
                    created_at=item.created_at or ts,
                    updated_at=stamp,
                )
            )
            continue
        if stamp < row.updated_at:
            continue
        row.child_id = item.child_id
        row.name = item.name
        row.year = item.year
        row.season = item.season
        row.memo = item.memo
        row.frames_json = json.dumps(item.frames, ensure_ascii=False)
        row.photos_json = json.dumps(item.photos, ensure_ascii=False)
        row.voice_uri = item.voice.uri if item.voice else None
        row.voice_duration = item.voice.duration_sec if item.voice else 0
        row.pos_x = item.pos.x if item.pos else None
        row.pos_z = item.pos.z if item.pos else None
        row.tone = item.tone
        row.deleted = False
        row.updated_at = stamp

    for cid in payload.deleted_child_ids:
        row = session.get(Child, (family.id, cid))
        if row is not None:
            row.deleted = True
            row.updated_at = ts
    for iid in payload.deleted_item_ids:
        row = session.get(Item, (family.id, iid))
        if row is not None:
            row.deleted = True
            row.updated_at = ts

    if payload.settings is not None:
        s = _settings_row(session, family)
        s.scan_target = payload.settings.scan_target
        s.backup = payload.settings.backup
        s.notify = payload.settings.notify
        s.onboarded = payload.settings.onboarded
        s.updated_at = ts

    session.commit()
    return _snapshot(session, family)
