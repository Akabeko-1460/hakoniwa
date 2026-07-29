from __future__ import annotations

import io


def _child(client, family, name="そうた", tone="#E08A63", age=6):
    res = client.post(
        "/api/children",
        json={"name": name, "age": age, "tone": tone},
        headers=family["headers"],
    )
    assert res.status_code == 201, res.text
    return res.json()


def _item(client, family, child_id, **over):
    payload = {
        "childId": child_id,
        "name": "くまのプーさん",
        "year": 2019,
        "season": "春",
        "memo": "はじめて自分でえらんだ ぬいぐるみ。",
        "frames": [],
        "photos": [],
        "tone": "#E08A63",
    }
    payload.update(over)
    res = client.post("/api/items", json=payload, headers=family["headers"])
    assert res.status_code == 201, res.text
    return res.json()


def test_health(client):
    assert client.get("/api/health").json()["status"] == "ok"


def test_auth_required(client):
    assert client.get("/api/children").status_code == 401
    assert (
        client.get("/api/children", headers={"Authorization": "Bearer nope"}).status_code
        == 401
    )


def test_child_crud(client, family):
    child = _child(client, family)
    assert child["name"] == "そうた"

    listed = client.get("/api/children", headers=family["headers"]).json()
    assert [c["id"] for c in listed] == [child["id"]]

    patched = client.patch(
        f"/api/children/{child['id']}", json={"age": 7}, headers=family["headers"]
    ).json()
    assert patched["age"] == 7
    assert patched["updatedAt"] >= child["updatedAt"]

    assert (
        client.delete(f"/api/children/{child['id']}", headers=family["headers"]).status_code
        == 204
    )
    assert client.get("/api/children", headers=family["headers"]).json() == []


def test_deleting_child_hides_its_items(client, family):
    child = _child(client, family)
    _item(client, family, child["id"])
    client.delete(f"/api/children/{child['id']}", headers=family["headers"])
    assert client.get("/api/items", headers=family["headers"]).json() == []


def test_item_requires_existing_child(client, family):
    res = client.post(
        "/api/items",
        json={"childId": "ghost", "name": "つみき", "year": 2024, "season": "冬"},
        headers=family["headers"],
    )
    assert res.status_code == 404


def test_timeline_is_newest_first(client, family):
    child = _child(client, family)
    _item(client, family, child["id"], name="くま", year=2019, season="春")
    _item(client, family, child["id"], name="ねんど", year=2023, season="夏")
    _item(client, family, child["id"], name="つみき", year=2023, season="冬")

    names = [i["name"] for i in client.get("/api/items", headers=family["headers"]).json()]
    assert names == ["つみき", "ねんど", "くま"]


def test_item_search_matches_name_and_memo(client, family):
    child = _child(client, family)
    _item(client, family, child["id"], name="かぞくの絵", memo="いぬのポチも")
    _item(client, family, child["id"], name="つみき", memo="たかく つみあげて")

    found = client.get("/api/items?q=ポチ", headers=family["headers"]).json()
    assert [i["name"] for i in found] == ["かぞくの絵"]


def test_place_item_on_the_floor(client, family):
    child = _child(client, family)
    item = _item(client, family, child["id"])
    assert item["pos"] is None

    placed = client.put(
        f"/api/items/{item['id']}/pos",
        json={"x": -0.32, "z": 0.1},
        headers=family["headers"],
    ).json()
    assert placed["pos"] == {"x": -0.32, "z": 0.1}


def test_pos_outside_the_floor_is_rejected(client, family):
    child = _child(client, family)
    item = _item(client, family, child["id"])
    res = client.put(
        f"/api/items/{item['id']}/pos", json={"x": 3.0, "z": 0.0}, headers=family["headers"]
    )
    assert res.status_code == 422


def test_item_patch_can_clear_voice(client, family):
    child = _child(client, family)
    item = _item(
        client,
        family,
        child["id"],
        voice={"uri": "media://abc", "durationSec": 12},
    )
    assert item["voice"]["durationSec"] == 12

    cleared = client.patch(
        f"/api/items/{item['id']}", json={"voice": None}, headers=family["headers"]
    ).json()
    assert cleared["voice"] is None


