import AsyncStorage from "@react-native-async-storage/async-storage";
import {
  displayPrefectureName,
  JAPAN_PREFECTURES,
  normalizePrefectureName,
} from "../data/japanPrefectures";
import { DEFAULT_MEGURI_PROFILE } from "./meguriSettings";

const BOARD_PREFECTURE_KEY = "meguri.board.prefecture.v1";

export const MEGURI_BOARD_PREFECTURE_OPTIONS = JAPAN_PREFECTURES.map((prefecture) =>
  normalizePrefectureName(prefecture.name),
);

export function normalizeMeguriBoardPrefecture(value?: string | null) {
  if (!value) return null;
  const normalized = normalizePrefectureName(value);
  return normalized ? normalized : null;
}

export function displayMeguriBoardPrefecture(value?: string | null) {
  const normalized = normalizeMeguriBoardPrefecture(value);
  return normalized ? displayPrefectureName(normalized) : "未設定";
}

export async function loadMeguriBoardDefaultPrefecture(fallback?: string | null) {
  const stored = normalizeMeguriBoardPrefecture(await AsyncStorage.getItem(BOARD_PREFECTURE_KEY));
  if (stored) return stored;
  return (
    normalizeMeguriBoardPrefecture(fallback) ??
    normalizeMeguriBoardPrefecture(DEFAULT_MEGURI_PROFILE.baseArea) ??
    "東京"
  );
}

export async function saveMeguriBoardDefaultPrefecture(value: string) {
  const normalized = normalizeMeguriBoardPrefecture(value);
  if (!normalized) return null;
  await AsyncStorage.setItem(BOARD_PREFECTURE_KEY, normalized);
  return normalized;
}
