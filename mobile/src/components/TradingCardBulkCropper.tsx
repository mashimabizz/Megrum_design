import * as ImagePicker from "expo-image-picker";
import { useEffect, useMemo, useRef, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  Image,
  Modal,
  PanResponder,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
  useWindowDimensions,
  type LayoutChangeEvent,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import {
  cropTradingCardsAsync,
  detectTradingCardsAsync,
  isTradingCardCropperAvailable,
  rotateTradingCardImagesAsync,
  type TradingCardFrame,
  type TradingCardPoint,
} from "../lib/tradingCardCropper";
import { ihubColors, ihubRadii, ihubShadow } from "../theme/tokens";

type CropperPhase = "guide" | "adjust" | "result";
type SourceKind = "camera" | "library";
type CornerKey = "topLeft" | "topRight" | "bottomRight" | "bottomLeft";
type ImageSize = { width: number; height: number };
type LayoutRect = { left: number; top: number; width: number; height: number };

type Props = {
  visible: boolean;
  onClose: () => void;
  onComplete: (imageUris: string[]) => void;
};

const EMPTY_FRAME = makeFrame("manual", {
  topLeft: { x: 0.31, y: 0.22 },
  topRight: { x: 0.69, y: 0.22 },
  bottomRight: { x: 0.69, y: 0.76 },
  bottomLeft: { x: 0.31, y: 0.76 },
});

export function TradingCardBulkCropper({ visible, onClose, onComplete }: Props) {
  const nativeAvailable = isTradingCardCropperAvailable();
  const [phase, setPhase] = useState<CropperPhase>("guide");
  const [sourceUri, setSourceUri] = useState<string | null>(null);
  const [imageSize, setImageSize] = useState<ImageSize | null>(null);
  const [frames, setFrames] = useState<TradingCardFrame[]>([]);
  const [selectedFrameId, setSelectedFrameId] = useState<string | null>(null);
  const [croppedUris, setCroppedUris] = useState<string[]>([]);
  const [rotations, setRotations] = useState<number[]>([]);
  const [working, setWorking] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    if (!visible) reset();
  }, [visible]);

  function reset() {
    setPhase("guide");
    setSourceUri(null);
    setImageSize(null);
    setFrames([]);
    setSelectedFrameId(null);
    setCroppedUris([]);
    setRotations([]);
    setWorking(false);
    setMessage(null);
  }

  async function pickSource(source: SourceKind) {
    setMessage(null);
    const permission =
      source === "camera"
        ? await ImagePicker.requestCameraPermissionsAsync()
        : await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) {
      setMessage(source === "camera" ? "カメラの利用を許可してください" : "写真ライブラリの利用を許可してください");
      return;
    }

    const result =
      source === "camera"
        ? await ImagePicker.launchCameraAsync({
            allowsEditing: false,
            mediaTypes: ["images"],
            quality: 0.92,
          })
        : await ImagePicker.launchImageLibraryAsync({
            allowsEditing: false,
            mediaTypes: ["images"],
            quality: 0.92,
            selectionLimit: 1,
          });
    if (result.canceled || !result.assets[0]?.uri) return;

    await prepareImage(result.assets[0].uri);
  }

  async function prepareImage(uri: string) {
    setWorking(true);
    setSourceUri(uri);
    setPhase("adjust");
    setFrames([]);
    setSelectedFrameId(null);
    setMessage("AIでカード枠を検出中…");
    Image.getSize(
      uri,
      (width, height) => setImageSize({ width, height }),
      () => setImageSize(null),
    );

    try {
      const detected = await detectTradingCardsAsync(uri);
      const nextFrames = detected.map((frame, index) => makeFrame(`detected-${index + 1}`, frame));
      setFrames(nextFrames);
      setSelectedFrameId(nextFrames[0]?.id ?? null);
      setMessage(
        nextFrames.length > 0
          ? `${nextFrames.length}枚のカード候補を検出しました。枠を確認して、必要なら角を調整してください。`
          : "カードが検出できませんでした。背景や明るさを変えて撮り直すか、手動で枠を追加してください。",
      );
    } catch (error) {
      setFrames([]);
      setSelectedFrameId(null);
      setMessage(error instanceof Error ? error.message : "カード検出に失敗しました。手動で枠を追加してください。");
    } finally {
      setWorking(false);
    }
  }

  function addManualFrame() {
    const id = `manual-${Date.now()}`;
    const next = makeFrame(id, EMPTY_FRAME);
    setFrames((current) => [...current, next]);
    setSelectedFrameId(id);
    setMessage("追加した枠の四隅をドラッグしてカードに合わせてください。");
  }

  function deleteSelectedFrame() {
    if (!selectedFrameId) return;
    setFrames((current) => {
      const next = current.filter((frame) => frame.id !== selectedFrameId);
      setSelectedFrameId(next[0]?.id ?? null);
      return next;
    });
  }

  function updateCorner(frameId: string, corner: CornerKey, point: TradingCardPoint) {
    setFrames((current) =>
      current.map((frame) =>
        frame.id === frameId
          ? { ...frame, [corner]: { x: clamp01(point.x), y: clamp01(point.y) } }
          : frame,
      ),
    );
  }

  async function cropFrames() {
    if (!sourceUri || frames.length === 0) {
      setMessage("切り出すカード枠を追加してください。");
      return;
    }

    setWorking(true);
    setMessage("カード画像を切り出し中…");
    try {
      const uris = await cropTradingCardsAsync(sourceUri, frames);
      setCroppedUris(uris);
      setRotations(uris.map(() => 0));
      setPhase("result");
      setMessage(`${uris.length}枚を切り出しました。向きが違うものは90度回転できます。`);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "カード画像の切り出しに失敗しました。");
    } finally {
      setWorking(false);
    }
  }

  function rotatePreview(index: number) {
    setRotations((current) =>
      current.map((rotation, currentIndex) =>
        currentIndex === index ? (rotation + 1) % 4 : rotation,
      ),
    );
  }

  async function confirmCrops() {
    if (croppedUris.length === 0) return;
    setWorking(true);
    setMessage("画像を保存用に整えています…");
    try {
      const finalUris = rotations.some((rotation) => rotation !== 0)
        ? await rotateTradingCardImagesAsync(croppedUris, rotations)
        : croppedUris;
      onComplete(finalUris);
      reset();
      onClose();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "画像の回転保存に失敗しました。");
    } finally {
      setWorking(false);
    }
  }

  function requestClose() {
    if (working) {
      Alert.alert("処理中です", "処理が終わってから閉じてください。");
      return;
    }
    reset();
    onClose();
  }

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="fullScreen" onRequestClose={requestClose}>
      <SafeAreaView style={styles.modal}>
        <View style={styles.header}>
          <Pressable onPress={requestClose} style={styles.closeButton}>
            <Text style={styles.closeText}>閉じる</Text>
          </Pressable>
          <View style={styles.headerCopy}>
            <Text style={styles.kicker}>TRADING CARD AI</Text>
            <Text style={styles.title}>AIで一括登録</Text>
          </View>
          <View style={styles.headerSpacer} />
        </View>

        {phase === "guide" ? (
          <ScrollView contentContainerStyle={styles.guideContent}>
            <View style={styles.guideCard}>
              <Text style={styles.guideTitle}>トレカをまとめて1枚ずつ切り出します</Text>
              <Text style={styles.guideText}>
                濃い無地の背景にカードを少し離して並べ、できるだけ真上から撮影してください。白いカードは黒系の背景がおすすめです。
              </Text>
              {!nativeAvailable ? (
                <View style={styles.warningBox}>
                  <Text style={styles.warningText}>
                    この端末のビルドにはSwift切り出しモジュールが未組み込みです。次のiOS開発ビルドで利用できます。
                  </Text>
                </View>
              ) : null}
              <View style={styles.guideList}>
                <Text style={styles.guideBullet}>・カード同士を少し離す</Text>
                <Text style={styles.guideBullet}>・影が強く出ない明るさにする</Text>
                <Text style={styles.guideBullet}>・検出後に枠の追加、削除、四隅調整ができます</Text>
              </View>
            </View>

            <View style={styles.sourceGrid}>
              <Pressable disabled={working} onPress={() => void pickSource("camera")} style={styles.sourceButton}>
                <Text style={styles.sourceIcon}>⌁</Text>
                <Text style={styles.sourceText}>カメラで撮る</Text>
              </Pressable>
              <Pressable disabled={working} onPress={() => void pickSource("library")} style={styles.sourceButton}>
                <Text style={styles.sourceIcon}>▧</Text>
                <Text style={styles.sourceText}>写真を選ぶ</Text>
              </Pressable>
            </View>

            {message ? <InlineMessage>{message}</InlineMessage> : null}
          </ScrollView>
        ) : null}

        {phase === "adjust" && sourceUri ? (
          <View style={styles.adjustContent}>
            <FramePreview
              frames={frames}
              imageSize={imageSize}
              imageUri={sourceUri}
              selectedFrameId={selectedFrameId}
              onSelectFrame={setSelectedFrameId}
              onUpdateCorner={updateCorner}
            />

            <View style={styles.adjustToolbar}>
              <Pressable onPress={addManualFrame} style={styles.toolbarButton}>
                <Text style={styles.toolbarButtonText}>枠を追加</Text>
              </Pressable>
              <Pressable
                disabled={!selectedFrameId}
                onPress={deleteSelectedFrame}
                style={[styles.toolbarButton, !selectedFrameId ? styles.toolbarButtonDisabled : null]}
              >
                <Text style={styles.toolbarMutedText}>選択枠を削除</Text>
              </Pressable>
            </View>

            {message ? <InlineMessage>{message}</InlineMessage> : null}

            <View style={styles.footerActions}>
              <Pressable disabled={working} onPress={() => setPhase("guide")} style={styles.secondaryAction}>
                <Text style={styles.secondaryActionText}>撮り直す</Text>
              </Pressable>
              <Pressable
                disabled={working || frames.length === 0}
                onPress={() => void cropFrames()}
                style={[styles.primaryAction, working || frames.length === 0 ? styles.primaryActionDisabled : null]}
              >
                {working ? <ActivityIndicator color={ihubColors.surface} /> : <Text style={styles.primaryActionText}>切り出す</Text>}
              </Pressable>
            </View>
          </View>
        ) : null}

        {phase === "result" ? (
          <View style={styles.resultContent}>
            <Text style={styles.resultLead}>切り出し結果</Text>
            <ScrollView contentContainerStyle={styles.resultGrid}>
              {croppedUris.map((uri, index) => (
                <View key={`${uri}-${index}`} style={styles.resultTile}>
                  <View style={styles.resultThumbBox}>
                    <Image
                      source={{ uri }}
                      resizeMode="contain"
                      style={[
                        styles.resultThumb,
                        { transform: [{ rotate: `${rotations[index] * 90}deg` }] },
                      ]}
                    />
                  </View>
                  <View style={styles.resultMeta}>
                    <Text style={styles.resultIndex}>{index + 1}枚目</Text>
                    <Pressable onPress={() => rotatePreview(index)} style={styles.rotateButton}>
                      <Text style={styles.rotateText}>90°回転</Text>
                    </Pressable>
                  </View>
                </View>
              ))}
            </ScrollView>

            {message ? <InlineMessage>{message}</InlineMessage> : null}

            <View style={styles.footerActions}>
              <Pressable disabled={working} onPress={() => setPhase("adjust")} style={styles.secondaryAction}>
                <Text style={styles.secondaryActionText}>枠調整へ戻る</Text>
              </Pressable>
              <Pressable
                disabled={working || croppedUris.length === 0}
                onPress={() => void confirmCrops()}
                style={[styles.primaryAction, working ? styles.primaryActionDisabled : null]}
              >
                {working ? <ActivityIndicator color={ihubColors.surface} /> : <Text style={styles.primaryActionText}>この画像で追加</Text>}
              </Pressable>
            </View>
          </View>
        ) : null}
      </SafeAreaView>
    </Modal>
  );
}

