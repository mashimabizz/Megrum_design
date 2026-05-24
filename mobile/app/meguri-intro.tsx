import { useEffect, useMemo, useRef, useState } from "react";
import { ActivityIndicator, Animated, Pressable, StyleSheet, Text, View } from "react-native";
import { router } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Screen } from "../src/components/Screen";
import {
  MEGURI_MAP_HEIGHT,
  MEGURI_MAP_REGION_COLORS,
  MEGURI_MAP_TILE_H,
  MEGURI_MAP_TILE_W,
  MEGURI_MAP_TILES,
  MEGURI_MAP_WIDTH,
  displayPrefectureName,
  normalizePrefectureName,
} from "../src/data/japanPrefectures";
import {
  MeguriThreeBoundary,
  MeguriThreeScene,
  type MeguriIntroPhase,
  type MeguriSceneMode,
  type MeguriSceneResident,
} from "../src/components/meguri/MeguriThreeScene";
import { ihubColors } from "../src/theme/tokens";
import {
  USERS,
  WalkingCard,
  hueTint,
  type MeguriUser,
} from "./(tabs)/encounters";
import {
  DEFAULT_MEGURI_AVATAR,
  DEFAULT_MEGURI_PROFILE,
  loadMeguriAvatarSettings,
  loadMeguriProfileSettings,
} from "../src/lib/meguriSettings";

const MAX_CHUNK_SIZE = 10;
const AREA_UNLOCK_MAP_SCALE = 0.62;
const fallbackHitokoto = [
  "今日はゆるっと推し活しています",
  "最近の供給をゆっくり味わっています",
  "同じ推しの気配に少し元気をもらいました",
];
const farewellLines = [
  "またお会いしましょう！",
  "まためぐりあえますように！",
  "またどこかで会えたらうれしいです！",
];

const SELF_USER: MeguriUser = {
  animalType: "rabbit",
  area: "東京",
  count: 1,
  furColor: "lavender",
  group: "VESTA",
  hitokoto: "今日は推し色の小物を持って出かけました",
  hue: "lav",
  id: "me",
  name: "あなた",
  oshi: "リオ",
  recent: "推し活の余韻をゆっくり味わっています",
  since: "今日",
  style: "現場 / 交換準備",
};

type DialogueLine = {
  body: string;
  kind?: "area" | "farewell";
  speaker: "me" | "partner";
};

type AreaUnlock = {
  area: string;
  hue: MeguriUser["hue"];
  name: string;
  unlockedAreas: string[];
};

