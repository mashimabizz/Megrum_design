import { useEffect, useState } from "react";
import { router } from "expo-router";
import {
  ActivityIndicator,
  Modal,
  Platform,
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
import { megrumColors, megrumRadii } from "../../src/theme/tokens";

type Member = {
  id: string;
  name: string;
};

type PendingMember = {
  id: string;
  name: string;
  mine: boolean;
};

type Section = {
  key: string;
  groupId: string | null;
  requestId: string | null;
  groupName: string;
  isPending: boolean;
  members: Member[];
  pendingMembers: PendingMember[];
  initialMemberIds: string[];
  initialRequestIds: string[];
  initialBox: boolean;
};

type Selection = {
  box: boolean;
  memberIds: string[];
  requestIds: string[];
};

export default function OnboardingMembersScreen() {
  const { user } = useAuth();
  const [sections, setSections] = useState<Section[]>([]);
  const [selection, setSelection] = useState<Record<string, Selection>>({});
  const [loading, setLoading] = useState(true);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [requestTarget, setRequestTarget] = useState<Section | null>(null);
  const [requestName, setRequestName] = useState("");
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
        .from("user_oshi")
        .select("id, group_id, oshi_request_id, character_id, character_request_id, kind, priority, group:groups_master(id, name), oshi_request:oshi_requests(id, requested_name)")
        .eq("user_id", user.id)
        .order("priority", { ascending: true }),
      supabase
        .from("characters_master")
        .select("id, group_id, name, display_order")
        .order("display_order", { ascending: true }),
      supabase
        .from("character_requests")
        .select("id, group_id, oshi_request_id, requested_name, user_id, created_at")
        .eq("status", "pending")
        .order("created_at", { ascending: false }),
    ])
      .then(([oshiRes, charsRes, requestRes]) => {
        if (!active) return;
        const rows = (oshiRes.data as Record<string, unknown>[] | null) ?? [];
        if (rows.length === 0) {
          router.replace("/onboarding/oshi");
          return;
        }
        const charsByGroup = new Map<string, Member[]>();
        for (const char of (charsRes.data as Record<string, unknown>[] | null) ?? []) {
          const groupId = typeof char.group_id === "string" ? char.group_id : null;
          if (!groupId) continue;
          const arr = charsByGroup.get(groupId) ?? [];
          arr.push({ id: String(char.id), name: String(char.name ?? "") });
          charsByGroup.set(groupId, arr);
        }

        const pendingByGroup = new Map<string, PendingMember[]>();
        const pendingByOshiRequest = new Map<string, PendingMember[]>();
        for (const request of (requestRes.data as Record<string, unknown>[] | null) ?? []) {
          const item: PendingMember = {
            id: String(request.id),
            name: String(request.requested_name ?? ""),
            mine: request.user_id === user.id,
          };
          const groupId = typeof request.group_id === "string" ? request.group_id : null;
          const oshiRequestId =
            typeof request.oshi_request_id === "string" ? request.oshi_request_id : null;
          if (groupId) {
            const arr = pendingByGroup.get(groupId) ?? [];
            arr.push(item);
            pendingByGroup.set(groupId, arr);
          } else if (oshiRequestId) {
            const arr = pendingByOshiRequest.get(oshiRequestId) ?? [];
            arr.push(item);
            pendingByOshiRequest.set(oshiRequestId, arr);
          }
        }

        const sectionMap = new Map<string, Section>();
        for (const row of rows) {
          const key = String(row.group_id ?? row.oshi_request_id ?? "");
          if (!key) continue;
          const group = pickRelation(row.group as RelationName | undefined);
          const request = pickRequest(row.oshi_request as RequestRelation | undefined);
          const existing = sectionMap.get(key);
          if (existing) {
            if (typeof row.character_id === "string") {
              existing.initialMemberIds.push(row.character_id);
              existing.initialBox = false;
            }
            if (typeof row.character_request_id === "string") {
              existing.initialRequestIds.push(row.character_request_id);
              existing.initialBox = false;
            }
            continue;
          }
          const groupId = typeof row.group_id === "string" ? row.group_id : null;
          const requestId =
            typeof row.oshi_request_id === "string" ? row.oshi_request_id : null;
          sectionMap.set(key, {
            key,
            groupId,
            requestId,
            groupName: group?.name ?? request?.requested_name ?? "推し",
            isPending: !!requestId,
            members: groupId ? charsByGroup.get(groupId) ?? [] : [],
            pendingMembers: groupId
              ? pendingByGroup.get(groupId) ?? []
              : requestId
                ? pendingByOshiRequest.get(requestId) ?? []
                : [],
            initialMemberIds:
              typeof row.character_id === "string" ? [row.character_id] : [],
            initialRequestIds:
              typeof row.character_request_id === "string"
                ? [row.character_request_id]
                : [],
            initialBox: row.kind !== "specific" && row.kind !== "multi",
          });
        }

        const nextSections = Array.from(sectionMap.values());
        const nextSelection: Record<string, Selection> = {};
        for (const section of nextSections) {
          nextSelection[section.key] = {
            box:
              section.initialBox &&
              section.initialMemberIds.length === 0 &&
              section.initialRequestIds.length === 0,
            memberIds: section.initialMemberIds,
            requestIds: section.initialRequestIds,
          };
        }
        setSections(nextSections);
        setSelection(nextSelection);
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

  function setBox(sectionKey: string) {
    setSelection((prev) => ({
      ...prev,
      [sectionKey]: { box: true, memberIds: [], requestIds: [] },
    }));
  }

  function toggleMember(sectionKey: string, memberId: string) {
    setSelection((prev) => {
      const current = prev[sectionKey] ?? { box: true, memberIds: [], requestIds: [] };
      const nextIds = current.memberIds.includes(memberId)
        ? current.memberIds.filter((id) => id !== memberId)
        : [...current.memberIds, memberId];
      return {
        ...prev,
        [sectionKey]: {
          box: nextIds.length === 0 && current.requestIds.length === 0,
          memberIds: nextIds,
          requestIds: current.requestIds,
        },
      };
    });
  }

  function toggleRequest(sectionKey: string, requestId: string) {
    setSelection((prev) => {
      const current = prev[sectionKey] ?? { box: true, memberIds: [], requestIds: [] };
      const nextIds = current.requestIds.includes(requestId)
        ? current.requestIds.filter((id) => id !== requestId)
        : [...current.requestIds, requestId];
      return {
        ...prev,
        [sectionKey]: {
          box: current.memberIds.length === 0 && nextIds.length === 0,
          memberIds: current.memberIds,
          requestIds: nextIds,
        },
      };
    });
  }

  function openRequest(section: Section) {
    setRequestTarget(section);
    setRequestName("");
    setRequestNote("");
    setError(null);
  }

  function closeRequest() {
    if (requestPending) return;
    setRequestTarget(null);
    setRequestName("");
    setRequestNote("");
  }

  async function submitRequest() {
    if (!user || !supabase) {
      router.replace("/login");
      return;
    }
    if (!requestTarget) return;
    const name = requestName.trim();
    if (!name) {
      setError("メンバー名を入力してください");
      return;
    }
    setRequestPending(true);
    setError(null);
    const { data, error: insertError } = await supabase
      .from("character_requests")
      .insert({
        user_id: user.id,
        group_id: requestTarget.groupId,
        oshi_request_id: requestTarget.groupId ? null : requestTarget.requestId,
        requested_name: name,
        note: requestNote.trim() || null,
      })
      .select("id, requested_name, user_id")
      .single();
    setRequestPending(false);
    if (insertError) {
      setError(insertError.message);
      return;
    }
    const row = data as Record<string, unknown>;
    const next: PendingMember = {
      id: String(row.id),
      name: String(row.requested_name ?? name),
      mine: true,
    };
    setSections((current) =>
      current.map((section) =>
        section.key === requestTarget.key
          ? { ...section, pendingMembers: [next, ...section.pendingMembers] }
          : section,
      ),
    );
    setSelection((current) => {
      const prev = current[requestTarget.key] ?? {
        box: true,
        memberIds: [],
        requestIds: [],
      };
      return {
        ...current,
        [requestTarget.key]: {
          box: false,
          memberIds: prev.memberIds,
          requestIds: [...new Set([next.id, ...prev.requestIds])],
        },
      };
    });
    closeRequest();
  }

  async function save() {
    if (!user || !supabase) {
      router.replace("/login");
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

    const rows: Record<string, unknown>[] = [];
    let priority = 1;
    for (const section of sections) {
      const current = selection[section.key] ?? { box: true, memberIds: [], requestIds: [] };
      const totalSelections = current.memberIds.length + current.requestIds.length;
      if (current.box || totalSelections === 0) {
        rows.push({
          user_id: user.id,
          group_id: section.groupId,
          oshi_request_id: section.requestId,
          kind: "box",
          priority: priority++,
        });
      } else {
        const kind = totalSelections > 1 ? "multi" : "specific";
        for (const character_id of current.memberIds) {
          rows.push({
            user_id: user.id,
            group_id: section.groupId,
            character_id,
            kind,
            priority: priority++,
          });
        }
        for (const character_request_id of current.requestIds) {
          rows.push({
            user_id: user.id,
            group_id: section.groupId,
            oshi_request_id: section.requestId,
            character_request_id,
            kind,
            priority: priority++,
          });
        }
      }
    }

    const { error: insertError } = await supabase.from("user_oshi").insert(rows);
    setPending(false);
    if (insertError) {
      setError(insertError.message);
      return;
    }
    router.push("/onboarding/area");
  }

  return (
    <Screen contentStyle={styles.screen}>
      <Header title="プロフィール設定" sub="推しメン・推しキャラ" progress="3/4" backTo="/onboarding/oshi" />
      <ProgressDots current={2} />
      <Text style={styles.title}>メンバーは？</Text>
      <Text style={styles.copy}>推しごとに「箱推し」または個別メンバーを選択できます</Text>
      {loading ? <ActivityIndicator color={megrumColors.lavender} /> : null}
      <View style={styles.sections}>
        {sections.map((section) => {
          const current = selection[section.key] ?? { box: true, memberIds: [], requestIds: [] };
          return (
            <View key={section.key} style={styles.sectionCard}>
              <View style={styles.sectionHeader}>
                <View style={styles.sectionCopy}>
                  <Text style={styles.groupName}>{section.groupName}</Text>
                  <Text style={styles.groupMeta}>
                    {section.isPending
                      ? "承認待ち・メンバーは追加リクエストで仮登録"
                      : section.members.length > 0
                        ? `${section.members.length}人から選択`
                        : "メンバーデータ準備中"}
                  </Text>
                </View>
              </View>
              <View style={styles.memberWrap}>
                <Chip label="箱推し（メンバー全員）" active={current.box} onPress={() => setBox(section.key)} />
                {section.members.map((member) => (
                  <Chip
                    key={member.id}
                    label={member.name}
                    active={current.memberIds.includes(member.id)}
                    onPress={() => toggleMember(section.key, member.id)}
                  />
                ))}
                {section.pendingMembers.map((member) => (
                  <Chip
                    key={member.id}
                    label={`🕐 ${member.name}${member.mine ? "（自分）" : ""}`}
                    active={current.requestIds.includes(member.id)}
                    pending
                    onPress={() => toggleRequest(section.key, member.id)}
                  />
                ))}
              </View>
              <Pressable onPress={() => openRequest(section)} style={styles.requestButton}>
                <Text style={styles.requestButtonText}>
                  + メンバーが見つからない場合は追加リクエスト
                </Text>
              </Pressable>
            </View>
          );
        })}
      </View>
      {error ? <Text style={styles.error}>{error}</Text> : null}
      <View style={styles.footer}>
        <PrimaryButton loading={pending} disabled={sections.length === 0} onPress={save}>
          次へ
        </PrimaryButton>
      </View>
      <Modal
        animationType={Platform.OS === "ios" ? "slide" : "fade"}
        presentationStyle={Platform.OS === "ios" ? "pageSheet" : "overFullScreen"}
        transparent={Platform.OS !== "ios"}
        visible={!!requestTarget}
        onRequestClose={closeRequest}
      >
        <View style={[styles.modalLayer, Platform.OS === "ios" ? styles.nativeSheetLayer : null]}>
          {Platform.OS !== "ios" ? <Pressable style={styles.modalBackdrop} onPress={closeRequest} /> : null}
          <View style={[styles.requestModal, Platform.OS === "ios" ? styles.nativeRequestModal : null]}>
            <View style={styles.modalHeader}>
              <View style={styles.modalTitleCopy}>
                <Text style={styles.modalTitle}>メンバー追加リクエスト</Text>
                <Text style={styles.modalSub}>
                  {requestTarget?.groupName ?? "推し"}に仮登録します
                </Text>
              </View>
              <Pressable onPress={closeRequest} style={styles.modalCloseButton}>
                <Text style={styles.modalCloseText}>×</Text>
              </Pressable>
            </View>
            <TextInput
              value={requestName}
              onChangeText={setRequestName}
              placeholder="メンバー / キャラクター名"
              placeholderTextColor="rgba(58,50,74,0.38)"
              style={styles.requestInput}
            />
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
type RequestRelation = { id?: string | null; requested_name?: string | null } | { id?: string | null; requested_name?: string | null }[] | null;

function pickRelation(value: RelationName | undefined) {
  if (!value) return null;
  return Array.isArray(value) ? value[0] ?? null : value;
}

function pickRequest(value: RequestRelation | undefined) {
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

function Chip({
  label,
  active,
  pending,
  onPress,
}: {
  label: string;
  active: boolean;
  pending?: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={[
        styles.chip,
        pending ? styles.chipPending : null,
        active ? styles.chipActive : null,
      ]}
    >
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
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  backText: {
    color: megrumColors.ink,
    fontSize: 30,
    fontWeight: "800",
    lineHeight: 32,
  },
  headerCopy: {
    flex: 1,
  },
  headerTitle: {
    color: megrumColors.ink,
    fontSize: 17,
    fontWeight: "900",
  },
  headerSub: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 2,
  },
  progressText: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: megrumRadii.pill,
    color: megrumColors.lavender,
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
    backgroundColor: megrumColors.lavender,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 22,
    fontWeight: "900",
    lineHeight: 28,
  },
  copy: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 19,
  },
  sections: {
    gap: 12,
  },
  sectionCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 13,
    padding: 14,
  },
  sectionHeader: {
    alignItems: "center",
    flexDirection: "row",
    gap: 11,
  },
  sectionCopy: {
    flex: 1,
  },
  groupName: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  groupMeta: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 3,
  },
  memberWrap: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  chip: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.12)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1.5,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  chipPending: {
    borderColor: "rgba(166,149,216,0.52)",
    borderStyle: "dashed",
  },
  chipActive: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderColor: megrumColors.lavender,
  },
  chipText: {
    color: megrumColors.ink,
    fontSize: 11.5,
    fontWeight: "900",
  },
  chipTextActive: {
    color: megrumColors.lavender,
  },
  requestButton: {
    alignSelf: "flex-start",
    backgroundColor: "rgba(166,149,216,0.10)",
    borderColor: "rgba(166,149,216,0.28)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  requestButtonText: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  error: {
    color: megrumColors.warn,
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
  nativeSheetLayer: {
    alignItems: "stretch",
    backgroundColor: megrumColors.background,
    justifyContent: "flex-start",
    padding: 16,
  },
  requestModal: {
    backgroundColor: megrumColors.background,
    borderColor: "rgba(255,255,255,0.72)",
    borderRadius: 28,
    borderWidth: 1,
    gap: 12,
    padding: 16,
    width: "100%",
  },
  nativeRequestModal: {
    borderRadius: 0,
    borderWidth: 0,
    paddingHorizontal: 0,
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
    color: megrumColors.ink,
    fontSize: 17,
    fontWeight: "900",
  },
  modalSub: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 2,
  },
  modalCloseButton: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: megrumRadii.pill,
    height: 34,
    justifyContent: "center",
    width: 34,
  },
  modalCloseText: {
    color: megrumColors.mutedInk,
    fontSize: 20,
    fontWeight: "900",
    lineHeight: 22,
  },
  requestInput: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    color: megrumColors.ink,
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
