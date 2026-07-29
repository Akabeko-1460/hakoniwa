"""SQLAlchemy のテーブル定義とセッション。

家族（Family）ごとにデータを分ける。子ども（Child）・思い出（Item）・設定
（FamilySettings）・メディア（Media）はすべて family_id にぶら下がる。
"""
from __future__ import annotations

import time
from typing import Iterator

from sqlalchemy import (
    Boolean,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    create_engine,
)
from sqlalchemy.orm import (
    DeclarativeBase,
    Mapped,
    Session,
    mapped_column,
    relationship,
    sessionmaker,
)

from .config import get_settings


def now_ms() -> int:
    return int(time.time() * 1000)


class Base(DeclarativeBase):
    pass


class Family(Base):
    """1つのハコニワ世帯。token を Bearer で送ることで認証する。"""

    __tablename__ = "families"

    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    name: Mapped[str] = mapped_column(String(120), default="わが家")
    token_hash: Mapped[str] = mapped_column(String(64), index=True)
    created_at: Mapped[int] = mapped_column(Integer, default=now_ms)

    children: Mapped[list["Child"]] = relationship(
        back_populates="family", cascade="all, delete-orphan"
    )
    items: Mapped[list["Item"]] = relationship(
        back_populates="family", cascade="all, delete-orphan"
    )


class Child(Base):
    """子ども = 1つのハコニワ空間。

    id は端末が付けるので、家族をまたぐと衝突しうる（見本データは全員 "sota"
    から始まる）。そのため主キーは (family_id, id) の組にしてある。
    """

    __tablename__ = "children"

    family_id: Mapped[str] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), primary_key=True
    )
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(120))
    age: Mapped[int | None] = mapped_column(Integer, nullable=True)
    tone: Mapped[str] = mapped_column(String(16))
    created_at: Mapped[int] = mapped_column(Integer, default=now_ms)
    updated_at: Mapped[int] = mapped_column(Integer, default=now_ms)
    deleted: Mapped[bool] = mapped_column(Boolean, default=False)

    family: Mapped[Family] = relationship(back_populates="children")


class Item(Base):
    """思い出のモノ。frames/photos はメディアIDのJSON配列で持つ。

    Child と同じく、主キーは (family_id, id) の組。
    """

    __tablename__ = "items"

    family_id: Mapped[str] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), primary_key=True
    )
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    child_id: Mapped[str] = mapped_column(String(64), index=True)
    name: Mapped[str] = mapped_column(String(200))
    year: Mapped[int] = mapped_column(Integer)
    season: Mapped[str] = mapped_column(String(4))
    memo: Mapped[str] = mapped_column(Text, default="")
    frames_json: Mapped[str] = mapped_column(Text, default="[]")
    photos_json: Mapped[str] = mapped_column(Text, default="[]")
    voice_uri: Mapped[str | None] = mapped_column(String(400), nullable=True)
    voice_duration: Mapped[int] = mapped_column(Integer, default=0)
    # 部屋の床の正規化座標。未配置は NULL
    pos_x: Mapped[float | None] = mapped_column(Float, nullable=True)
    pos_z: Mapped[float | None] = mapped_column(Float, nullable=True)
    tone: Mapped[str] = mapped_column(String(16))
    created_at: Mapped[int] = mapped_column(Integer, default=now_ms)
    updated_at: Mapped[int] = mapped_column(Integer, default=now_ms)
    deleted: Mapped[bool] = mapped_column(Boolean, default=False)

    family: Mapped[Family] = relationship(back_populates="items")


class FamilySettings(Base):
    __tablename__ = "family_settings"

    family_id: Mapped[str] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), primary_key=True
    )
    scan_target: Mapped[int] = mapped_column(Integer, default=20)
    backup: Mapped[bool] = mapped_column(Boolean, default=True)
    notify: Mapped[bool] = mapped_column(Boolean, default=False)
    onboarded: Mapped[bool] = mapped_column(Boolean, default=False)
    updated_at: Mapped[int] = mapped_column(Integer, default=now_ms)


class Media(Base):
    """アップロードされた画像・音声のメタ情報。実体は data/media/ に置く。"""

    __tablename__ = "media"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    family_id: Mapped[str] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), index=True
    )
    filename: Mapped[str] = mapped_column(String(200))
    content_type: Mapped[str] = mapped_column(String(120))
    size: Mapped[int] = mapped_column(Integer)
    created_at: Mapped[int] = mapped_column(Integer, default=now_ms)


_settings = get_settings()
_settings.data_dir.mkdir(parents=True, exist_ok=True)

engine = create_engine(
    f"sqlite:///{_settings.db_path}",
    connect_args={"check_same_thread": False},
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


def init_db() -> None:
    Base.metadata.create_all(engine)


def get_session() -> Iterator[Session]:
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()
