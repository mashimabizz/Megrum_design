import { useEffect, useMemo, useState } from "react";
import {
  ActivityIndicator,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { router } from "expo-router";
import { useAuth } from "../src/auth/AuthProvider";
import { PrimaryButton } from "../src/components/PrimaryButton";
import { Screen } from "../src/components/Screen";
import { supabase } from "../src/lib/supabase";
import { ihubColors, ihubRadii, ihubShadow } from "../src/theme/tokens";

type GroupSource = "master" | "request";
type MemberSource = "master" | "request";
type OshiRequestKind = "group" | "work" | "solo";

type OshiRow = {
  id: string;
  group_id: string | null;
  character_id: string | null;
  oshi_request_id: string | null;
  character_request_id: string | null;
  kind: "box" | "specific" | "multi";
  priority: number;
  group: { id: string; name: string | null } | { id: string; name: string | null }[] | null;
  character: { id: string; name: string | null } | { id: string; name: string | null }[] | null;
  oshi_request:
    | { id: string; requested_name: string | null; status: string | null }
    | { id: string; requested_name: string | null; status: string | null }[]
    | null;
  character_request:
    | { id: string; requested_name: string | null; status: string | null }
    | { id: string; requested_name: string | null; status: string | null }[]
    | null;
};

type CharacterRow = { id: string; name: string; group_id: string | null };
type GenreOption = { id: string; name: string };
type MasterGroupRow = {
  id: string;
  name: string;
  aliases: string[] | null;
  kind: OshiRequestKind | string | null;
  display_order: number | null;
  genre:
    | { id: string; name: string; kind?: string | null }
    | { id: string; name: string; kind?: string | null }[]
    | null;
};

type OshiMember = {
  id: string;
  rowId: string;
  source: MemberSource;
  name: string;
  pending: boolean;
};

type OshiGroup = {
  key: string;
  source: GroupSource;
  groupId?: string;
  requestId?: string;
  name: string;
  pending: boolean;
  priority: number;
  members: OshiMember[];
  availableCharacters: { id: string; name: string }[];
};

type MasterOption = {
  id: string;
  name: string;
  aliases: string[];
  kind: OshiRequestKind;
  genreId: string;
  genreName: string;
  characters: { id: string; name: string }[];
};

type OshiData = {
  groups: OshiGroup[];
  genres: GenreOption[];
  masterOptions: MasterOption[];
};

type RequestModalState =
  | { type: "oshi"; initialName?: string }
  | { type: "member"; group: OshiGroup };

type RequestSubmit = {
  name: string;
  note: string;
  kind: OshiRequestKind;
  genreId: string | null;
};

const REQUEST_KINDS: { value: OshiRequestKind; label: string }[] = [
  { value: "group", label: "グループ" },
  { value: "work", label: "作品" },
  { value: "solo", label: "ソロ" },
];

export default function OshiSettingsScreen() {
  const { user, previewMode } = useAuth();
  const [groups, setGroups] = useState<OshiGroup[]>([]);
  const [genres, setGenres] = useState<GenreOption[]>([]);
  const [masterOptions, setMasterOptions] = useState<MasterOption[]>([]);
  const [loading, setLoading] = useState(false);
  const [busyKey, setBusyKey] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [masterOpen, setMasterOpen] = useState(false);
  const [requestModal, setRequestModal] = useState<RequestModalState | null>(null);

  const selectedMasterIds = useMemo(
    () => new Set(groups.filter((group) => group.source === "master").map((group) => group.groupId)),
    [groups],
  );
  const summary = useMemo(() => {
    const memberCount = groups.reduce((sum, group) => sum + group.members.length, 0);
    return `${groups.length}グループ・${memberCount}メンバー`;
  }, [groups]);

  useEffect(() => {
    if (!supabase || !user || previewMode) {
      setGroups([]);
      setGenres([]);
      setMasterOptions([]);
      setLoading(false);
      setError(previewMode ? null : "ログイン後に推し設定を確認できます");
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);
    fetchOshiData(user.id)
      .then((next) => {
        if (!active) return;
        setGroups(next.groups);
        setGenres(next.genres);
        setMasterOptions(next.masterOptions);
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
  }, [previewMode, user]);

  async function reload() {
    if (!user || !supabase) return;
    const next = await fetchOshiData(user.id);
    setGroups(next.groups);
    setGenres(next.genres);
    setMasterOptions(next.masterOptions);
  }

  async function runMutation(key: string, task: () => Promise<void>, success?: string) {
    if (!user || !supabase) return;
    setBusyKey(key);
    setError(null);
    setNotice(null);
    try {
      await task();
      await reload();
      if (success) setNotice(success);
    } catch (mutationError) {
      setError(mutationError instanceof Error ? mutationError.message : "保存に失敗しました");
    } finally {
      setBusyKey(null);
    }
  }

  function handleAddMaster(option: MasterOption) {
    if (!user || selectedMasterIds.has(option.id)) {
      setMasterOpen(false);
      return;
    }
    setMasterOpen(false);
    void runMutation(
      `group:${option.id}`,
      () => addMasterGroup(user.id, option.id),
      "登録済みの推しを追加しました。",
    );
  }

  function handleRemoveGroup(group: OshiGroup) {
    if (!user) return;
    void runMutation(
      group.key,
      () => removeGroup(user.id, group),
      "推し設定から削除しました。",
    );
  }

  function handleAddMember(group: OshiGroup, character: { id: string; name: string }) {
    if (!user || group.source !== "master" || !group.groupId) return;
    void runMutation(
      `${group.key}:${character.id}`,
      () => addMasterMember(user.id, group, character.id),
      "推しメンバーを追加しました。",
    );
  }

  function handleRemoveMember(group: OshiGroup, member: OshiMember) {
    if (!user) return;
    void runMutation(
      member.rowId,
      () => removeMemberAndRestoreBox(user.id, group, member),
      "推しメンバーを外しました。",
    );
  }

  function handleRequestSubmit(payload: RequestSubmit) {
    if (!user || !requestModal) return;
    const target = requestModal;
    setRequestModal(null);
    if (target.type === "oshi") {
      void runMutation(
        `request:${payload.name}`,
        () => requestOshiAndAdd(user.id, payload),
        "追加リクエストを送信し、推し設定に仮登録しました。",
      );
      return;
    }
    void runMutation(
      `member-request:${target.group.key}:${payload.name}`,
      () => requestCharacterAndAdd(user.id, target.group, payload),
      "メンバー追加リクエストを送信し、推しメンバーに仮登録しました。",
    );
  }

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
        <View style={styles.headerCopy}>
          <Text style={styles.title}>推し設定</Text>
          <Text style={styles.subtitle}>{summary}</Text>
        </View>
      </View>

      <View style={styles.actionStack}>
        <PrimaryButton variant="secondary" onPress={() => setMasterOpen(true)}>
          ＋ 登録済みの推しを追加
        </PrimaryButton>
        <Pressable onPress={() => setRequestModal({ type: "oshi" })} style={styles.requestEntryButton}>
          <Text style={styles.requestEntryText}>マスタに無い推しを追加リクエスト</Text>
        </Pressable>
      </View>

      {loading ? (
        <View style={styles.loadingRow}>
          <ActivityIndicator color={ihubColors.lavender} />
          <Text style={styles.inlineNotice}>推し設定を読み込み中…</Text>
        </View>
      ) : null}
      {error ? <Text style={styles.inlineError}>{error}</Text> : null}
      {notice ? <Text style={styles.inlineNoticeStrong}>{notice}</Text> : null}

      {groups.length === 0 && !loading ? (
        <View style={styles.emptyBox}>
          <Text style={styles.emptyTitle}>推しが未設定です</Text>
          <Text style={styles.emptyText}>
            登録済みの推しを検索して追加できます。見つからない場合は追加リクエストから仮登録できます。
          </Text>
        </View>
      ) : null}

      <View style={styles.groupList}>
        {groups.map((group) => (
          <GroupCard
            key={group.key}
            group={group}
            busyKey={busyKey}
            onAddMember={handleAddMember}
            onMemberRequest={() => setRequestModal({ type: "member", group })}
            onRemoveGroup={() => handleRemoveGroup(group)}
            onRemoveMember={(member) => handleRemoveMember(group, member)}
          />
        ))}
      </View>

      <MasterSelectModal
        visible={masterOpen}
        genres={genres}
        options={masterOptions}
        selectedIds={selectedMasterIds}
        onClose={() => setMasterOpen(false)}
        onRequest={(name) => {
          setMasterOpen(false);
          setRequestModal({ type: "oshi", initialName: name });
        }}
        onSelect={handleAddMaster}
      />

      <RequestModal
        state={requestModal}
        genres={genres}
        onClose={() => setRequestModal(null)}
        onSubmit={handleRequestSubmit}
      />
    </Screen>
  );
}

function GroupCard({
  group,
  busyKey,
  onAddMember,
  onMemberRequest,
  onRemoveGroup,
  onRemoveMember,
}: {
  group: OshiGroup;
  busyKey: string | null;
  onAddMember: (group: OshiGroup, character: { id: string; name: string }) => void;
  onMemberRequest: () => void;
  onRemoveGroup: () => void;
  onRemoveMember: (member: OshiMember) => void;
}) {
  const [showAdd, setShowAdd] = useState(false);
  const groupBusy = busyKey === group.key;
  return (
    <View style={styles.groupCard}>
      <View style={styles.groupHeader}>
        <View style={styles.groupCopy}>
          <View style={styles.groupTitleRow}>
            <Text numberOfLines={1} style={styles.groupName}>{group.name}</Text>
            {group.pending ? (
              <View style={styles.pendingBadge}>
                <Text style={styles.pendingText}>承認待ち</Text>
              </View>
            ) : null}
          </View>
          <Text style={styles.groupMeta}>
            {group.members.length === 0
              ? "箱推し（メンバー指定なし）"
              : `推しメンバー ${group.members.length}人`}
          </Text>
        </View>
        <Pressable
          disabled={groupBusy}
          onPress={onRemoveGroup}
          style={styles.removeButton}
        >
          <Text style={styles.removeButtonText}>削除</Text>
        </Pressable>
      </View>

      <View style={styles.memberWrap}>
        {group.members.map((member) => (
          <Pressable
            key={`${member.source}:${member.id}`}
            disabled={busyKey === member.rowId}
            onPress={() => onRemoveMember(member)}
            style={styles.memberChip}
          >
            <Text style={styles.memberText}>
              {member.name}
              {member.pending ? "（承認待ち）" : ""}
            </Text>
            <Text style={styles.memberDelete}>×</Text>
          </Pressable>
        ))}
        <Pressable onPress={() => setShowAdd((current) => !current)} style={styles.addMemberChip}>
          <Text style={styles.addMemberText}>{showAdd ? "閉じる" : "+ 追加"}</Text>
        </Pressable>
      </View>

      {showAdd ? (
        <View style={styles.memberAddBox}>
          {group.availableCharacters.length > 0 ? (
            <>
              <Text style={styles.memberAddTitle}>追加できるメンバー</Text>
              <View style={styles.memberWrap}>
                {group.availableCharacters.map((character) => (
                  <Pressable
                    key={character.id}
                    onPress={() => onAddMember(group, character)}
                    style={styles.availableMemberChip}
                  >
                    <Text style={styles.availableMemberText}>+ {character.name}</Text>
                  </Pressable>
                ))}
              </View>
            </>
          ) : (
            <Text style={styles.noMemberText}>
              {group.pending
                ? "仮登録中の推しです。メンバーは追加リクエストで仮登録できます。"
                : "追加できるメンバーがマスタにありません。"}
            </Text>
          )}
          <Pressable onPress={onMemberRequest} style={styles.memberRequestButton}>
            <Text style={styles.memberRequestText}>マスタに無いメンバーを追加リクエスト</Text>
          </Pressable>
        </View>
      ) : null}
    </View>
  );
}

function MasterSelectModal({
  visible,
  genres,
  options,
  selectedIds,
  onClose,
  onRequest,
  onSelect,
}: {
  visible: boolean;
  genres: GenreOption[];
  options: MasterOption[];
  selectedIds: Set<string | undefined>;
  onClose: () => void;
  onRequest: (name?: string) => void;
  onSelect: (option: MasterOption) => void;
}) {
  const [query, setQuery] = useState("");
  const [genreId, setGenreId] = useState<string | "all">("all");
  const normalizedQuery = query.trim().toLowerCase();
  const filtered = useMemo(
    () =>
      options.filter((option) => {
        if (genreId !== "all" && option.genreId !== genreId) return false;
        if (!normalizedQuery) return true;
        return [option.name, ...option.aliases]
          .map((value) => value.toLowerCase())
          .some((value) => value.includes(normalizedQuery));
      }),
    [genreId, normalizedQuery, options],
  );

  return (
    <Modal animationType="fade" transparent visible={visible} onRequestClose={onClose}>
      <View style={styles.modalLayer}>
        <Pressable style={styles.modalBackdrop} onPress={onClose} />
        <View style={styles.masterModal}>
          <View style={styles.modalHeader}>
            <View style={styles.modalTitleCopy}>
              <Text style={styles.modalTitle}>登録済みの推しを追加</Text>
              <Text style={styles.modalSub}>グループ・作品マスタから選択</Text>
            </View>
            <Pressable onPress={() => onRequest(query.trim() || undefined)} style={styles.modalRequestButton}>
              <Text style={styles.modalRequestText}>追加リクエスト</Text>
            </Pressable>
            <Pressable onPress={onClose} style={styles.modalCloseButton}>
              <Text style={styles.modalCloseText}>×</Text>
            </Pressable>
          </View>
          <TextInput
            value={query}
            onChangeText={setQuery}
            placeholder="作品名・グループ名で検索"
            placeholderTextColor="rgba(58,50,74,0.38)"
            style={styles.searchInput}
          />
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.genreTabs}
          >
            <FilterChip label="すべて" active={genreId === "all"} onPress={() => setGenreId("all")} />
            {genres.map((genre) => (
              <FilterChip
                key={genre.id}
                label={genre.name}
                active={genreId === genre.id}
                onPress={() => setGenreId(genre.id)}
              />
            ))}
          </ScrollView>
          <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.masterList}>
            {filtered.length === 0 ? (
              <View style={styles.modalEmpty}>
                <Text style={styles.emptyTitle}>見つかりませんでした</Text>
                <Text style={styles.emptyText}>追加リクエストで仮登録できます。</Text>
                <PrimaryButton onPress={() => onRequest(query.trim() || undefined)}>
                  追加リクエストへ
                </PrimaryButton>
              </View>
            ) : (
              filtered.map((option) => {
                const selected = selectedIds.has(option.id);
                return (
                  <Pressable
                    key={option.id}
                    disabled={selected}
                    onPress={() => onSelect(option)}
                    style={[styles.masterRow, selected ? styles.masterRowSelected : null]}
                  >
                    <View style={styles.masterCopy}>
                      <Text numberOfLines={1} style={styles.masterName}>{option.name}</Text>
                      <Text numberOfLines={1} style={styles.masterMeta}>
                        {option.genreName} / {kindLabel(option.kind)} / {option.characters.length}メンバー
                      </Text>
                    </View>
                    <Text style={[styles.masterAdd, selected ? styles.masterAdded : null]}>
                      {selected ? "追加済み" : "追加"}
                    </Text>
                  </Pressable>
                );
              })
            )}
          </ScrollView>
        </View>
      </View>
    </Modal>
  );
}

