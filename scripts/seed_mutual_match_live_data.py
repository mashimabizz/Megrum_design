#!/usr/bin/env python3
"""Clean or seed live Supabase rows for the native iOS mutual-match smoke test.

The script intentionally reads local environment files instead of containing
any credentials. By default it removes deterministic `codex_mm_*` goods/listings
and marks those users as test accounts so they do not leak into normal home
candidates. Use `--seed` only for a dedicated live smoke-test account.
"""

from __future__ import annotations

import json
import sys
import time
import uuid
from pathlib import Path
from typing import Any
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ENV_PATH = ROOT / "web" / ".env.local"
SUMMARY_PATH = Path("/tmp/megrum_mutual_match_seed.json")
PASSWORD = "CodexMutualMatchTest!2026"
EMAIL_DOMAIN = "megrum-mutual-test.invalid"
SEED_NAMESPACE = uuid.uuid5(uuid.NAMESPACE_DNS, "megrum-mutual-match-live-data")


class SupabaseHTTPError(RuntimeError):
    def __init__(self, status: int, body: str):
        super().__init__(f"Supabase HTTP {status}: {body[:300]}")
        self.status = status
        self.body = body


def load_env(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values
    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key] = value.strip().strip('"').strip("'")
    return values


def normalized_tag(label: str) -> str:
    return " ".join(label.strip().lower().split())


def stable_uuid(name: str) -> str:
    return str(uuid.uuid5(SEED_NAMESPACE, name))


class Supabase:
    def __init__(self, url: str, service_key: str, publishable_key: str):
        self.url = url.rstrip("/")
        self.service_key = service_key
        self.publishable_key = publishable_key

    def request(
        self,
        method: str,
        path: str,
        *,
        query: dict[str, str] | None = None,
        body: Any | None = None,
        service: bool = True,
        prefer: str | None = None,
    ) -> Any:
        key = self.service_key if service else self.publishable_key
        target = f"{self.url}{path}"
        if query:
            target += "?" + urlencode(query, safe="(),.*")
        data = None if body is None else json.dumps(body).encode()
        headers = {
            "apikey": key,
            "Authorization": f"Bearer {key}",
            "Accept": "application/json",
        }
        if body is not None:
            headers["Content-Type"] = "application/json"
        if prefer:
            headers["Prefer"] = prefer
        request = Request(target, data=data, method=method, headers=headers)
        try:
            with urlopen(request, timeout=30) as response:
                payload = response.read().decode()
                if not payload:
                    return None
                return json.loads(payload)
        except HTTPError as error:
            raise SupabaseHTTPError(error.code, error.read().decode()) from error

    def select(self, table: str, **query: str) -> list[dict[str, Any]]:
        return self.request("GET", f"/rest/v1/{table}", query=query)

    def delete(self, table: str, **query: str) -> None:
        self.request("DELETE", f"/rest/v1/{table}", query=query, prefer="return=minimal")

    def upsert(
        self,
        table: str,
        rows: list[dict[str, Any]],
        *,
        on_conflict: str,
        select: str = "*",
    ) -> list[dict[str, Any]]:
        return self.request(
            "POST",
            f"/rest/v1/{table}",
            query={"select": select, "on_conflict": on_conflict},
            body=rows,
            prefer="resolution=merge-duplicates,return=representation",
        )

    def create_auth_user_if_needed(self, handle: str, display_name: str) -> str:
        existing = self.select("users", select="id,handle", handle=f"eq.{handle}", limit="1")
        if existing:
            return existing[0]["id"]

        email = f"{handle}@{EMAIL_DOMAIN}"
        payload = {
            "email": email,
            "password": PASSWORD,
            "email_confirm": True,
            "user_metadata": {
                "handle": handle,
                "display_name": display_name,
            },
        }
        created = self.request("POST", "/auth/v1/admin/users", body=payload)
        user_id = created["id"]
        for _ in range(10):
            row = self.select("users", select="id,handle", id=f"eq.{user_id}", limit="1")
            if row:
                return user_id
            time.sleep(0.2)
        self.upsert(
            "users",
            [
                {
                    "id": user_id,
                    "handle": handle,
                    "display_name": display_name,
                    "account_status": "active",
                }
            ],
            on_conflict="id",
            select="id",
        )
        return user_id


def first_row(rows: list[dict[str, Any]], label: str) -> dict[str, Any]:
    if not rows:
        raise RuntimeError(f"Missing master row: {label}")
    return rows[0]


