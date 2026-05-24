export type PrefectureHue = "lav" | "sky" | "pink" | "mint" | "butter";

export type JapanPrefecture = {
  abbr: string;
  col: number;
  hue: PrefectureHue;
  name: string;
  region: string;
  row: number;
};

export type MeguriMapRegion =
  | "chubu"
  | "chugoku"
  | "hokkaido"
  | "kansai"
  | "kanto"
  | "kyushu"
  | "shikoku"
  | "tohoku";

export type MeguriMapTile = {
  h?: number;
  name: string;
  region: MeguriMapRegion;
  w?: number;
  x: number;
  y: number;
};

export const JAPAN_PREFECTURE_GRID = {
  height: 378,
  stepX: 26,
  stepY: 23,
  tile: 24,
  width: 322,
} as const;

export const MEGURI_MAP_WIDTH = 340;
export const MEGURI_MAP_HEIGHT = 550;
export const MEGURI_MAP_TILE_W = 31;
export const MEGURI_MAP_TILE_H = 30;

export const MEGURI_MAP_REGION_COLORS: Record<MeguriMapRegion, string> = {
  chubu: "#38ccd0",
  chugoku: "#efc436",
  hokkaido: "#6377de",
  kansai: "#d6dc1f",
  kanto: "#31cd82",
  kyushu: "#fb7188",
  shikoku: "#ff944f",
  tohoku: "#3da9dc",
};

export const MEGURI_MAP_TILES: MeguriMapTile[] = [
  { name: "沖縄", region: "kyushu", x: 0, y: 178 },
  { name: "佐賀", region: "kyushu", x: 0, y: 346 },
  { name: "福岡", region: "kyushu", x: 34, y: 346 },
  { name: "長崎", region: "kyushu", x: 0, y: 380 },
  { name: "大分", region: "kyushu", x: 34, y: 380 },
  { name: "熊本", region: "kyushu", x: 0, y: 414 },
  { name: "宮崎", region: "kyushu", x: 34, y: 414 },
  { name: "鹿児島", region: "kyushu", x: 0, y: 448, w: 65 },

  { name: "山口", region: "chugoku", x: 68, y: 346, h: 64 },
  { name: "島根", region: "chugoku", x: 102, y: 346 },
  { name: "鳥取", region: "chugoku", x: 136, y: 346 },
  { name: "広島", region: "chugoku", x: 102, y: 380 },
  { name: "岡山", region: "chugoku", x: 136, y: 380 },

  { name: "愛媛", region: "shikoku", x: 102, y: 448 },
  { name: "香川", region: "shikoku", x: 136, y: 448 },
  { name: "高知", region: "shikoku", x: 102, y: 482 },
  { name: "徳島", region: "shikoku", x: 136, y: 482 },

  { name: "兵庫", region: "kansai", x: 170, y: 380, h: 64 },
  { name: "京都", region: "kansai", x: 204, y: 380 },
  { name: "大阪", region: "kansai", x: 204, y: 414 },
  { name: "滋賀", region: "kansai", x: 238, y: 414 },
  { name: "奈良", region: "kansai", x: 204, y: 448 },
  { name: "和歌山", region: "kansai", x: 238, y: 448 },

  { name: "石川", region: "chubu", x: 170, y: 312 },
  { name: "富山", region: "chubu", x: 204, y: 244 },
  { name: "福井", region: "chubu", x: 170, y: 346 },
  { name: "岐阜", region: "chubu", x: 204, y: 278 },
  { name: "愛知", region: "chubu", x: 204, y: 346 },
  { name: "三重", region: "chubu", x: 238, y: 380 },
  { name: "新潟", region: "chubu", x: 238, y: 210 },
  { name: "長野", region: "chubu", x: 238, y: 244, h: 64 },
  { name: "山梨", region: "chubu", x: 238, y: 312 },
  { name: "静岡", region: "chubu", x: 238, y: 346 },

  { name: "北海道", region: "hokkaido", x: 272, y: 34, w: 65, h: 66 },
  { name: "青森", region: "tohoku", x: 272, y: 110, w: 65 },
  { name: "秋田", region: "tohoku", x: 272, y: 146 },
  { name: "岩手", region: "tohoku", x: 306, y: 146 },
  { name: "山形", region: "tohoku", x: 272, y: 180 },
  { name: "宮城", region: "tohoku", x: 306, y: 180 },
  { name: "福島", region: "tohoku", x: 272, y: 214, w: 65 },

  { name: "群馬", region: "kanto", x: 272, y: 244 },
  { name: "栃木", region: "kanto", x: 306, y: 244 },
  { name: "埼玉", region: "kanto", x: 272, y: 278 },
  { name: "茨城", region: "kanto", x: 306, y: 278, h: 64 },
  { name: "東京", region: "kanto", x: 272, y: 312 },
  { name: "神奈川", region: "kanto", x: 272, y: 346 },
  { name: "千葉", region: "kanto", x: 306, y: 346, h: 64 },
];

