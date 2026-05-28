import { useState } from "react";
import { router } from "expo-router";
import { Linking, Pressable, StyleSheet, Text, View } from "react-native";
import { RouteHeader } from "../src/components/RouteHeader";
import { Screen } from "../src/components/Screen";
import { IconSymbol, type IconSymbolName } from "../src/components/IconSymbol";
import { megrumColors, megrumRadii } from "../src/theme/tokens";

const FAQ_SECTIONS = [
  {
    label: "取引の流れ",
    items: [
      {
        q: "Megrumとは？",
        a: "K-POP / アニメ等の推し活グッズを現地で物々交換するためのマッチング・取引プラットフォームです。",
      },
      {
        q: "取引の基本フロー",
        a: "ホームでマッチを探す、相手に打診を送る、合意後に取引チャットへ進む、当日交換して証跡を撮影、双方承認で完了します。",
      },
      {
        q: "現地モードとは？",
        a: "近くで今交換できそうな相手を探すモードです。OFFでは距離を問わず譲とWishの一致を探します。",
      },
    ],
  },
  {
    label: "マッチング・打診",
    items: [
      {
        q: "個別募集とは？",
        a: "複数グッズをセット交換、いずれかOKなど条件付きで募集できる機能です。具体的な条件マッチに使います。",
      },
      {
        q: "ネゴと打診の違い",
        a: "打診は最初の提案、ネゴは送信後に条件を相談するやりとりです。両者が合意すると取引予定に進みます。",
      },
    ],
  },
  {
    label: "取引・申告",
    items: [
      {
        q: "取引証跡とは？",
        a: "当日交換時に、受け取ったグッズが揃っていることを確認するための写真です。申告時の証拠にもなります。",
      },
      {
        q: "相違ありの場合",
        a: "取引完了確認で相違ありを選ぶと申告フォームに進みます。相手が来なかった、グッズが違う等を運営へ報告できます。",
      },
    ],
  },
];

export default function HelpScreen() {
  return (
    <Screen contentStyle={styles.screen}>
      <RouteHeader title="ヘルプ・FAQ" subtitle="使い方・取引の流れ・よくある質問" />

      <View style={styles.contactHero}>
        <Text style={styles.contactTitle}>お困りの場合は運営に直接ご連絡ください</Text>
        <Text style={styles.contactText}>
          FAQにない内容や、取引のトラブルなどは下記の窓口から受け付けています。
        </Text>
        <Pressable
          accessibilityRole="button"
          onPress={() => Linking.openURL("mailto:support@megrum.jp")}
          style={styles.mailButton}
        >
          <IconSymbol name="mail-outline" size={15} color="#fff" />
          <Text style={styles.mailText}>support@megrum.jp</Text>
        </Pressable>
      </View>

      {FAQ_SECTIONS.map((section) => (
        <View key={section.label} style={styles.section}>
          <Text style={styles.sectionLabel}>{section.label}</Text>
          <View style={styles.sectionCard}>
            {section.items.map((item) => (
              <FaqRow key={item.q} answer={item.a} question={item.q} />
            ))}
          </View>
        </View>
      ))}

      <View style={styles.section}>
        <Text style={styles.sectionLabel}>規約・ポリシー</Text>
        <View style={styles.sectionCard}>
          <LinkRow title="利用規約" icon="document-text-outline" href="/legal/terms" />
          <LinkRow title="プライバシーポリシー" icon="lock-closed-outline" href="/legal/privacy" />
          <LinkRow title="特定商取引法に基づく表記" icon="receipt-outline" href="/legal/notice" />
        </View>
      </View>
    </Screen>
  );
}

function FaqRow({ answer, question }: { answer: string; question: string }) {
  const [open, setOpen] = useState(false);
  return (
    <Pressable
      accessibilityRole="button"
      onPress={() => setOpen((current) => !current)}
      style={styles.faqRow}
    >
      <View style={styles.faqTop}>
        <View style={styles.qBadge}>
          <Text style={styles.qBadgeText}>Q</Text>
        </View>
        <Text style={styles.question}>{question}</Text>
        <IconSymbol
          name={open ? "chevron-down" : "chevron-forward"}
          size={14}
          color={megrumColors.mutedInk}
        />
      </View>
      {open ? <Text style={styles.answer}>{answer}</Text> : null}
    </Pressable>
  );
}

function LinkRow({
  href,
  icon,
  title,
}: {
  href: string;
  icon: IconSymbolName;
  title: string;
}) {
  return (
    <Pressable accessibilityRole="button" onPress={() => router.push(href)} style={styles.linkRow}>
      <IconSymbol name={icon} size={17} color={megrumColors.lavender} />
      <Text style={styles.linkTitle}>{title}</Text>
      <IconSymbol name="chevron-forward" size={14} color={megrumColors.mutedInk} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  screen: {
    gap: 16,
  },
  contactHero: {
    backgroundColor: "rgba(166,149,216,0.08)",
    borderColor: "rgba(166,149,216,0.24)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    padding: 14,
  },
  contactTitle: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "900",
  },
  contactText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "700",
    lineHeight: 17,
    marginTop: 5,
  },
  mailButton: {
    alignItems: "center",
    alignSelf: "flex-start",
    backgroundColor: megrumColors.lavender,
    borderRadius: 10,
    flexDirection: "row",
    gap: 6,
    marginTop: 10,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  mailText: {
    color: megrumColors.surface,
    fontSize: 11.5,
    fontWeight: "900",
  },
  section: {
    gap: 7,
  },
  sectionLabel: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "900",
    letterSpacing: 0.4,
    paddingHorizontal: 2,
  },
  sectionCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    overflow: "hidden",
  },
  faqRow: {
    borderBottomColor: "rgba(58,50,74,0.05)",
    borderBottomWidth: 1,
    paddingHorizontal: 14,
    paddingVertical: 13,
  },
  faqTop: {
    alignItems: "center",
    flexDirection: "row",
    gap: 9,
  },
  qBadge: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.16)",
    borderRadius: megrumRadii.pill,
    height: 22,
    justifyContent: "center",
    width: 22,
  },
  qBadgeText: {
    color: megrumColors.lavender,
    fontSize: 10,
    fontWeight: "900",
  },
  question: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 12.5,
    fontWeight: "900",
  },
  answer: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "700",
    lineHeight: 19,
    paddingLeft: 31,
    paddingTop: 8,
  },
  linkRow: {
    alignItems: "center",
    borderBottomColor: "rgba(58,50,74,0.05)",
    borderBottomWidth: 1,
    flexDirection: "row",
    gap: 10,
    paddingHorizontal: 14,
    paddingVertical: 14,
  },
  linkTitle: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 12.5,
    fontWeight: "900",
  },
});
