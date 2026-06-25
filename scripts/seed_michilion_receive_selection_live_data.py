#!/usr/bin/env python3
"""Seed live Supabase rows that show receive selection for michilion.

This prepares a visible individual listing owned by `haru_trade_0624`.
The listing offers three goods and requires "2 or more", so michilion sees
the "受け取るものを選ぶ" section after opening a matched goods image.
"""

from __future__ import annotations

import json
import sys
import uuid
from pathlib import Path
from typing import Any

from seed_mutual_match_live_data import (
    Supabase,
    SupabaseHTTPError,
    goods_stock_columns_supported,
    load_env,
    users_payment_columns_supported,
    users_test_account_column_supported,
)


ROOT = Path(__file__).resolve().parents[1]
ENV_PATH = ROOT / "web" / ".env.local"
SUMMARY_PATH = Path("/tmp/megrum_michilion_receive_selection_seed.json")
SEED_NAMESPACE = uuid.uuid5(uuid.NAMESPACE_DNS, "megrum-michilion-receive-selection-live-data")
VIEWER_HANDLE = "michilion"
PARTNER_HANDLE = "haru_trade_0624"


def stable_uuid(name: str) -> str:
    return str(uuid.uuid5(SEED_NAMESPACE, name))


def first_row(rows: list[dict[str, Any]], label: str) -> dict[str, Any]:
    if not rows:
        raise RuntimeError(f"Missing required row: {label}")
    return rows[0]


def find_user(client: Supabase, handle: str) -> dict[str, Any]:
    return first_row(
        client.select(
            "users",
            select="id,handle,display_name,account_status,is_test_account,primary_area,payment_methods",
            handle=f"eq.{handle}",
            limit="1",
        ),
        f"users.handle={handle}",
    )


def lookup_master_data(client: Supabase) -> dict[str, str]:
    bts = first_row(client.select("groups_master", select="id,name", name="eq.BTS", limit="1"), "BTS")
    trading_card = first_row(
        client.select("goods_types_master", select="id,name", name="eq.トレカ", limit="1"),
        "トレカ",
    )

    def character(name: str) -> str:
        return first_row(
            client.select(
                "characters_master",
                select="id,name,group_id",
                group_id=f"eq.{bts['id']}",
                name=f"eq.{name}",
                limit="1",
            ),
            f"BTS/{name}",
        )["id"]

    return {
        "bts": bts["id"],
        "trading_card": trading_card["id"],
        "jin": character("ジン"),
        "suga": character("SUGA"),
        "rm": character("RM"),
        "v": character("V"),
    }


def ensure_partner_visible(
    client: Supabase,
    partner_id: str,
    *,
    include_payment_fields: bool,
    include_test_account_field: bool,
) -> None:
    patch: dict[str, Any] = {
        "account_status": "active",
        "primary_area": "大阪府",
    }
    if include_payment_fields:
        patch["payment_methods"] = ["paypay"]
        patch["payment_note"] = "michilion receive-selection review data"
    if include_test_account_field:
        patch["is_test_account"] = False
    client.request(
        "PATCH",
        "/rest/v1/users",
        query={"id": f"eq.{partner_id}"},
        body=patch,
        prefer="return=minimal",
    )


def goods_row(
    key: str,
    user_id: str,
    kind: str,
    group_id: str,
    character_id: str,
    goods_type_id: str,
    title: str,
    *,
    include_stock_fields: bool,
) -> dict[str, Any]:
    row: dict[str, Any] = {
        "id": stable_uuid(f"goods:{key}"),
        "user_id": user_id,
        "kind": kind,
        "group_id": group_id,
        "character_id": character_id,
        "goods_type_id": goods_type_id,
        "title": title,
        "quantity": 1,
        "photo_urls": [f"https://picsum.photos/seed/megrum-{key}/360/360"],
        "status": "active",
        "exchange_type": "any",
    }
    if include_stock_fields:
        row["locked_qty"] = 0
    return row


def ensure_viewer_offer(
    client: Supabase,
    viewer_id: str,
    masters: dict[str, str],
    *,
    include_stock_fields: bool,
) -> dict[str, Any]:
    existing = client.select(
        "goods_inventory",
        select="id,title,group_id,character_id,goods_type_id",
        user_id=f"eq.{viewer_id}",
        kind="eq.for_trade",
        group_id=f"eq.{masters['bts']}",
        character_id=f"eq.{masters['jin']}",
        goods_type_id=f"eq.{masters['trading_card']}",
        status="eq.active",
        limit="1",
    )
    if existing:
        return existing[0]

    inserted = client.upsert(
        "goods_inventory",
        [
            goods_row(
                "viewer_offer_jin",
                viewer_id,
                "for_trade",
                masters["bts"],
                masters["jin"],
                masters["trading_card"],
                "ジン トレカ（受取選択テスト用）",
                include_stock_fields=include_stock_fields,
            )
        ],
        on_conflict="id",
        select="id,title,group_id,character_id,goods_type_id",
    )
    return inserted[0]


