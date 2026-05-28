import { router, useLocalSearchParams } from "expo-router";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { PrimaryButton } from "../src/components/PrimaryButton";
import { Screen } from "../src/components/Screen";
import { StatusPill } from "../src/components/StatusPill";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

type DetailKind = "match" | "transaction" | "profile" | "generic";

export default function PreviewDetailScreen() {
  const params = useLocalSearchParams<{
    title?: string | string[];
    subtitle?: string | string[];
    badge?: string | string[];
    kind?: DetailKind | DetailKind[];
    tone?: string | string[];
  }>();
  const title = one(params.title) || "詳細";
  const subtitle = one(params.subtitle) || "この導線の詳細画面を準備しています。";
  const badge = one(params.badge) || "PREVIEW";
  const kind = (one(params.kind) as DetailKind | "") || "generic";

  return (
    <Screen contentStyle={styles.screen}>
      <View style={styles.header}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="戻る"
          onPress={() => router.back()}
          style={styles.backButton}
        >
          <Text style={styles.backText}>‹</Text>
        </Pressable>
        <StatusPill label={badge} tone={kind === "transaction" ? "sky" : "lavender"} />
      </View>

      <View style={styles.hero}>
        <View style={styles.heroAuraPink} />
        <View style={styles.heroAuraSky} />
        <View style={styles.icon}>
          <Text style={styles.iconText}>{title.slice(0, 1)}</Text>
        </View>
        <Text style={styles.title}>{title}</Text>
        <Text style={styles.subtitle}>{subtitle}</Text>
      </View>

      <View style={styles.panel}>
        <Text style={styles.panelTitle}>{sectionTitle(kind)}</Text>
        {detailRows(kind).map((row) => (
          <View key={row.label} style={styles.detailRow}>
            <View style={styles.detailDot} />
            <View style={styles.detailCopy}>
              <Text style={styles.detailLabel}>{row.label}</Text>
              <Text style={styles.detailText}>{row.text}</Text>
            </View>
          </View>
        ))}
      </View>

      <PrimaryButton
        onPress={() => {
          if (router.canGoBack()) {
            router.back();
          }
        }}
      >
        戻る
      </PrimaryButton>
    </Screen>
  );
}

function one(value?: string | string[]) {
  if (Array.isArray(value)) {
    return value[0];
  }
  return value;
}

function sectionTitle(kind: DetailKind) {
  if (kind === "match") return "次の選択へつなぐ";
  if (kind === "transaction") return "取引の確認";
  if (kind === "profile") return "プロフィール導線";
  return "詳細";
}

function detailRows(kind: DetailKind) {
  if (kind === "match") {
    return [
      {
        label: "選んだグッズ",
        text: "ホームで押したカードを起点に、関係図または提示物の選択へ進めます。",
      },
      {
        label: "個別募集判定",
        text: "個別募集に含まれる場合だけ関係図へ、それ以外は次の選択画面へ進む想定です。",
      },
    ];
  }

  if (kind === "transaction") {
    return [
      {
        label: "要対応",
        text: "返信、合意、チャットなど、いま必要な操作をこの画面に集約します。",
      },
      {
        label: "待ち合わせ",
        text: "成立後も同じ流れで、場所・時間・当日の合流を確認できるようにします。",
      },
    ];
  }

  if (kind === "profile") {
    return [
      {
        label: "右スライド",
        text: "プロフィール編集、推し設定、スケジュールを同じ遷移文法で開きます。",
      },
      {
        label: "次の実装",
        text: "各画面の入力UIと保存処理を、Web版の仕様に合わせて本体化します。",
      },
    ];
  }

  return [
    {
      label: "プレビュー",
      text: "ここから詳細画面を増やしていきます。",
    },
  ];
}

const styles = StyleSheet.create({
  screen: {
    gap: 16,
  },
  header: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  backButton: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    height: 44,
    justifyContent: "center",
    width: 44,
    ...megrumShadow,
  },
  backText: {
    color: megrumColors.ink,
    fontSize: 32,
    fontWeight: "700",
    lineHeight: 34,
  },
  hero: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.20)",
    borderRadius: 28,
    borderWidth: 1,
    minHeight: 260,
    overflow: "hidden",
    padding: 22,
    ...megrumShadow,
  },
  heroAuraPink: {
    backgroundColor: "rgba(243,197,212,0.50)",
    borderRadius: 999,
    height: 150,
    position: "absolute",
    right: -48,
    top: -46,
    width: 150,
  },
  heroAuraSky: {
    backgroundColor: "rgba(168,212,230,0.42)",
    borderRadius: 999,
    bottom: -62,
    height: 168,
    left: -58,
    position: "absolute",
    width: 168,
  },
  icon: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderColor: "rgba(255,255,255,0.86)",
    borderRadius: 30,
    borderWidth: 2,
    height: 70,
    justifyContent: "center",
    marginTop: 8,
    width: 70,
  },
  iconText: {
    color: megrumColors.surface,
    fontSize: 26,
    fontWeight: "900",
  },
  title: {
    color: megrumColors.ink,
    fontSize: 27,
    fontWeight: "900",
    marginTop: 18,
    textAlign: "center",
  },
  subtitle: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "800",
    lineHeight: 20,
    marginTop: 8,
    textAlign: "center",
  },
  panel: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 14,
    padding: 16,
  },
  panelTitle: {
    color: megrumColors.ink,
    fontSize: 16,
    fontWeight: "900",
  },
  detailRow: {
    flexDirection: "row",
    gap: 10,
  },
  detailDot: {
    backgroundColor: megrumColors.sky,
    borderRadius: 999,
    height: 9,
    marginTop: 5,
    width: 9,
  },
  detailCopy: {
    flex: 1,
    gap: 3,
  },
  detailLabel: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  detailText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
  },
});