function FramePreview({
  frames,
  imageSize,
  imageUri,
  selectedFrameId,
  onSelectFrame,
  onUpdateCorner,
}: {
  frames: TradingCardFrame[];
  imageSize: ImageSize | null;
  imageUri: string;
  selectedFrameId: string | null;
  onSelectFrame: (id: string | null) => void;
  onUpdateCorner: (frameId: string, corner: CornerKey, point: TradingCardPoint) => void;
}) {
  const { height } = useWindowDimensions();
  const [containerSize, setContainerSize] = useState<ImageSize | null>(null);
  const previewHeight = Math.max(360, Math.min(520, height * 0.58));
  const displayRect = useMemo(
    () => getContainedRect(containerSize, imageSize),
    [containerSize, imageSize],
  );

  function handleLayout(event: LayoutChangeEvent) {
    const { width, height: layoutHeight } = event.nativeEvent.layout;
    setContainerSize({ width, height: layoutHeight });
  }

  return (
    <View onLayout={handleLayout} style={[styles.previewBox, { height: previewHeight }]}>
      <Image source={{ uri: imageUri }} resizeMode="contain" style={styles.previewImage} />
      {displayRect ? (
        <View pointerEvents="box-none" style={StyleSheet.absoluteFill}>
          {frames.map((frame) => {
            const selected = frame.id === selectedFrameId;
            return (
              <FrameOverlay
                key={frame.id}
                displayRect={displayRect}
                frame={frame}
                selected={selected}
                onSelect={() => onSelectFrame(frame.id ?? null)}
                onUpdateCorner={onUpdateCorner}
              />
            );
          })}
        </View>
      ) : null}
    </View>
  );
}