def seed_partner_rows(
    client: Supabase,
    partner_id: str,
    masters: dict[str, str],
    *,
    include_stock_fields: bool,
) -> dict[str, Any]:
    offer_specs = [
        ("partner_offer_suga", "SUGA", masters["suga"]),
        ("partner_offer_rm", "RM", masters["rm"]),
        ("partner_offer_v", "V", masters["v"]),
    ]
    offer_rows = [
        goods_row(
            key,
            partner_id,
            "for_trade",
            masters["bts"],
            character_id,
            masters["trading_card"],
            f"{member} トレカ（受取選択テスト）",
            include_stock_fields=include_stock_fields,
        )
        for key, member, character_id in offer_specs
    ]
    wanted_row = goods_row(
        "partner_want_jin",
        partner_id,
        "wanted",
        masters["bts"],
        masters["jin"],
        masters["trading_card"],
        "ジン トレカ（受取選択テスト希望）",
        include_stock_fields=include_stock_fields,
    )

    client.upsert(
        "goods_inventory",
        offer_rows + [wanted_row],
        on_conflict="id",
        select="id,user_id,title,kind",
    )

    listing_id = stable_uuid("listing:partner_receive_multi")
    option_id = stable_uuid("option:partner_receive_multi_want_jin")
    client.upsert(
        "listings",
        [
            {
                "id": listing_id,
                "user_id": partner_id,
                "have_ids": [row["id"] for row in offer_rows],
                "have_qtys": [1, 1, 1],
                "have_logic": "at_least",
                "have_min_count": 2,
                "status": "active",
                "note": "michilion確認用：譲るもの3件から2個以上",
            }
        ],
        on_conflict="id",
        select="id,user_id,have_ids,have_logic,have_min_count,status,note",
    )
    client.upsert(
        "listing_wish_options",
        [
            {
                "id": option_id,
                "listing_id": listing_id,
                "position": 1,
                "wish_ids": [wanted_row["id"]],
                "wish_qtys": [1],
                "logic": "or",
                "min_count": 1,
                "exchange_type": "any",
                "is_cash_offer": False,
                "cash_amount": None,
            }
        ],
        on_conflict="id",
        select="id,listing_id,position,wish_ids,logic,min_count,wish_group_id,wish_goods_type_id",
    )

    return {
        "listing_id": listing_id,
        "option_id": option_id,
        "offer_ids": [row["id"] for row in offer_rows],
        "wanted_id": wanted_row["id"],
    }


def verify_seed(client: Supabase, ids: dict[str, Any]) -> dict[str, Any]:
    listing = first_row(
        client.select(
            "listings",
            select="id,user_id,have_ids,have_logic,have_min_count,status,note",
            id=f"eq.{ids['listing_id']}",
            limit="1",
        ),
        "seed listing",
    )
    option = first_row(
        client.select(
            "listing_wish_options",
            select="id,listing_id,wish_ids,logic,min_count,wish_group_id,wish_goods_type_id",
            id=f"eq.{ids['option_id']}",
            limit="1",
        ),
        "seed option",
    )
    offers = client.select(
        "goods_inventory",
        select="id,title,kind,status,market_available_qty",
        id=f"in.({','.join(ids['offer_ids'])})",
    )
    return {
        "listing": listing,
        "option": option,
        "offer_titles": [row["title"] for row in offers],
    }


def main() -> int:
    env = load_env(ENV_PATH)
    url = env.get("NEXT_PUBLIC_SUPABASE_URL") or env.get("MEGRUM_SUPABASE_URL")
    publishable_key = env.get("NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY") or env.get("MEGRUM_SUPABASE_PUBLISHABLE_KEY")
    service_key = env.get("SUPABASE_SECRET_KEY")
    if not url or not publishable_key or not service_key:
        print("Missing Supabase env in web/.env.local", file=sys.stderr)
        return 2

    client = Supabase(url, service_key, publishable_key)
    try:
        include_payment_fields = users_payment_columns_supported(client)
        include_test_account_field = users_test_account_column_supported(client)
        include_stock_fields = goods_stock_columns_supported(client)
        viewer = find_user(client, VIEWER_HANDLE)
        partner = find_user(client, PARTNER_HANDLE)
        masters = lookup_master_data(client)

        ensure_partner_visible(
            client,
            partner["id"],
            include_payment_fields=include_payment_fields,
            include_test_account_field=include_test_account_field,
        )
        viewer_offer = ensure_viewer_offer(
            client,
            viewer["id"],
            masters,
            include_stock_fields=include_stock_fields,
        )
        seeded = seed_partner_rows(
            client,
            partner["id"],
            masters,
            include_stock_fields=include_stock_fields,
        )
        verification = verify_seed(client, seeded)
    except SupabaseHTTPError as error:
        print(f"Supabase error {error.status}: {error.body}", file=sys.stderr)
        return 1

    summary = {
        "mode": "seed",
        "viewer": {"id": viewer["id"], "handle": VIEWER_HANDLE},
        "partner": {"id": partner["id"], "handle": PARTNER_HANDLE},
        "viewer_offer_used": viewer_offer,
        **seeded,
        "verification": verification,
    }
    SUMMARY_PATH.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(summary, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
