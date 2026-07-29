"""サーバー設定（環境変数 HAKONIWA_* で上書きできる）。"""
from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="HAKONIWA_", env_file=".env")

    # データ置き場（SQLite とアップロードされたメディア）
    data_dir: Path = Path("./data")
    # 1ファイルあたりの上限（スキャンフレームは 20 枚ほど送られてくる）
    max_upload_bytes: int = 16 * 1024 * 1024
    # CORS。Flutter Web からの開発アクセス用。"*" で全許可
    cors_origins: str = "*"

    @property
    def db_path(self) -> Path:
        return self.data_dir / "hakoniwa.db"

    @property
    def media_dir(self) -> Path:
        return self.data_dir / "media"

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    settings = Settings()
    settings.media_dir.mkdir(parents=True, exist_ok=True)
    return settings
