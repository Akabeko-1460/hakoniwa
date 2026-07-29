"""子ども（=ハコニワ空間）の CRUD。"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..db import Child, Family, Item, get_session, now_ms
from ..schemas import ChildIn, ChildOut, ChildPatch
from ..security import current_family, new_id

router = APIRouter(prefix="/api/children", tags=["children"])


def _get(session: Session, family: Family, child_id: str) -> Child:
    row = session.scalar(
        select(Child).where(
            Child.id == child_id,
            Child.family_id == family.id,
            Child.deleted.is_(False),
        )
    )
    if row is None:
        raise HTTPException(status_code=404, detail="その子どもは見つかりません")
    return row


@router.get("", response_model=list[ChildOut])
def list_children(
    family: Family = Depends(current_family),
    session: Session = Depends(get_session),
) -> list[ChildOut]:
    rows = session.scalars(
        select(Child)
        .where(Child.family_id == family.id, Child.deleted.is_(False))
        .order_by(Child.created_at)
    ).all()
    return [ChildOut.of(r) for r in rows]


@router.post("", response_model=ChildOut, status_code=201)
def create_child(
    payload: ChildIn,
    family: Family = Depends(current_family),
    session: Session = Depends(get_session),
) -> ChildOut:
    ts = now_ms()
    row = Child(
        id=payload.id or new_id(),
        family_id=family.id,
        name=payload.name,
        age=payload.age,
        tone=payload.tone,
        created_at=payload.created_at or ts,
        updated_at=ts,
    )
    if session.get(Child, (family.id, row.id)) is not None:
        raise HTTPException(status_code=409, detail="そのIDはすでに使われています")
    session.add(row)
    session.commit()
    return ChildOut.of(row)


@router.patch("/{child_id}", response_model=ChildOut)
def update_child(
    child_id: str,
    payload: ChildPatch,
    family: Family = Depends(current_family),
    session: Session = Depends(get_session),
) -> ChildOut:
    row = _get(session, family, child_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(row, field, value)
    row.updated_at = now_ms()
    session.commit()
    return ChildOut.of(row)


@router.delete("/{child_id}", status_code=204)
def delete_child(
    child_id: str,
    family: Family = Depends(current_family),
    session: Session = Depends(get_session),
) -> None:
    """論理削除。ぶら下がる思い出もまとめて消す（他端末へ同期させるため）。"""
    row = _get(session, family, child_id)
    ts = now_ms()
    row.deleted = True
    row.updated_at = ts
    for item in session.scalars(
        select(Item).where(Item.family_id == family.id, Item.child_id == child_id)
    ):
        item.deleted = True
        item.updated_at = ts
    session.commit()
