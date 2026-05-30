import { useMemo, useState } from "react";
import { router } from "expo-router";
import { Pressable, StyleSheet, Text, TextInput, View } from "react-native";
import { Screen } from "../src/components/Screen";
import { useAuth } from "../src/auth/AuthProvider";
import { IconSymbol, type IconSymbolName } from "../src/components/IconSymbol";
import { megrumColors, megrumRadii } from "../src/theme/tokens";

type SettingsRow = {
  description: string;
  href?: Parameters<typeof router.push>[0];
  icon: IconSymbolName;
  title: string;
};

const PRIMARY_SETTINGS_ROWS: SettingsRow[] = [
  {
    title: "セキュリティとログイン",
    description: "メールアドレスでのログインやパスワード再設定を管理します。",
    icon: "lock-closed-outline",
    href: "/password-reset",
  },
  {
    title: "通知",
    description: "打診、取引チャット、現地交換モードの通知を調整します。",
    icon: "notifications-outline",
    href: "/notification-settings",
  },
  {
    title: "住所設定",
    description: "郵送交換で使う宛名・住所・電話番号を管理します。",
    icon: "mail-outline",
    href: "/address-settings",
  },
  {
    title: "ブロックした人",
    description: "ブロック中のユーザーを確認し、必要に応じて解除します。",
    icon: "ban-outline",
    href: "/blocked-users",
  },
  {
    title: "ヘルプ",
    description: "使い方、FAQ、問い合わせ先を確認します。",
    icon: "mail-outline",
    href: "/help",
  },
];

const LEGAL_SETTINGS_ROWS: SettingsRow[] = [
  {
    title: "利用規約",
    description: "Megrumの利用条件、禁止事項、取引時の責任範囲を確認します。",
    icon: "document-text-outline",
    href: "/legal/terms",
  },
  {
    title: "プライバシーポリシー",
    description: "Megrumで扱う情報、公開範囲、データの利用方針を確認します。",
    icon: "shield-checkmark-outline",
    href: "/legal/privacy",
  },
  {
    title: "特定商取引法に基づく表記",
    description: "運営事業者情報、問い合わせ窓口、有料機能の価格を確認します。",
    icon: "receipt-outline",
    href: "/legal/notice",
  },
];

export default function SettingsPrivacyScreen() {
  const { user } = useAuth();
  const metadata = user?.user_metadata as Record<string, unknown> | undefined;
  const handle =
    stringMeta(metadata?.handle) ??
    user?.email?.split("@")[0] ??
    "megrum_user";
  const [query, setQuery] = useState("");
  const visiblePrimaryRows = useMemo(() => {
    const needle = query.trim().toLowerCase();
    if (!needle) return PRIMARY_SETTINGS_ROWS;
    return PRIMARY_SETTINGS_ROWS.filter((row) =>
      `${row.title} ${row.description}`.toLowerCase().includes(needle),
    );
  }, [query]);
  const visibleLegalRows = useMemo(() => {
    const needle = query.trim().toLowerCase();
    if (!needle) return LEGAL_SETTINGS_ROWS;
    return LEGAL_SETTINGS_ROWS.filter((row) =>
      `${row.title} ${row.description}`.toLowerCase().includes(needle),
    );
  }, [query]);
  const hasRows = visiblePrimaryRows.length > 0 || visibleLegalRows.length > 0;

  return (
    <Screen contentStyle={styles.screen}>
      <View style={styles.header}>
        <Pressable
          accessibilityLabel="戻る"
          accessibilityRole="button"
          onPress={() => {
            if (router.canGoBack()) {
              router.back();
              return;
            }
            router.replace("/");
          }}
          style={styles.backButton}
        >
          <Text style={styles.backText}>‹</Text>
        </Pressable>
        <View style={styles.headerCopy}>
          <Text style={styles.title}>設定</Text>
          <Text numberOfLines={1} style={styles.handle}>
            @{handle.replace(/^@/, "")}
          </Text>
        </View>
        <View style={styles.headerSpacer} />
      </View>

      <View style={styles.searchPill}>
        <IconSymbol name="search" size={20} color={megrumColors.mutedInk} />
        <TextInput
          autoCorrect={false}
          clearButtonMode="while-editing"
          onChangeText={setQuery}
          placeholder="検索設定"
          placeholderTextColor={megrumColors.mutedInk}
          returnKeyType="search"
          style={styles.searchInput}
          value={query}
        />
      </View>

      <View style={styles.list}>
        {visiblePrimaryRows.map((row) => (
          <SettingsListRow key={row.title} row={row} />
        ))}
        {visibleLegalRows.length > 0 ? (
          <View style={styles.legalSection}>
            <Text style={styles.sectionLabel}>規約と法的情報</Text>
            {visibleLegalRows.map((row) => (
              <SettingsListRow key={row.title} row={row} />
            ))}
          </View>
        ) : null}
        {!hasRows ? (
          <View style={styles.emptyBox}>
            <Text style={styles.emptyText}>該当する設定はありません</Text>
          </View>
        ) : null}
      </View>
    </Screen>
  );
}

