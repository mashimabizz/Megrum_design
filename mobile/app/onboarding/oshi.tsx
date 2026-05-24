import { useEffect, useMemo, useState } from "react";
import { router } from "expo-router";
import {
  ActivityIndicator,
  Modal,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { PrimaryButton } from "../../src/components/PrimaryButton";
import { Screen } from "../../src/components/Screen";
import { useAuth } from "../../src/auth/AuthProvider";
import { supabase } from "../../src/lib/supabase";
import { ihubColors, ihubRadii } from "../../src/theme/tokens";

type GenreOption = {
  id: string;
  name: string;
  kind: string | null;
};

type OshiOption = {
  id: string;
  name: string;
  aliases: string[];
  genreId: string | null;
  genreName: string | null;
  pending?: boolean;
  mine?: boolean;
};

type OshiRequestKind = "group" | "work" | "solo";

const REQUEST_KINDS: { value: OshiRequestKind; label: string }[] = [
  { value: "group", label: "グループ" },
  { value: "work", label: "作品" },
  { value: "solo", label: "ソロ" },
];

export default function OnboardingOshiScreen() {
  const { user } = useAuth();
  const [genres, setGenres] = useState<GenreOption[]>([]);
  const [options, setOptions] = useState<OshiOption[]>([]);
  const [selectedGroups, setSelectedGroups] = useState<string[]>([]);
  const [selectedRequests, setSelectedRequests] = useState<string[]>([]);
  const [activeGenre, setActiveGenre] = useState("all");
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [requestOpen, setRequestOpen] = useState(false);
  const [requestName, setRequestName] = useState("");
  const [requestKind, setRequestKind] = useState<OshiRequestKind>("group");
  const [requestGenreId, setRequestGenreId] = useState<string | null>(null);
  const [requestNote, setRequestNote] = useState("");
  const [requestPending, setRequestPending] = useState(false);

  useEffect(() => {
    if (!user || !supabase) {
      router.replace("/login");
      return;
    }
    let active = true;
    setLoading(true);
    Promise.all([
      supabase
        .from("genres_master")
        .select("id, name, kind, display_order")
        .order("display_order", { ascending: true }),
      supabase
        .from("groups_master")
        .select("id, name, aliases, kind, display_order, genre_id, genre:genres_master(id, name, kind)")
        .order("display_order", { ascending: true }),
      supabase
        .from("user_oshi")
        .select("group_id, oshi_request_id, priority")
        .eq("user_id", user.id)
        .order("priority", { ascending: true }),
      supabase
        .from("oshi_requests")
        .select("id, requested_name, requested_kind, status, user_id, genre:genres_master(id, name)")
        .eq("status", "pending")
        .order("created_at", { ascending: false }),
    ])
      .then(([genreRes, groupRes, existingRes, requestRes]) => {
        if (!active) return;
        const nextGenres = ((genreRes.data as GenreOption[] | null) ?? []).map((genre) => ({
          id: genre.id,
          name: genre.name,
          kind: genre.kind,
        }));
        const nextGroups = ((groupRes.data as Record<string, unknown>[] | null) ?? []).map(
          (group) => {
            const genre = pickRelation(group.genre as RelationName | undefined);
            return {
              id: String(group.id),
              name: String(group.name ?? ""),
              aliases: Array.isArray(group.aliases)
                ? group.aliases.filter((item): item is string => typeof item === "string")
                : [],
              genreId:
                typeof group.genre_id === "string" ? group.genre_id : genre?.id ?? null,
              genreName: genre?.name ?? null,
            };
          },
        );
        const nextRequests = ((requestRes.data as Record<string, unknown>[] | null) ?? []).map(
          (request) => {
            const genre = pickRelation(request.genre as RelationName | undefined);
            return {
              id: String(request.id),
              name: String(request.requested_name ?? ""),
              aliases: [],
              genreId: genre?.id ?? null,
              genreName: genre?.name ?? null,
              pending: true,
              mine: request.user_id === user.id,
            };
          },
        );
        setGenres(nextGenres);
        setOptions([...nextGroups, ...nextRequests]);
        setSelectedGroups(
          ((existingRes.data as { group_id: string | null }[] | null) ?? [])
            .map((row) => row.group_id)
            .filter((id): id is string => !!id),
        );
        setSelectedRequests(
          ((existingRes.data as { oshi_request_id: string | null }[] | null) ?? [])
            .map((row) => row.oshi_request_id)
            .filter((id): id is string => !!id),
        );
      })
      .catch((loadError: unknown) => {
        if (!active) return;
        setError(loadError instanceof Error ? loadError.message : "読み込みに失敗しました");
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [user]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return options.filter((option) => {
      if (activeGenre !== "all" && option.genreId !== activeGenre) return false;
      if (!q) return true;
      return (
        option.name.toLowerCase().includes(q) ||
        option.aliases.some((alias) => alias.toLowerCase().includes(q))
      );
    });
  }, [activeGenre, options, query]);

  function toggle(option: OshiOption) {
    if (option.pending) {
      setSelectedRequests((prev) =>
        prev.includes(option.id) ? prev.filter((id) => id !== option.id) : [...prev, option.id],
      );
      return;
    }
    setSelectedGroups((prev) =>
      prev.includes(option.id) ? prev.filter((id) => id !== option.id) : [...prev, option.id],
    );
  }

  async function save() {
    if (!user || !supabase) {
      router.replace("/login");
      return;
    }
    if (selectedGroups.length + selectedRequests.length === 0) {
      setError("推しを1つ以上選択してください");
      return;
    }
    setPending(true);
    setError(null);
    const { error: deleteError } = await supabase
      .from("user_oshi")
      .delete()
      .eq("user_id", user.id);
    if (deleteError) {
      setPending(false);
      setError(deleteError.message);
      return;
    }
    const rows = [
      ...selectedGroups.map((group_id, index) => ({
        user_id: user.id,
        group_id,
        kind: "box",
        priority: index + 1,
      })),
      ...selectedRequests.map((oshi_request_id, index) => ({
        user_id: user.id,
        oshi_request_id,
        kind: "box",
        priority: selectedGroups.length + index + 1,
      })),
    ];
    const { error: insertError } = await supabase.from("user_oshi").insert(rows);
    setPending(false);
    if (insertError) {
      setError(insertError.message);
      return;
    }
    router.push("/onboarding/members");
  }

  async function submitRequest() {
    if (!user || !supabase) {
      router.replace("/login");
      return;
    }
    const name = requestName.trim();
    if (!name) {
      setError("追加したい推しの名前を入力してください");
      return;
    }
    setRequestPending(true);
    setError(null);
    const { data, error: insertError } = await supabase
      .from("oshi_requests")
      .insert({
        user_id: user.id,
        requested_name: name,
        requested_kind: requestKind,
        requested_genre_id: requestGenreId,
        note: requestNote.trim() || null,
      })
      .select("id, requested_name, user_id, genre:genres_master(id, name)")
      .single();
    setRequestPending(false);
    if (insertError) {
      setError(insertError.message);
      return;
    }
    const row = data as Record<string, unknown>;
    const genre = pickRelation(row.genre as RelationName | undefined);
    const next: OshiOption = {
      id: String(row.id),
      name: String(row.requested_name ?? name),
      aliases: [],
      genreId: genre?.id ?? requestGenreId,
      genreName: genre?.name ?? genres.find((item) => item.id === requestGenreId)?.name ?? null,
      pending: true,
      mine: true,
    };
    setOptions((current) => [next, ...current]);
    setSelectedRequests((current) => [...new Set([next.id, ...current])]);
    setRequestOpen(false);
    setRequestName("");
    setRequestNote("");
    setRequestGenreId(null);
    setRequestKind("group");
  }

  return (
    <Screen contentStyle={styles.screen}>
      <Header title="プロフィール設定" sub="あなたの推し（複数選択可）" progress="2/4" backTo="/onboarding/gender" />
      <ProgressDots current={1} />
      <Text style={styles.title}>推しは？</Text>
      <Text style={styles.copy}>グループ・作品・配信者など、ジャンル横断で選べます</Text>
      <TextInput
        value={query}
        onChangeText={setQuery}
        placeholder="推しを検索"
        placeholderTextColor="rgba(58,50,74,0.35)"
        style={styles.search}
      />
      <View style={styles.genreWrap}>
        <Chip label="すべて" active={activeGenre === "all"} onPress={() => setActiveGenre("all")} />
        {genres.map((genre) => (
          <Chip
            key={genre.id}
            label={genre.name}
            active={activeGenre === genre.id}
            onPress={() => setActiveGenre(genre.id)}
          />
        ))}
      </View>
      {loading ? <ActivityIndicator color={ihubColors.lavender} /> : null}
      <View style={styles.cards}>
        {filtered.map((option) => {
          const active = option.pending
            ? selectedRequests.includes(option.id)
            : selectedGroups.includes(option.id);
          return (
            <Pressable
              key={`${option.pending ? "request" : "group"}-${option.id}`}
              onPress={() => toggle(option)}
              style={[styles.card, active ? styles.cardActive : null]}
            >
              <View style={styles.cardCopy}>
                <Text numberOfLines={1} style={styles.cardTitle}>{option.name}</Text>
                <Text numberOfLines={1} style={styles.cardMeta}>
                  {option.pending ? (option.mine ? "審査中・自分のリクエスト" : "審査中") : option.genreName ?? "マスタ登録済み"}
                </Text>
              </View>
              <Text style={[styles.cardCheck, active ? styles.cardCheckActive : null]}>
                {active ? "✓" : "+"}
              </Text>
            </Pressable>
          );
        })}
      </View>
      {!loading && filtered.length === 0 ? (
        <View style={styles.emptyBox}>
          <Text style={styles.empty}>該当する推しが見つかりません</Text>
          <PrimaryButton
            variant="secondary"
            onPress={() => {
              setRequestName(query.trim());
              setRequestOpen(true);
            }}
          >
            追加リクエストを送る
          </PrimaryButton>
        </View>
      ) : null}
      {error ? <Text style={styles.error}>{error}</Text> : null}
      <View style={styles.footer}>
        <PrimaryButton
          loading={pending}
          disabled={selectedGroups.length + selectedRequests.length === 0}
          onPress={save}
        >
          次へ
        </PrimaryButton>
      </View>
      <Modal
        animationType="fade"
        transparent
        visible={requestOpen}
        onRequestClose={() => setRequestOpen(false)}
      >
        <View style={styles.modalLayer}>
          <Pressable style={styles.modalBackdrop} onPress={() => setRequestOpen(false)} />
          <View style={styles.requestModal}>
            <View style={styles.modalHeader}>
              <View style={styles.modalTitleCopy}>
                <Text style={styles.modalTitle}>推し追加リクエスト</Text>
                <Text style={styles.modalSub}>送信後、この画面で選択済みにします</Text>
              </View>
              <Pressable onPress={() => setRequestOpen(false)} style={styles.modalCloseButton}>
                <Text style={styles.modalCloseText}>×</Text>
              </Pressable>
            </View>
            <TextInput
              value={requestName}
              onChangeText={setRequestName}
              placeholder="グループ・作品名"
              placeholderTextColor="rgba(58,50,74,0.38)"
              style={styles.requestInput}
            />
            <View style={styles.genreWrap}>
              {REQUEST_KINDS.map((kind) => (
                <Chip
                  key={kind.value}
                  label={kind.label}
                  active={requestKind === kind.value}
                  onPress={() => setRequestKind(kind.value)}
                />
              ))}
            </View>
            <View style={styles.genreWrap}>
              <Chip
                label="ジャンル未選択"
                active={!requestGenreId}
                onPress={() => setRequestGenreId(null)}
              />
              {genres.map((genre) => (
                <Chip
                  key={genre.id}
                  label={genre.name}
                  active={requestGenreId === genre.id}
                  onPress={() => setRequestGenreId(genre.id)}
                />
              ))}
            </View>
            <TextInput
              value={requestNote}
              onChangeText={setRequestNote}
              multiline
              placeholder="補足（任意）"
              placeholderTextColor="rgba(58,50,74,0.38)"
              style={[styles.requestInput, styles.requestNoteInput]}
              textAlignVertical="top"
            />
            <PrimaryButton
              loading={requestPending}
              disabled={!requestName.trim()}
              onPress={submitRequest}
            >
              送信して選択する
            </PrimaryButton>
          </View>
        </View>
      </Modal>
    </Screen>
  );
}

type RelationName = { id?: string | null; name?: string | null } | { id?: string | null; name?: string | null }[] | null;

function pickRelation(value: RelationName | undefined) {
  if (!value) return null;
  return Array.isArray(value) ? value[0] ?? null : value;
}

function Header({ title, sub, progress, backTo }: { title: string; sub: string; progress: string; backTo: string }) {
  return (
    <View style={styles.header}>
      <Pressable onPress={() => router.replace(backTo)} style={styles.backButton}>
        <Text style={styles.backText}>‹</Text>
      </Pressable>
      <View style={styles.headerCopy}>
        <Text style={styles.headerTitle}>{title}</Text>
        <Text style={styles.headerSub}>{sub}</Text>
      </View>
      <Text style={styles.progressText}>{progress}</Text>
    </View>
  );
}

function ProgressDots({ current }: { current: number }) {
  return (
    <View style={styles.dots}>
      {[0, 1, 2, 3].map((index) => (
        <View key={index} style={[styles.dot, index <= current ? styles.dotActive : null]} />
      ))}
    </View>
  );
}

function Chip({ label, active, onPress }: { label: string; active: boolean; onPress: () => void }) {
  return (
    <Pressable onPress={onPress} style={[styles.chip, active ? styles.chipActive : null]}>
      <Text style={[styles.chipText, active ? styles.chipTextActive : null]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  screen: {
    flexGrow: 1,
    gap: 13,
  },
  header: {
    alignItems: "center",
    flexDirection: "row",
    gap: 12,
  },
  backButton: {
    alignItems: "center",
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: ihubRadii.pill,
    borderWidth: 1,
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  backText: {
    color: ihubColors.ink,
    fontSize: 30,
    fontWeight: "800",
    lineHeight: 32,
  },
  headerCopy: {
    flex: 1,
  },
  headerTitle: {
    color: ihubColors.ink,
    fontSize: 17,
    fontWeight: "900",
  },
  headerSub: {
    color: ihubColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 2,
  },
  progressText: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: ihubRadii.pill,
    color: ihubColors.lavender,
    fontSize: 12,
    fontWeight: "900",
    paddingHorizontal: 12,
    paddingVertical: 7,
  },
  dots: {
    flexDirection: "row",
    gap: 6,
    marginTop: 5,
  },
  dot: {
    backgroundColor: "rgba(58,50,74,0.12)",
    borderRadius: 999,
    flex: 1,
    height: 5,
  },
  dotActive: {
    backgroundColor: ihubColors.lavender,
  },
  title: {
    color: ihubColors.ink,
    fontSize: 22,
    fontWeight: "900",
    lineHeight: 28,
  },
  copy: {
    color: ihubColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 19,
  },
  search: {
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: ihubRadii.md,
    borderWidth: 1,
    color: ihubColors.ink,
    fontSize: 14,
    fontWeight: "800",
    minHeight: 48,
    paddingHorizontal: 14,
  },
  genreWrap: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 7,
  },
  chip: {
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: ihubRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  chipActive: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderColor: ihubColors.lavender,
  },
  chipText: {
    color: ihubColors.ink,
    fontSize: 11.5,
    fontWeight: "900",
  },
  chipTextActive: {
    color: ihubColors.lavender,
  },
  cards: {
    gap: 9,
  },
  card: {
    alignItems: "center",
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 18,
    borderWidth: 1.5,
    flexDirection: "row",
    gap: 11,
    padding: 12,
  },
  cardActive: {
    backgroundColor: "rgba(166,149,216,0.08)",
    borderColor: ihubColors.lavender,
  },
  cardCopy: {
    flex: 1,
  },
  cardTitle: {
    color: ihubColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  cardMeta: {
    color: ihubColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 3,
  },
  cardCheck: {
    color: ihubColors.mutedInk,
    fontSize: 20,
    fontWeight: "900",
    width: 24,
  },
  cardCheckActive: {
    color: ihubColors.lavender,
  },
  empty: {
    color: ihubColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    textAlign: "center",
  },
  emptyBox: {
    gap: 10,
  },
  error: {
    color: ihubColors.warn,
    fontSize: 12,
    fontWeight: "800",
  },
  footer: {
    marginTop: "auto",
    paddingTop: 16,
  },
  modalLayer: {
    alignItems: "center",
    flex: 1,
    justifyContent: "center",
    padding: 18,
  },
  modalBackdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(20,18,28,0.44)",
  },
  requestModal: {
    backgroundColor: ihubColors.background,
    borderColor: "rgba(255,255,255,0.72)",
    borderRadius: 28,
    borderWidth: 1,
    gap: 12,
    padding: 16,
    width: "100%",
  },
  modalHeader: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
  },
  modalTitleCopy: {
    flex: 1,
  },
  modalTitle: {
    color: ihubColors.ink,
    fontSize: 17,
    fontWeight: "900",
  },
  modalSub: {
    color: ihubColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 2,
  },
  modalCloseButton: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: ihubRadii.pill,
    height: 34,
    justifyContent: "center",
    width: 34,
  },
  modalCloseText: {
    color: ihubColors.mutedInk,
    fontSize: 20,
    fontWeight: "900",
    lineHeight: 22,
  },
  requestInput: {
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: ihubRadii.md,
    borderWidth: 1,
    color: ihubColors.ink,
    fontSize: 14,
    fontWeight: "800",
    minHeight: 48,
    paddingHorizontal: 14,
  },
  requestNoteInput: {
    minHeight: 88,
    paddingTop: 12,
  },
});
