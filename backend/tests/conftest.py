from __future__ import annotations

import importlib
import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))


@pytest.fixture
def client(tmp_path, monkeypatch):
    """テストごとに使い捨ての data ディレクトリでアプリを起こす。"""
    monkeypatch.setenv("HAKONIWA_DATA_DIR", str(tmp_path / "data"))

    # 設定と engine はモジュール読み込み時に確定するので、読み直す
    from app import config

    config.get_settings.cache_clear()
    for name in [m for m in list(sys.modules) if m.startswith("app.")]:
        del sys.modules[name]

    main = importlib.import_module("app.main")
    with TestClient(main.app) as c:
        yield c


@pytest.fixture
def family(client):
    """認証済みヘッダーと家族IDを返す。"""
    res = client.post("/api/families", json={"name": "テスト家"})
    assert res.status_code == 201
    body = res.json()
    return {
        "id": body["familyId"],
        "headers": {"Authorization": f"Bearer {body['token']}"},
    }
