import { Platform } from "react-native";
import { requireNativeModule } from "expo-modules-core";

export type TradingCardPoint = {
  x: number;
  y: number;
};

export type TradingCardFrame = {
  id?: string;
  topLeft: TradingCardPoint;
  topRight: TradingCardPoint;
  bottomRight: TradingCardPoint;
  bottomLeft: TradingCardPoint;
};

type NativeTradingCardCropper = {
  detectCardsAsync(imagePath: string): Promise<TradingCardFrame[]>;
  cropCardsAsync(imagePath: string, frames: TradingCardFrame[]): Promise<string[]>;
  rotateImagesAsync(imagePaths: string[], rotations: number[]): Promise<string[]>;
};

let nativeModule: NativeTradingCardCropper | null | undefined;

function getNativeModule() {
  if (Platform.OS !== "ios") return null;
  if (nativeModule !== undefined) return nativeModule;
  try {
    nativeModule = requireNativeModule<NativeTradingCardCropper>("TradingCardCropper");
  } catch {
    nativeModule = null;
  }
  return nativeModule;
}

export function isTradingCardCropperAvailable() {
  return getNativeModule() !== null;
}

export async function detectTradingCardsAsync(imagePath: string) {
  const module = getNativeModule();
  if (!module) {
    throw new Error("このiOSビルドにはトレカ切り出しモジュールが含まれていません。新しい開発ビルドで有効になります。");
  }
  return module.detectCardsAsync(imagePath);
}

export async function cropTradingCardsAsync(imagePath: string, frames: TradingCardFrame[]) {
  const module = getNativeModule();
  if (!module) {
    throw new Error("このiOSビルドにはトレカ切り出しモジュールが含まれていません。新しい開発ビルドで有効になります。");
  }
  return module.cropCardsAsync(imagePath, frames);
}

export async function rotateTradingCardImagesAsync(imagePaths: string[], rotations: number[]) {
  const module = getNativeModule();
  if (!module) {
    throw new Error("このiOSビルドにはトレカ切り出しモジュールが含まれていません。新しい開発ビルドで有効になります。");
  }
  return module.rotateImagesAsync(imagePaths, rotations);
}