function FrameOverlay({
  displayRect,
  frame,
  selected,
  onSelect,
  onUpdateCorner,
}: {
  displayRect: LayoutRect;
  frame: TradingCardFrame;
  selected: boolean;
  onSelect: () => void;
  onUpdateCorner: (frameId: string, corner: CornerKey, point: TradingCardPoint) => void;
}) {
  const color = selected ? ihubColors.lavender : "rgba(255,255,255,0.92)";
  const corners = [frame.topLeft, frame.topRight, frame.bottomRight, frame.bottomLeft].map((point) =>
    toScreenPoint(point, displayRect),
  );
  const bounds = getBounds(corners);

  if (!frame.id) return null;

  return (
    <View pointerEvents="box-none" style={StyleSheet.absoluteFill}>
      <Pressable onPress={onSelect} style={[styles.frameTouchTarget, bounds]} />
      <FrameLine from={corners[0]} to={corners[1]} color={color} />
      <FrameLine from={corners[1]} to={corners[2]} color={color} />
      <FrameLine from={corners[2]} to={corners[3]} color={color} />
      <FrameLine from={corners[3]} to={corners[0]} color={color} />
      {selected ? (
        <>
          <CornerHandle
            corner="topLeft"
            displayRect={displayRect}
            frame={frame}
            onUpdateCorner={onUpdateCorner}
          />
          <CornerHandle
            corner="topRight"
            displayRect={displayRect}
            frame={frame}
            onUpdateCorner={onUpdateCorner}
          />
          <CornerHandle
            corner="bottomRight"
            displayRect={displayRect}
            frame={frame}
            onUpdateCorner={onUpdateCorner}
          />
          <CornerHandle
            corner="bottomLeft"
            displayRect={displayRect}
            frame={frame}
            onUpdateCorner={onUpdateCorner}
          />
        </>
      ) : null}
    </View>
  );
}

