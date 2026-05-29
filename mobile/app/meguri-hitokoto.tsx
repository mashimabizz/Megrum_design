import { Pressable, StyleSheet, Text, TextInput, View } from "react-native";
import { router } from "expo-router";
import { useEffect, useState } from "react";
import { Screen } from "../src/components/Screen";
import { RouteHeader } from "../src/components/RouteHeader";
import { IconSymbol } from "../src/components/IconSymbol";
import { megrumColors, megrumShadow } from "../src/theme/tokens";
import { USERS, WalkingCard, hueTint } from "./(tabs)/encounters";
import {
  DEFAULT_MEGURI_PROFILE,
  loadMeguriProfileSettings,
  saveMeguriProfileSettings,
} from "../src/lib/meguriSettings";

const HISTORY = [
  { prompt: "今日の現場テンションは？", answer: "千秋楽前で胸がいっぱい", when: "昨日" },
  { prompt: "推しを好きになったきっかけは？", answer: "去年のフェスの映像", when: "3日前" },
  { prompt: "今いちばん探しているものは？", answer: "東京2023のトレカ", when: "1週間前" },
];

export default function MeguriHitokotoScreen() {
  const user = USERS[0];
  const [promptIndex, setPromptIndex] = useState(0);
  const [answer, setAnswer] = useState(DEFAULT_MEGURI_PROFILE.hitokoto);
  const [savedDraft, setSavedDraft] = useState(false);
  const currentPrompt = HITOKOTO_PROMPTS[promptIndex % HITOKOTO_PROMPTS.length];

  useEffect(() => {
    loadMeguriProfileSettings()
      .then((settings) => setAnswer(settings.hitokoto || DEFAULT_MEGURI_PROFILE.hitokoto))
      .catch(() => undefined);
  }, []);

  async function saveCard() {
    const current = await loadMeguriProfileSettings();
    await saveMeguriProfileSettings({ ...current, hitokoto: answer });
    router.back();
  }

  async function saveDraft() {
    const current = await loadMeguriProfileSettings();
    await saveMeguriProfileSettings({ ...current, hitokoto: answer });
    setSavedDraft(true);
  }

  return (
    <Screen contentStyle={styles.screen}>
      <RouteHeader title="今日のひとこと" subtitle="めぐりあった人に見える短い自己紹介" />

      <View style={styles.prompt}>
        <Text style={styles.kicker}>今日のお題</Text>
        <Text style={styles.title}>{currentPrompt}</Text>
        <Text style={styles.body}>この答えが、めぐりあった人へのあなたのひとことになります。</Text>
      </View>

      <View style={styles.editorCard}>
        <TextInput
          maxLength={60}
          multiline
          onChangeText={setAnswer}
          onFocus={() => setSavedDraft(false)}
          placeholder="気軽に書いて大丈夫です…"
          placeholderTextColor="rgba(58,50,74,0.35)"
          style={styles.input}
          value={answer}
        />
        <View style={styles.inputFooter}>
          <Text style={styles.counter}>{answer.length} / 60 文字</Text>
          <Pressable onPress={() => setPromptIndex((current) => current + 1)} style={styles.promptButton}>
            <IconSymbol name="sparkles-outline" color={megrumColors.ink} size={13} />
            <Text style={styles.promptButtonText}>お題を変える</Text>
          </Pressable>
        </View>
      </View>

      <Text style={styles.sectionTitle}>あなたのカードのプレビュー</Text>
      <View style={styles.preview}>
        <WalkingCard user={user} size={82} active />
        <View style={styles.previewBubble}>
          <Text style={styles.previewKicker}>ひとこと</Text>
          <Text style={styles.previewText}>「{answer}」</Text>
        </View>
      </View>

      <Text style={styles.sectionTitle}>これまでのひとこと</Text>
      <View style={styles.historyList}>
        {HISTORY.map((item) => (
          <Pressable
            key={item.prompt}
            onPress={() => {
              setAnswer(item.answer);
              setSavedDraft(false);
            }}
            style={styles.historyItem}
          >
            <Text style={styles.historyPrompt}>
              {item.prompt} <Text style={styles.historyWhen}>· {item.when}</Text>
            </Text>
            <Text style={styles.historyAnswer}>「{item.answer}」</Text>
          </Pressable>
        ))}
      </View>

      <View style={styles.actions}>
        <Pressable onPress={saveDraft} style={styles.secondary}>
          <Text style={styles.secondaryText}>{savedDraft ? "保存しました" : "下書きに保存"}</Text>
        </Pressable>
        <Pressable onPress={saveCard} style={styles.primary}>
          <Text style={styles.primaryText}>カードを更新</Text>
        </Pressable>
      </View>

      <Text style={styles.safety}>住所・本名・連絡先・SNSアカウントは書かないでください。</Text>
    </Screen>
  );
}

