"""API の入出力スキーマ。Flutter 側の models/ と 1:1 で対応する。

JSON のキーは Dart 側に合わせて camelCase を使う。
"""
from __future__ import annotations

import json
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from . import db as tables

Season = Literal["春", "夏", "秋", "冬"]


def _camel(s: str) -> str:
    head, *rest = s.split("_")
    return head + "".join(w.capitalize() for w in rest)


class CamelModel(BaseModel):
    model_config = ConfigDict(alias_generator=_camel, populate_by_name=True)


# --- 家族 ---------------------------------------------------------------


class FamilyCreate(CamelModel):
    name: str = Field(default="わが家", max_length=120)


class FamilyCredentials(CamelModel):
    """作成時に一度だけ返す。token はサーバーに平文で残さない。"""

    family_id: str
    name: str
    token: str


class FamilyInfo(CamelModel):
    family_id: str
    name: str
    created_at: int


# --- 子ども -------------------------------------------------------------


class ChildIn(CamelModel):
    id: str | None = None
    name: str = Field(min_length=1, max_length=120)
    age: int | None = Field(default=None, ge=0, le=25)
    tone: str = "#E08A63"
    created_at: int | None = None
    # 同期時の勝敗判定に使う。省略時はサーバー時刻
    updated_at: int | None = None


class ChildOut(CamelModel):
    id: str
    name: str
    age: int | None
    tone: str
    created_at: int
    updated_at: int

    @classmethod
    def of(cls, row: tables.Child) -> "ChildOut":
        return cls(
            id=row.id,
            name=row.name,
            age=row.age,
            tone=row.tone,
            created_at=row.created_at,
            updated_at=row.updated_at,
        )


class ChildPatch(CamelModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)
    age: int | None = Field(default=None, ge=0, le=25)
    tone: str | None = None


# --- 思い出 -------------------------------------------------------------


class RoomPos(CamelModel):
    x: float = Field(ge=-1, le=1)
    z: float = Field(ge=-1, le=1)


class VoiceMemo(CamelModel):
    uri: str
    duration_sec: int = Field(ge=0)


class ItemIn(CamelModel):
    id: str | None = None
    child_id: str
    name: str = Field(min_length=1, max_length=200)
    year: int = Field(ge=1900, le=2200)
    season: Season
    memo: str = ""
    frames: list[str] = []
    photos: list[str] = []
    voice: VoiceMemo | None = None
    pos: RoomPos | None = None
    tone: str = "#7FA6C4"
    created_at: int | None = None
    # 同期時の勝敗判定に使う。省略時はサーバー時刻
    updated_at: int | None = None

    @field_validator("frames", "photos")
    @classmethod
    def _cap(cls, v: list[str]) -> list[str]:
        # スキャンは最大20方向、写真は4枚まで。壊れた端末からの暴走を止める
        if len(v) > 40:
            raise ValueError("メディアの数が多すぎます")
        return v


class ItemOut(CamelModel):
    id: str
    child_id: str
    name: str
    year: int
    season: str
    memo: str
    frames: list[str]
    photos: list[str]
    voice: VoiceMemo | None
    pos: RoomPos | None
    tone: str
    created_at: int
    updated_at: int

    @classmethod
    def of(cls, row: tables.Item) -> "ItemOut":
        pos = (
            RoomPos(x=row.pos_x, z=row.pos_z)
            if row.pos_x is not None and row.pos_z is not None
            else None
        )
        voice = (
            VoiceMemo(uri=row.voice_uri, duration_sec=row.voice_duration)
            if row.voice_uri
            else None
        )
        return cls(
            id=row.id,
            child_id=row.child_id,
            name=row.name,
            year=row.year,
            season=row.season,
            memo=row.memo,
            frames=json.loads(row.frames_json),
            photos=json.loads(row.photos_json),
            voice=voice,
            pos=pos,
            tone=row.tone,
            created_at=row.created_at,
            updated_at=row.updated_at,
        )


class ItemPatch(CamelModel):
    name: str | None = Field(default=None, min_length=1, max_length=200)
    year: int | None = Field(default=None, ge=1900, le=2200)
    season: Season | None = None
    memo: str | None = None
    photos: list[str] | None = None
    voice: VoiceMemo | None = None
    pos: RoomPos | None = None
    tone: str | None = None


# --- 設定・同期 ---------------------------------------------------------


class SettingsIn(CamelModel):
    scan_target: Literal[12, 20] = 20
    backup: bool = True
    notify: bool = False
    onboarded: bool = False


class SettingsOut(SettingsIn):
    updated_at: int


class MediaOut(CamelModel):
    id: str
    url: str
    content_type: str
    size: int


class Snapshot(CamelModel):
    """アプリ起動時に丸ごと引くための全データ。"""

    version: int = 1
    server_time: int
    children: list[ChildOut]
    items: list[ItemOut]
    settings: SettingsOut


class SyncPush(CamelModel):
    """端末のローカルDBをまるごと送る。updatedAt の新しい方が勝つ。"""

    children: list[ChildIn] = []
    items: list[ItemIn] = []
    settings: SettingsIn | None = None
    deleted_child_ids: list[str] = []
    deleted_item_ids: list[str] = []