function RequestModal({
  state,
  genres,
  onClose,
  onSubmit,
}: {
  state: RequestModalState | null;
  genres: GenreOption[];
  onClose: () => void;
  onSubmit: (payload: RequestSubmit) => void;
}) {
  const [name, setName] = useState("");
  const [note, setNote] = useState("");
  const [kind, setKind] = useState<OshiRequestKind>("group");
  const [genreId, setGenreId] = useState<string | null>(null);

  useEffect(() => {
    setName(state?.type === "oshi" ? state.initialName ?? "" : "");
    setNote("");
    setKind("group");
    setGenreId(null);
  }, [state]);

  if (!state) return null;
  const isOshi = state.type === "oshi";
  return (
    <Modal animationType="fade" transparent visible onRequestClose={onClose}>
      <View style={styles.modalLayer}>
        <Pressable style={styles.modalBackdrop} onPress={onClose} />
        <View style={styles.requestModal}>
          <View style={styles.modalHeader}>
            <View style={styles.modalTitleCopy}>
              <Text style={styles.modalTitle}>
                {isOshi ? "推し追加リクエスト" : "メンバー追加リクエスト"}
              </Text>
              <Text style={styles.modalSub}>
                {isOshi ? "送信後、推し設定に仮登録されます" : `${state.group.name} に仮登録します`}
              </Text>
            </View>
            <Pressable onPress={onClose} style={styles.modalCloseButton}>
              <Text style={styles.modalCloseText}>×</Text>
            </Pressable>
          </View>
          <TextInput
            value={name}
            onChangeText={setName}
            placeholder={isOshi ? "グループ・作品名" : "メンバー名"}
            placeholderTextColor="rgba(58,50,74,0.38)"
            style={styles.searchInput}
          />
          {isOshi ? (
            <>
              <View style={styles.genreTabs}>
                {REQUEST_KINDS.map((option) => (
                  <FilterChip
                    key={option.value}
                    label={option.label}
                    active={kind === option.value}
                    onPress={() => setKind(option.value)}
                  />
                ))}
              </View>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.genreTabs}>
                <FilterChip label="ジャンル未選択" active={!genreId} onPress={() => setGenreId(null)} />
                {genres.map((genre) => (
                  <FilterChip
                    key={genre.id}
                    label={genre.name}
                    active={genreId === genre.id}
                    onPress={() => setGenreId(genre.id)}
                  />
                ))}
              </ScrollView>
            </>
          ) : null}
          <TextInput
            value={note}
            onChangeText={setNote}
            multiline
            placeholder="補足（任意）"
            placeholderTextColor="rgba(58,50,74,0.38)"
            style={[styles.searchInput, styles.noteInput]}
            textAlignVertical="top"
          />
          <PrimaryButton
            disabled={!name.trim()}
            onPress={() => onSubmit({ name: name.trim(), note, kind, genreId })}
          >
            送信して仮登録
          </PrimaryButton>
        </View>
      </View>
    </Modal>
  );
}