export const JAPAN_PREFECTURES: JapanPrefecture[] = [
  { name: "北海道", abbr: "北", region: "北海道・東北", col: 10, row: 0, hue: "sky" },
  { name: "青森", abbr: "青", region: "北海道・東北", col: 10, row: 3, hue: "sky" },
  { name: "岩手", abbr: "岩", region: "北海道・東北", col: 11, row: 4, hue: "sky" },
  { name: "宮城", abbr: "宮", region: "北海道・東北", col: 11, row: 5, hue: "sky" },
  { name: "秋田", abbr: "秋", region: "北海道・東北", col: 10, row: 4, hue: "sky" },
  { name: "山形", abbr: "山", region: "北海道・東北", col: 10, row: 5, hue: "sky" },
  { name: "福島", abbr: "福", region: "北海道・東北", col: 10, row: 6, hue: "sky" },
  { name: "茨城", abbr: "茨", region: "関東", col: 11, row: 7, hue: "lav" },
  { name: "栃木", abbr: "栃", region: "関東", col: 10, row: 7, hue: "lav" },
  { name: "群馬", abbr: "群", region: "関東", col: 9, row: 7, hue: "lav" },
  { name: "埼玉", abbr: "埼", region: "関東", col: 9, row: 8, hue: "lav" },
  { name: "千葉", abbr: "千", region: "関東", col: 11, row: 8, hue: "lav" },
  { name: "東京", abbr: "東", region: "関東", col: 10, row: 8, hue: "lav" },
  { name: "神奈川", abbr: "神", region: "関東", col: 10, row: 9, hue: "lav" },
  { name: "新潟", abbr: "新", region: "甲信越・北陸", col: 8, row: 5, hue: "mint" },
  { name: "富山", abbr: "富", region: "甲信越・北陸", col: 7, row: 6, hue: "mint" },
  { name: "石川", abbr: "石", region: "甲信越・北陸", col: 6, row: 6, hue: "mint" },
  { name: "福井", abbr: "井", region: "甲信越・北陸", col: 6, row: 7, hue: "mint" },
  { name: "山梨", abbr: "梨", region: "甲信越・北陸", col: 9, row: 9, hue: "mint" },
  { name: "長野", abbr: "長", region: "甲信越・北陸", col: 8, row: 7, hue: "mint" },
  { name: "岐阜", abbr: "岐", region: "東海", col: 7, row: 8, hue: "mint" },
  { name: "静岡", abbr: "静", region: "東海", col: 8, row: 10, hue: "mint" },
  { name: "愛知", abbr: "愛", region: "東海", col: 7, row: 9, hue: "mint" },
  { name: "三重", abbr: "三", region: "東海", col: 6, row: 10, hue: "mint" },
  { name: "滋賀", abbr: "滋", region: "近畿", col: 5, row: 8, hue: "pink" },
  { name: "京都", abbr: "京", region: "近畿", col: 4, row: 8, hue: "pink" },
  { name: "大阪", abbr: "阪", region: "近畿", col: 4, row: 9, hue: "pink" },
  { name: "兵庫", abbr: "兵", region: "近畿", col: 3, row: 9, hue: "pink" },
  { name: "奈良", abbr: "奈", region: "近畿", col: 5, row: 9, hue: "pink" },
  { name: "和歌山", abbr: "和", region: "近畿", col: 4, row: 10, hue: "pink" },
  { name: "鳥取", abbr: "鳥", region: "中国", col: 3, row: 8, hue: "butter" },
  { name: "島根", abbr: "島", region: "中国", col: 2, row: 8, hue: "butter" },
  { name: "岡山", abbr: "岡", region: "中国", col: 3, row: 10, hue: "butter" },
  { name: "広島", abbr: "広", region: "中国", col: 2, row: 10, hue: "butter" },
  { name: "山口", abbr: "口", region: "中国", col: 1, row: 10, hue: "butter" },
  { name: "徳島", abbr: "徳", region: "四国", col: 4, row: 12, hue: "pink" },
  { name: "香川", abbr: "香", region: "四国", col: 4, row: 11, hue: "pink" },
  { name: "愛媛", abbr: "媛", region: "四国", col: 3, row: 12, hue: "pink" },
  { name: "高知", abbr: "高", region: "四国", col: 3, row: 13, hue: "pink" },
  { name: "福岡", abbr: "福", region: "九州・沖縄", col: 0, row: 11, hue: "butter" },
  { name: "佐賀", abbr: "佐", region: "九州・沖縄", col: 0, row: 12, hue: "butter" },
  { name: "長崎", abbr: "崎", region: "九州・沖縄", col: 0, row: 13, hue: "butter" },
  { name: "熊本", abbr: "熊", region: "九州・沖縄", col: 1, row: 12, hue: "butter" },
  { name: "大分", abbr: "分", region: "九州・沖縄", col: 2, row: 12, hue: "butter" },
  { name: "宮崎", abbr: "崎", region: "九州・沖縄", col: 1, row: 13, hue: "butter" },
  { name: "鹿児島", abbr: "鹿", region: "九州・沖縄", col: 1, row: 14, hue: "butter" },
  { name: "沖縄", abbr: "沖", region: "九州・沖縄", col: 0, row: 15, hue: "sky" },
];

export function normalizePrefectureName(area: string) {
  const trimmed = area.trim();
  if (trimmed === "北海道") return trimmed;
  return trimmed.replace(/[都府県]$/, "");
}

export function displayPrefectureName(area: string) {
  const normalized = normalizePrefectureName(area);
  if (normalized === "北海道") return normalized;
  if (normalized === "東京") return "東京都";
  if (normalized === "大阪" || normalized === "京都") return `${normalized}府`;
  return `${normalized}県`;
}
