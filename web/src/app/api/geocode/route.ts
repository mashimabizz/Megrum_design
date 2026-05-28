/**
 * Geocode proxy — Nominatim (OpenStreetMap) を経由したジオコーディング API。
 *
 * ブラウザから直接 Nominatim を叩くと CORS / User-Agent 制約に引っかかるため、
 * サーバー側で proxy して User-Agent を付与する。
 *
 * Nominatim 利用ポリシー:
 *   - 1 req/sec 上限
 *   - User-Agent 必須（識別可能な値）
 *   - 重い用途は別ホストの利用が望ましい
 *   - 詳細: https://operations.osmfoundation.org/policies/nominatim/
 */

import { NextRequest } from "next/server";

const NOMINATIM_BASE = "https://nominatim.openstreetmap.org";
const USER_AGENT = "Megrum/0.1 (https://megrum.jp; support@megrum.jp)";

/**
 * GET /api/geocode?q=横浜アリーナ          — forward geocoding
 * GET /api/geocode?lat=35.5&lon=139.7      — reverse geocoding
 */
export async function GET(req: NextRequest) {
  const { searchParams } = req.nextUrl;
  const q = searchParams.get("q");
  const lat = searchParams.get("lat");
  const lon = searchParams.get("lon");

  let url: string;
  if (q) {
    // forward
    url = `${NOMINATIM_BASE}/search?format=json&q=${encodeURIComponent(
      q,
    )}&limit=8&accept-language=ja&countrycodes=jp&addressdetails=1`;
  } else if (lat && lon) {
    // reverse
    url = `${NOMINATIM_BASE}/reverse?format=json&lat=${encodeURIComponent(
      lat,
    )}&lon=${encodeURIComponent(lon)}&accept-language=ja&zoom=18&addressdetails=1`;
  } else {
    return Response.json(
      { error: "missing q or (lat, lon)" },
      { status: 400 },
    );
  }

  try {
    const upstream = await fetch(url, {
      headers: { "User-Agent": USER_AGENT, Referer: "https://megrum.jp" },
      // 1 時間キャッシュ（同じクエリの繰り返しを軽減）
      next: { revalidate: 3600 },
    });
    if (!upstream.ok) {
      return Response.json(
        { error: `nominatim ${upstream.status}` },
        { status: 502 },
      );
    }
    const data = await upstream.json();
    return Response.json(data, {
      headers: { "Cache-Control": "public, s-maxage=3600" },
    });
  } catch (e) {
    return Response.json(
      { error: String(e instanceof Error ? e.message : e) },
      { status: 500 },
    );
  }
}