function FrameLine({ color, from, to }: { color: string; from: TradingCardPoint; to: TradingCardPoint }) {
  const dx = to.x - from.x;
  const dy = to.y - from.y;
  const length = Math.sqrt(dx * dx + dy * dy);
  const angle = Math.atan2(dy, dx);
  const left = from.x + dx / 2 - length / 2;
  const top = from.y + dy / 2 - 1.5;
  return (
    <View
      pointerEvents="none"
      style={[
        styles.frameLine,
        {
          backgroundColor: color,
          left,
          top,
          width: length,
          transform: [{ rotateZ: `${angle}rad` }],
        },
      ]}
    />
  );
}

function CornerHandle({
  corner,
  displayRect,
  frame,
  onUpdateCorner,
}: {
  corner: CornerKey;
  displayRect: LayoutRect;
  frame: TradingCardFrame;
  onUpdateCorner: (frameId: string, corner: CornerKey, point: TradingCardPoint) => void;
}) {
  const startPoint = useRef<TradingCardPoint>(frame[corner]);
  const screenPoint = toScreenPoint(frame[corner], displayRect);
  const responder = useMemo(
    () =>
      PanResponder.create({
        onStartShouldSetPanResponder: () => true,
        onMoveShouldSetPanResponder: () => true,
        onPanResponderGrant: () => {
          startPoint.current = frame[corner];
        },
        onPanResponderMove: (_, gesture) => {
          if (!frame.id) return;
          onUpdateCorner(frame.id, corner, {
            x: startPoint.current.x + gesture.dx / displayRect.width,
            y: startPoint.current.y + gesture.dy / displayRect.height,
          });
        },
      }),
    [corner, displayRect.height, displayRect.width, frame, onUpdateCorner],
  );

  return (
    <View
      {...responder.panHandlers}
      style={[
        styles.cornerHandle,
        {
          left: screenPoint.x - 14,
          top: screenPoint.y - 14,
        },
      ]}
    />
  );
}