function FilterChip({
  label,
  active,
  onPress,
}: {
  label: string;
  active: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable onPress={onPress} style={[styles.filterChip, active ? styles.filterChipActive : null]}>
      <Text style={[styles.filterChipText, active ? styles.filterChipTextActive : null]}>
        {label}
      </Text>
    </Pressable>
  );
}

async function fetchOshiData(userId: string): Promise<OshiData> {
  if (!supabase) return { groups: [], genres: [], masterOptions: [] };
  const [
    { data: oshi, error: oshiError },
    { data: characters, error: characterError },
    { data: genres, error: genreError },
    { data: masterGroups, error: masterError },
  ] = await Promise.all([
    supabase
      .from("user_oshi")
      .select(
        "id, group_id, character_id, oshi_request_id, character_request_id, kind, priority, group:groups_master(id, name), character:characters_master(id, name), oshi_request:oshi_requests(id, requested_name, status), character_request:character_requests(id, requested_name, status)",
      )
      .eq("user_id", userId)
      .order("priority", { ascending: true }),
    supabase
      .from("characters_master")
      .select("id, name, group_id")
      .order("display_order", { ascending: true }),
    supabase
      .from("genres_master")
      .select("id, name")
      .order("display_order", { ascending: true }),
    supabase
      .from("groups_master")
      .select("id, name, aliases, kind, display_order, genre:genres_master(id, name, kind)")
      .order("display_order", { ascending: true }),
  ]);
  if (oshiError) throw oshiError;
  if (characterError) throw characterError;
  if (genreError) throw genreError;
  if (masterError) throw masterError;

  const characterRows = (characters as CharacterRow[] | null) ?? [];
  const groups = buildGroups((oshi as OshiRow[] | null) ?? [], characterRows);
  const charactersByGroup = new Map<string, { id: string; name: string }[]>();
  for (const character of characterRows) {
    if (!character.group_id) continue;
    const list = charactersByGroup.get(character.group_id) ?? [];
    list.push({ id: character.id, name: character.name });
    charactersByGroup.set(character.group_id, list);
  }
  const masterOptions = ((masterGroups as MasterGroupRow[] | null) ?? []).flatMap((group) => {
    const genre = pickOne(group.genre);
    if (!genre) return [];
    return [
      {
        id: group.id,
        name: group.name,
        aliases: group.aliases ?? [],
        kind: normalizeRequestKind(group.kind),
        genreId: genre.id,
        genreName: genre.name,
        characters: charactersByGroup.get(group.id) ?? [],
      },
    ];
  });

  return {
    groups,
    genres: ((genres as GenreOption[] | null) ?? []).map((genre) => ({
      id: genre.id,
      name: genre.name,
    })),
    masterOptions,
  };
}