def master_data(client: Supabase) -> dict[str, str]:
    bts = first_row(client.select("groups_master", select="id,name", name="eq.BTS", limit="1"), "BTS")
    twice = first_row(client.select("groups_master", select="id,name", name="eq.TWICE", limit="1"), "TWICE")
    tr = first_row(
        client.select("goods_types_master", select="id,name", name="eq.トレカ", limit="1"),
        "トレカ",
    )

    def character(group_id: str, name: str) -> dict[str, Any]:
        return first_row(
            client.select(
                "characters_master",
                select="id,name,group_id",
                group_id=f"eq.{group_id}",
                name=f"eq.{name}",
                limit="1",
            ),
            name,
        )

    return {
        "bts": bts["id"],
        "twice": twice["id"],
        "trading_card": tr["id"],
        "jin": character(bts["id"], "ジン")["id"],
        "suga": character(bts["id"], "SUGA")["id"],
        "rm": character(bts["id"], "RM")["id"],
        "sana": character(twice["id"], "サナ")["id"],
        "momo": character(twice["id"], "モモ")["id"],
    }


def users_payment_columns_supported(client: Supabase) -> bool:
    try:
        client.select("users", select="id,payment_methods,payment_note", limit="1")
        return True
    except SupabaseHTTPError as error:
        if error.status == 400 and ("payment_methods" in error.body or "payment_note" in error.body):
            return False
        raise


def users_test_account_column_supported(client: Supabase) -> bool:
    try:
        client.select("users", select="id,is_test_account", limit="1")
        return True
    except SupabaseHTTPError as error:
        if error.status == 400 and "is_test_account" in error.body:
            return False
        raise


def goods_stock_columns_supported(client: Supabase) -> bool:
    try:
        client.select("goods_inventory", select="id,locked_qty,market_available_qty", limit="1")
        return True
    except SupabaseHTTPError as error:
        if error.status == 400 and ("locked_qty" in error.body or "market_available_qty" in error.body):
            return False
        raise


def ensure_users(
    client: Supabase,
    *,
    include_payment_fields: bool,
    include_test_account_field: bool,
) -> dict[str, str]:
    profiles = {
        "viewer": ("codex_mm_viewer", "Codex相互テスト本人", "東京都", ["paypay", "bank_transfer"]),
        "ready": ("codex_mm_ready", "相互成立テスト", "東京都", ["paypay"]),
        "tag": ("codex_mm_tag", "タグ不一致テスト", "大阪府", ["bank_transfer"]),
        "cash": ("codex_mm_cash", "金額不足テスト", "福岡県", ["cash_exchange"]),
        "set": ("codex_mm_set", "セット表示テスト", "東京都", ["paypay"]),
        "nomatch": ("codex_mm_nomatch", "不一致非表示テスト", "東京都", ["paypay"]),
        "amount": ("codex_mm_amount", "金額込み候補テスト", "東京都", ["paypay"]),
    }
    result: dict[str, str] = {}
    for key, (handle, display_name, area, payment_methods) in profiles.items():
        user_id = client.create_auth_user_if_needed(handle, display_name)
        result[key] = user_id
        profile = {
            "id": user_id,
            "handle": handle,
            "display_name": display_name,
            "primary_area": area,
            "account_status": "suspended",
        }
        if include_payment_fields:
            profile["payment_methods"] = payment_methods
            profile["payment_note"] = "mutual-match smoke test"
        if include_test_account_field:
            profile["is_test_account"] = True
        client.upsert("users", [profile], on_conflict="id", select="id,handle")
    return result


def clean_seed_rows(client: Supabase, user_ids: dict[str, str], *, include_test_account_field: bool = False) -> None:
    ids = ",".join(user_ids.values())
    client.delete("listings", user_id=f"in.({ids})")
    client.delete("goods_inventory", user_id=f"in.({ids})")
    profile_patch = {
        "account_status": "suspended",
    }
    if include_test_account_field:
        profile_patch["is_test_account"] = True
    for user_id in user_ids.values():
        client.request(
            "PATCH",
            "/rest/v1/users",
            query={"id": f"eq.{user_id}"},
            body=profile_patch,
            prefer="return=minimal",
        )


def find_existing_seed_users(client: Supabase) -> dict[str, str]:
    rows = client.select("users", select="id,handle", handle="like.codex_mm_%")
    return {row["handle"]: row["id"] for row in rows}