export default function MeguriIntroScreen() {
  const insets = useSafeAreaInsets();
  const arrivals = USERS.slice(0, MAX_CHUNK_SIZE);
  const [activeIndex, setActiveIndex] = useState(0);
  const [completedIds, setCompletedIds] = useState<string[]>([]);
  const [dialogueIndex, setDialogueIndex] = useState(0);
  const [bubbleReady, setBubbleReady] = useState(false);
  const [revealSignal, setRevealSignal] = useState(0);
  const [areaUnlock, setAreaUnlock] = useState<AreaUnlock | null>(null);
  const [selfUser, setSelfUser] = useState<MeguriUser | null>(null);
  const [unlockedAreas, setUnlockedAreas] = useState<Set<string>>(() => new Set());
  const [introPhase, setIntroPhase] = useState<MeguriIntroPhase>("camera");
  const [mode, setMode] = useState<MeguriSceneMode>("summary");
  const [threeFailed, setThreeFailed] = useState(false);
  const active = arrivals[activeIndex] ?? null;
  const done = mode === "done";
  const currentLines = useMemo(
    () => (active && selfUser ? createDialogue(active, selfUser) : []),
    [active, selfUser],
  );
  const currentLine = currentLines[dialogueIndex] ?? null;
  const residents = useMemo(() => arrivals.map(toSceneResident), [arrivals]);
  const self = useMemo(() => (selfUser ? toSceneResident(selfUser) : null), [selfUser]);
  const activeId = mode === "summary" || done ? null : active?.id ?? null;
  const progressText = done
    ? `${arrivals.length} / ${arrivals.length}`
    : mode === "summary"
      ? `0 / ${arrivals.length}`
      : `${Math.min(activeIndex + 1, arrivals.length)} / ${arrivals.length}`;
  const topInset = Math.max(insets.top, 12);
  const bottomInset = Math.max(insets.bottom, 12);
  const locked =
    mode === "approaching" ||
    mode === "exiting" ||
    Boolean(areaUnlock) ||
    (mode === "summary" && introPhase === "camera");
  const headerTitle = getSceneHeaderTitle(mode, introPhase, done, arrivals.length);
  const showPrimary = mode === "done";
  const speakingId =
    mode === "dialogue" && currentLine
      ? currentLine.speaker === "me"
        ? self?.id ?? null
        : active?.id ?? null
      : null;
  const smilingId =
    mode === "dialogue" && currentLine
      ? currentLine.kind === "farewell"
        ? active?.id ?? null
        : !bubbleReady
          ? speakingId
          : null
      : null;
  const wavingId =
    mode === "dialogue" && currentLine?.kind === "farewell"
      ? active?.id ?? null
      : null;

  useEffect(() => {
    if (!selfUser) return undefined;
    const splashTimer = setTimeout(() => setIntroPhase("splash"), 2800);
    const walkingTimer = setTimeout(() => setIntroPhase("walking"), 4300);
    const readyTimer = setTimeout(() => setIntroPhase("ready"), 6200);
    return () => {
      clearTimeout(splashTimer);
      clearTimeout(walkingTimer);
      clearTimeout(readyTimer);
    };
  }, [selfUser]);

  useEffect(() => {
    let mounted = true;
    Promise.all([loadMeguriAvatarSettings(), loadMeguriProfileSettings()])
      .then(([avatar, profile]) => {
        if (!mounted) return;
        const nextSelf: MeguriUser = {
          ...SELF_USER,
          animalType: avatar.animalType ?? DEFAULT_MEGURI_AVATAR.animalType,
          area: profile.baseArea || DEFAULT_MEGURI_PROFILE.baseArea,
          furColor: avatar.furColor ?? DEFAULT_MEGURI_AVATAR.furColor,
          hitokoto: profile.hitokoto || DEFAULT_MEGURI_PROFILE.hitokoto,
          hue: avatar.hue ?? DEFAULT_MEGURI_AVATAR.hue,
          name: profile.displayName || DEFAULT_MEGURI_PROFILE.displayName,
          recent: profile.publicMemo || DEFAULT_MEGURI_PROFILE.publicMemo,
        };
        setSelfUser(nextSelf);
        setUnlockedAreas(new Set([normalizePrefectureName(nextSelf.area)]));
      })
      .catch(() => {
        if (!mounted) return;
        setSelfUser(SELF_USER);
        setUnlockedAreas(new Set([normalizePrefectureName(SELF_USER.area)]));
      });
    return () => {
      mounted = false;
    };
  }, []);

  useEffect(() => {
    if (mode !== "approaching") return;

    const timer = setTimeout(() => setMode("dialogue"), 760);
    return () => clearTimeout(timer);
  }, [mode, activeIndex]);

  useEffect(() => {
    if (mode !== "exiting" || !active) return;

    const timer = setTimeout(() => {
      setCompletedIds((current) => [...new Set([...current, active.id])]);
      if (activeIndex >= arrivals.length - 1) {
        setMode("done");
        return;
      }
      setActiveIndex((current) => current + 1);
      setDialogueIndex(0);
      setMode("approaching");
    }, 3400);

    return () => clearTimeout(timer);
  }, [active, activeIndex, arrivals.length, mode]);

  function closeAreaUnlock() {
    if (!areaUnlock) return;
    setAreaUnlock(null);
    if (dialogueIndex < currentLines.length - 1) {
      setDialogueIndex((current) => current + 1);
      setBubbleReady(false);
      return;
    }
    setMode("exiting");
    setBubbleReady(false);
  }

  function advance() {
    if (!self) return;
    if (areaUnlock) {
      closeAreaUnlock();
      return;
    }

    if (!arrivals.length) {
      router.replace("/encounters");
      return;
    }

    if (mode === "summary") {
      if (introPhase === "camera") return;
      setMode("approaching");
      setDialogueIndex(0);
      setBubbleReady(false);
      return;
    }

    if (mode === "dialogue") {
      if (!bubbleReady) {
        setRevealSignal((current) => current + 1);
        return;
      }
      const activeArea = active ? normalizePrefectureName(active.area) : null;
      if (currentLine?.kind === "area" && active && activeArea && !unlockedAreas.has(activeArea)) {
        const nextAreas = [...new Set([...unlockedAreas, activeArea])];
        setUnlockedAreas(new Set(nextAreas));
        setAreaUnlock({
          area: activeArea,
          hue: active.hue,
          name: active.name,
          unlockedAreas: nextAreas,
        });
        return;
      }
      if (dialogueIndex < currentLines.length - 1) {
        setDialogueIndex((current) => current + 1);
        setBubbleReady(false);
        return;
      }
      setMode("exiting");
      setBubbleReady(false);
      return;
    }

    if (mode === "done") {
      if (!bubbleReady) {
        setRevealSignal((current) => current + 1);
        return;
      }
      router.replace("/meguri-plaza");
    }
  }

  if (!self) {
    return (
      <Screen bottomInset={false} contentStyle={styles.loadingRoot} scroll={false} topInset={false}>
        <ActivityIndicator color={ihubColors.lavender} />
      </Screen>
    );
  }

  return (
    <Screen
      bottomInset={false}
      scroll={false}
      topInset={false}
      topPadding={0}
      contentStyle={styles.screen}
    >
      <Pressable
        accessibilityRole="button"
        disabled={locked}
        onPress={advance}
        style={styles.scene}
      >
        {mode === "summary" && introPhase !== "camera" ? (
          <MeguriSplash count={arrivals.length} />
        ) : headerTitle ? (
          <View style={[styles.sceneHeader, { top: topInset + 70 }]}>
            <Text style={styles.sceneTitle}>{headerTitle}</Text>
          </View>
        ) : null}

        <View style={styles.stageShell}>
          {threeFailed ? (
            <MeguriFallbackScene
              active={active}
              completedIds={completedIds}
              done={done}
              introPhase={introPhase}
              residents={arrivals}
            />
          ) : (
            <MeguriThreeBoundary
              fallback={
                <MeguriFallbackScene
                  active={active}
                  completedIds={completedIds}
                  done={done}
                  introPhase={introPhase}
                  residents={arrivals}
                />
              }
              onError={() => setThreeFailed(true)}
            >
              <MeguriThreeScene
                activeId={activeId}
                completedIds={completedIds}
                introPhase={introPhase}
                mode={mode}
                onUnavailable={() => setThreeFailed(true)}
                residents={residents}
                self={self}
                smilingId={smilingId}
                speaking={Boolean(speakingId) && !bubbleReady}
                speakingId={speakingId}
                wavingId={wavingId}
              />
            </MeguriThreeBoundary>
          )}
        </View>
      </Pressable>

      <View style={[styles.topBar, { top: topInset + 8 }]}>
        <Pressable
          accessibilityLabel="戻る"
          accessibilityRole="button"
          onPress={() => router.back()}
          style={styles.round}
        >
          <Text style={styles.back}>‹</Text>
        </Pressable>
        <View style={styles.topCenter}>
          <Text style={styles.kicker}>MEGURI</Text>
          <Text style={styles.progress}>{progressText}</Text>
        </View>
        <Pressable
          accessibilityRole="button"
          onPress={() => router.replace("/encounters")}
          style={styles.skipButton}
        >
          <Text style={styles.skipText}>スキップ</Text>
        </Pressable>
      </View>

      <Pressable
        accessibilityRole="button"
        disabled={locked}
        onPress={advance}
        style={[styles.dialogueSlot, { top: topInset + 136 }]}
      >
        {mode === "dialogue" || mode === "done" ? (
          <SpeechBubble
            currentLine={currentLine}
            done={done}
            mode={mode}
            onReadyChange={setBubbleReady}
            partner={active}
            revealSignal={revealSignal}
            threeFailed={threeFailed}
          />
        ) : null}
      </Pressable>

      {showPrimary ? (
        <Pressable
          accessibilityRole="button"
          disabled={locked}
          onPress={advance}
          style={[
            styles.primary,
            { bottom: bottomInset + 14 },
            locked ? styles.primaryDisabled : null,
          ]}
        >
          <Text style={styles.primaryText}>{buttonLabel(mode, introPhase)}</Text>
        </Pressable>
      ) : null}

      {areaUnlock ? (
        <AreaUnlockOverlay unlock={areaUnlock} onContinue={closeAreaUnlock} />
      ) : null}
    </Screen>
  );
}

