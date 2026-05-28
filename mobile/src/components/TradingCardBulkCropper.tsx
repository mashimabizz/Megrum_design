import * as ImagePicker from "expo-image-picker";
import { useEffect, useMemo, useRef, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  GestureResponderEvent,
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
import { SafeAreaView, useSafeAreaInsets } from "react-native-safe-area-context";
import {
  cropTradingCardsAsync,
  detectTradingCardsAsync,
  isTradingCardCropperAvailable,
  rotateTradingCardImagesAsync,
  type TradingCardFrame,
  type TradingCardPoint,
} from "../lib/tradingCardCropper";
import { megrumColors, megrumRadii, megrumShadow } from "../theme/tokens";

type CropperPhase = "guide" | "adjust" | "manual" | "result";
type SourceKind = "camera" | "library";
type CornerKey = "topLeft" | "topRight" | "bottomRight" | "bottomLeft";
type ImageSize = { width: number; height: number };
type LayoutRect = { left: number; top: number; width: number; height: number };

type Props = {
  visible: boolean;
  onClose: () => void;
  onComplete: (imageUris: string[]) => void;
};

export function TradingCardBulkCropper({ visible, onClose, onComplete }: Props) {
  const insets = useSafeAreaInsets();
  const nativeAvailable = isTradingCardCropperAvailable();
  const [phase, setPhase] = useState<CropperPhase>("guide");
  const [sourceUri, setSourceUri] = useState<string | null>(null);
  const [imageSize, setImageSize] = useState<ImageSize | null>(null);
  const [frames, setFrames] = useState<TradingCardFrame[]>([]);
  const [selectedFrameId, setSelectedFrameId] = useState<string | null>(null);
  const [croppedUris, setCroppedUris] = useState<string[]>([]);
  const [rotations, setRotations] = useState<number[]>([]);
  const [adjustPreviewUris, setAdjustPreviewUris] = useState<string[]>([]);
  const [adjustPreviewLoading, setAdjustPreviewLoading] = useState(false);
  const [adjustScrollEnabled, setAdjustScrollEnabled] = useState(true);
  const [working, setWorking] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const previewRequestRef = useRef(0);

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
    setAdjustPreviewUris([]);
    setAdjustPreviewLoading(false);
    setAdjustScrollEnabled(true);
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
          ? `${nextFrames.length}枚のカード候補を検出しました。枠を確認して、必要なら角を調整してください。手動追加は「切り出す」から進めます。`
          : "カードが検出できませんでした。背景や明るさを変えて撮り直すか、「切り出す」から手動で枠を追加してください。",
      );
    } catch (error) {
      setFrames([]);
      setSelectedFrameId(null);
      setMessage(error instanceof Error ? error.message : "カード検出に失敗しました。手動で枠を追加してください。");
    } finally {
      setWorking(false);
    }
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

  function enterManualMode() {
    if (!sourceUri) return;
    setSelectedFrameId(null);
    setPhase("manual");
    setMessage("画像の上で指を置いて引いて離すと、新しい枠を追加できます。");
  }

  function clearSelection() {
    setSelectedFrameId(null);
    setMessage("選択中の枠を解除しました。");
  }

  function rotatePreview(index: number) {
    setRotations((current) =>
      current.map((rotation, currentIndex) =>
        currentIndex === index ? (rotation + 1) % 4 : rotation,
      ),
    );
  }

  function deleteCroppedResult(index: number) {
    setCroppedUris((current) => {
      const next = current.filter((_, currentIndex) => currentIndex !== index);
      setRotations((rotationCurrent) =>
        rotationCurrent.filter((_, currentIndex) => currentIndex !== index),
      );
      if (next.length === 0) {
        setMessage("切り出し結果がありません。枠調整に戻ってやり直してください。");
      } else {
        setMessage(`${next.length}枚を保持しています。不要なものは引き続き削除できます。`);
      }
      return next;
    });
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

  useEffect(() => {
    if (phase !== "adjust" || !sourceUri || frames.length === 0) {
      setAdjustPreviewUris([]);
      setAdjustPreviewLoading(false);
      return;
    }

    const requestId = previewRequestRef.current + 1;
    previewRequestRef.current = requestId;
    setAdjustPreviewLoading(true);
    const timeout = setTimeout(() => {
      void cropTradingCardsAsync(sourceUri, frames)
        .then((uris) => {
          if (previewRequestRef.current !== requestId) return;
          setAdjustPreviewUris(uris);
        })
        .catch(() => {
          if (previewRequestRef.current !== requestId) return;
          setAdjustPreviewUris([]);
        })
        .finally(() => {
          if (previewRequestRef.current !== requestId) return;
          setAdjustPreviewLoading(false);
        });
    }, 320);

    return () => clearTimeout(timeout);
  }, [frames, phase, sourceUri]);

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="fullScreen" onRequestClose={requestClose}>
      <SafeAreaView edges={["left", "right", "bottom"]} style={styles.modal}>
        <View style={[styles.header, { paddingTop: Math.max(12, insets.top + 6) }]}>
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
            <ScrollView scrollEnabled={adjustScrollEnabled} contentContainerStyle={styles.adjustScrollContent}>
              <FramePreview
                frames={frames}
                imageSize={imageSize}
                imageUri={sourceUri}
                interactionMode="select"
                selectedFrameId={selectedFrameId}
                onDragStateChange={setAdjustScrollEnabled}
                onSelectFrame={setSelectedFrameId}
                onUpdateCorner={updateCorner}
              />

              <View style={[styles.footerActions, styles.photoFooterActions]}>
                <Pressable disabled={working} onPress={() => setPhase("guide")} style={styles.secondaryAction}>
                  <Text style={styles.secondaryActionText}>撮り直す</Text>
                </Pressable>
                <Pressable
                  disabled={working}
                  onPress={enterManualMode}
                  style={[styles.primaryAction, working ? styles.primaryActionDisabled : null]}
                >
                  {working ? <ActivityIndicator color={megrumColors.surface} /> : <Text style={styles.primaryActionText}>切り出す</Text>}
                </Pressable>
              </View>

              <View style={styles.previewStripCard}>
                <View style={styles.previewStripHeader}>
                  <Text style={styles.previewStripTitle}>切り取りプレビュー</Text>
                  <View style={styles.previewStripHeaderActions}>
                    {selectedFrameId ? (
                      <Pressable onPress={deleteSelectedFrame} style={styles.previewHeaderDeleteChip}>
                        <Text style={styles.previewHeaderDeleteText}>選択枠を削除</Text>
                      </Pressable>
                    ) : null}
                    {adjustPreviewLoading ? <Text style={styles.previewStripHint}>更新中…</Text> : null}
                  </View>
                </View>
                {adjustPreviewUris.length > 0 ? (
                  <View style={styles.previewStripGrid}>
                    {adjustPreviewUris.map((uri, index) => {
                      const frameId = frames[index]?.id ?? null;
                      const selected = frameId !== null && frameId === selectedFrameId;
                      return (
                        <Pressable
                          key={`${uri}-${index}`}
                          onPress={() => setSelectedFrameId(frameId)}
                          style={[
                            styles.previewStripTile,
                            selected ? styles.previewStripTileSelected : null,
                          ]}
                        >
                          <Image source={{ uri }} resizeMode="cover" style={styles.previewStripImage} />
                        </Pressable>
                      );
                    })}
                  </View>
                ) : (
                  <Text style={styles.previewStripEmpty}>
                    「切り出す」から手動切り取りモードへ進むと、ここに切り取り結果の一覧が追加されます。
                  </Text>
                )}
              </View>

              <View style={styles.dragHintCard}>
                <Text style={styles.dragHintTitle}>枠の調整方法</Text>
                <Text style={styles.dragHintText}>
                  重なっている場所は連続タップで枠を切り替えられます。角の丸いハンドルを動かすと、選択中の枠だけ微調整できます。
                </Text>
              </View>

              {message ? <InlineMessage>{message}</InlineMessage> : null}
            </ScrollView>
          </View>
        ) : null}

        {phase === "manual" && sourceUri ? (
          <View style={styles.manualContent}>
            <FramePreview
              frames={frames}
              imageSize={imageSize}
              imageUri={sourceUri}
              interactionMode="create"
              selectedFrameId={selectedFrameId}
              fullHeight
              onDragStateChange={() => undefined}
              onCreateFrame={(frame) => {
                const id = `drag-${Date.now()}`;
                setFrames((current) => [...current, makeFrame(id, frame)]);
                setSelectedFrameId(id);
                setMessage("手動で枠を追加しました。下のプレビューに反映されています。");
              }}
              onSelectFrame={setSelectedFrameId}
              onUpdateCorner={updateCorner}
            />

            <View style={styles.previewStripCard}>
              <View style={styles.previewStripHeader}>
                <Text style={styles.previewStripTitle}>切り取りプレビュー</Text>
                <View style={styles.previewStripHeaderActions}>
                  {adjustPreviewLoading ? <Text style={styles.previewStripHint}>更新中…</Text> : null}
                </View>
              </View>
              {adjustPreviewUris.length > 0 ? (
                <View style={styles.previewStripGrid}>
                  {adjustPreviewUris.map((uri, index) => (
                    <View key={`${uri}-${index}`} style={styles.previewStripTile}>
                      <Image source={{ uri }} resizeMode="cover" style={styles.previewStripImage} />
                    </View>
                  ))}
                </View>
              ) : (
                <Text style={styles.previewStripEmpty}>
                  この画面ではドラッグで新しい枠を追加できます。追加した結果がここに並びます。
                </Text>
              )}
            </View>

            <View style={styles.footerActions}>
              <Pressable disabled={working} onPress={clearSelection} style={styles.secondaryAction}>
                <Text style={styles.secondaryActionText}>選択枠を解除</Text>
              </Pressable>
              <Pressable
                disabled={working || frames.length === 0}
                onPress={() => void cropFrames()}
                style={[styles.primaryAction, working || frames.length === 0 ? styles.primaryActionDisabled : null]}
              >
                {working ? (
                  <ActivityIndicator color={megrumColors.surface} />
                ) : (
                  <Text style={styles.primaryActionText}>角度調整に進む</Text>
                )}
              </Pressable>
            </View>

            {message ? <InlineMessage>{message}</InlineMessage> : null}
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
                    <View style={styles.resultActions}>
                      <Pressable onPress={() => rotatePreview(index)} style={styles.rotateButton}>
                        <Text style={styles.rotateText}>90°回転</Text>
                      </Pressable>
                      <Pressable onPress={() => deleteCroppedResult(index)} style={styles.deleteButton}>
                        <Text style={styles.deleteText}>削除</Text>
                      </Pressable>
                    </View>
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
                {working ? <ActivityIndicator color={megrumColors.surface} /> : <Text style={styles.primaryActionText}>この画像で追加</Text>}
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
  fullHeight,
  imageSize,
  imageUri,
  interactionMode,
  onDragStateChange,
  onCreateFrame,
  selectedFrameId,
  onSelectFrame,
  onUpdateCorner,
}: {
  frames: TradingCardFrame[];
  fullHeight?: boolean;
  imageSize: ImageSize | null;
  imageUri: string;
  interactionMode: "select" | "create";
  onDragStateChange: (enabled: boolean) => void;
  onCreateFrame?: (frame: TradingCardFrame) => void;
  selectedFrameId: string | null;
  onSelectFrame: (id: string | null) => void;
  onUpdateCorner: (frameId: string, corner: CornerKey, point: TradingCardPoint) => void;
}) {
  const { height } = useWindowDimensions();
  const [containerSize, setContainerSize] = useState<ImageSize | null>(null);
  const [draftRect, setDraftRect] = useState<LayoutRect | null>(null);
  const draftRectRef = useRef<LayoutRect | null>(null);
  const lastTapCycleRef = useRef<{ ids: string[]; nextIndex: number } | null>(null);
  const dragStartRef = useRef<TradingCardPoint | null>(null);
  const previewHeight = Math.max(360, Math.min(520, height * 0.58));
  const displayRect = useMemo(
    () => getContainedRect(containerSize, imageSize),
    [containerSize, imageSize],
  );

  function handleLayout(event: LayoutChangeEvent) {
    const { width, height: layoutHeight } = event.nativeEvent.layout;
    setContainerSize({ width, height: layoutHeight });
  }

  function handleOverlayPress(event: GestureResponderEvent) {
    if (!displayRect) return;
    const tapPoint = clampPointToRect(
      { x: event.nativeEvent.locationX, y: event.nativeEvent.locationY },
      displayRect,
    );
    const hitFrames = frames
      .filter((frame) => frame.id)
      .map((frame) => ({
        area: frameArea(frame),
        frame,
      }))
      .filter(({ frame }) => pointInsideFrame(tapPoint, frame, displayRect))
      .sort((left, right) => left.area - right.area)
      .map(({ frame }) => frame);

    if (hitFrames.length === 0) {
      lastTapCycleRef.current = null;
      return;
    }

    const hitIds = hitFrames.map((frame) => frame.id ?? "");
    const lastCycle = lastTapCycleRef.current;
    const sameSet =
      lastCycle &&
      lastCycle.ids.length === hitIds.length &&
      lastCycle.ids.every((id, index) => id === hitIds[index]);

    const nextIndex = sameSet ? lastCycle.nextIndex % hitIds.length : 0;
    const selected = hitFrames[nextIndex]?.id ?? null;
    onSelectFrame(selected);
    lastTapCycleRef.current = {
      ids: hitIds,
      nextIndex: nextIndex + 1,
    };
  }

  const overlayResponder = useMemo(
    () =>
      PanResponder.create({
        onStartShouldSetPanResponder: () => true,
        onStartShouldSetPanResponderCapture: () => true,
        onMoveShouldSetPanResponder: () => true,
        onMoveShouldSetPanResponderCapture: () => true,
        onPanResponderGrant: (event) => {
          if (!displayRect) return;
          onDragStateChange(false);
          dragStartRef.current = clampPointToRect(
            { x: event.nativeEvent.locationX, y: event.nativeEvent.locationY },
            displayRect,
          );
          draftRectRef.current = null;
          setDraftRect(null);
        },
        onPanResponderMove: (_, gesture) => {
          if (!displayRect || !dragStartRef.current) return;
          const currentPoint = clampPointToRect(
            {
              x: dragStartRef.current.x + gesture.dx,
              y: dragStartRef.current.y + gesture.dy,
            },
            displayRect,
          );
          if (Math.abs(gesture.dx) < 8 && Math.abs(gesture.dy) < 8) {
            draftRectRef.current = null;
            setDraftRect(null);
            return;
          }
          const nextRect = rectFromPoints(dragStartRef.current, currentPoint);
          draftRectRef.current = nextRect;
          setDraftRect(nextRect);
        },
        onPanResponderRelease: (_, gesture) => {
          if (!displayRect || !dragStartRef.current) return;
          const currentPoint = clampPointToRect(
            {
              x: dragStartRef.current.x + gesture.dx,
              y: dragStartRef.current.y + gesture.dy,
            },
            displayRect,
          );
          const finalRect = draftRectRef.current ?? rectFromPoints(dragStartRef.current, currentPoint);
          if (
            interactionMode === "create" &&
            onCreateFrame &&
            Math.abs(gesture.dx) >= 8 &&
            Math.abs(gesture.dy) >= 8 &&
            finalRect.width >= 18 &&
            finalRect.height >= 18
          ) {
            onCreateFrame(frameFromRect(dragStartRef.current, currentPoint, displayRect));
          } else {
            lastTapCycleRef.current = null;
          }
          dragStartRef.current = null;
          draftRectRef.current = null;
          setDraftRect(null);
          onDragStateChange(true);
        },
        onPanResponderTerminate: () => {
          dragStartRef.current = null;
          draftRectRef.current = null;
          setDraftRect(null);
          onDragStateChange(true);
        },
      }),
    [displayRect, interactionMode, onCreateFrame, onDragStateChange],
  );

  return (
    <View
      onLayout={handleLayout}
      style={[styles.previewBox, fullHeight ? styles.previewBoxFullHeight : { height: previewHeight }]}
    >
      <Image source={{ uri: imageUri }} resizeMode="contain" style={styles.previewImage} />
      {displayRect ? (
        <View pointerEvents="box-none" style={StyleSheet.absoluteFill}>
          {interactionMode === "create" ? (
            <View
              {...overlayResponder.panHandlers}
              style={[
                styles.overlayHitArea,
                {
                  left: displayRect.left,
                  top: displayRect.top,
                  width: displayRect.width,
                  height: displayRect.height,
                },
              ]}
            />
          ) : (
            <Pressable
              onPress={handleOverlayPress}
              style={[
                styles.overlayHitArea,
                {
                  left: displayRect.left,
                  top: displayRect.top,
                  width: displayRect.width,
                  height: displayRect.height,
                },
              ]}
            />
          )}
          {draftRect ? <View pointerEvents="none" style={[styles.draftRect, draftRect]} /> : null}
          {frames.map((frame) => {
            const selected = frame.id === selectedFrameId;
            return (
              <FrameOverlay
                key={frame.id}
                displayRect={displayRect}
                frame={frame}
                selected={selected && interactionMode === "select"}
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
  onUpdateCorner,
}: {
  displayRect: LayoutRect;
  frame: TradingCardFrame;
  selected: boolean;
  onUpdateCorner: (frameId: string, corner: CornerKey, point: TradingCardPoint) => void;
}) {
  const color = selected ? "#ffd84d" : "rgba(255,216,77,0.72)";
  const corners = [frame.topLeft, frame.topRight, frame.bottomRight, frame.bottomLeft].map((point) =>
    toScreenPoint(point, displayRect),
  );

  if (!frame.id) return null;

  return (
    <View pointerEvents="box-none" style={StyleSheet.absoluteFill}>
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

function frameArea(frame: TradingCardFrame) {
  return Math.abs(
    polygonArea([frame.topLeft, frame.topRight, frame.bottomRight, frame.bottomLeft]),
  );
}

function pointInsideFrame(
  point: TradingCardPoint,
  frame: TradingCardFrame,
  displayRect: LayoutRect,
) {
  const corners = [frame.topLeft, frame.topRight, frame.bottomRight, frame.bottomLeft].map((framePoint) =>
    toScreenPoint(framePoint, displayRect),
  );
  return pointInPolygon(point, corners);
}

function pointInPolygon(point: TradingCardPoint, polygon: TradingCardPoint[]) {
  let inside = false;
  for (let index = 0, previous = polygon.length - 1; index < polygon.length; previous = index++) {
    const currentPoint = polygon[index];
    const previousPoint = polygon[previous];
    const crosses =
      (currentPoint.y > point.y) !== (previousPoint.y > point.y) &&
      point.x <
        ((previousPoint.x - currentPoint.x) * (point.y - currentPoint.y)) /
          ((previousPoint.y - currentPoint.y) || Number.EPSILON) +
          currentPoint.x;
    if (crosses) inside = !inside;
  }
  return inside;
}

function polygonArea(points: TradingCardPoint[]) {
  let sum = 0;
  for (let index = 0; index < points.length; index += 1) {
    const next = points[(index + 1) % points.length];
    sum += points[index].x * next.y - next.x * points[index].y;
  }
  return sum / 2;
}

function clampPointToRect(point: TradingCardPoint, rect: LayoutRect) {
  return {
    x: Math.max(rect.left, Math.min(rect.left + rect.width, point.x)),
    y: Math.max(rect.top, Math.min(rect.top + rect.height, point.y)),
  };
}

function rectFromPoints(start: TradingCardPoint, end: TradingCardPoint): LayoutRect {
  return {
    left: Math.min(start.x, end.x),
    top: Math.min(start.y, end.y),
    width: Math.abs(end.x - start.x),
    height: Math.abs(end.y - start.y),
  };
}

function frameFromRect(
  start: TradingCardPoint,
  end: TradingCardPoint,
  displayRect: LayoutRect,
): TradingCardFrame {
  const rect = rectFromPoints(start, end);
  return {
    topLeft: toNormalizedPoint({ x: rect.left, y: rect.top }, displayRect),
    topRight: toNormalizedPoint({ x: rect.left + rect.width, y: rect.top }, displayRect),
    bottomRight: toNormalizedPoint(
      { x: rect.left + rect.width, y: rect.top + rect.height },
      displayRect,
    ),
    bottomLeft: toNormalizedPoint({ x: rect.left, y: rect.top + rect.height }, displayRect),
  };
}

function toNormalizedPoint(point: TradingCardPoint, rect: LayoutRect): TradingCardPoint {
  return {
    x: clamp01((point.x - rect.left) / rect.width),
    y: clamp01((point.y - rect.top) / rect.height),
  };
}

const styles = StyleSheet.create({
  modal: {
    flex: 1,
    backgroundColor: megrumColors.background,
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
    color: megrumColors.mutedInk,
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
    color: megrumColors.lavender,
    fontSize: 10,
    fontWeight: "900",
    letterSpacing: 0,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
    marginTop: 2,
  },
  guideContent: {
    gap: 16,
    padding: 18,
  },
  guideCard: {
    backgroundColor: megrumColors.surface,
    borderRadius: megrumRadii.lg,
    gap: 12,
    padding: 16,
    ...megrumShadow,
  },
  guideTitle: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
    lineHeight: 25,
  },
  guideText: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "700",
    lineHeight: 21,
  },
  warningBox: {
    backgroundColor: "rgba(245,158,11,0.12)",
    borderColor: "rgba(245,158,11,0.28)",
    borderRadius: megrumRadii.md,
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
    color: megrumColors.ink,
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
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.2)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    flex: 1,
    gap: 8,
    minHeight: 116,
    justifyContent: "center",
    padding: 16,
    ...megrumShadow,
  },
  sourceIcon: {
    color: megrumColors.lavender,
    fontSize: 28,
    fontWeight: "900",
  },
  sourceText: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  adjustContent: {
    flex: 1,
  },
  adjustScrollContent: {
    gap: 12,
    padding: 14,
    paddingBottom: 24,
  },
  manualContent: {
    flex: 1,
    gap: 12,
    padding: 14,
    paddingBottom: 20,
  },
  previewBox: {
    backgroundColor: "#111018",
    borderRadius: megrumRadii.lg,
    overflow: "hidden",
    width: "100%",
  },
  previewBoxFullHeight: {
    flex: 1,
    minHeight: 0,
  },
  previewImage: {
    height: "100%",
    width: "100%",
  },
  overlayHitArea: {
    position: "absolute",
  },
  draftRect: {
    borderColor: "#ffd84d",
    borderRadius: 10,
    borderStyle: "dashed",
    borderWidth: 2,
    position: "absolute",
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
    backgroundColor: megrumColors.surface,
    borderColor: "#ffd84d",
    borderRadius: 14,
    borderWidth: 4,
    height: 28,
    position: "absolute",
    width: 28,
  },
  previewStripCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(255,216,77,0.22)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    gap: 10,
    padding: 12,
  },
  previewStripHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  previewStripHeaderActions: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
  },
  previewStripTitle: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  previewStripHint: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
  },
  previewHeaderDeleteChip: {
    backgroundColor: "rgba(239,68,68,0.08)",
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  previewHeaderDeleteText: {
    color: "#dc2626",
    fontSize: 11,
    fontWeight: "900",
  },
  previewStripGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  previewStripTile: {
    aspectRatio: 0.71,
    backgroundColor: "rgba(58,50,74,0.06)",
    borderColor: "rgba(166,149,216,0.18)",
    borderRadius: 10,
    borderWidth: 1,
    overflow: "hidden",
    width: "18.4%",
  },
  previewStripTileSelected: {
    borderColor: "#ffd84d",
    borderWidth: 2,
  },
  previewStripImage: {
    height: "100%",
    width: "100%",
  },
  previewStripEmpty: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    lineHeight: 16,
  },
  dragHintCard: {
    backgroundColor: "rgba(255,216,77,0.12)",
    borderColor: "rgba(255,216,77,0.28)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    gap: 4,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  dragHintTitle: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  dragHintText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    lineHeight: 16,
  },
  messageBox: {
    backgroundColor: "rgba(168,212,230,0.18)",
    borderColor: "rgba(168,212,230,0.36)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  messageText: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
  },
  footerActions: {
    flexDirection: "row",
    gap: 10,
    marginTop: "auto",
  },
  photoFooterActions: {
    marginTop: 2,
  },
  secondaryAction: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.22)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    flex: 1,
    justifyContent: "center",
    minHeight: 50,
  },
  secondaryActionText: {
    color: megrumColors.mutedInk,
    fontSize: 14,
    fontWeight: "900",
  },
  primaryAction: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: megrumRadii.md,
    flex: 1.25,
    justifyContent: "center",
    minHeight: 50,
  },
  primaryActionDisabled: {
    opacity: 0.55,
  },
  primaryActionText: {
    color: megrumColors.surface,
    fontSize: 15,
    fontWeight: "900",
  },
  resultContent: {
    flex: 1,
    gap: 12,
    padding: 14,
  },
  resultLead: {
    color: megrumColors.ink,
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
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.18)",
    borderRadius: megrumRadii.lg,
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
    gap: 8,
    padding: 10,
  },
  resultIndex: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  resultActions: {
    flexDirection: "row",
    gap: 8,
  },
  rotateButton: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  rotateText: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  deleteButton: {
    backgroundColor: "rgba(239,68,68,0.1)",
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  deleteText: {
    color: "#dc2626",
    fontSize: 11,
    fontWeight: "900",
  },
});