def goods_row(
    key: str,
    user_id: str,
    kind: str,
    group_id: str,
    character_id: str,
    goods_type_id: str,
    title: str,
    *,
    quantity: int = 1,
    include_stock_fields: bool = True,
) -> dict[str, Any]:
    row = {
        "id": stable_uuid(f"goods:{key}"),
        "user_id": user_id,
        "kind": kind,
        "group_id": group_id,
        "character_id": character_id,
        "goods_type_id": goods_type_id,
        "title": title,
        "quantity": quantity,
        "photo_urls": [f"https://picsum.photos/seed/megrum-{key}/360/360"],
        "status": "active",
        "exchange_type": "any",
    }
    if include_stock_fields:
        row["locked_qty"] = 0
    return row


def listing_row(key: str, user_id: str, have_keys: list[str], logic: str) -> dict[str, Any]:
    return {
        "id": stable_uuid(f"listing:{key}"),
        "user_id": user_id,
        "have_ids": [stable_uuid(f"goods:{item}") for item in have_keys],
        "have_qtys": [1 for _ in have_keys],
        "have_logic": logic,
        "status": "active",
        "note": "codex mutual match live test",
    }


def option_row(
    key: str,
    listing_key: str,
    position: int,
    wish_keys: list[str],
    logic: str,
    *,
    is_cash_offer: bool = False,
    cash_amount: int | None = None,
    include_cash_amount_field: bool = True,
) -> dict[str, Any]:
    row: dict[str, Any] = {
        "id": stable_uuid(f"option:{key}"),
        "listing_id": stable_uuid(f"listing:{listing_key}"),
        "position": position,
        "wish_ids": [stable_uuid(f"goods:{item}") for item in wish_keys],
        "wish_qtys": [1 for _ in wish_keys],
        "logic": logic,
        "exchange_type": "any",
        "is_cash_offer": is_cash_offer,
    }
    if include_cash_amount_field:
        row["cash_amount"] = cash_amount
    return row