function createDialogue(partner: MeguriUser, me: MeguriUser): DialogueLine[] {
  return [
    {
      speaker: "partner",
      body: `はじめまして、${partner.name}です。`,
    },
    {
      speaker: "me",
      body: `はじめまして、${me.name}です。`,
    },
    {
      speaker: "partner",
      kind: "area",
      body: `${partner.area}からきました！`,
    },
    {
      speaker: "partner",
      body: partner.hitokoto || pickFallback(partner.id),
    },
    {
      speaker: "me",
      body: me.hitokoto || pickFallback(me.id),
    },
    {
      speaker: "partner",
      kind: "farewell",
      body: pickFarewell(partner.id),
    },
  ];
}

function pickFallback(id: string) {
  const seed = [...id].reduce((sum, char) => sum + char.charCodeAt(0), 0);
  return fallbackHitokoto[seed % fallbackHitokoto.length];
}

function pickFarewell(id: string) {
  const seed = [...id].reduce((sum, char) => sum + char.charCodeAt(0), 0);
  return farewellLines[seed % farewellLines.length];
}

function buttonLabel(mode: MeguriSceneMode, introPhase: MeguriIntroPhase) {
  switch (mode) {
    case "summary":
      return "";
    case "approaching":
      return "";
    case "dialogue":
      return "次へ";
    case "exiting":
      return "広場へ移動中…";
    case "done":
      return "めぐり広場へ";
  }
}

function getSceneHeaderTitle(
  mode: MeguriSceneMode,
  introPhase: MeguriIntroPhase,
  done: boolean,
  count: number,
) {
  if (done || mode === "summary" || mode === "approaching" || mode === "exiting") return null;
  return null;
}

function toSceneResident(user: MeguriUser): MeguriSceneResident {
  return {
    animalType: user.animalType,
    furColor: user.furColor,
    hue: user.hue,
    id: user.id,
    name: user.name,
  };
}