function buildGroups(rows: OshiRow[], characters: CharacterRow[]): OshiGroup[] {
  const map = new Map<string, OshiGroup>();
  for (const row of rows) {
    const group = pickOne(row.group);
    const request = pickOne(row.oshi_request);
    const source: GroupSource | null = row.group_id ? "master" : row.oshi_request_id ? "request" : null;
    const id = row.group_id ?? row.oshi_request_id;
    const name = group?.name ?? request?.requested_name;
    if (!source || !id || !name) continue;
    const key = `${source}:${id}`;
    const current =
      map.get(key) ??
      {
        key,
        source,
        groupId: source === "master" ? id : undefined,
        requestId: source === "request" ? id : undefined,
        name,
        pending: source === "request",
        priority: row.priority,
        members: [],
        availableCharacters: [],
      };
    current.priority = Math.min(current.priority, row.priority);

    const character = pickOne(row.character);
    const characterRequest = pickOne(row.character_request);
    const memberId = row.character_id ?? row.character_request_id;
    const memberName = character?.name ?? characterRequest?.requested_name;
    if (memberId && memberName) {
      current.members.push({
        id: memberId,
        rowId: row.id,
        source: row.character_id ? "master" : "request",
        name: memberName,
        pending: !row.character_id,
      });
    }
    map.set(key, current);
  }

  for (const group of map.values()) {
    if (group.source !== "master" || !group.groupId) continue;
    const selected = new Set(group.members.filter((member) => member.source === "master").map((member) => member.id));
    group.availableCharacters = characters
      .filter((character) => character.group_id === group.groupId && !selected.has(character.id))
      .map((character) => ({ id: character.id, name: character.name }));
  }

  return Array.from(map.values()).sort((a, b) => a.priority - b.priority || a.name.localeCompare(b.name, "ja"));
}

