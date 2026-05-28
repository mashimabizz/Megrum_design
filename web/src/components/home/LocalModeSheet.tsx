"use client";

import { useEffect, useMemo, useRef, useState, useTransition } from "react";
import dynamic from "next/dynamic";
import { useRouter } from "next/navigation";
import {
  applyLocalModeAW,
  resetLocalModeSelections,
  type LocalModeSettings,
} from "./actions";

const MapPicker = dynamic(() => import("@/components/map/MapPicker"), {
  ssr: false,
  loading: () => (
    <div className="flex h-full w-full items-center justify-center bg-[#a8d4e61a] text-[10px] text-[#3a324a8c]">
      地図を読み込み中…
    </div>
  ),
});

export type SimpleAW = {
  id: string;
  venue: string;
  eventName: string | null;
  eventless: boolean;
  startAt: string;
  endAt: string;
  radiusM: number;
  centerLat?: number | null;
  centerLng?: number | null;
};

export type SimpleItem = {
  id: string;
  title: string;
  groupName: string | null;
  characterName: string | null;
  goodsTypeName: string | null;
  photoUrl: string | null;
};

// Nominatim 検索結果
type Place = {
  display_name: string;
  lat: string;
  lon: string;
  address?: {
    leisure?: string;
    amenity?: string;
    building?: string;
    shop?: string;
    tourism?: string;
    road?: string;
    suburb?: string;
    neighbourhood?: string;
    city?: string;
    town?: string;
  };
};

function labelFromAddress(p: Place): string {
  const a = p.address ?? {};
  return (
    a.leisure ||
    a.amenity ||
    a.tourism ||
    a.building ||
    a.shop ||
    a.road ||
    a.neighbourhood ||
    a.suburb ||
    a.city ||
    a.town ||
    p.display_name.split(",")[0] ||
    "場所"
  );
}

const DURATION_OPTIONS = [
  { value: 60, label: "1 時間" },
  { value: 120, label: "2 時間" },
  { value: 180, label: "3 時間" },
  { value: 360, label: "6 時間" },
  { value: 720, label: "終日" },
];

function nowPlusMinutesISO(min: number): string {
  return new Date(Date.now() + min * 60_000).toISOString();
}

function isoToDatetimeLocal(iso: string): string {
  const d = new Date(iso);
  d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
  return d.toISOString().slice(0, 16);
}

const FALLBACK_CENTER: [number, number] = [35.6595, 139.7005];

/* iter132: シート内 draft（localStorage 保存）─ グッズ選択画面など別画面に
   行って戻ってくる時のフォーム途中状態を引き継ぐため */
const DRAFT_KEY = "megrum:localModeSheet:draft";
const DRAFT_TTL_MS = 30 * 60 * 1000; // 30 分

type SheetDraft = {
  venue: string;
  centerLat: number;
  centerLng: number;
  radiusM: number;
  startAt: string;
  endAt: string;
  savedAt: number;
};

function saveDraft(draft: Omit<SheetDraft, "savedAt">) {
  if (typeof window === "undefined") return;
  try {
    const full: SheetDraft = { ...draft, savedAt: Date.now() };
    localStorage.setItem(DRAFT_KEY, JSON.stringify(full));
  } catch {
    // localStorage が使えない場合は黙って無視
  }
}

function loadDraft(): SheetDraft | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = localStorage.getItem(DRAFT_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as SheetDraft;
    if (typeof parsed.savedAt !== "number") return null;
    if (Date.now() - parsed.savedAt > DRAFT_TTL_MS) {
      localStorage.removeItem(DRAFT_KEY);
      return null;
    }
    return parsed;
  } catch {
    return null;
  }
}

function clearDraft() {
  if (typeof window === "undefined") return;
  try {
    localStorage.removeItem(DRAFT_KEY);
  } catch {
    // ignore
  }
}

/**
 * 現地交換モード設定シート — iter65.8 でリッチ化。
 *
 * 1 シート内で AW（場所・時間・半径）を作成 or 更新し、持参グッズも選ぶ。
 * 別画面に飛ばずに完結する。
 */