function SettingsListRow({ row }: { row: SettingsRow }) {
  return (
    <Pressable
      accessibilityRole={row.href ? "button" : undefined}
      onPress={() => {
        if (row.href) router.push(row.href);
      }}
      style={({ pressed }) => [
        styles.row,
        pressed && row.href ? styles.rowPressed : null,
      ]}
    >
      <View style={styles.iconColumn}>
        <IconSymbol name={row.icon} size={27} color={megrumColors.mutedInk} />
      </View>
      <View style={styles.rowCopy}>
        <Text style={styles.rowTitle}>{row.title}</Text>
        <Text style={styles.rowDescription}>{row.description}</Text>
      </View>
      <IconSymbol name="chevron-forward" size={18} color="rgba(58,50,74,0.28)" />
    </Pressable>
  );
}

function stringMeta(value: unknown) {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

const styles = StyleSheet.create({
  screen: {
    gap: 18,
    paddingHorizontal: 20,
  },
  header: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
  },
  backButton: {
    alignItems: "center",
    height: 44,
    justifyContent: "center",
    width: 44,
  },
  backText: {
    color: megrumColors.ink,
    fontSize: 38,
    fontWeight: "500",
    lineHeight: 40,
  },
  headerCopy: {
    alignItems: "center",
    flex: 1,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 22,
    fontWeight: "900",
    lineHeight: 26,
  },
  handle: {
    color: megrumColors.mutedInk,
    fontSize: 15,
    fontWeight: "800",
    marginTop: 2,
  },
  headerSpacer: {
    width: 44,
  },
  searchPill: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.07)",
    borderRadius: megrumRadii.pill,
    flexDirection: "row",
    gap: 9,
    minHeight: 52,
    paddingHorizontal: 18,
  },
  searchInput: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 20,
    fontWeight: "700",
    paddingVertical: 0,
  },
  list: {
    gap: 2,
    paddingTop: 6,
  },
  legalSection: {
    borderTopColor: "rgba(58,50,74,0.10)",
    borderTopWidth: StyleSheet.hairlineWidth,
    marginTop: 8,
    paddingTop: 18,
  },
  sectionLabel: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "900",
    marginBottom: 6,
    paddingLeft: 52,
  },
  row: {
    alignItems: "center",
    borderRadius: 12,
    flexDirection: "row",
    gap: 16,
    minHeight: 98,
    paddingHorizontal: 2,
    paddingVertical: 12,
  },
  rowPressed: {
    backgroundColor: "rgba(58,50,74,0.05)",
  },
  iconColumn: {
    alignItems: "center",
    width: 36,
  },
  rowCopy: {
    flex: 1,
    gap: 3,
  },
  rowTitle: {
    color: megrumColors.ink,
    fontSize: 20,
    fontWeight: "900",
    lineHeight: 25,
  },
  rowDescription: {
    color: megrumColors.mutedInk,
    fontSize: 15,
    fontWeight: "700",
    lineHeight: 21,
  },
  emptyBox: {
    alignItems: "center",
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: 20,
    borderStyle: "dashed",
    borderWidth: 1,
    paddingVertical: 28,
  },
  emptyText: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "800",
  },
});