function InlineMessage({ children }: { children: string }) {
  return (
    <View style={styles.messageBox}>
      <Text style={styles.messageText}>{children}</Text>
    </View>
  );
}

function makeFrame(id: string, frame: TradingCardFrame): TradingCardFrame {
  return {
    id,
    topLeft: normalizePoint(frame.topLeft),
    topRight: normalizePoint(frame.topRight),
    bottomRight: normalizePoint(frame.bottomRight),
    bottomLeft: normalizePoint(frame.bottomLeft),
  };
}

function normalizePoint(point: TradingCardPoint) {
  return { x: clamp01(point.x), y: clamp01(point.y) };
}

function clamp01(value: number) {
  return Math.max(0, Math.min(1, value));
}

function getContainedRect(container: ImageSize | null, image: ImageSize | null): LayoutRect | null {
  if (!container || !image || image.width <= 0 || image.height <= 0) return null;
  const containerRatio = container.width / container.height;
  const imageRatio = image.width / image.height;
  if (imageRatio > containerRatio) {
    const width = container.width;
    const height = width / imageRatio;
    return { left: 0, top: (container.height - height) / 2, width, height };
  }
  const height = container.height;
  const width = height * imageRatio;
  return { left: (container.width - width) / 2, top: 0, width, height };
}

function toScreenPoint(point: TradingCardPoint, rect: LayoutRect): TradingCardPoint {
  return {
    x: rect.left + point.x * rect.width,
    y: rect.top + point.y * rect.height,
  };
}

function getBounds(points: TradingCardPoint[]) {
  const xs = points.map((point) => point.x);
  const ys = points.map((point) => point.y);
  const left = Math.min(...xs);
  const top = Math.min(...ys);
  const right = Math.max(...xs);
  const bottom = Math.max(...ys);
  return {
    left,
    top,
    width: Math.max(24, right - left),
    height: Math.max(24, bottom - top),
  };
}

