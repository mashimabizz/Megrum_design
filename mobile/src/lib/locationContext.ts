export type MegrumCoordinate = {
  accuracy: number | null;
  latitude: number;
  longitude: number;
};

export type MegrumLocationContext = {
  city: string | null;
  coordinate: MegrumCoordinate | null;
  denied: boolean;
  label: string | null;
  prefecture: string | null;
};

export async function getCurrentLocationContext(): Promise<MegrumLocationContext> {
  const Location = await import("expo-location");
  const permission = await Location.requestForegroundPermissionsAsync();
  if (!permission.granted) {
    return emptyLocationContext(true);
  }

  const lastKnown = await Location.getLastKnownPositionAsync().catch(() => null);
  const position =
    lastKnown ??
    (await Location.getCurrentPositionAsync({
      accuracy: Location.Accuracy.Balanced,
    }).catch(() => null));

  if (!position) {
    return emptyLocationContext(false);
  }

  const coordinate: MegrumCoordinate = {
    accuracy: typeof position.coords.accuracy === "number" ? position.coords.accuracy : null,
    latitude: position.coords.latitude,
    longitude: position.coords.longitude,
  };
  const addresses = await Location.reverseGeocodeAsync({
    latitude: coordinate.latitude,
    longitude: coordinate.longitude,
  }).catch(() => []);
  const first = addresses[0] ?? null;
  const prefecture = normalizePrefectureName(first?.region ?? null);
  const city = normalizeAreaPart(first?.city ?? first?.subregion ?? null);
  return {
    city,
    coordinate,
    denied: false,
    label: [prefecture, city].filter(Boolean).join(" ") || prefecture || city || null,
    prefecture,
  };
}

export function normalizePrefectureName(value: string | null | undefined) {
  const normalized = normalizeAreaPart(value);
  if (!normalized) return null;
  if (normalized === "Tokyo") return "東京都";
  if (normalized === "Osaka") return "大阪府";
  if (normalized === "Kyoto") return "京都府";
  if (normalized === "Hokkaido") return "北海道";
  return normalized;
}

export function coordinateFromParams(input: {
  latitude?: string | string[] | null;
  longitude?: string | string[] | null;
}): MegrumCoordinate | null {
  const latitude = numberParam(input.latitude);
  const longitude = numberParam(input.longitude);
  if (latitude === null || longitude === null) return null;
  return { accuracy: null, latitude, longitude };
}

export function numberParam(value: string | string[] | null | undefined) {
  const raw = Array.isArray(value) ? value[0] : value;
  if (!raw) return null;
  const parsed = Number(raw);
  return Number.isFinite(parsed) ? parsed : null;
}

function emptyLocationContext(denied: boolean): MegrumLocationContext {
  return {
    city: null,
    coordinate: null,
    denied,
    label: null,
    prefecture: null,
  };
}

function normalizeAreaPart(value: string | null | undefined) {
  if (!value) return null;
  const trimmed = value.replace(/\s+/g, " ").trim();
  return trimmed.length > 0 ? trimmed : null;
}