async function addMasterGroup(userId: string, groupId: string) {
  if (!supabase) return;
  const { data: existing } = await supabase
    .from("user_oshi")
    .select("id")
    .eq("user_id", userId)
    .eq("group_id", groupId)
    .limit(1);
  if (existing && existing.length > 0) return;
  const priority = await getNextPriority(userId);
  const { error } = await supabase.from("user_oshi").insert({
    user_id: userId,
    group_id: groupId,
    character_id: null,
    oshi_request_id: null,
    character_request_id: null,
    kind: "box",
    priority,
  });
  if (error) throw error;
}

async function addMasterMember(userId: string, group: OshiGroup, characterId: string) {
  if (!supabase || !group.groupId) return;
  const { data: existing } = await supabase
    .from("user_oshi")
    .select("id")
    .eq("user_id", userId)
    .eq("group_id", group.groupId)
    .eq("character_id", characterId)
    .maybeSingle();
  if (existing) return;
  const priorityRows = await getParentPriorityRows(userId, group);
  await supabase
    .from("user_oshi")
    .delete()
    .eq("user_id", userId)
    .eq("group_id", group.groupId)
    .is("character_id", null)
    .is("character_request_id", null);
  const priority = nextPriorityPreservingParent(priorityRows);
  const { error } = await supabase.from("user_oshi").insert({
    user_id: userId,
    group_id: group.groupId,
    oshi_request_id: null,
    character_id: characterId,
    character_request_id: null,
    kind: "specific",
    priority,
  });
  if (error) throw error;
}

