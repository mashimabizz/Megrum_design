import { useEffect, useState } from "react";
import { Alert, Pressable, StyleSheet, Text, View } from "react-native";
import { IconSymbol } from "../src/components/IconSymbol";
import { Screen } from "../src/components/Screen";
import { RouteHeader } from "../src/components/RouteHeader";
import { ihubColors, ihubShadow } from "../src/theme/tokens";
import { useAuth } from "../src/auth/AuthProvider";
import { MONTHLY_PRICE, PLUS_SEND_LIMIT, FREE_SEND_LIMIT, hueTint } from "./(tabs)/encounters";
import {
  loadMeguriPlusState,
  saveMeguriPlusReviewOverride,
} from "../src/lib/meguriPlus";
import { requestMeguriPlusStorePurchase } from "../src/lib/meguriPlusPurchase";

const FEATURES = [
  { title: "届いたメッセージを表示", sub: "本文を読めるようになります", icon: "mail-outline" as const },
  { title: "メッセージに返信できる", sub: "ゆっくり会話を続けられます", icon: "create-outline" as const },
  { title: `送信枠が月${PLUS_SEND_LIMIT}通に`, sub: `${FREE_SEND_LIMIT}通から${PLUS_SEND_LIMIT}通へ拡張`, icon: "sparkles-outline" as const },
  { title: "めぐりカードの深掘り", sub: "プロフ・推し履歴・再めぐり履歴", icon: "document-text-outline" as const },
  { title: "めぐり履歴の振り返り", sub: "12ヶ月まで保存", icon: "time-outline" as const },
  { title: "マップの詳細分析", sub: "地方・時期・推しジャンル別", icon: "search" as const },
];

export default function MeguriPlusScreen() {
  const { profile } = useAuth();
  const [picked, setPicked] = useState<"monthly" | "free">("monthly");
  const [savedActive, setSavedActive] = useState(false);
  const [canUseReviewToggle, setCanUseReviewToggle] = useState(false);
  const [purchaseLoading, setPurchaseLoading] = useState(false);

  useEffect(() => {
    loadMeguriPlusState(profile)
      .then((settings) => {
        setSavedActive(settings.active);
        setCanUseReviewToggle(settings.canUseReviewToggle);
        setPicked(settings.active ? "monthly" : "free");
      })
      .catch(() => undefined);
  }, [profile?.handle]);

  async function applyPlan() {
    if (!canUseReviewToggle) {
      setPurchaseLoading(true);
      try {
        await requestMeguriPlusStorePurchase();
      } catch (error) {
        const message = error instanceof Error ? error.message : "購入を開始できませんでした";
        Alert.alert("めぐりPlus", message);
      } finally {
        setPurchaseLoading(false);
      }
      return;
    }
    const active = !savedActive;
    const saved = await saveMeguriPlusReviewOverride(profile, active);
    if (!saved) return;
    setSavedActive(active);
    setPicked(active ? "monthly" : "free");
  }

  return (
    <Screen contentStyle={styles.screen}>
      <RouteHeader title="めぐりPlus" subtitle="MEMBERSHIP" />

      <View style={styles.hero}>
        <Text style={styles.kicker}>MEGURI · PLUS</Text>
        <Text style={styles.heroTitle}>めぐりを、{"\n"}もう少し近くへ。</Text>
        <Text style={styles.heroText}>
          めぐりあった誰かから届いたメッセージを読んだり、返信したり。今日の巡り合いを、あとから大切に振り返れます。
        </Text>
      </View>

      <View style={styles.plans}>
        <PlanRow
          picked={picked === "monthly"}
          title="月額 めぐりPlus"
          price={`¥${MONTHLY_PRICE.toLocaleString()}`}
          unit="/ 月"
          note="いつでも解約できます"
          recommended
          onPress={() => setPicked("monthly")}
        />
        <PlanRow
          picked={picked === "free"}
          title="今は無料のまま"
          price="¥0"
          unit=""
          note={`めぐり・広場・送信枠 月${FREE_SEND_LIMIT}通 は無料`}
          onPress={() => setPicked("free")}
        />
      </View>

      <View style={styles.statusCard}>
        <IconSymbol
          name={savedActive ? "checkmark-circle-outline" : "lock-closed-outline"}
          color={savedActive ? "#27a06b" : ihubColors.lavender}
          size={18}
        />
        <Text style={styles.statusText}>
          {savedActive
            ? `めぐりPlusが有効です。届いた本文の開封と${FREE_SEND_LIMIT + 1}通目以降の送信ができます。`
            : `現在はFreeです。本文の開封と${FREE_SEND_LIMIT + 1}通目以降の送信はめぐりPlusで使えます。`}
        </Text>
      </View>

      <Text style={styles.sectionTitle}>めぐりPlus でできること</Text>
      <View style={styles.featureList}>
        {FEATURES.map((feature) => (
          <View key={feature.title} style={styles.featureRow}>
            <View style={styles.featureIcon}>
              <IconSymbol name={feature.icon} color={ihubColors.lavender} size={18} />
            </View>
            <View style={styles.featureCopy}>
              <Text style={styles.featureTitle}>{feature.title}</Text>
              <Text style={styles.featureSub}>{feature.sub}</Text>
            </View>
          </View>
        ))}
      </View>

      <Pressable onPress={applyPlan} style={styles.primary}>
        <Text style={styles.primaryText}>
          {canUseReviewToggle
            ? !savedActive
              ? "めぐりPlus会員に切り替える"
              : "無料会員に切り替える"
            : purchaseLoading
              ? "App Storeを開いています"
              : "App Storeで始める"}
        </Text>
      </Pressable>
      {canUseReviewToggle ? (
        <Text style={styles.note}>
          michilion 開発レビュー用の切り替えです。本番課金・他アカウントには表示しません。
        </Text>
      ) : null}
      <Text style={styles.note}>
        無料体験はありません。単発の本文表示チケットは取り扱っていません。解約は設定からいつでもできます。
      </Text>
    </Screen>
  );
}