const styles = StyleSheet.create({
  modal: {
    flex: 1,
    backgroundColor: ihubColors.background,
  },
  header: {
    alignItems: "center",
    borderBottomColor: "rgba(166,149,216,0.16)",
    borderBottomWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    gap: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  closeButton: {
    alignItems: "center",
    borderColor: "rgba(166,149,216,0.28)",
    borderRadius: 999,
    borderWidth: 1,
    height: 36,
    justifyContent: "center",
    width: 64,
  },
  closeText: {
    color: ihubColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
  headerCopy: {
    flex: 1,
  },
  headerSpacer: {
    width: 64,
  },
  kicker: {
    color: ihubColors.lavender,
    fontSize: 10,
    fontWeight: "900",
    letterSpacing: 0,
  },
  title: {
    color: ihubColors.ink,
    fontSize: 18,
    fontWeight: "900",
    marginTop: 2,
  },
  guideContent: {
    gap: 16,
    padding: 18,
  },
  guideCard: {
    backgroundColor: ihubColors.surface,
    borderRadius: ihubRadii.lg,
    gap: 12,
    padding: 16,
    ...ihubShadow,
  },
  guideTitle: {
    color: ihubColors.ink,
    fontSize: 18,
    fontWeight: "900",
    lineHeight: 25,
  },
  guideText: {
    color: ihubColors.mutedInk,
    fontSize: 13,
    fontWeight: "700",
    lineHeight: 21,
  },
  warningBox: {
    backgroundColor: "rgba(245,158,11,0.12)",
    borderColor: "rgba(245,158,11,0.28)",
    borderRadius: ihubRadii.md,
    borderWidth: 1,
    padding: 12,
  },
  warningText: {
    color: "#8a5a00",
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
  },
  guideList: {
    gap: 7,
  },
  guideBullet: {
    color: ihubColors.ink,
    fontSize: 13,
    fontWeight: "800",
    lineHeight: 19,
  },
  sourceGrid: {
    flexDirection: "row",
    gap: 12,
  },
  sourceButton: {
    alignItems: "center",
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(166,149,216,0.2)",
    borderRadius: ihubRadii.lg,
    borderWidth: 1,
    flex: 1,
    gap: 8,
    minHeight: 116,
    justifyContent: "center",
    padding: 16,
    ...ihubShadow,
  },
  sourceIcon: {
    color: ihubColors.lavender,
    fontSize: 28,
    fontWeight: "900",
  },
  sourceText: {
    color: ihubColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  adjustContent: {
    flex: 1,
    gap: 12,
    padding: 14,
  },
  previewBox: {
    backgroundColor: "#111018",
    borderRadius: ihubRadii.lg,
    overflow: "hidden",
    width: "100%",
  },
  previewImage: {
    height: "100%",
    width: "100%",
  },
  frameTouchTarget: {
    position: "absolute",
  },
  frameLine: {
    height: 3,
    opacity: 0.96,
    position: "absolute",
  },
  cornerHandle: {
    backgroundColor: ihubColors.surface,
    borderColor: ihubColors.lavender,
    borderRadius: 14,
    borderWidth: 4,
    height: 28,
    position: "absolute",
    width: 28,
  },
  adjustToolbar: {
    flexDirection: "row",
    gap: 10,
  },
  toolbarButton: {
    alignItems: "center",
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(166,149,216,0.24)",
    borderRadius: 999,
    borderWidth: 1,
    flex: 1,
    justifyContent: "center",
    minHeight: 42,
    paddingHorizontal: 14,
  },
  toolbarButtonDisabled: {
    opacity: 0.45,
  },
  toolbarButtonText: {
    color: ihubColors.lavender,
    fontSize: 13,
    fontWeight: "900",
  },
  toolbarMutedText: {
    color: ihubColors.mutedInk,
    fontSize: 13,
    fontWeight: "900",
  },
  messageBox: {
    backgroundColor: "rgba(168,212,230,0.18)",
    borderColor: "rgba(168,212,230,0.36)",
    borderRadius: ihubRadii.md,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  messageText: {
    color: ihubColors.ink,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
  },
  footerActions: {
    flexDirection: "row",
    gap: 10,
    marginTop: "auto",
  },
  secondaryAction: {
    alignItems: "center",
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(166,149,216,0.22)",
    borderRadius: ihubRadii.md,
    borderWidth: 1,
    flex: 1,
    justifyContent: "center",
    minHeight: 50,
  },
  secondaryActionText: {
    color: ihubColors.mutedInk,
    fontSize: 14,
    fontWeight: "900",
  },
  primaryAction: {
    alignItems: "center",
    backgroundColor: ihubColors.lavender,
    borderRadius: ihubRadii.md,
    flex: 1.25,
    justifyContent: "center",
    minHeight: 50,
  },
  primaryActionDisabled: {
    opacity: 0.55,
  },
  primaryActionText: {
    color: ihubColors.surface,
    fontSize: 15,
    fontWeight: "900",
  },
  resultContent: {
    flex: 1,
    gap: 12,
    padding: 14,
  },
  resultLead: {
    color: ihubColors.ink,
    fontSize: 16,
    fontWeight: "900",
  },
  resultGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 12,
    paddingBottom: 12,
  },
  resultTile: {
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(166,149,216,0.18)",
    borderRadius: ihubRadii.lg,
    borderWidth: 1,
    overflow: "hidden",
    width: "48%",
  },
  resultThumbBox: {
    alignItems: "center",
    aspectRatio: 0.71,
    backgroundColor: "rgba(58,50,74,0.06)",
    justifyContent: "center",
    width: "100%",
  },
  resultThumb: {
    height: "92%",
    width: "92%",
  },
  resultMeta: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    padding: 10,
  },
  resultIndex: {
    color: ihubColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  rotateButton: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  rotateText: {
    color: ihubColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
});