def seed_goods_and_listings(
    client: Supabase,
    users: dict[str, str],
    masters: dict[str, str],
    *,
    include_stock_fields: bool,
) -> bool:
    tr = masters["trading_card"]
    def seed_goods_row(
        key: str,
        user_id: str,
        kind: str,
        group_id: str,
        character_id: str,
        goods_type_id: str,
        title: str,
        *,
        quantity: int = 1,
    ) -> dict[str, Any]:
        return goods_row(
            key,
            user_id,
            kind,
            group_id,
            character_id,
            goods_type_id,
            title,
            quantity=quantity,
            include_stock_fields=include_stock_fields,
        )

    goods = [
        seed_goods_row("ready_viewer_offer", users["viewer"], "for_trade", masters["bts"], masters["jin"], tr, "ジン トレカ"),
        seed_goods_row("ready_viewer_want", users["viewer"], "wanted", masters["bts"], masters["suga"], tr, "SUGA トレカ"),
        seed_goods_row("ready_partner_offer", users["ready"], "for_trade", masters["bts"], masters["suga"], tr, "SUGA トレカ"),
        seed_goods_row("ready_partner_want", users["ready"], "wanted", masters["bts"], masters["jin"], tr, "ジン トレカ"),
        seed_goods_row("tag_viewer_offer", users["viewer"], "for_trade", masters["twice"], masters["momo"], tr, "モモ トレカ"),
        seed_goods_row("tag_viewer_want", users["viewer"], "wanted", masters["twice"], masters["sana"], tr, "サナ トレカ"),
        seed_goods_row("tag_partner_offer", users["tag"], "for_trade", masters["twice"], masters["sana"], tr, "サナ トレカ"),
        seed_goods_row("tag_partner_want", users["tag"], "wanted", masters["twice"], masters["momo"], tr, "モモ トレカ"),
        seed_goods_row("cash_viewer_offer", users["viewer"], "for_trade", masters["bts"], masters["rm"], tr, "RM トレカ"),
        seed_goods_row("cash_partner_offer", users["cash"], "for_trade", masters["bts"], masters["jin"], tr, "ジン トレカ"),
        seed_goods_row("set_viewer_offer_1", users["viewer"], "for_trade", masters["bts"], masters["jin"], tr, "ジン トレカ"),
        seed_goods_row("set_viewer_offer_2", users["viewer"], "for_trade", masters["bts"], masters["rm"], tr, "RM トレカ"),
        seed_goods_row("set_viewer_want_1", users["viewer"], "wanted", masters["twice"], masters["sana"], tr, "サナ トレカ"),
        seed_goods_row("set_viewer_want_2", users["viewer"], "wanted", masters["twice"], masters["momo"], tr, "モモ トレカ"),
        seed_goods_row("set_partner_offer_1", users["set"], "for_trade", masters["twice"], masters["sana"], tr, "サナ トレカ"),
        seed_goods_row("set_partner_offer_2", users["set"], "for_trade", masters["twice"], masters["momo"], tr, "モモ トレカ"),
        seed_goods_row("set_partner_want_1", users["set"], "wanted", masters["bts"], masters["jin"], tr, "ジン トレカ"),
        seed_goods_row("set_partner_want_2", users["set"], "wanted", masters["bts"], masters["rm"], tr, "RM トレカ"),
        seed_goods_row("nomatch_viewer_want", users["viewer"], "wanted", masters["twice"], masters["sana"], tr, "サナ トレカ"),
        seed_goods_row("nomatch_partner_offer", users["nomatch"], "for_trade", masters["twice"], masters["momo"], tr, "モモ トレカ"),
        seed_goods_row("nomatch_partner_want", users["nomatch"], "wanted", masters["bts"], masters["jin"], tr, "ジン トレカ"),
        seed_goods_row("amount_viewer_offer", users["viewer"], "for_trade", masters["bts"], masters["suga"], tr, "SUGA トレカ"),
        seed_goods_row("amount_partner_offer", users["amount"], "for_trade", masters["bts"], masters["jin"], tr, "ジン トレカ"),
    ]
    client.upsert("goods_inventory", goods, on_conflict="id", select="id,user_id,title")

    tags = {
        "ready_viewer_offer": ["live-2026"],
        "ready_viewer_want": ["live-2026"],
        "ready_partner_offer": ["live-2026"],
        "ready_partner_want": ["live-2026"],
        "tag_viewer_offer": ["alpha-test"],
        "tag_viewer_want": ["beta-test"],
        "tag_partner_offer": ["gamma-test"],
        "tag_partner_want": ["delta-test"],
    }
    tag_rows = []
    for label in sorted({label for labels in tags.values() for label in labels}):
        tag_rows.extend(
            client.upsert(
                "tags_master",
                [
                    {
                        "label": label,
                        "normalized_label": normalized_tag(label),
                        "created_by": users["viewer"],
                    }
                ],
                on_conflict="normalized_label",
                select="id,label,normalized_label",
            )
        )
    tag_id_by_label = {row["label"]: row["id"] for row in tag_rows}
    client.upsert(
        "goods_inventory_tags",
        [
            {
                "inventory_id": stable_uuid(f"goods:{goods_key}"),
                "tag_id": tag_id_by_label[label],
            }
            for goods_key, labels in tags.items()
            for label in labels
        ],
        on_conflict="inventory_id,tag_id",
        select="inventory_id,tag_id",
    )

    listings = [
        listing_row("ready_viewer", users["viewer"], ["ready_viewer_offer"], "or"),
        listing_row("ready_partner", users["ready"], ["ready_partner_offer"], "or"),
        listing_row("tag_viewer", users["viewer"], ["tag_viewer_offer"], "or"),
        listing_row("tag_partner", users["tag"], ["tag_partner_offer"], "or"),
        listing_row("cash_viewer", users["viewer"], ["cash_viewer_offer"], "or"),
        listing_row("cash_partner", users["cash"], ["cash_partner_offer"], "or"),
        listing_row("set_viewer", users["viewer"], ["set_viewer_offer_1", "set_viewer_offer_2"], "and"),
        listing_row("set_partner", users["set"], ["set_partner_offer_1", "set_partner_offer_2"], "and"),
        listing_row("nomatch_viewer", users["viewer"], ["ready_viewer_offer"], "or"),
        listing_row("nomatch_partner", users["nomatch"], ["nomatch_partner_offer"], "or"),
        listing_row("amount_viewer", users["viewer"], ["amount_viewer_offer"], "or"),
        listing_row("amount_partner", users["amount"], ["amount_partner_offer"], "or"),
    ]
    client.upsert("listings", listings, on_conflict="id", select="id,user_id")

    options = [
        option_row("ready_viewer_1", "ready_viewer", 1, ["ready_viewer_want"], "or"),
        option_row("ready_partner_1", "ready_partner", 1, ["ready_partner_want"], "or"),
        option_row("tag_viewer_1", "tag_viewer", 1, ["tag_viewer_want"], "or"),
        option_row("tag_partner_1", "tag_partner", 1, ["tag_partner_want"], "or"),
        option_row("cash_viewer_1", "cash_viewer", 1, [], "or", is_cash_offer=True, cash_amount=2000),
        option_row("cash_partner_1", "cash_partner", 1, [], "or", is_cash_offer=True, cash_amount=1500),
        option_row("set_viewer_1", "set_viewer", 1, ["set_viewer_want_1"], "and"),
        option_row("set_viewer_2", "set_viewer", 2, ["set_viewer_want_2"], "and"),
        option_row("set_partner_1", "set_partner", 1, ["set_partner_want_1"], "and"),
        option_row("set_partner_2", "set_partner", 2, ["set_partner_want_2"], "and"),
        option_row("nomatch_viewer_1", "nomatch_viewer", 1, ["nomatch_viewer_want"], "or"),
        option_row("nomatch_partner_1", "nomatch_partner", 1, ["nomatch_partner_want"], "or"),
    ]
    client.upsert("listing_wish_options", options, on_conflict="id", select="id,listing_id")

    amount_included_supported = False
    try:
        client.upsert(
            "listing_wish_options",
            [
                option_row(
                    "amount_viewer_1",
                    "amount_viewer",
                    1,
                    [],
                    "or",
                    is_cash_offer=True,
                    cash_amount=None,
                    include_cash_amount_field=True,
                ),
                option_row(
                    "amount_partner_1",
                    "amount_partner",
                    1,
                    [],
                    "or",
                    is_cash_offer=True,
                    cash_amount=1200,
                ),
            ],
            on_conflict="id",
            select="id,listing_id,cash_amount",
        )
        amount_included_supported = True
    except SupabaseHTTPError as error:
        try:
            client.upsert(
                "listing_wish_options",
                [
                    option_row(
                        "amount_viewer_1",
                        "amount_viewer",
                        1,
                        [],
                        "or",
                        is_cash_offer=True,
                        cash_amount=None,
                        include_cash_amount_field=False,
                    ),
                    option_row(
                        "amount_partner_1",
                        "amount_partner",
                        1,
                        [],
                        "or",
                        is_cash_offer=True,
                        cash_amount=1200,
                    ),
                ],
                on_conflict="id",
                select="id,listing_id,cash_amount",
            )
            amount_included_supported = True
        except SupabaseHTTPError:
            print(f"amount_included_seed_skipped status={error.status}")
    return amount_included_supported


