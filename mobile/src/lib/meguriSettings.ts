import AsyncStorage from "@react-native-async-storage/async-storage";

export type MeguriAvatarSettings = {
  animalType: "cat" | "fox" | "rabbit";
  furColor: "lavender" | "sky" | "pink" | "cream" | "mint" | "cocoa" | "gray";
  hue: "lav" | "sky" | "pink" | "mint" | "butter";
};

export type MeguriProfileSettings = {
  baseArea: string;
  displayName: string;
  farewellMessage: string;
  hitokoto: string;
  publicMemo: string;
};

export type MeguriPlusSettings = {
  active: boolean;
  freeSendLimit: number;
  monthlySendLimit: number;
};

const AVATAR_KEY = "meguri.avatar.v1";
const PROFILE_KEY = "meguri.profile.v1";
const PLUS_KEY = "meguri.plus.v1";

export const DEFAULT_MEGURI_AVATAR: MeguriAvatarSettings = {
  animalType: "rabbit",
  furColor: "lavender",
  hue: "lav",
};

export const DEFAULT_MEGURI_PROFILE: MeguriProfileSettings = {
  baseArea: "東京",
  displayName: "あなた",
  farewellMessage: "またお会いしましょう！",
  hitokoto: "今日は推し色の小物を持って出かけました",
  publicMemo: "推し活の余韻をゆっくり味わっています",
};

export const DEFAULT_MEGURI_PLUS: MeguriPlusSettings = {
  active: false,
  freeSendLimit: 2,
  monthlySendLimit: 20,
};

export async function loadMeguriAvatarSettings() {
  const settings = await loadSetting(AVATAR_KEY, DEFAULT_MEGURI_AVATAR);
  return {
    ...settings,
    animalType: normalizeMeguriAnimalType(settings.animalType),
  };
}

export async function saveMeguriAvatarSettings(settings: MeguriAvatarSettings) {
  await AsyncStorage.setItem(AVATAR_KEY, JSON.stringify(settings));
}

export async function loadMeguriProfileSettings() {
  return loadSetting(PROFILE_KEY, DEFAULT_MEGURI_PROFILE);
}

export async function saveMeguriProfileSettings(settings: MeguriProfileSettings) {
  await AsyncStorage.setItem(PROFILE_KEY, JSON.stringify(settings));
}

export async function loadMeguriPlusSettings() {
  return loadSetting(PLUS_KEY, DEFAULT_MEGURI_PLUS);
}

export async function saveMeguriPlusSettings(settings: MeguriPlusSettings) {
  await AsyncStorage.setItem(PLUS_KEY, JSON.stringify(settings));
}

async function loadSetting<T extends object>(key: string, fallback: T): Promise<T> {
  const raw = await AsyncStorage.getItem(key);
  if (!raw) return fallback;
  try {
    return { ...fallback, ...JSON.parse(raw) } as T;
  } catch {
    return fallback;
  }
}

function normalizeMeguriAnimalType(
  animalType: unknown,
): MeguriAvatarSettings["animalType"] {
  if (animalType === "cat" || animalType === "fox" || animalType === "rabbit") {
    return animalType;
  }
  return "fox";
}