async function requestOshiAndAdd(userId: string, payload: RequestSubmit) {
  if (!supabase) return;
  const { data: request, error: requestError } = await supabase
    .from("oshi_requests")
    .insert({
      user_id: userId,
      requested_name: payload.name,
      requested_genre_id: payload.genreId,
      requested_kind: payload.kind,
      note: payload.note.trim() || null,
    })
    .select("id")
    .single();
  if (requestError) throw requestError;
  const priority = await getNextPriority(userId);
  const { error } = await supabase.from("user_oshi").insert({
    user_id: userId,
    group_id: null,
    oshi_request_id: (request as { id: string }).id,
    character_id: null,
    character_request_id: null,
    kind: "box",
    priority,
  });
  if (error) throw error;
}

async function requestCharacterAndAdd(userId: string, group: OshiGroup, payload: RequestSubmit) {
  if (!supabase) return;
  if (!group.groupId && !group.requestId) throw new Error("追加先の推しが見つかりません");
  const { data: request, error: requestError } = await supabase
    .from("character_requests")
    .insert({
      user_id: userId,
      group_id: group.groupId ?? null,
      oshi_request_id: group.requestId ?? null,
      requested_name: payload.name,
      note: payload.note.trim() || null,
    })
    .select("id")
    .single();
  if (requestError) throw requestError;
  let deleteBox = supabase
    .from("user_oshi")
    .delete()
    .eq("user_id", userId)
    .is("character_id", null)
    .is("character_request_id", null);
  deleteBox = group.groupId ? deleteBox.eq("group_id", group.groupId) : deleteBox.eq("oshi_request_id", group.requestId!);
  const { error: deleteError } = await deleteBox;
  if (deleteError) throw deleteError;
  const priorityRows = await getParentPriorityRows(userId, group);
  const priority = nextPriorityPreservingParent(priorityRows);
  const { error } = await supabase.from("user_oshi").insert({
    user_id: userId,
    group_id: group.groupId ?? null,
    oshi_request_id: group.requestId ?? null,
    character_id: null,
    character_request_id: (request as { id: string }).id,
    kind: "specific",
    priority,
  });
  if (error) throw error;
}

async function removeGroup(userId: string, group: OshiGroup) {
  if (!supabase) return;
  let query = supabase.from("user_oshi").delete().eq("user_id", userId);
  query = group.groupId ? query.eq("group_id", group.groupId) : query.eq("oshi_request_id", group.requestId!);
  const { error } = await query;
  if (error) throw error;
}