def test_media_upload_and_download(client, family):
    res = client.post(
        "/api/media",
        files={"file": ("frame.jpg", io.BytesIO(b"\xff\xd8\xff-fake-jpeg"), "image/jpeg")},
        headers=family["headers"],
    )
    assert res.status_code == 201, res.text
    media = res.json()

    got = client.get(media["url"], headers=family["headers"])
    assert got.status_code == 200
    assert got.content == b"\xff\xd8\xff-fake-jpeg"


def test_media_rejects_unsupported_type(client, family):
    res = client.post(
        "/api/media",
        files={"file": ("bad.exe", io.BytesIO(b"MZ"), "application/x-msdownload")},
        headers=family["headers"],
    )
    assert res.status_code == 415


def test_media_is_not_readable_by_another_family(client, family):
    res = client.post(
        "/api/media",
        files={"file": ("a.jpg", io.BytesIO(b"secret"), "image/jpeg")},
        headers=family["headers"],
    )
    media_id = res.json()["id"]

    other = client.post("/api/families", json={"name": "よその家"}).json()
    other_headers = {"Authorization": f"Bearer {other['token']}"}
    assert client.get(f"/api/media/{media_id}", headers=other_headers).status_code == 404


def test_families_are_isolated(client, family):
    _child(client, family)
    other = client.post("/api/families", json={"name": "よその家"}).json()
    other_headers = {"Authorization": f"Bearer {other['token']}"}
    assert client.get("/api/children", headers=other_headers).json() == []


def test_settings_round_trip(client, family):
    defaults = client.get("/api/settings", headers=family["headers"]).json()
    assert defaults["scanTarget"] == 20 and defaults["onboarded"] is False

    saved = client.put(
        "/api/settings",
        json={"scanTarget": 12, "backup": False, "notify": True, "onboarded": True},
        headers=family["headers"],
    ).json()
    assert saved["scanTarget"] == 12 and saved["onboarded"] is True


def test_sync_pushes_local_db_and_returns_snapshot(client, family):
    res = client.post(
        "/api/sync",
        json={
            "children": [
                {
                    "id": "sota",
                    "name": "そうた",
                    "age": 6,
                    "tone": "#E08A63",
                    "createdAt": 1000,
                    "updatedAt": 1000,
                }
            ],
            "items": [
                {
                    "id": "bear",
                    "childId": "sota",
                    "name": "くまのプーさん",
                    "year": 2019,
                    "season": "春",
                    "memo": "",
                    "pos": {"x": -0.32, "z": 0.1},
                    "tone": "#E08A63",
                    "createdAt": 1000,
                    "updatedAt": 1000,
                }
            ],
            "settings": {
                "scanTarget": 12,
                "backup": True,
                "notify": False,
                "onboarded": True,
            },
        },
        headers=family["headers"],
    )
    assert res.status_code == 200, res.text
    snap = res.json()
    assert [c["id"] for c in snap["children"]] == ["sota"]
    assert snap["items"][0]["pos"] == {"x": -0.32, "z": 0.1}
    assert snap["settings"]["scanTarget"] == 12


def test_sync_keeps_the_newer_edit(client, family):
    base = {
        "children": [
            {"id": "sota", "name": "そうた", "tone": "#E08A63", "updatedAt": 5000}
        ]
    }
    client.post("/api/sync", json=base, headers=family["headers"])

    stale = {
        "children": [
            {"id": "sota", "name": "ふるい名まえ", "tone": "#E08A63", "updatedAt": 4000}
        ]
    }
    snap = client.post("/api/sync", json=stale, headers=family["headers"]).json()
    assert snap["children"][0]["name"] == "そうた"

    fresh = {
        "children": [
            {"id": "sota", "name": "あたらしい名まえ", "tone": "#8BA36F", "updatedAt": 9000}
        ]
    }
    snap = client.post("/api/sync", json=fresh, headers=family["headers"]).json()
    assert snap["children"][0]["name"] == "あたらしい名まえ"