const HITOKOTO_PROMPTS = [
  "最近の推し活は？",
  "今日いちばん語りたいことは？",
  "今探しているグッズは？",
  "次の現場で楽しみにしていることは？",
];

const styles = StyleSheet.create({
  screen: { gap: 15 },
  prompt: {
    backgroundColor: hueTint("pink", 0.2),
    borderRadius: 26,
    padding: 22,
    ...megrumShadow,
  },
  kicker: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 1.8,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 25,
    fontWeight: "900",
    lineHeight: 32,
    marginTop: 7,
  },
  body: {
    color: megrumColors.mutedInk,
    fontSize: 12.5,
    fontWeight: "800",
    lineHeight: 19,
    marginTop: 8,
  },
  editorCard: {
    backgroundColor: "#fff",
    borderRadius: 24,
    padding: 16,
    ...megrumShadow,
  },
  input: {
    backgroundColor: "#fff",
    borderColor: "rgba(166,149,216,0.22)",
    borderRadius: 18,
    borderWidth: 1,
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "800",
    minHeight: 96,
    padding: 14,
    textAlignVertical: "top",
  },
  inputFooter: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    marginTop: 10,
  },
  counter: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
  },
  promptButton: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.7)",
    borderColor: "rgba(58,50,74,0.1)",
    borderRadius: 999,
    borderWidth: 1,
    flexDirection: "row",
    gap: 5,
    paddingHorizontal: 11,
    paddingVertical: 7,
  },
  promptButtonText: {
    color: megrumColors.ink,
    fontSize: 11.5,
    fontWeight: "900",
  },
  sectionTitle: {
    color: megrumColors.ink,
    fontSize: 16,
    fontWeight: "900",
    paddingHorizontal: 6,
  },
  preview: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: 24,
    flexDirection: "row",
    gap: 14,
    padding: 18,
    ...megrumShadow,
  },
  previewBubble: {
    backgroundColor: hueTint("lav", 0.18),
    borderRadius: 18,
    flex: 1,
    padding: 14,
  },
  previewKicker: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0.6,
  },
  previewText: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "800",
    lineHeight: 21,
    marginTop: 4,
  },
  historyList: {
    gap: 8,
  },
  historyItem: {
    backgroundColor: "#fff",
    borderRadius: 16,
    padding: 13,
  },
  historyPrompt: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
  },
  historyWhen: {
    fontWeight: "700",
  },
  historyAnswer: {
    color: megrumColors.ink,
    fontSize: 13.5,
    fontWeight: "900",
    marginTop: 5,
  },
  actions: {
    flexDirection: "row",
    gap: 9,
  },
  secondary: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderColor: "rgba(166,149,216,0.22)",
    borderRadius: 999,
    borderWidth: 1,
    flex: 1,
    paddingVertical: 14,
  },
  secondaryText: {
    color: megrumColors.ink,
    fontSize: 13.5,
    fontWeight: "900",
  },
  primary: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 999,
    flex: 1,
    paddingVertical: 14,
  },
  primaryText: {
    color: "#fff",
    fontSize: 13.5,
    fontWeight: "900",
  },
  safety: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 18,
    textAlign: "center",
  },
});