export function LocalModeSheet({
  open,
  onClose,
  onApplied,
  initial,
  currentAW,
  carryingItems,
}: {
  open: boolean;
  onClose: () => void;
  /** iter129: AW 適用成功時に呼ばれる（cancel でキャンセル時には呼ばれない） */
  onApplied?: () => void;
  initial: LocalModeSettings;
  currentAW: SimpleAW | null;
  carryingItems: SimpleItem[];
}) {
  // ─── 状態 ────────────────────────────────────────────────
  const [venue, setVenue] = useState(currentAW?.venue ?? "");
  const [center, setCenter] = useState<[number, number]>(() => {
    if (currentAW?.centerLat && currentAW?.centerLng) {
      return [currentAW.centerLat, currentAW.centerLng];
    }
    if (initial.lastLat && initial.lastLng) {
      return [initial.lastLat, initial.lastLng];
    }
    return FALLBACK_CENTER;
  });
  const [radiusM, setRadiusM] = useState(currentAW?.radiusM ?? initial.radiusM);
  const [startAt, setStartAt] = useState<string>(
    currentAW?.startAt ?? new Date().toISOString(),
  );
  const [endAt, setEndAt] = useState<string>(
    currentAW?.endAt ?? nowPlusMinutesISO(120),
  );
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [searchQ, setSearchQ] = useState("");
  const [searchResults, setSearchResults] = useState<Place[]>([]);
  const [searching, setSearching] = useState(false);
  const [showResults, setShowResults] = useState(false);
  const [geolocating, setGeolocating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();
  // iter132: グッズ選択画面への navigation 用
  const router = useRouter();
  const [resetting, startReset] = useTransition();

  // iter132: ユーザーが venue を手入力中なら center 変化で上書きしない
  const venueManuallyEditedRef = useRef(false);

  // iter132: open のたびに draft → DB 値の順で再初期化
  //   draft（localStorage）：グッズ選択画面など別画面に行って戻ってきた時の途中状態
  //   draft が無ければ DB 値（currentAW）を使う
  /* eslint-disable react-hooks/set-state-in-effect -- シートを開く瞬間に localStorage / DB 値からフォーム draft を復元する */
  useEffect(() => {
    if (open) {
      const draft = loadDraft();
      if (draft) {
        setVenue(draft.venue);
        setCenter([draft.centerLat, draft.centerLng]);
        setRadiusM(draft.radiusM);
        setStartAt(draft.startAt);
        setEndAt(draft.endAt);
        venueManuallyEditedRef.current = !!draft.venue;
      } else {
        setVenue(currentAW?.venue ?? "");
        if (currentAW?.centerLat && currentAW?.centerLng) {
          setCenter([currentAW.centerLat, currentAW.centerLng]);
        }
        setRadiusM(currentAW?.radiusM ?? initial.radiusM);
        setStartAt(currentAW?.startAt ?? new Date().toISOString());
        setEndAt(currentAW?.endAt ?? nowPlusMinutesISO(120));
        venueManuallyEditedRef.current = !!currentAW?.venue;
      }
      setError(null);
    }
  }, [open, initial, currentAW]);
  /* eslint-enable react-hooks/set-state-in-effect */

  // iter132: center 変化で reverse geocode → 自動で venue を埋める
  //   ただし「ユーザーが venue を手入力済」の場合は上書きしない
  useEffect(() => {
    if (!open) return;
    if (venueManuallyEditedRef.current) return;
    const lat = center[0];
    const lng = center[1];
    if (!isFinite(lat) || !isFinite(lng)) return;
    const t = setTimeout(async () => {
      try {
        const res = await fetch(
          `/api/geocode?lat=${encodeURIComponent(String(lat))}&lon=${encodeURIComponent(String(lng))}`,
        );
        if (!res.ok) return;
        const data = (await res.json()) as
          | { display_name?: string; address?: Record<string, string> }
          | { error: string };
        if ("error" in data) return;
        const addr = data.address ?? {};
        // address parts から場所名候補を組み立て
        const candidate =
          addr.attraction ||
          addr.tourism ||
          addr.amenity ||
          addr.building ||
          addr.shop ||
          addr.station ||
          [addr.city, addr.suburb, addr.neighbourhood]
            .filter(Boolean)
            .join(" ") ||
          data.display_name?.split(",").slice(0, 2).join("、") ||
          "";
        if (candidate && !venueManuallyEditedRef.current) {
          setVenue(candidate);
        }
      } catch {
        // ignore
      }
    }, 600); // debounce
    return () => clearTimeout(t);
  }, [center, open]);

  // body scroll lock
  useEffect(() => {
    if (open) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [open]);

  // 検索（debounce）
  /* eslint-disable react-hooks/set-state-in-effect -- 検索文字数が足りない時に候補表示を即時クリアする */
  useEffect(() => {
    const q = searchQ.trim();
    if (q.length < 2) {
      setSearchResults([]);
      setShowResults(false);
      return;
    }
    const t = setTimeout(async () => {
      setSearching(true);
      try {
        const res = await fetch(`/api/geocode?q=${encodeURIComponent(q)}`);
        const data = (await res.json()) as Place[] | { error: string };
        if (Array.isArray(data)) {
          setSearchResults(data);
          setShowResults(true);
        }
      } catch {
        // ignore
      } finally {
        setSearching(false);
      }
    }, 350);
    return () => clearTimeout(t);
  }, [searchQ]);
  /* eslint-enable react-hooks/set-state-in-effect */

  function pickSearchResult(p: Place) {
    const lat = parseFloat(p.lat);
    const lon = parseFloat(p.lon);
    if (isFinite(lat) && isFinite(lon)) {
      setCenter([lat, lon]);
      setVenue(labelFromAddress(p));
      setShowResults(false);
      setSearchQ("");
    }
  }

  function useCurrentLocation() {
    if (typeof window === "undefined" || !navigator.geolocation) return;
    setGeolocating(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setCenter([pos.coords.latitude, pos.coords.longitude]);
        setGeolocating(false);
      },
      () => setGeolocating(false),
      { enableHighAccuracy: true, timeout: 10000 },
    );
  }

  // iter139: duration は「現在時刻 + 分数」で end を再計算
  //   開始時刻は最終的に handleApply で now に上書きされる前提
  //   詳細パネルで開始時刻を変更している場合は、その開始時刻 + 分数
  function applyDuration(minutes: number) {
    const baseStartMs = showAdvanced
      ? new Date(startAt).getTime()
      : new Date().getTime();
    const newEnd = new Date(baseStartMs + minutes * 60_000);
    setEndAt(newEnd.toISOString());
    // 詳細パネルが閉じている時は startAt も now に揃える（表示の整合性）
    if (!showAdvanced) {
      setStartAt(new Date(baseStartMs).toISOString());
    }
  }

  function handleApply() {
    setError(null);
    if (!venue.trim()) {
      setError("場所を入力してください");
      return;
    }
    // iter135 + iter139: 詳細パネルを開いていれば自由な開始時刻、閉じていれば
    //   「適用した瞬間」を開始にする（duration はそのまま生かす）
    const minDurMs = 30 * 60_000;
    let finalStartIso: string;
    let finalEndIso: string;
    if (showAdvanced) {
      // 詳細パネル：ユーザーが選んだ start/end をそのまま尊重
      const dur = new Date(endAt).getTime() - new Date(startAt).getTime();
      const safeDur = Math.max(minDurMs, dur);
      finalStartIso = startAt;
      finalEndIso = new Date(
        new Date(startAt).getTime() + safeDur,
      ).toISOString();
    } else {
      // 通常：開始 = now、終了 = now + duration（既存）
      const existingDurMs =
        new Date(endAt).getTime() - new Date(startAt).getTime();
      const durMs = Math.max(minDurMs, existingDurMs);
      finalStartIso = new Date().toISOString();
      finalEndIso = new Date(Date.now() + durMs).toISOString();
    }
    startTransition(async () => {
      const r = await applyLocalModeAW({
        venue,
        centerLat: center[0],
        centerLng: center[1],
        radiusM,
        startAt: finalStartIso,
        endAt: finalEndIso,
      });
      if (r?.error) {
        setError(r.error);
        return;
      }
      // iter129: 適用成功を親に通知してから閉じる
      // iter132: 適用成功なら draft を消す
      clearDraft();
      onApplied?.();
      onClose();
    });
  }

  function handleReset() {
    if (!confirm("持参グッズの選択をすべて解除しますか？")) return;
    startReset(async () => {
      const r = await resetLocalModeSelections();
      if (r?.error) {
        alert(r.error);
        return;
      }
    });
  }

  const radiusLabel = useMemo(
    () =>
      radiusM >= 1000 ? `${(radiusM / 1000).toFixed(1)}km` : `${radiusM}m`,
    [radiusM],
  );

  const fmtTime = (iso: string) => {
    const d = new Date(iso);
    return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
  };
  const durationMin = Math.round(
    (new Date(endAt).getTime() - new Date(startAt).getTime()) / 60_000,
  );

  // 選択中の持参グッズ件数
  const selectedCarryingCount = initial.selectedCarryingIds.length;

  return (
    <div
      className={`fixed inset-0 z-[60] flex flex-col ${
        open ? "pointer-events-auto" : "pointer-events-none"
      }`}
      role="dialog"
      aria-modal="true"
    >
      {/* backdrop */}
      <button
        type="button"
        onClick={onClose}
        aria-label="閉じる"
        className={`absolute inset-0 bg-[linear-gradient(180deg,rgba(58,50,74,0.18),rgba(58,50,74,0.32))] transition-opacity duration-200 ${
          open ? "opacity-100" : "opacity-0"
        }`}
      />

      <div className="flex-1" />

      <div
        className={`relative mx-auto flex w-full max-w-md flex-col rounded-t-[22px] bg-white shadow-[0_-10px_40px_rgba(58,50,74,0.18)] transition-transform duration-300 ${
          open ? "translate-y-0" : "translate-y-full"
        }`}
        style={{
          maxHeight: "78vh",
          paddingBottom: "env(safe-area-inset-bottom)",
        }}
      >
        {/* drag handle */}
        <div className="mx-auto mt-2.5 mb-2 h-1 w-9 flex-shrink-0 rounded-sm bg-[#3a324a4d]" />

        {/* Header */}
        <div className="flex flex-shrink-0 items-baseline justify-between px-5 pb-2">
          <div>
            <h2 className="text-[17px] font-extrabold tracking-[0.3px] text-gray-900">
              現地交換モード
            </h2>
            <p className="mt-0.5 text-[11px] text-[#3a324a8c]">
              場所・時間・半径と持参グッズで時空マッチを絞ります
            </p>
          </div>
        </div>

        <div className="flex-1 space-y-4 overflow-y-auto px-5 py-2">
          {/* 場所 */}
          <Section title="場所">
            {/* 検索バー + 現在地 */}
            <div className="flex gap-1.5">
              <div className="relative flex-1">
                <input
                  type="text"
                  value={searchQ}
                  onChange={(e) => setSearchQ(e.target.value)}
                  placeholder="場所を検索（駅名・施設名）"
                  className="block w-full rounded-xl border border-[#3a324a14] bg-white px-3 py-2.5 text-[12px] text-gray-900 placeholder:text-gray-400 focus:border-[#a695d8] focus:outline-none"
                />
                {searching && (
                  <span className="absolute right-3 top-3 text-[10px] text-[#3a324a8c]">
                    ...
                  </span>
                )}
                {showResults && searchResults.length > 0 && (
                  <div className="absolute inset-x-0 top-full z-[1100] mt-1 max-h-[200px] overflow-y-auto rounded-xl border-[0.5px] border-[#3a324a14] bg-white shadow-[0_8px_20px_rgba(58,50,74,0.18)]">
                    {searchResults.map((p, i) => {
                      const label = labelFromAddress(p);
                      return (
                        <button
                          key={`${p.lat},${p.lon}-${i}`}
                          type="button"
                          onClick={() => pickSearchResult(p)}
                          className="flex w-full items-start gap-2 border-b-[0.5px] border-[#3a324a08] px-3 py-2 text-left last:border-0 hover:bg-[#a695d80f]"
                        >
                          <div className="min-w-0 flex-1">
                            <div className="truncate text-[11.5px] font-bold text-[#3a324a]">
                              {label}
                            </div>
                            <div className="mt-0.5 truncate text-[9.5px] text-[#3a324a8c]">
                              {p.display_name}
                            </div>
                          </div>
                        </button>
                      );
                    })}
                  </div>
                )}
              </div>
              <button
                type="button"
                onClick={useCurrentLocation}
                disabled={geolocating}
                className="flex h-[42px] flex-shrink-0 items-center gap-1 rounded-xl border border-[#3a324a14] bg-white px-3 text-[11px] font-bold text-[#a695d8] disabled:opacity-50"
              >
                {geolocating ? (
                  <span className="block h-3 w-3 animate-spin rounded-full border-2 border-[#a695d8] border-t-transparent" />
                ) : (
                  <svg width="13" height="13" viewBox="0 0 13 13">
                    <circle cx="6.5" cy="6.5" r="2" fill="#a695d8" />
                    <circle
                      cx="6.5"
                      cy="6.5"
                      r="5.5"
                      stroke="#a695d8"
                      strokeWidth="1"
                      fill="none"
                    />
                  </svg>
                )}
                現在地
              </button>
            </div>

            {/* 地図 */}
            <div className="relative mt-2 h-[180px] overflow-hidden rounded-xl border border-[#3a324a14]">
              <MapPicker
                center={center}
                radiusM={radiusM}
                onCenterChange={(lat, lng) => setCenter([lat, lng])}
                className="absolute inset-0"
              />
              <div className="pointer-events-none absolute right-2.5 top-2.5 z-[900] rounded-full bg-[#a695d8] px-2 py-[3px] text-[10px] font-extrabold tabular-nums text-white shadow-[0_4px_10px_#a695d855]">
                {radiusLabel}
              </div>
            </div>

            {/* 場所名（iter132: 手入力中は center 変化での自動上書きを止める） */}
            <input
              type="text"
              value={venue}
              onChange={(e) => {
                setVenue(e.target.value);
                venueManuallyEditedRef.current = true;
              }}
              placeholder="場所を選ぶと自動で入ります（手入力も可）"
              maxLength={100}
              className="mt-2 block w-full rounded-xl border border-[#3a324a14] bg-white px-3 py-2.5 text-[13px] font-semibold text-gray-900 placeholder:font-medium placeholder:text-gray-400 focus:border-[#a695d8] focus:outline-none"
            />
          </Section>

          {/* 半径 */}
          <Section title={`マッチ範囲 / ${radiusLabel}`}>
            <input
              type="range"
              min={200}
              max={2000}
              step={100}
              value={radiusM}
              onChange={(e) => setRadiusM(Number(e.target.value))}
              className="block w-full"
              style={{ accentColor: "#a695d8" }}
            />
            <div className="mt-0.5 flex justify-between text-[9.5px] tabular-nums text-[#3a324a8c]">
              <span>200m</span>
              <span>2km</span>
            </div>
          </Section>

          {/* 時間（iter135 + iter139: 通常は「今すぐ開始」、詳細を開けば自由指定） */}
          <Section
            title={
              showAdvanced
                ? `有効時間 / ${fmtTime(startAt)} 〜 ${fmtTime(endAt)} (${durationMin}分)`
                : `有効時間 / 今すぐ開始 (${durationMin} 分)`
            }
          >
            <div className="mb-2 flex flex-wrap gap-1.5">
              {DURATION_OPTIONS.map((d) => {
                const active = durationMin === d.value;
                return (
                  <button
                    key={d.value}
                    type="button"
                    onClick={() => applyDuration(d.value)}
                    className={`rounded-full px-3 py-1.5 text-[11px] font-bold transition-all ${
                      active
                        ? "bg-[#a695d8] text-white"
                        : "border border-[#3a324a14] bg-white text-gray-700"
                    }`}
                  >
                    {d.label}
                  </button>
                );
              })}
            </div>
            <button
              type="button"
              onClick={() => setShowAdvanced((v) => !v)}
              className="text-[10.5px] font-bold text-[#a695d8]"
            >
              {showAdvanced ? "詳細を閉じる" : "開始・終了を細かく指定"}
            </button>
            {showAdvanced && (
              <div className="mt-2 space-y-2">
                <div>
                  <div className="mb-0.5 text-[10px] font-bold text-[#3a324a8c]">
                    開始
                  </div>
                  <input
                    type="datetime-local"
                    value={isoToDatetimeLocal(startAt)}
                    onChange={(e) =>
                      setStartAt(new Date(e.target.value).toISOString())
                    }
                    className="block w-full rounded-lg border border-[#3a324a14] bg-white px-2.5 py-1.5 text-[12px] text-gray-900 focus:border-[#a695d8] focus:outline-none"
                  />
                  <div className="mt-0.5 text-[9.5px] text-[#3a324a8c]">
                    詳細を閉じれば「適用した瞬間」になります
                  </div>
                </div>
                <div>
                  <div className="mb-0.5 text-[10px] font-bold text-[#3a324a8c]">
                    終了
                  </div>
                  <input
                    type="datetime-local"
                    value={isoToDatetimeLocal(endAt)}
                    onChange={(e) =>
                      setEndAt(new Date(e.target.value).toISOString())
                    }
                    className="block w-full rounded-lg border border-[#3a324a14] bg-white px-2.5 py-1.5 text-[12px] text-gray-900 focus:border-[#a695d8] focus:outline-none"
                  />
                </div>
              </div>
            )}
          </Section>

          {/* 持参グッズ — 別画面リンク（iter132: 遷移前に draft を保存） */}
          <Section title="持参するグッズ">
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => {
                  saveDraft({
                    venue,
                    centerLat: center[0],
                    centerLng: center[1],
                    radiusM,
                    startAt,
                    endAt,
                  });
                  router.push("/inventory/select-carrying?return=local-mode");
                }}
                className="flex flex-1 items-center gap-3 rounded-xl border border-[#3a324a14] bg-white p-3 text-left transition-all active:scale-[0.99]"
              >
                <div className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-xl bg-[#a695d80a]">
                  <svg
                    width="18"
                    height="18"
                    viewBox="0 0 22 22"
                    fill="none"
                    stroke="#a695d8"
                    strokeWidth="1.5"
                  >
                    <rect x="3" y="5" width="16" height="13" rx="2" />
                    <circle cx="11" cy="11.5" r="3" />
                    <path d="M7 5l1.5-2h5L15 5" />
                  </svg>
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-[12.5px] font-bold text-gray-900">
                    グッズを選ぶ
                  </div>
                  <div className="mt-0.5 text-[10.5px] text-[#3a324a8c]">
                    {carryingItems.length === 0
                      ? "在庫がありません · 先に登録 →"
                      : `${selectedCarryingCount} 件選択中 / 全${carryingItems.length}件`}
                  </div>
                </div>
                <svg
                  width="14"
                  height="14"
                  viewBox="0 0 14 14"
                  fill="none"
                  stroke="#3a324a8c"
                  strokeWidth="1.6"
                  strokeLinecap="round"
                >
                  <path d="M5 2l5 5-5 5" />
                </svg>
              </button>
              {selectedCarryingCount > 0 && (
                <button
                  type="button"
                  onClick={handleReset}
                  disabled={resetting}
                  className="rounded-xl border border-[#3a324a14] bg-white px-2.5 py-2 text-[10.5px] font-bold text-[#3a324a8c] disabled:opacity-50"
                >
                  解除
                </button>
              )}
            </div>
          </Section>

          {error && (
            <div className="rounded-xl border border-red-200 bg-red-50 p-3 text-[12px] text-red-700">
              {error}
            </div>
          )}
        </div>

        {/* CTA */}
        <div className="flex flex-shrink-0 items-center gap-2 border-t border-[#3a324a08] px-5 py-3">
          <button
            type="button"
            onClick={onClose}
            disabled={pending}
            className="h-11 rounded-xl border border-[#3a324a14] bg-white px-4 text-[12.5px] font-bold text-gray-700 disabled:opacity-50"
          >
            キャンセル
          </button>
          <button
            type="button"
            onClick={handleApply}
            disabled={pending || !venue.trim()}
            className="h-11 flex-1 rounded-xl bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] text-[13.5px] font-bold tracking-[0.3px] text-white shadow-[0_4px_14px_rgba(166,149,216,0.33)] disabled:opacity-60"
          >
            {pending ? "適用中…" : "この設定で表示"}
          </button>
        </div>
      </div>
    </div>
  );
}

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <div className="mb-1.5 text-[11px] font-bold uppercase tracking-wider text-[#a695d8]">
        {title}
      </div>
      {children}
    </div>
  );
}