def main() -> int:
    env = load_env(DEFAULT_ENV_PATH)
    url = env.get("NEXT_PUBLIC_SUPABASE_URL") or env.get("MEGRUM_SUPABASE_URL")
    publishable_key = env.get("NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY") or env.get("MEGRUM_SUPABASE_PUBLISHABLE_KEY")
    service_key = env.get("SUPABASE_SECRET_KEY")
    if not url or not publishable_key or not service_key:
        print("Missing Supabase env in web/.env.local", file=sys.stderr)
        return 2

    client = Supabase(url, service_key, publishable_key)
    include_payment_fields = users_payment_columns_supported(client)
    include_test_account_field = users_test_account_column_supported(client)
    include_stock_fields = goods_stock_columns_supported(client)
    existing_seed_users = find_existing_seed_users(client)
    if "--seed" not in sys.argv[1:]:
        if existing_seed_users:
            clean_seed_rows(client, existing_seed_users, include_test_account_field=include_test_account_field)
        summary = {
            "mode": "cleanup",
            "cleaned_handles": sorted(existing_seed_users.keys()),
            "users_test_account_column_supported": include_test_account_field,
        }
        SUMMARY_PATH.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n")
        print(json.dumps(summary, ensure_ascii=False))
        return 0

    masters = master_data(client)
    users = ensure_users(
        client,
        include_payment_fields=include_payment_fields,
        include_test_account_field=include_test_account_field,
    )
    clean_seed_rows(client, users, include_test_account_field=include_test_account_field)
    amount_included_supported = seed_goods_and_listings(
        client,
        users,
        masters,
        include_stock_fields=include_stock_fields,
    )

    summary = {
        "mode": "seed",
        "viewer_id": users["viewer"],
        "handles": {
            "viewer": "codex_mm_viewer",
            "ready": "codex_mm_ready",
            "tag": "codex_mm_tag",
            "cash": "codex_mm_cash",
            "set": "codex_mm_set",
            "nomatch": "codex_mm_nomatch",
            "amount": "codex_mm_amount",
        },
        "amount_included_supported": amount_included_supported,
        "users_payment_columns_supported": include_payment_fields,
        "users_test_account_column_supported": include_test_account_field,
        "goods_stock_columns_supported": include_stock_fields,
    }
    SUMMARY_PATH.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(summary, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