function SpeechBubble({
  currentLine,
  done,
  mode,
  onReadyChange,
  partner,
  revealSignal,
  threeFailed,
}: {
  currentLine: DialogueLine | null;
  done: boolean;
  mode: MeguriSceneMode;
  onReadyChange: (ready: boolean) => void;
  partner: MeguriUser | null;
  revealSignal: number;
  threeFailed: boolean;
}) {
  const bubbleAnim = useRef(new Animated.Value(0)).current;
  const caretAnim = useRef(new Animated.Value(0)).current;
  const handledRevealSignalRef = useRef(revealSignal);
  const showTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const typeIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const typeTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [showText, setShowText] = useState(false);
  const [visibleCount, setVisibleCount] = useState(0);
  const speaker = done
    ? "system"
    : currentLine?.speaker ?? "partner";
  const isMe = speaker === "me";
  const speakerLabel = done
    ? "めぐり広場"
    : isMe
      ? "自分"
      : `@${partner?.id} さん`;
  const body = done
    ? "今日のめぐりが広場に入りました。"
    : currentLine?.body;
  const visibleBody = (body ?? "").slice(0, visibleCount);
  const textComplete = Boolean(body) && visibleCount >= (body ?? "").length;
  const contentKey = `${speaker}:${body}`;

  function clearTypingTimers() {
    if (showTimerRef.current) clearTimeout(showTimerRef.current);
    if (typeTimerRef.current) clearTimeout(typeTimerRef.current);
    if (typeIntervalRef.current) clearInterval(typeIntervalRef.current);
    showTimerRef.current = null;
    typeTimerRef.current = null;
    typeIntervalRef.current = null;
  }

  useEffect(() => {
    clearTypingTimers();
    handledRevealSignalRef.current = revealSignal;
    onReadyChange(false);
    setShowText(false);
    setVisibleCount(0);
    bubbleAnim.setValue(0);
    caretAnim.setValue(0);
    Animated.spring(bubbleAnim, {
      damping: 9,
      mass: 0.8,
      stiffness: 210,
      toValue: 1,
      useNativeDriver: true,
    }).start();
    showTimerRef.current = setTimeout(() => setShowText(true), 210);
    typeTimerRef.current = setTimeout(() => {
      let next = 0;
      typeIntervalRef.current = setInterval(() => {
        next += 1;
        setVisibleCount(next);
        if (next >= (body ?? "").length && typeIntervalRef.current) {
          clearInterval(typeIntervalRef.current);
          typeIntervalRef.current = null;
        }
      }, 34);
    }, 300);
    return clearTypingTimers;
  }, [body, bubbleAnim, caretAnim, contentKey, onReadyChange]);

  useEffect(() => {
    if (
      revealSignal <= 0 ||
      revealSignal === handledRevealSignalRef.current ||
      !body ||
      textComplete
    ) {
      return;
    }
    handledRevealSignalRef.current = revealSignal;
    clearTypingTimers();
    setShowText(true);
    setVisibleCount(body.length);
    onReadyChange(true);
  }, [body, onReadyChange, revealSignal, textComplete]);

  useEffect(() => {
    if (!textComplete) return;
    onReadyChange(true);
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(caretAnim, {
          duration: 460,
          toValue: 1,
          useNativeDriver: true,
        }),
        Animated.timing(caretAnim, {
          duration: 460,
          toValue: 0.22,
          useNativeDriver: true,
        }),
      ]),
    );
    loop.start();
    return () => loop.stop();
  }, [caretAnim, onReadyChange, textComplete]);

  return (
    <View style={styles.speechWrap}>
      {threeFailed ? <Text style={styles.fallbackNote}>2D表示で再生中</Text> : null}
      <Animated.View
        style={[
          styles.speechBubble,
          isMe ? styles.speechBubbleMe : styles.speechBubblePartner,
          {
            opacity: bubbleAnim,
            transform: [
              {
                scale: bubbleAnim.interpolate({
                  inputRange: [0, 1],
                  outputRange: [0.82, 1],
                }),
              },
              {
                translateY: bubbleAnim.interpolate({
                  inputRange: [0, 1],
                  outputRange: [10, 0],
                }),
              },
            ],
          },
        ]}
      >
        {showText ? (
          <>
            <Text style={styles.speaker}>{speakerLabel}</Text>
            <Text style={styles.dialogueText}>{visibleBody}</Text>
            {textComplete ? (
              <Animated.Text
                style={[
                  styles.nextGlyph,
                  {
                    opacity: caretAnim.interpolate({
                      inputRange: [0, 1],
                      outputRange: [0.22, 1],
                    }),
                  },
                ]}
              >
                ▼
              </Animated.Text>
            ) : null}
          </>
        ) : (
          <View style={styles.bubbleTextDelay}>
            <View style={styles.bubbleDot} />
            <View style={[styles.bubbleDot, styles.bubbleDotSecond]} />
            <View style={styles.bubbleDot} />
          </View>
        )}
        <View
          style={[
            styles.bubbleTail,
            isMe ? styles.bubbleTailMe : styles.bubbleTailPartner,
          ]}
        />
      </Animated.View>
    </View>
  );
}

function MeguriSplash({ count }: { count: number }) {
  const appear = useRef(new Animated.Value(0)).current;
  const glow = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.spring(appear, {
      damping: 12,
      mass: 0.9,
      stiffness: 120,
      toValue: 1,
      useNativeDriver: true,
    }).start();
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(glow, {
          duration: 640,
          toValue: 1,
          useNativeDriver: true,
        }),
        Animated.timing(glow, {
          duration: 620,
          toValue: 0,
          useNativeDriver: true,
        }),
      ]),
    );
    loop.start();
    return () => loop.stop();
  }, [appear, glow]);

  return (
    <Animated.View
      pointerEvents="none"
      style={[
        styles.splashOverlay,
        {
          opacity: appear,
          transform: [
            {
              translateY: appear.interpolate({
                inputRange: [0, 1],
                outputRange: [18, 0],
              }),
            },
            {
              scale: appear.interpolate({
                inputRange: [0, 0.64, 1],
                outputRange: [0.76, 1.08, 1],
              }),
            },
          ],
        },
      ]}
    >
      <Animated.View
        style={[
          styles.splashGlow,
          {
            opacity: glow.interpolate({
              inputRange: [0, 1],
              outputRange: [0.2, 0.62],
            }),
            transform: [
              {
                scale: glow.interpolate({
                  inputRange: [0, 1],
                  outputRange: [0.92, 1.06],
                }),
              },
            ],
          },
        ]}
      />
      <Text style={styles.splashCount}>{count}</Text>
      <Text style={styles.splashTitle}>人にめぐりあいました！</Text>
    </Animated.View>
  );
}