function PlanRow({
  note,
  onPress,
  picked,
  price,
  recommended,
  title,
  unit,
}: {
  note: string;
  onPress: () => void;
  picked: boolean;
  price: string;
  recommended?: boolean;
  title: string;
  unit: string;
}) {
  return (
    <Pressable onPress={onPress} style={[styles.planRow, picked ? styles.planRowPicked : null]}>
      <View style={[styles.radio, picked ? styles.radioPicked : null]} />
      <View style={styles.planCopy}>
        <View style={styles.planTitleRow}>
          <Text style={styles.planTitle}>{title}</Text>
          {recommended ? <Text style={styles.recommended}>おすすめ</Text> : null}
        </View>
        <Text style={styles.planNote}>{note}</Text>
      </View>
      <View style={styles.priceCopy}>
        <Text style={styles.price}>{price}</Text>
        {unit ? <Text style={styles.unit}>{unit}</Text> : null}
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  screen: { gap: 16 },
  hero: {
    backgroundColor: "#e7d8f7",
    borderRadius: 30,
    overflow: "hidden",
    padding: 26,
    ...ihubShadow,
  },
  kicker: {
    color: ihubColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 1.7,
  },
  heroTitle: {
    color: ihubColors.ink,
    fontSize: 30,
    fontWeight: "900",
    lineHeight: 38,
    marginTop: 10,
  },
  heroText: {
    color: ihubColors.ink,
    fontSize: 14,
    fontWeight: "800",
    lineHeight: 23,
    marginTop: 12,
    opacity: 0.72,
  },
  plans: {
    gap: 10,
  },
  statusCard: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderColor: "rgba(166,149,216,0.18)",
    borderRadius: 18,
    borderWidth: 1,
    flexDirection: "row",
    gap: 9,
    padding: 13,
  },
  statusText: {
    color: ihubColors.ink,
    flex: 1,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
  },
  planRow: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.64)",
    borderColor: "rgba(58,50,74,0.1)",
    borderRadius: 20,
    borderWidth: 1.5,
    flexDirection: "row",
    gap: 12,
    padding: 16,
  },
  planRowPicked: {
    backgroundColor: "#fff",
    borderColor: ihubColors.lavender,
    shadowColor: ihubColors.lavender,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.18,
    shadowRadius: 14,
  },
  radio: {
    borderColor: "rgba(58,50,74,0.16)",
    borderRadius: 999,
    borderWidth: 2,
    height: 22,
    width: 22,
  },
  radioPicked: {
    backgroundColor: "#fff",
    borderColor: ihubColors.lavender,
    borderWidth: 7,
  },
  planCopy: {
    flex: 1,
  },
  planTitleRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
  },
  planTitle: {
    color: ihubColors.ink,
    fontSize: 16.5,
    fontWeight: "900",
  },
  recommended: {
    backgroundColor: hueTint("pink", 0.32),
    borderRadius: 999,
    color: "#b34a6e",
    fontSize: 10,
    fontWeight: "900",
    overflow: "hidden",
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  planNote: {
    color: ihubColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    marginTop: 3,
  },
  priceCopy: {
    alignItems: "flex-end",
  },
  price: {
    color: ihubColors.ink,
    fontSize: 22,
    fontWeight: "900",
  },
  unit: {
    color: ihubColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
  },
  sectionTitle: {
    color: ihubColors.ink,
    fontSize: 18,
    fontWeight: "900",
    paddingHorizontal: 6,
  },
  featureList: {
    gap: 10,
  },
  featureRow: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: 18,
    flexDirection: "row",
    gap: 14,
    padding: 13,
  },
  featureIcon: {
    alignItems: "center",
    backgroundColor: hueTint("lav", 0.18),
    borderRadius: 13,
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  featureCopy: {
    flex: 1,
  },
  featureTitle: {
    color: ihubColors.ink,
    fontSize: 14.5,
    fontWeight: "900",
  },
  featureSub: {
    color: ihubColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    marginTop: 2,
  },
  primary: {
    alignItems: "center",
    backgroundColor: ihubColors.lavender,
    borderRadius: 999,
    paddingVertical: 16,
  },
  primaryText: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "900",
  },
  note: {
    color: ihubColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 18,
    textAlign: "center",
  },
});