def test_sync_takes_the_incoming_row_when_timestamps_tie(client, family):
    """保存してすぐ配置すると updatedAt がミリ秒まで並びうる。

    同着を「古い」とみなすと、置いた場所がサーバーに届かないまま消える。
    """
    base = {
        "id": "blocks",
        "childId": "sota",
        "name": "つみき",
        "year": 2024,
        "season": "冬",
        "tone": "#7FA6C4",
        "updatedAt": 5000,
    }
    client.post(
        "/api/sync",
        json={"children": [{"id": "sota", "name": "そうた", "updatedAt": 5000}]},
        headers=family["headers"],
    )
    client.post("/api/sync", json={"items": [base]}, headers=family["headers"])

    placed = client.post(
        "/api/sync",
        json={"items": [{**base, "pos": {"x": 0.2, "z": -0.3}}]},
        headers=family["headers"],
    ).json()

    assert placed["items"][0]["pos"] == {"x": 0.2, "z": -0.3}


def test_sync_still_ignores_a_genuinely_older_row(client, family):
    client.post(
        "/api/sync",
        json={"children": [{"id": "sota", "name": "いま", "updatedAt": 5000}]},
        headers=family["headers"],
    )
    snap = client.post(
        "/api/sync",
        json={"children": [{"id": "sota", "name": "むかし", "updatedAt": 4999}]},
        headers=family["headers"],
    ).json()
    assert snap["children"][0]["name"] == "いま"


def test_sync_cannot_overwrite_another_familys_row(client, family):
    """IDは端末が付けるので家族をまたぐと衝突する。それぞれ別の行として扱う。

    見本データは全員 id="sota" から始まるので、ここが同じ行を指してしまうと
    2番目に同期した家族のデータが丸ごと消える。
    """
    client.post(
        "/api/sync",
        json={"children": [{"id": "sota", "name": "そうた", "updatedAt": 1000}]},
        headers=family["headers"],
    )
    other = client.post("/api/families", json={"name": "よその家"}).json()
    other_headers = {"Authorization": f"Bearer {other['token']}"}

    snap = client.post(
        "/api/sync",
        json={"children": [{"id": "sota", "name": "よその子", "updatedAt": 9999}]},
        headers=other_headers,
    ).json()
    # よその家は自分の "sota" を持てる
    assert [c["name"] for c in snap["children"]] == ["よその子"]

    # こちらの "sota" は書きかえられていない
    mine = client.get("/api/children", headers=family["headers"]).json()
    assert [c["name"] for c in mine] == ["そうた"]


def test_two_families_can_sync_the_same_seed_ids(client, family):
    """見本データそのままの2世帯が、どちらも思い出を失わない。"""
    seed = {
        "children": [{"id": "sota", "name": "そうた", "tone": "#E08A63"}],
        "items": [
            {
                "id": "bear",
                "childId": "sota",
                "name": "くまのプーさん",
                "year": 2019,
                "season": "春",
                "tone": "#E08A63",
            }
        ],
    }
    first = client.post("/api/sync", json=seed, headers=family["headers"]).json()
    assert [i["name"] for i in first["items"]] == ["くまのプーさん"]

    other = client.post("/api/families", json={"name": "よその家"}).json()
    other_headers = {"Authorization": f"Bearer {other['token']}"}
    second = client.post("/api/sync", json=seed, headers=other_headers).json()

    assert [i["name"] for i in second["items"]] == ["くまのプーさん"]
    assert len(second["children"]) == 1


def test_deleting_an_item_does_not_touch_the_same_id_elsewhere(client, family):
    seed = {
        "children": [{"id": "sota", "name": "そうた"}],
        "items": [
            {
                "id": "bear",
                "childId": "sota",
                "name": "くま",
                "year": 2019,
                "season": "春",
            }
        ],
    }
    client.post("/api/sync", json=seed, headers=family["headers"])
    other = client.post("/api/families", json={"name": "よその家"}).json()
    other_headers = {"Authorization": f"Bearer {other['token']}"}
    client.post("/api/sync", json=seed, headers=other_headers)

    client.post(
        "/api/sync", json={"deletedItemIds": ["bear"]}, headers=other_headers
    )

    mine = client.get("/api/items", headers=family["headers"]).json()
    assert [i["name"] for i in mine] == ["くま"], "よその家の削除でこちらが消えている"


def test_sync_propagates_deletions(client, family):
    child = _child(client, family)
    item = _item(client, family, child["id"])
    snap = client.post(
        "/api/sync",
        json={"deletedItemIds": [item["id"]]},
        headers=family["headers"],
    ).json()
    assert snap["items"] == []