function AreaUnlockOverlay({
  onContinue,
  unlock,
}: {
  onContinue: () => void;
  unlock: AreaUnlock;
}) {
  const appear = useRef(new Animated.Value(0)).current;
  const pulse = useRef(new Animated.Value(0)).current;
  const [canContinue, setCanContinue] = useState(false);
  const activeArea = normalizePrefectureName(unlock.area);
  const activePref = MEGURI_MAP_TILES.find((pref) => pref.name === activeArea);
  const activeColor = activePref ? MEGURI_MAP_REGION_COLORS[activePref.region] : ihubColors.lavender;
  const activeWidth = (activePref?.w ?? MEGURI_MAP_TILE_W) * AREA_UNLOCK_MAP_SCALE;
  const activeHeight = (activePref?.h ?? MEGURI_MAP_TILE_H) * AREA_UNLOCK_MAP_SCALE;
  const activeGlowSize = 72 * AREA_UNLOCK_MAP_SCALE;
  const unlockedSet = useMemo(
    () => new Set(unlock.unlockedAreas.map(normalizePrefectureName)),
    [unlock.unlockedAreas],
  );

  useEffect(() => {
    Animated.spring(appear, {
      damping: 13,
      mass: 0.9,
      stiffness: 150,
      toValue: 1,
      useNativeDriver: true,
    }).start();
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, {
          duration: 540,
          toValue: 1,
          useNativeDriver: true,
        }),
        Animated.timing(pulse, {
          duration: 620,
          toValue: 0,
          useNativeDriver: true,
        }),
      ]),
    );
    loop.start();
    const unlockTimer = setTimeout(() => setCanContinue(true), 1000);
    return () => {
      clearTimeout(unlockTimer);
      loop.stop();
    };
  }, [appear, pulse]);

  return (
    <Pressable
      accessibilityRole="button"
      onPress={() => {
        if (canContinue) onContinue();
      }}
      style={styles.areaOverlay}
    >
      <Animated.View
        style={[
          styles.areaUnlockPanel,
          {
            opacity: appear,
            transform: [
              {
                translateY: appear.interpolate({
                  inputRange: [0, 1],
                  outputRange: [22, 0],
                }),
              },
              {
                scale: appear.interpolate({
                  inputRange: [0, 1],
                  outputRange: [0.92, 1],
                }),
              },
            ],
          },
        ]}
      >
        <View style={styles.mapStage}>
          <View style={styles.mapSea} />
          <View
            style={[
              styles.areaMapGrid,
              {
                height: MEGURI_MAP_HEIGHT * AREA_UNLOCK_MAP_SCALE,
                width: MEGURI_MAP_WIDTH * AREA_UNLOCK_MAP_SCALE,
              },
            ]}
          >
            <View
              style={[
                styles.areaMapGuideLine,
                styles.areaMapGuideLineTopLeft,
                scaleAreaMapBox(styles.areaMapGuideLineTopLeft),
              ]}
            />
            <View
              style={[
                styles.areaMapGuideLine,
                styles.areaMapGuideLineOkinawaA,
                scaleAreaMapBox(styles.areaMapGuideLineOkinawaA),
              ]}
            />
            <View
              style={[
                styles.areaMapGuideLine,
                styles.areaMapGuideLineOkinawaB,
                scaleAreaMapBox(styles.areaMapGuideLineOkinawaB),
              ]}
            />
            <View
              style={[
                styles.areaMapGuideLine,
                styles.areaMapGuideLineBottom,
                scaleAreaMapBox(styles.areaMapGuideLineBottom),
              ]}
            />
            {activePref ? (
              <Animated.View
                style={[
                  styles.areaActiveGlow,
                  {
                    backgroundColor: activeColor,
                    height: activeGlowSize,
                    left:
                      activePref.x * AREA_UNLOCK_MAP_SCALE +
                      activeWidth / 2 -
                      activeGlowSize / 2,
                    opacity: pulse.interpolate({
                      inputRange: [0, 1],
                      outputRange: [0.22, 0.72],
                    }),
                    top:
                      activePref.y * AREA_UNLOCK_MAP_SCALE +
                      activeHeight / 2 -
                      activeGlowSize / 2,
                    transform: [
                      {
                        scale: pulse.interpolate({
                          inputRange: [0, 1],
                          outputRange: [0.72, 1.32],
                        }),
                      },
                    ],
                    width: activeGlowSize,
                  },
                ]}
              />
            ) : null}
            {MEGURI_MAP_TILES.map((pref) => {
              const unlocked = unlockedSet.has(pref.name);
              const active = pref.name === activeArea;
              const color = MEGURI_MAP_REGION_COLORS[pref.region];
              const width = pref.w ?? MEGURI_MAP_TILE_W;
              const height = pref.h ?? MEGURI_MAP_TILE_H;
              const labelFontSize = width >= 60 ? 9.8 : height >= 60 ? 9.2 : 8.4;
              return (
                <Animated.View
                  key={pref.name}
                  style={[
                    styles.areaPrefBlock,
                    unlocked ? styles.areaPrefBlockUnlocked : null,
                    !unlocked ? styles.areaPrefBlockLocked : null,
                    {
                      backgroundColor: unlocked
                        ? active
                          ? color
                          : color
                        : "rgba(222,219,230,0.96)",
                      height: height * AREA_UNLOCK_MAP_SCALE,
                      left: pref.x * AREA_UNLOCK_MAP_SCALE,
                      opacity: unlocked ? 1 : 0.74,
                      top: pref.y * AREA_UNLOCK_MAP_SCALE,
                      width: width * AREA_UNLOCK_MAP_SCALE,
                      zIndex: active ? 3 : 1,
                    },
                    active
                      ? {
                          borderColor: "#fff",
                          shadowColor: color,
                          shadowOpacity: 0.72,
                          transform: [
                            {
                              scale: pulse.interpolate({
                                inputRange: [0, 1],
                                outputRange: [1.22, 1.58],
                              }),
                            },
                          ],
                        }
                      : null,
                  ]}
                >
                  <Text
                    adjustsFontSizeToFit
                    minimumFontScale={0.5}
                    numberOfLines={1}
                    style={[
                      styles.areaPrefName,
                      {
                        color: unlocked ? "#fff" : "rgba(58,50,74,0.42)",
                        fontSize: labelFontSize * AREA_UNLOCK_MAP_SCALE,
                      },
                    ]}
                  >
                    {pref.name}
                  </Text>
                </Animated.View>
              );
            })}
          </View>
        </View>
        <Text style={styles.areaEyebrow}>実績解除</Text>
        <Text style={styles.areaTitle}>{displayPrefectureName(activeArea)}の人に初遭遇！</Text>
        <Animated.Text
          style={[
            styles.areaNextGlyph,
            {
              opacity: canContinue
                ? pulse.interpolate({
                    inputRange: [0, 1],
                    outputRange: [0.28, 1],
                  })
                : 0,
            },
          ]}
        >
          ▼
        </Animated.Text>
      </Animated.View>
    </Pressable>
  );
}