async function removeMemberAndRestoreBox(userId: string, group: OshiGroup, member: OshiMember) {
  if (!supabase) return;
  const { error } = await supabase
    .from("user_oshi")
    .delete()
    .eq("id", member.rowId)
    .eq("user_id", userId);
  if (error) throw error;
  let remaining = supabase.from("user_oshi").select("id").eq("user_id", userId);
  remaining = group.groupId ? remaining.eq("group_id", group.groupId) : remaining.eq("oshi_request_id", group.requestId!);
  const { data: rows } = await remaining;
  if (rows && rows.length > 0) return;
  const { error: restoreError } = await supabase.from("user_oshi").insert({
    user_id: userId,
    group_id: group.groupId ?? null,
    oshi_request_id: group.requestId ?? null,
    character_id: null,
    character_request_id: null,
    kind: "box",
    priority: group.priority,
  });
  if (restoreError) throw restoreError;
}

async function getNextPriority(userId: string) {
  if (!supabase) return 1;
  const { data } = await supabase
    .from("user_oshi")
    .select("priority")
    .eq("user_id", userId)
    .order("priority", { ascending: false })
    .limit(1)
    .maybeSingle();
  return ((data as { priority?: number } | null)?.priority ?? 0) + 1;
}

async function getParentPriorityRows(userId: string, group: OshiGroup) {
  if (!supabase) return [];
  let query = supabase
    .from("user_oshi")
    .select("priority, character_id, character_request_id")
    .eq("user_id", userId)
    .order("priority", { ascending: true });
  query = group.groupId ? query.eq("group_id", group.groupId) : query.eq("oshi_request_id", group.requestId!);
  const { data } = await query;
  return (data ?? []) as {
    priority: number;
    character_id: string | null;
    character_request_id: string | null;
  }[];
}

function nextPriorityPreservingParent(
  rows: {
    priority: number;
    character_id: string | null;
    character_request_id: string | null;
  }[],
) {
  if (rows.length === 0) return 1;
  const hasSpecific = rows.some((row) => row.character_id != null || row.character_request_id != null);
  if (hasSpecific) return Math.max(...rows.map((row) => row.priority)) + 1;
  return Math.min(...rows.map((row) => row.priority));
}

function pickOne<T>(value: T | T[] | null | undefined) {
  if (!value) return null;
  return Array.isArray(value) ? value[0] ?? null : value;
}

function normalizeRequestKind(value: string | null | undefined): OshiRequestKind {
  if (value === "work" || value === "solo") return value;
  return "group";
}

function kindLabel(kind: OshiRequestKind) {
  if (kind === "work") return "作品";
  if (kind === "solo") return "ソロ";
  return "グループ";
}

