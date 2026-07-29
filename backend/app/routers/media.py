"""スキャンフレーム・写真・こえメモのアップロードと配信。"""
from __future__ import annotations

import mimetypes
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from ..config import Settings, get_settings
from ..db import Family, Media, get_session, now_ms
from ..schemas import MediaOut
from ..security import current_family, new_id

router = APIRouter(prefix="/api/media", tags=["media"])

ALLOWED = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "audio/mp4": ".m4a",
    "audio/aac": ".m4a",
    "audio/mpeg": ".mp3",
    "audio/wav": ".wav",
    "audio/x-wav": ".wav",
    "audio/webm": ".webm",
    "video/webm": ".webm",
}


def _stored_path(settings: Settings, family_id: str, media_id: str, ext: str) -> Path:
    directory = settings.media_dir / family_id
    directory.mkdir(parents=True, exist_ok=True)
    return directory / f"{media_id}{ext}"


@router.post("", response_model=MediaOut, status_code=201)
async def upload(
    file: UploadFile = File(...),
    family: Family = Depends(current_family),
    session: Session = Depends(get_session),
    settings: Settings = Depends(get_settings),
) -> MediaOut:
    content_type = (file.content_type or "").split(";")[0].strip()
    if content_type not in ALLOWED:
        raise HTTPException(
            status_code=415,
            detail=f"対応していない形式です: {content_type or '(不明)'}",
        )

    body = await file.read(settings.max_upload_bytes + 1)
    if len(body) > settings.max_upload_bytes:
        raise HTTPException(
            status_code=413,
            detail=f"ファイルが大きすぎます（上限 {settings.max_upload_bytes} バイト）",
        )
    if not body:
        raise HTTPException(status_code=400, detail="からのファイルです")

    media_id = new_id()
    ext = ALLOWED[content_type]
    _stored_path(settings, family.id, media_id, ext).write_bytes(body)

    row = Media(
        id=media_id,
        family_id=family.id,
        filename=f"{media_id}{ext}",
        content_type=content_type,
        size=len(body),
        created_at=now_ms(),
    )
    session.add(row)
    session.commit()
    return MediaOut(
        id=media_id,
        url=f"/api/media/{media_id}",
        content_type=content_type,
        size=len(body),
    )


@router.get("/{media_id}")
def download(
    media_id: str,
    family: Family = Depends(current_family),
    session: Session = Depends(get_session),
    settings: Settings = Depends(get_settings),
) -> FileResponse:
    row = session.get(Media, media_id)
    # 他家族のメディアは 404 として扱う（存在を漏らさない）
    if row is None or row.family_id != family.id:
        raise HTTPException(status_code=404, detail="そのメディアは見つかりません")
    path = settings.media_dir / family.id / row.filename
    if not path.is_file():
        raise HTTPException(status_code=410, detail="実体が失われています")
    media_type = row.content_type or mimetypes.guess_type(row.filename)[0]
    return FileResponse(path, media_type=media_type, filename=row.filename)