function scaleAreaMapBox(box: { height?: number; left?: number; top?: number; width?: number }) {
  return {
    height: typeof box.height === "number" ? Math.max(1, box.height * AREA_UNLOCK_MAP_SCALE) : undefined,
    left: typeof box.left === "number" ? box.left * AREA_UNLOCK_MAP_SCALE : undefined,
    top: typeof box.top === "number" ? box.top * AREA_UNLOCK_MAP_SCALE : undefined,
    width: typeof box.width === "number" ? box.width * AREA_UNLOCK_MAP_SCALE : undefined,
  };
}

function MeguriFallbackScene({
  active,
  completedIds,
  done,
  introPhase,
  residents,
}: {
  active: MeguriUser | null;
  completedIds: string[];
  done: boolean;
  introPhase: MeguriIntroPhase;
  residents: MeguriUser[];
}) {
  const visible =
    introPhase === "splash"
      ? []
      : residents.filter((user) => !completedIds.includes(user.id));

  return (
    <View style={styles.fallbackScene}>
      <View style={styles.fallbackGate}>
        <Text style={styles.fallbackGateText}>広場</Text>
      </View>
      <View style={styles.selfSpot}>
        <WalkingCard user={SELF_USER} size={76} active />
        <Text style={styles.smallLabel}>自分</Text>
      </View>
      <View style={styles.fallbackQueue}>
        {visible.slice(0, 7).map((user, index) => (
          <View
            key={user.id}
            style={[
              styles.fallbackQueueItem,
              {
                bottom: 10 + index * 34,
                right: 10 + Math.min(index, 4) * 7,
                transform: [{ scale: Math.max(0.72, 1 - index * 0.045) }],
                zIndex: 20 - index,
              },
            ]}
          >
            <WalkingCard user={user} size={44} active={user.id === active?.id} />
          </View>
        ))}
      </View>
      {active && !done ? (
        <View style={styles.activeFallback}>
          <WalkingCard user={active} size={94} active />
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    paddingHorizontal: 0,
  },
  loadingRoot: {
    alignItems: "center",
    backgroundColor: "#b9eefa",
    flex: 1,
    justifyContent: "center",
    paddingHorizontal: 0,
  },
  topBar: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    left: 16,
    position: "absolute",
    right: 16,
    zIndex: 10,
  },
  topCenter: {
    alignItems: "center",
    gap: 2,
  },
  round: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.9)",
    borderRadius: 999,
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  back: {
    color: ihubColors.ink,
    fontSize: 34,
    fontWeight: "800",
    lineHeight: 36,
  },
  kicker: {
    color: ihubColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 1.8,
  },
  progress: {
    color: ihubColors.mutedInk,
    fontSize: 13,
    fontWeight: "900",
  },
  skipButton: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.9)",
    borderRadius: 999,
    height: 42,
    justifyContent: "center",
    paddingHorizontal: 14,
  },
  skipText: {
    color: ihubColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  scene: {
    backgroundColor: "#bdefff",
    flex: 1,
    overflow: "hidden",
  },
  splashOverlay: {
    alignItems: "center",
    alignSelf: "center",
    backgroundColor: "rgba(255,255,255,0.9)",
    borderColor: "rgba(22,108,136,0.18)",
    borderRadius: 30,
    borderWidth: 1,
    justifyContent: "center",
    paddingHorizontal: 28,
    paddingVertical: 24,
    position: "absolute",
    top: "27%",
    zIndex: 8,
  },
  splashGlow: {
    backgroundColor: "rgba(255,246,165,0.7)",
    borderRadius: 999,
    bottom: -12,
    left: -18,
    position: "absolute",
    right: -18,
    top: -12,
  },
  splashCount: {
    color: "#16708e",
    fontSize: 72,
    fontWeight: "900",
    letterSpacing: 0,
    lineHeight: 76,
    textShadowColor: "rgba(255,255,255,0.95)",
    textShadowOffset: { height: 3, width: 0 },
    textShadowRadius: 2,
  },
  splashTitle: {
    color: "#166c88",
    fontSize: 24,
    fontWeight: "900",
    lineHeight: 31,
    textAlign: "center",
  },
  sceneHeader: {
    alignItems: "center",
    gap: 4,
    position: "absolute",
    width: "100%",
    zIndex: 2,
  },
  sceneEyebrow: {
    color: "#157a9a",
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 1.6,
    textShadowColor: "rgba(255,255,255,0.9)",
    textShadowOffset: { height: 1, width: 0 },
    textShadowRadius: 2,
  },
  sceneTitle: {
    color: "#166c88",
    fontSize: 25,
    fontWeight: "900",
    lineHeight: 31,
    textAlign: "center",
    textShadowColor: "rgba(255,255,255,0.95)",
    textShadowOffset: { height: 2, width: 0 },
    textShadowRadius: 3,
  },
  stageShell: {
    flex: 1,
  },
  dialogueSlot: {
    left: 16,
    position: "absolute",
    right: 16,
    zIndex: 10,
  },
  speechWrap: {
    alignItems: "stretch",
  },
  speechBubble: {
    backgroundColor: "rgba(255,255,255,0.94)",
    borderColor: "rgba(166,149,216,0.22)",
    borderRadius: 24,
    borderWidth: 1,
    gap: 5,
    minHeight: 116,
    paddingHorizontal: 18,
    paddingVertical: 16,
    position: "relative",
  },
  speechBubbleMe: {
    marginRight: 88,
  },
  speechBubblePartner: {
    marginLeft: 88,
  },
  bubbleTail: {
    borderLeftColor: "transparent",
    borderLeftWidth: 12,
    borderRightColor: "transparent",
    borderRightWidth: 12,
    borderTopColor: "rgba(255,255,255,0.94)",
    borderTopWidth: 16,
    bottom: -15,
    height: 0,
    position: "absolute",
    width: 0,
  },
  bubbleTailMe: {
    left: 58,
  },
  bubbleTailPartner: {
    right: 58,
  },
  bubbleTextDelay: {
    alignItems: "center",
    flexDirection: "row",
    gap: 7,
    minHeight: 82,
    paddingTop: 22,
  },
  bubbleDot: {
    backgroundColor: "rgba(166,149,216,0.62)",
    borderRadius: 999,
    height: 9,
    width: 9,
  },
  bubbleDotSecond: {
    opacity: 0.72,
  },
  speaker: {
    color: ihubColors.lavender,
    fontSize: 13,
    fontWeight: "900",
  },
  dialogueText: {
    color: ihubColors.ink,
    fontSize: 18,
    fontWeight: "900",
    lineHeight: 27,
  },
  nextGlyph: {
    alignSelf: "flex-end",
    color: ihubColors.lavender,
    fontSize: 17,
    fontWeight: "900",
    lineHeight: 18,
    marginTop: 2,
  },
  fallbackNote: {
    alignSelf: "flex-start",
    backgroundColor: hueTint("sky", 0.26),
    borderRadius: 999,
    color: ihubColors.ink,
    fontSize: 11,
    fontWeight: "900",
    marginBottom: 2,
    paddingHorizontal: 9,
    paddingVertical: 4,
  },
  primary: {
    alignItems: "center",
    backgroundColor: ihubColors.lavender,
    borderRadius: 18,
    justifyContent: "center",
    left: 18,
    minHeight: 54,
    position: "absolute",
    right: 18,
    zIndex: 10,
  },
  primaryDisabled: {
    opacity: 0.66,
  },
  primaryText: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "900",
  },
  areaOverlay: {
    alignItems: "center",
    backgroundColor: "rgba(41,48,69,0.18)",
    bottom: 0,
    justifyContent: "center",
    left: 0,
    paddingHorizontal: 22,
    position: "absolute",
    right: 0,
    top: 0,
    zIndex: 30,
  },
  areaUnlockPanel: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.96)",
    borderColor: "rgba(166,149,216,0.24)",
    borderRadius: 28,
    borderWidth: 1,
    paddingBottom: 18,
    paddingHorizontal: 18,
    paddingTop: 18,
    width: "100%",
  },
  mapStage: {
    alignItems: "center",
    borderRadius: 24,
    height: MEGURI_MAP_HEIGHT * AREA_UNLOCK_MAP_SCALE + 16,
    justifyContent: "center",
    marginBottom: 15,
    overflow: "hidden",
    position: "relative",
    width: "100%",
  },
  mapSea: {
    backgroundColor: "rgba(168,212,230,0.26)",
    bottom: 0,
    left: 0,
    position: "absolute",
    right: 0,
    top: 0,
  },
  mapIsland: {
    backgroundColor: "rgba(255,249,232,0.96)",
    borderColor: "rgba(87,76,104,0.08)",
    borderWidth: 1,
    position: "absolute",
    transform: [{ rotate: "-24deg" }],
  },
  mapHokkaido: {
    borderRadius: 26,
    height: 48,
    right: 42,
    top: 22,
    width: 74,
  },
  mapHonshu: {
    borderRadius: 999,
    height: 64,
    right: 44,
    top: 88,
    width: 184,
  },
  mapShikoku: {
    borderRadius: 999,
    bottom: 48,
    height: 28,
    left: 92,
    width: 76,
  },
  mapKyushu: {
    borderRadius: 24,
    bottom: 28,
    height: 64,
    left: 42,
    width: 58,
  },
  areaMapGrid: {
    position: "relative",
  },
  areaActiveGlow: {
    borderRadius: 999,
    position: "absolute",
  },
  areaMapGuideLine: {
    backgroundColor: "rgba(58,50,74,0.13)",
    position: "absolute",
  },
  areaMapGuideLineTopLeft: {
    height: 1,
    left: 58,
    top: 40,
    transform: [{ rotate: "48deg" }],
    width: 92,
  },
  areaMapGuideLineOkinawaA: {
    height: 1.5,
    left: 0,
    top: 268,
    width: 46,
  },
  areaMapGuideLineOkinawaB: {
    height: 1.5,
    left: 32,
    top: 248,
    transform: [{ rotate: "-49deg" }],
    width: 72,
  },
  areaMapGuideLineBottom: {
    height: 1,
    left: 56,
    top: 520,
    transform: [{ rotate: "-48deg" }],
    width: 80,
  },
  areaPrefBlock: {
    alignItems: "center",
    borderColor: "rgba(255,255,255,0.9)",
    borderRadius: 3.5,
    borderWidth: 1,
    justifyContent: "center",
    position: "absolute",
    shadowColor: "#3a324a",
    shadowOffset: { height: 2, width: 0 },
    shadowOpacity: 0.07,
    shadowRadius: 8,
  },
  areaPrefBlockUnlocked: {
    borderColor: "#fff",
    shadowOpacity: 0.16,
  },
  areaPrefBlockLocked: {
    borderColor: "rgba(255,255,255,0.78)",
    shadowOpacity: 0.02,
  },
  areaPrefName: {
    fontWeight: "900",
    textAlign: "center",
  },
  areaGlow: {
    borderRadius: 999,
    height: 68,
    position: "absolute",
    width: 68,
  },
  areaPin: {
    borderColor: "rgba(255,255,255,0.95)",
    borderRadius: 999,
    borderWidth: 3,
    height: 18,
    marginLeft: -9,
    marginTop: -9,
    position: "absolute",
    shadowColor: "rgba(58,50,74,0.2)",
    shadowOffset: { height: 3, width: 0 },
    shadowOpacity: 1,
    shadowRadius: 6,
    width: 18,
  },
  areaEyebrow: {
    color: ihubColors.lavender,
    fontSize: 13,
    fontWeight: "900",
    letterSpacing: 1.2,
    marginBottom: 6,
  },
  areaTitle: {
    color: ihubColors.ink,
    fontSize: 24,
    fontWeight: "900",
    lineHeight: 31,
    textAlign: "center",
  },
  areaBody: {
    color: ihubColors.mutedInk,
    fontSize: 15,
    fontWeight: "900",
    lineHeight: 22,
    marginTop: 8,
    textAlign: "center",
  },
  areaName: {
    color: ihubColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    marginTop: 4,
  },
  areaNextGlyph: {
    color: ihubColors.lavender,
    fontSize: 18,
    fontWeight: "900",
    height: 20,
    lineHeight: 20,
    marginTop: 8,
  },
  fallbackScene: {
    flex: 1,
    justifyContent: "center",
    position: "relative",
  },
  fallbackGate: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.78)",
    borderColor: "rgba(166,149,216,0.34)",
    borderRadius: 24,
    borderWidth: 2,
    height: 118,
    justifyContent: "center",
    left: 12,
    position: "absolute",
    top: 120,
    width: 104,
  },
  fallbackGateText: {
    color: ihubColors.lavender,
    fontSize: 14,
    fontWeight: "900",
  },
  selfSpot: {
    alignItems: "center",
    bottom: 188,
    left: 24,
    position: "absolute",
  },
  smallLabel: {
    color: ihubColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
    marginTop: 4,
  },
  fallbackQueue: {
    bottom: 170,
    height: 280,
    position: "absolute",
    right: 0,
    width: 150,
  },
  fallbackQueueItem: {
    position: "absolute",
    width: 46,
  },
  activeFallback: {
    alignItems: "center",
    bottom: 194,
    left: 72,
    position: "absolute",
  },
});