const styles = StyleSheet.create({
  screen: {
    gap: 14,
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
    height: 44,
    justifyContent: "center",
    width: 44,
    ...ihubShadow,
  },
  backText: {
    color: ihubColors.ink,
    fontSize: 32,
    fontWeight: "800",
    lineHeight: 34,
  },
  headerCopy: {
    flex: 1,
  },
  title: {
    color: ihubColors.ink,
    fontSize: 20,
    fontWeight: "900",
  },
  subtitle: {
    color: ihubColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 2,
  },
  actionStack: {
    gap: 9,
  },
  requestEntryButton: {
    alignItems: "center",
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(58,50,74,0.09)",
    borderRadius: ihubRadii.lg,
    borderWidth: 1,
    paddingHorizontal: 14,
    paddingVertical: 13,
  },
  requestEntryText: {
    color: ihubColors.lavender,
    fontSize: 12.5,
    fontWeight: "900",
  },
  loadingRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
  },
  inlineNotice: {
    color: ihubColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
  },
  inlineNoticeStrong: {
    backgroundColor: "rgba(168,212,230,0.18)",
    borderRadius: ihubRadii.md,
    color: ihubColors.ink,
    fontSize: 11.5,
    fontWeight: "900",
    lineHeight: 18,
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  inlineError: {
    color: ihubColors.warn,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
  },
  emptyBox: {
    alignItems: "center",
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: ihubRadii.xl,
    borderStyle: "dashed",
    borderWidth: 1,
    gap: 6,
    padding: 24,
  },
  emptyTitle: {
    color: ihubColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  emptyText: {
    color: ihubColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
    textAlign: "center",
  },
  groupList: {
    gap: 11,
  },
  groupCard: {
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: ihubRadii.xl,
    borderWidth: 1,
    gap: 12,
    padding: 14,
  },
  groupHeader: {
    alignItems: "center",
    flexDirection: "row",
    gap: 11,
  },
  groupCopy: {
    flex: 1,
    minWidth: 0,
  },
  groupTitleRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 6,
  },
  groupName: {
    color: ihubColors.ink,
    flexShrink: 1,
    fontSize: 15,
    fontWeight: "900",
  },
  pendingBadge: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: ihubRadii.pill,
    paddingHorizontal: 7,
    paddingVertical: 2,
  },
  pendingText: {
    color: ihubColors.lavender,
    fontSize: 9,
    fontWeight: "900",
  },
  groupMeta: {
    color: ihubColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 2,
  },
  removeButton: {
    backgroundColor: "rgba(217,130,107,0.12)",
    borderRadius: ihubRadii.pill,
    paddingHorizontal: 10,
    paddingVertical: 7,
  },
  removeButtonText: {
    color: ihubColors.warn,
    fontSize: 10.5,
    fontWeight: "900",
  },
  memberWrap: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 7,
  },
  memberChip: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.12)",
    borderColor: "rgba(166,149,216,0.24)",
    borderRadius: ihubRadii.pill,
    borderWidth: 1,
    flexDirection: "row",
    gap: 5,
    paddingHorizontal: 10,
    paddingVertical: 7,
  },
  memberText: {
    color: ihubColors.ink,
    fontSize: 11.5,
    fontWeight: "900",
  },
  memberDelete: {
    color: ihubColors.warn,
    fontSize: 12,
    fontWeight: "900",
  },
  addMemberChip: {
    borderColor: "rgba(58,50,74,0.20)",
    borderRadius: ihubRadii.pill,
    borderStyle: "dashed",
    borderWidth: 1,
    paddingHorizontal: 11,
    paddingVertical: 7,
  },
  addMemberText: {
    color: ihubColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "900",
  },
  memberAddBox: {
    backgroundColor: ihubColors.background,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: ihubRadii.lg,
    borderWidth: 1,
    gap: 10,
    padding: 12,
  },
  memberAddTitle: {
    color: ihubColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
  },
  availableMemberChip: {
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: ihubRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 11,
    paddingVertical: 7,
  },
  availableMemberText: {
    color: ihubColors.ink,
    fontSize: 11.5,
    fontWeight: "900",
  },
  memberRequestButton: {
    alignItems: "center",
    borderTopColor: "rgba(58,50,74,0.08)",
    borderTopWidth: 1,
    paddingTop: 10,
  },
  memberRequestText: {
    color: ihubColors.lavender,
    fontSize: 11.5,
    fontWeight: "900",
  },
  noMemberText: {
    color: ihubColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 18,
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
  masterModal: {
    backgroundColor: ihubColors.background,
    borderColor: "rgba(255,255,255,0.72)",
    borderRadius: 28,
    borderWidth: 1,
    maxHeight: "82%",
    padding: 16,
    width: "100%",
    ...ihubShadow,
  },
  requestModal: {
    backgroundColor: ihubColors.background,
    borderColor: "rgba(255,255,255,0.72)",
    borderRadius: 28,
    borderWidth: 1,
    gap: 12,
    padding: 16,
    width: "100%",
    ...ihubShadow,
  },
  modalHeader: {
    alignItems: "center",
    flexDirection: "row",
    gap: 9,
    marginBottom: 12,
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
  modalRequestButton: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: ihubRadii.pill,
    paddingHorizontal: 11,
    paddingVertical: 8,
  },
  modalRequestText: {
    color: ihubColors.lavender,
    fontSize: 10.5,
    fontWeight: "900",
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
  searchInput: {
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: ihubRadii.lg,
    borderWidth: 1,
    color: ihubColors.ink,
    fontSize: 13,
    fontWeight: "800",
    minHeight: 48,
    paddingHorizontal: 14,
  },
  noteInput: {
    minHeight: 92,
    paddingTop: 12,
  },
  genreTabs: {
    flexDirection: "row",
    gap: 7,
    paddingVertical: 10,
  },
  filterChip: {
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: ihubRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 11,
    paddingVertical: 7,
  },
  filterChipActive: {
    backgroundColor: ihubColors.lavender,
    borderColor: ihubColors.lavender,
  },
  filterChipText: {
    color: ihubColors.ink,
    fontSize: 11,
    fontWeight: "900",
  },
  filterChipTextActive: {
    color: ihubColors.surface,
  },
  masterList: {
    gap: 9,
    paddingBottom: 4,
  },
  masterRow: {
    alignItems: "center",
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: ihubRadii.lg,
    borderWidth: 1,
    flexDirection: "row",
    gap: 11,
    padding: 11,
  },
  masterRowSelected: {
    opacity: 0.52,
  },
  masterCopy: {
    flex: 1,
    minWidth: 0,
  },
  masterName: {
    color: ihubColors.ink,
    fontSize: 13.5,
    fontWeight: "900",
  },
  masterMeta: {
    color: ihubColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 2,
  },
  masterAdd: {
    color: ihubColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  masterAdded: {
    color: ihubColors.mutedInk,
  },
  modalEmpty: {
    gap: 10,
    paddingVertical: 24,
  },
});
