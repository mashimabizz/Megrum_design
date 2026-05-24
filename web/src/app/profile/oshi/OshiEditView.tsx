"use client";

import {
  useEffect,
  useMemo,
  useRef,
  useState,
  type Dispatch,
  type FormEvent,
  type SetStateAction,
} from "react";
import { createPortal } from "react-dom";
import { useRouter } from "next/navigation";
import {
  addOshiGroup,
  addCharacterToOshi,
  requestCharacterAndAddToProfile,
  requestOshiAndAddToProfile,
  removeCharacterFromOshi,
  removeOshiGroup,
} from "@/app/profile/actions";
import { PrimaryButton } from "@/components/auth/PrimaryButton";

type GroupSource = "master" | "request";
type MemberSource = "master" | "request";
type OshiMember = {
  id: string;
  name: string;
  source: MemberSource;
};

type Group = {
  groupId: string;
  source: GroupSource;
  groupName: string;
  priority: number;
  members: OshiMember[];
  availableCharacters: { id: string; name: string }[];
};

type ActionResult = { error?: string } | undefined;
type OshiMutation = () => Promise<ActionResult>;
type GenreOption = { id: string; name: string };
type OshiRequestKind = "group" | "work" | "solo";
type RequestModalState =
  | { type: "oshi"; initialName?: string }
  | {
      type: "member";
      groupName: string;
      groupId?: string;
      oshiRequestId?: string;
    };
type RequestDonePayload =
  | { type: "oshi"; requestId: string; name: string }
  | {
      type: "member";
      requestId: string;
      name: string;
      groupId?: string;
      oshiRequestId?: string;
    };
type OshiMasterOption = {
  id: string;
  name: string;
  aliases: string[];
  kind: OshiRequestKind;
  displayOrder: number;
  genreId: string;
  genreName: string;
  genreKind: "idol" | "anime" | "game" | "other";
  characters: { id: string; name: string }[];
};

const REQUEST_KINDS: { value: OshiRequestKind; label: string }[] = [
  { value: "group", label: "グループ" },
  { value: "work", label: "作品" },
  { value: "solo", label: "ソロ" },
];

/**
 * 推し設定編集（モックアップ account-extras.jsx::OshiEdit ベース・案 Z）
 *
 * - グループ削除
 * - メンバー削除（各 chip の ×）
 * - メンバー追加（同グループの未選択キャラを inline 展開）
 * - 登録済みマスタからの推し追加 → 画面内モーダルで検索・選択
 * - 推し / メンバー追加リクエスト（マスタにない）→ 画面内モーダルで送信
 */
export function OshiEditView({
  oshiGroups,
  initialRequestModal = false,
  genreOptions,
  masterOptions,
}: {
  oshiGroups: Group[];
  initialRequestModal?: boolean;
  genreOptions: GenreOption[];
  masterOptions: OshiMasterOption[];
}) {
  const router = useRouter();
  const [groups, setGroups] = useState<Group[]>(oshiGroups);
  const [mutationError, setMutationError] = useState<string | null>(null);
  const [requestNotice, setRequestNotice] = useState<string | null>(null);
  const [requestModal, setRequestModal] = useState<RequestModalState | null>(
    initialRequestModal ? { type: "oshi" } : null,
  );
  const [masterModalOpen, setMasterModalOpen] = useState(false);
  const mutationQueueRef = useRef<Promise<void>>(Promise.resolve());
  const pendingMutationsRef = useRef(0);
  const selectedMasterGroupIds = useMemo(
    () =>
      new Set(
        groups.filter((g) => g.source === "master").map((g) => g.groupId),
      ),
    [groups],
  );
  const nextLocalGroupPriority = () =>
    Math.max(0, ...groups.map((group) => group.priority)) + 1;

  useEffect(() => {
    if (pendingMutationsRef.current === 0) {
      setGroups(oshiGroups);
    }
  }, [oshiGroups]);

  useEffect(() => {
    if (initialRequestModal) router.replace("/profile/oshi", { scroll: false });
  }, [initialRequestModal, router]);

  function enqueueMutation(
    task: OshiMutation,
    onRollback?: (error: Error) => void,
  ) {
    setMutationError(null);
    pendingMutationsRef.current += 1;

    const run = mutationQueueRef.current.then(async () => {
      const result = await task();
      if (result?.error) {
        throw new Error(result.error);
      }
    });

    const tracked = run
      .catch((error) => {
        const normalized =
          error instanceof Error
            ? error
            : new Error("推し設定の保存に失敗しました");
        onRollback?.(normalized);
        setMutationError(normalized.message);
      })
      .finally(() => {
        pendingMutationsRef.current = Math.max(
          0,
          pendingMutationsRef.current - 1,
        );
        if (pendingMutationsRef.current === 0) {
          router.refresh();
        }
      });

    mutationQueueRef.current = tracked.then(() => undefined);
  }

  function openOshiRequest(initialName?: string) {
    setRequestNotice(null);
    setRequestModal({ type: "oshi", initialName });
  }

  function openMemberRequest(
    group: Pick<Group, "groupId" | "groupName" | "source">,
  ) {
    setRequestNotice(null);
    setRequestModal({
      type: "member",
      groupId: group.source === "master" ? group.groupId : undefined,
      oshiRequestId: group.source === "request" ? group.groupId : undefined,
      groupName: group.groupName,
    });
  }

  function handleRequestDone(payload: RequestDonePayload) {
    setRequestModal(null);
    if (payload.type === "oshi") {
      setGroups((prev) => {
        if (
          prev.some(
            (g) => g.source === "request" && g.groupId === payload.requestId,
          )
        ) {
          return prev;
        }
        return [
          ...prev,
          {
            groupId: payload.requestId,
            source: "request",
            groupName: payload.name,
            priority: Math.max(0, ...prev.map((group) => group.priority)) + 1,
            members: [],
            availableCharacters: [],
          },
        ];
      });
      setRequestNotice("推し追加リクエストを送信し、推し設定に仮登録しました。");
    } else {
      setGroups((prev) =>
        prev.map((group) => {
          const sameParent = payload.groupId
            ? group.source === "master" && group.groupId === payload.groupId
            : group.source === "request" &&
              group.groupId === payload.oshiRequestId;
          if (!sameParent) return group;
          if (group.members.some((member) => member.id === payload.requestId)) {
            return group;
          }
          return {
            ...group,
            members: [
              ...group.members,
              {
                id: payload.requestId,
                name: payload.name,
                source: "request",
              },
            ],
          };
        }),
      );
      setRequestNotice(
        "メンバー追加リクエストを送信し、推しメンバーに仮登録しました。",
      );
    }
    router.refresh();
  }

  function handleAddMasterOptions(options: OshiMasterOption[]) {
    const addableOptions = options.filter(
      (option) => !selectedMasterGroupIds.has(option.id),
    );
    if (addableOptions.length === 0) {
      setMasterModalOpen(false);
      return;
    }

    const basePriority = nextLocalGroupPriority();
    const rollbackIds = new Set(addableOptions.map((option) => option.id));
    const nextGroups: Group[] = addableOptions.map((option, index) => ({
      groupId: option.id,
      source: "master",
      groupName: option.name,
      priority: basePriority + index,
      members: [],
      availableCharacters: option.characters,
    }));

    setGroups((prev) => {
      const existingIds = new Set(
        prev.filter((g) => g.source === "master").map((g) => g.groupId),
      );
      return [
        ...prev,
        ...nextGroups.filter((group) => !existingIds.has(group.groupId)),
      ];
    });
    setMasterModalOpen(false);
    setRequestNotice(null);

    enqueueMutation(
      async () => {
        for (const option of addableOptions) {
          const result = await addOshiGroup(option.id);
          if (result?.error) return result;
        }
        return undefined;
      },
      () => {
        setGroups((prev) =>
          prev.filter((g) => g.source !== "master" || !rollbackIds.has(g.groupId)),
        );
      },
    );
  }

  return (
    <div className="space-y-3.5">
      {/* 説明バナー */}
      <div className="rounded-xl border border-[#a695d833] bg-[#a695d810] px-3.5 py-3 text-[12px] leading-[1.6] text-[#3a324a]">
        推しを追加すると、マッチング・コレクション・ホームの基準が更新されます。
      </div>
      {mutationError && (
        <div className="rounded-xl border border-red-200 bg-red-50 px-3.5 py-2.5 text-[11.5px] leading-relaxed text-red-700">
          {mutationError}
        </div>
      )}
      {requestNotice && (
        <div className="rounded-xl border border-[#a8d4e655] bg-[#a8d4e61a] px-3.5 py-2.5 text-[11.5px] font-semibold leading-relaxed text-[#3a324a]">
          {requestNotice}
        </div>
      )}

      {/* グループ一覧 */}
      {groups.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-[#3a324a14] bg-white py-8 text-center text-[12px] text-[#3a324a8c]">
          推しがまだ設定されていません
          <br />
          <button
            type="button"
            onClick={() => setMasterModalOpen(true)}
            className="mt-2 inline-block font-bold text-[#a695d8]"
          >
            + 登録済みの推しを追加 →
          </button>
          <button
            type="button"
            onClick={() => openOshiRequest()}
            className="mt-2 block w-full font-bold text-[#a695d8]"
          >
            マスタに無い推しを追加リクエスト
          </button>
        </div>
      ) : (
        groups.map((g) => (
          <GroupCard
            key={`${g.source}:${g.groupId}`}
            group={g}
            setGroups={setGroups}
            enqueueMutation={enqueueMutation}
            onMemberRequest={openMemberRequest}
          />
        ))
      )}

      {/* + 推しを追加（グループ） */}
      <button
        type="button"
        onClick={() => setMasterModalOpen(true)}
        className="block w-full rounded-[14px] border-[1.5px] border-dashed border-[#a695d855] bg-white px-4 py-4 text-center text-[13px] font-bold text-[#a695d8] transition-all active:scale-[0.99]"
      >
        ＋ 登録済みの推しを追加（グループ・作品）
      </button>
      <button
        type="button"
        onClick={() => openOshiRequest()}
        className="block w-full rounded-[14px] border border-[#3a324a14] bg-white px-4 py-3.5 text-center text-[12.5px] font-bold text-[#a695d8] transition-all active:scale-[0.99]"
      >
        マスタに無い推しを追加リクエスト
      </button>

      {requestModal && (
        <RequestModal
          state={requestModal}
          genres={genreOptions}
          onClose={() => setRequestModal(null)}
          onDone={handleRequestDone}
        />
      )}
      {masterModalOpen && (
        <MasterSelectModal
          genres={genreOptions}
          options={masterOptions}
          selectedGroupIds={selectedMasterGroupIds}
          onSelect={handleAddMasterOptions}
          onRequest={(name) => {
            setMasterModalOpen(false);
            openOshiRequest(name);
          }}
          onClose={() => setMasterModalOpen(false)}
        />
      )}
    </div>
  );
}

/* ─── Group Card ─────────────────────────────────────────── */

function GroupCard({
  group,
  setGroups,
  enqueueMutation,
  onMemberRequest,
}: {
  group: Group;
  setGroups: Dispatch<SetStateAction<Group[]>>;
  enqueueMutation: (
    task: OshiMutation,
    onRollback?: (error: Error) => void,
  ) => void;
  onMemberRequest: (
    group: Pick<Group, "groupId" | "groupName" | "source">,
  ) => void;
}) {
  const [showAddChars, setShowAddChars] = useState(false);

  function handleRemoveGroup() {
    if (
      !confirm(
        `「${group.groupName}」を推しリストから削除しますか？\n（メンバー指定もすべて解除されます）`,
      )
    )
      return;

    let previousIndex = 0;
    const snapshot = group;
    setGroups((prev) => {
      previousIndex = Math.max(
        0,
        prev.findIndex(
          (g) => g.source === group.source && g.groupId === group.groupId,
        ),
      );
      return prev.filter(
        (g) => g.source !== group.source || g.groupId !== group.groupId,
      );
    });

    enqueueMutation(
      () =>
        removeOshiGroup({
          groupId: group.source === "master" ? group.groupId : undefined,
          oshiRequestId:
            group.source === "request" ? group.groupId : undefined,
        }),
      () => {
        setGroups((prev) => {
          if (
            prev.some(
              (g) => g.source === snapshot.source && g.groupId === snapshot.groupId,
            )
          ) {
            return prev;
          }
          const next = [...prev];
          next.splice(previousIndex, 0, snapshot);
          return next;
        });
      },
    );
  }

  function handleRemoveMember(member: OshiMember) {
    setGroups((prev) =>
      prev.map((g) => {
        if (g.source !== group.source || g.groupId !== group.groupId) return g;
        const availableCharacters =
          member.source === "master" &&
          !g.availableCharacters.some((c) => c.id === member.id)
            ? sortCharacters([
                ...g.availableCharacters,
                { id: member.id, name: member.name },
              ])
            : g.availableCharacters;
        return {
          ...g,
          members: g.members.filter((m) => m.id !== member.id),
          availableCharacters,
        };
      }),
    );

    enqueueMutation(
      () =>
        removeCharacterFromOshi({
          groupId: group.source === "master" ? group.groupId : undefined,
          oshiRequestId:
            group.source === "request" ? group.groupId : undefined,
          characterId: member.source === "master" ? member.id : undefined,
          characterRequestId:
            member.source === "request" ? member.id : undefined,
        }),
      () => {
        setGroups((prev) =>
          prev.map((g) => {
            if (g.source !== group.source || g.groupId !== group.groupId) return g;
            return {
              ...g,
              members: g.members.some((m) => m.id === member.id)
                ? g.members
                : [...g.members, member],
              availableCharacters:
                member.source === "master"
                  ? g.availableCharacters.filter((c) => c.id !== member.id)
                  : g.availableCharacters,
            };
          }),
        );
      },
    );
  }

  function handleAddMember(characterId: string) {
    if (group.source !== "master") return;
    const character = group.availableCharacters.find(
      (c) => c.id === characterId,
    );
    if (!character) return;

    setGroups((prev) =>
      prev.map((g) => {
        if (g.source !== group.source || g.groupId !== group.groupId) return g;
        return {
          ...g,
          members: g.members.some((m) => m.id === character.id)
            ? g.members
            : [...g.members, { ...character, source: "master" }],
          availableCharacters: g.availableCharacters.filter(
            (c) => c.id !== character.id,
          ),
        };
      }),
    );

    enqueueMutation(
      () =>
        addCharacterToOshi({
          groupId: group.groupId,
          characterId,
        }),
      () => {
        setGroups((prev) =>
          prev.map((g) => {
            if (g.source !== group.source || g.groupId !== group.groupId) return g;
            const availableCharacters = g.availableCharacters.some(
              (c) => c.id === character.id,
            )
              ? g.availableCharacters
              : sortCharacters([...g.availableCharacters, character]);
            return {
              ...g,
              members: g.members.filter((m) => m.id !== character.id),
              availableCharacters,
            };
          }),
        );
      },
    );
  }

  return (
    <div className="overflow-hidden rounded-[14px] border border-[#3a324a0f] bg-white">
      {/* ヘッダー */}
      <div className="flex items-center gap-3 border-b border-[#3a324a0f] px-4 py-3.5">
        <div className="flex-1 min-w-0">
          <div className="flex min-w-0 items-center gap-1.5">
            <div className="truncate text-[14px] font-bold text-gray-900">
              {group.groupName}
            </div>
            {group.source === "request" && (
              <span className="flex-shrink-0 rounded-full bg-[#a695d814] px-2 py-0.5 text-[9.5px] font-extrabold text-[#a695d8]">
                承認待ち
              </span>
            )}
          </div>
          <div className="mt-0.5 text-[11px] text-[#3a324a8c]">
            {group.members.length === 0
              ? "箱推し（メンバー指定なし）"
              : `推しメンバー ${group.members.length}人`}
          </div>
        </div>
        <button
          type="button"
          onClick={handleRemoveGroup}
          className="rounded-[10px] border border-[#3a324a14] bg-transparent px-3 py-1.5 text-[11px] font-semibold text-[#3a324a8c] transition-all active:scale-[0.97]"
        >
          削除
        </button>
      </div>

      {/* 推しメンバー chip 群 */}
      <div className="px-4 py-3">
        <div className="mb-1.5 text-[11px] font-bold text-[#3a324a8c]">
          推しメンバー・推しキャラ ({group.members.length})
        </div>
        <div className="flex flex-wrap gap-1.5">
          {group.members.map((m) => (
            <button
              key={m.id}
              type="button"
              onClick={() => handleRemoveMember(m)}
              className="inline-flex items-center gap-1.5 rounded-full bg-[#a695d814] px-3 py-1 text-[12px] font-bold text-[#a695d8] transition-all active:scale-[0.97]"
              title="タップで削除"
            >
              {m.name}
              {m.source === "request" && (
                <span className="rounded-full bg-white/70 px-1.5 py-0.5 text-[9px] font-extrabold text-[#a695d8]">
                  承認待ち
                </span>
              )}
              <span className="text-[14px] leading-none text-[#3a324a8c]">×</span>
            </button>
          ))}

          {/* + 追加 chip */}
          <button
            type="button"
            onClick={() => setShowAddChars((v) => !v)}
            className="inline-flex items-center gap-1 rounded-full border border-dashed border-[#3a324a30] bg-transparent px-3 py-1 text-[12px] font-medium text-[#3a324a8c]"
          >
            {showAddChars ? "閉じる" : "+ 追加"}
          </button>
        </div>

        {/* メンバー追加 inline */}
        {showAddChars && (
          <div className="mt-3 rounded-xl border border-[#3a324a0f] bg-[#fbf9fc] p-3">
            {group.availableCharacters.length === 0 ? (
              <div className="text-[11.5px] text-[#3a324a8c]">
                {group.source === "request"
                  ? "承認待ちの推しです。メンバーは追加リクエストで仮登録できます。"
                  : "追加可能なメンバーがマスタにありません。"}
              </div>
            ) : (
              <>
                <div className="mb-1.5 text-[11px] font-bold text-[#3a324a8c]">
                  追加できるメンバー
                </div>
                <div className="flex flex-wrap gap-1.5">
                  {group.availableCharacters.map((c) => (
                    <button
                      key={c.id}
                      type="button"
                      onClick={() => handleAddMember(c.id)}
                      className="rounded-full border border-[#3a324a14] bg-white px-3 py-1 text-[12px] font-bold text-gray-700 transition-all active:scale-[0.97] hover:border-[#a695d8] hover:text-[#a695d8]"
                    >
                      + {c.name}
                    </button>
                  ))}
                </div>
              </>
            )}
            <div className="mt-3 border-t border-[#3a324a0f] pt-2.5 text-center">
              <button
                type="button"
                onClick={() => onMemberRequest(group)}
                className="text-[11.5px] font-bold text-[#a695d8]"
              >
                マスタに無いメンバーを追加リクエスト
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

/* ─── Master Select Modal ───────────────────────────────────── */

function MasterSelectModal({
  genres,
  options,
  selectedGroupIds,
  onSelect,
  onRequest,
  onClose,
}: {
  genres: GenreOption[];
  options: OshiMasterOption[];
  selectedGroupIds: Set<string>;
  onSelect: (options: OshiMasterOption[]) => void;
  onRequest: (initialName?: string) => void;
  onClose: () => void;
}) {
  const [query, setQuery] = useState("");
  const [activeGenreId, setActiveGenreId] = useState<"all" | string>("all");
  const [draftSelectedIds, setDraftSelectedIds] = useState<string[]>([]);
  const normalizedQuery = query.trim().toLowerCase();
  const filteredOptions = useMemo(() => {
    return options.filter((option) => {
      if (activeGenreId !== "all" && option.genreId !== activeGenreId) {
        return false;
      }
      if (!normalizedQuery) return true;
      const haystacks = [option.name, ...option.aliases].map((value) =>
        value.toLowerCase(),
      );
      return haystacks.some((value) => value.includes(normalizedQuery));
    });
  }, [activeGenreId, normalizedQuery, options]);

  const draftSelectedOptions = useMemo(() => {
    const selectedSet = new Set(draftSelectedIds);
    return options.filter((option) => selectedSet.has(option.id));
  }, [draftSelectedIds, options]);

  function toggleDraftSelection(option: OshiMasterOption) {
    if (selectedGroupIds.has(option.id)) return;
    setDraftSelectedIds((prev) =>
      prev.includes(option.id)
        ? prev.filter((id) => id !== option.id)
        : [...prev, option.id],
    );
  }

  function submitDraftSelection() {
    if (draftSelectedOptions.length === 0) return;
    onSelect(draftSelectedOptions);
    setDraftSelectedIds([]);
  }

  if (typeof document === "undefined") return null;

  const modal = (
    <div
      className="fixed inset-0 z-[118] flex items-center justify-center bg-black/45 px-4 py-6 backdrop-blur-[2px]"
      role="dialog"
      aria-modal="true"
      aria-label="登録済みの推しを追加"
      onClick={onClose}
    >
      <div
        className="relative flex h-[min(78dvh,640px)] max-h-[calc(100dvh-48px)] w-full max-w-[380px] flex-col overflow-hidden rounded-[28px] border border-white/80 bg-[#fbf9fc] shadow-[0_22px_58px_rgba(58,50,74,0.24)]"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex-shrink-0 bg-white px-5 pb-3 pt-4">
          <div className="mb-4 flex items-center gap-3">
            <div className="min-w-0 flex-1">
              <h2 className="text-[17px] font-extrabold text-[#3a324a]">
                登録済みの推しを追加
              </h2>
              <p className="mt-0.5 text-[11px] font-medium text-[#3a324a8c]">
                グループ・作品マスタから選択
              </p>
            </div>
            <button
              type="button"
              onClick={() => onRequest(query.trim() || undefined)}
              className="rounded-full bg-[#a695d814] px-3.5 py-2 text-[11.5px] font-extrabold text-[#a695d8] transition-all active:scale-[0.97]"
            >
              追加リクエスト
            </button>
            <button
              type="button"
              onClick={onClose}
              className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full bg-[#3a324a08] text-[18px] font-bold text-[#3a324a8c] transition-all active:scale-[0.96]"
              aria-label="閉じる"
            >
              ×
            </button>
          </div>

          <div className="flex items-center gap-2 rounded-xl border border-[#3a324a14] bg-white px-3.5 py-3 shadow-[0_6px_16px_rgba(58,50,74,0.05)]">
            <svg
              width="14"
              height="14"
              viewBox="0 0 14 14"
              fill="none"
              stroke="#6b6478"
              strokeWidth="1.4"
            >
              <circle cx="6" cy="6" r="4.5" />
              <path d="M9.5 9.5L13 13" />
            </svg>
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="作品名・グループ名で検索"
              className="min-w-0 flex-1 bg-transparent text-[13px] font-medium text-gray-900 placeholder:text-gray-400 focus:outline-none"
              autoFocus
            />
            {query && (
              <button
                type="button"
                onClick={() => setQuery("")}
                className="flex h-7 w-7 items-center justify-center rounded-full bg-[#3a324a08] text-[15px] font-bold text-[#3a324a8c]"
                aria-label="検索を消す"
              >
                ×
              </button>
            )}
          </div>

          <div className="-mx-5 mt-3 flex gap-1.5 overflow-x-auto px-5 pb-1 [&::-webkit-scrollbar]:hidden">
            <GenreTab
              label="すべて"
              active={activeGenreId === "all"}
              onClick={() => setActiveGenreId("all")}
            />
            {genres.map((genre) => (
              <GenreTab
                key={genre.id}
                label={genre.name}
                active={activeGenreId === genre.id}
                onClick={() => setActiveGenreId(genre.id)}
              />
            ))}
          </div>
        </div>

        <div
          className={`min-h-0 flex-1 space-y-2 overflow-y-auto px-5 py-3 ${
            draftSelectedOptions.length > 0 ? "pb-24" : "pb-4"
          }`}
        >
          {filteredOptions.length > 0 ? (
            filteredOptions.map((option) => {
              const selected = selectedGroupIds.has(option.id);
              const draftSelected = draftSelectedIds.includes(option.id);
              const latin = isLatin(option.name);
              return (
                <button
                  key={option.id}
                  type="button"
                  disabled={selected}
                  onClick={() => toggleDraftSelection(option)}
                  className={`flex w-full items-center gap-3 rounded-2xl border-[1.5px] border-solid px-4 py-3.5 text-left shadow-[0_6px_18px_rgba(58,50,74,0.05)] transition-all duration-150 active:scale-[0.99] disabled:opacity-65 ${
                    selected
                      ? "border-[#a695d833] bg-[#a695d80d]"
                      : draftSelected
                        ? "border-[#a695d8] bg-[#a695d814]"
                      : "border-[#3a324a14] bg-white hover:border-[#a695d855]"
                  }`}
                >
                  <div className="min-w-0 flex-1">
                    <div
                      className="truncate text-[14px] font-extrabold text-[#3a324a]"
                      style={
                        latin
                          ? {
                              fontFamily:
                                "var(--font-inter-tight), system-ui",
                              letterSpacing: "0.2px",
                            }
                          : undefined
                      }
                    >
                      {option.name}
                    </div>
                    <div className="mt-0.5 truncate text-[11px] font-medium text-[#3a324a8c]">
                      {option.genreName}・{kindLabel(option.kind)}
                      {option.kind !== "solo" && option.characters.length > 0
                        ? `・メンバー ${option.characters.length}件`
                        : ""}
                      {selected ? "・設定済み" : ""}
                    </div>
                  </div>
                </button>
              );
            })
          ) : (
            <div className="rounded-2xl border border-dashed border-[#3a324a14] bg-white px-4 py-8 text-center">
              <div className="text-[13px] font-extrabold text-[#3a324a]">
                該当する推しが見つかりません
              </div>
              <p className="mt-2 text-[11.5px] leading-relaxed text-[#3a324a8c]">
                表記ゆれや未登録の可能性があります。
              </p>
              <button
                type="button"
                onClick={() => onRequest(query.trim() || undefined)}
                className="mt-4 inline-flex items-center justify-center rounded-full bg-[#a695d8] px-4 py-2 text-[12px] font-extrabold text-white shadow-[0_8px_18px_rgba(166,149,216,0.32)] transition-all active:scale-[0.97]"
              >
                {query.trim()
                  ? `「${query.trim()}」を追加リクエスト`
                  : "追加リクエストを送る"}
              </button>
            </div>
          )}
        </div>
        {draftSelectedOptions.length > 0 && (
          <PrimaryButton
            type="button"
            onClick={submitDraftSelection}
            className="absolute bottom-[calc(env(safe-area-inset-bottom)+16px)] right-5 z-20 w-auto rounded-full px-5 py-3 text-[13px] shadow-lg"
            aria-label={`${draftSelectedOptions.length}件の推しを登録`}
          >
            登録
          </PrimaryButton>
        )}
      </div>
    </div>
  );

  return createPortal(modal, document.body);
}

function GenreTab({
  label,
  active,
  onClick,
}: {
  label: string;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex-shrink-0 whitespace-nowrap rounded-full border-[1.5px] border-solid px-3.5 py-1.5 text-[12px] transition-all duration-150 active:scale-[0.97] ${
        active
          ? "border-[#a695d8] bg-[#a695d8] font-bold text-white"
          : "border-[#3a324a14] bg-white font-medium text-gray-900 hover:border-[#3a324a26]"
      }`}
    >
      {label}
    </button>
  );
}

/* ─── Request Modal ─────────────────────────────────────────── */

function RequestModal({
  state,
  genres,
  onClose,
  onDone,
}: {
  state: RequestModalState;
  genres: GenreOption[];
  onClose: () => void;
  onDone: (payload: RequestDonePayload) => void;
}) {
  const [name, setName] = useState(
    state.type === "oshi" ? (state.initialName ?? "") : "",
  );
  const [genreId, setGenreId] = useState("");
  const [kind, setKind] = useState<OshiRequestKind | "">("");
  const [note, setNote] = useState("");
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (typeof document === "undefined") return null;

  const isMemberRequest = state.type === "member";
  const title = isMemberRequest
    ? "メンバー追加リクエスト"
    : "推し追加リクエスト";
  const description = isMemberRequest
    ? "送信後すぐ推しメンバーに仮登録し、運営確認後に正式反映されます。"
    : "送信後すぐ推し設定に仮登録し、運営確認後に正式反映されます。";

  async function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const trimmed = name.trim();
    if (!trimmed) {
      setError(
        isMemberRequest
          ? "メンバー名を入力してください"
          : "推しの名前を入力してください",
      );
      return;
    }

    setPending(true);
    setError(null);
    const result =
      state.type === "member"
        ? await requestCharacterAndAddToProfile({
            groupId: state.groupId,
            oshiRequestId: state.oshiRequestId,
            name: trimmed,
            note: note.trim() || undefined,
          })
        : await requestOshiAndAddToProfile({
            name: trimmed,
            genreId: genreId || undefined,
            kind: kind || undefined,
            note: note.trim() || undefined,
          });

    if (result?.error) {
      setPending(false);
      setError(result.error);
      return;
    }

    if (!result.requestId || !result.name) {
      setPending(false);
      setError("追加リクエストの保存結果を確認できませんでした");
      return;
    }

    onDone(
      state.type === "member"
        ? {
            type: "member",
            requestId: result.requestId,
            name: result.name,
            groupId: state.groupId,
            oshiRequestId: state.oshiRequestId,
          }
        : {
            type: "oshi",
            requestId: result.requestId,
            name: result.name,
          },
    );
  }

  const modal = (
    <div
      className="fixed inset-0 z-[120] flex items-end justify-center bg-black/45 px-0 backdrop-blur-[2px]"
      role="dialog"
      aria-modal="true"
      aria-label={title}
      onClick={() => {
        if (!pending) onClose();
      }}
    >
      <div
        className="w-full max-w-md rounded-t-[28px] border border-white/80 bg-white px-5 pb-[calc(env(safe-area-inset-bottom)+18px)] pt-3 shadow-[0_-22px_54px_rgba(58,50,74,0.24)]"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="mx-auto mb-4 h-1.5 w-10 rounded-full bg-[#3a324a1f]" />
        <div className="mb-4 flex items-start gap-3">
          <div className="flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-2xl bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] text-[16px] font-extrabold text-white">
            +
          </div>
          <div className="min-w-0 flex-1">
            <h2 className="text-[17px] font-extrabold text-[#3a324a]">
              {title}
            </h2>
            <p className="mt-1 text-[11.5px] leading-relaxed text-[#3a324a99]">
              {description}
            </p>
          </div>
          <button
            type="button"
            disabled={pending}
            onClick={onClose}
            className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full bg-[#3a324a08] text-[18px] font-bold text-[#3a324a8c] transition-all active:scale-[0.96] disabled:opacity-40"
            aria-label="閉じる"
          >
            ×
          </button>
        </div>

        <form className="space-y-4" onSubmit={handleSubmit}>
          {isMemberRequest && (
            <div className="rounded-xl bg-[#a695d810] px-4 py-3 text-[12px] text-[#3a324a]">
              <span className="font-bold">追加先:</span>{" "}
              <span className="font-extrabold">{state.groupName}</span>
            </div>
          )}

          <div>
            <label
              htmlFor="profile_oshi_request_name"
              className="block text-[13px] font-bold text-gray-900"
            >
              {isMemberRequest
                ? "メンバー / キャラクター名"
                : "推しの名前"}{" "}
              <span className="text-red-500">*</span>
            </label>
            <input
              id="profile_oshi_request_name"
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder={isMemberRequest ? "例: スア" : "例: LUMENA"}
              maxLength={100}
              className="mt-2 block w-full rounded-xl border border-[#3a324a14] bg-white px-4 py-3 text-base text-gray-900 placeholder:text-gray-400 focus:border-[#a695d8] focus:outline-none focus:ring-1 focus:ring-[#a695d855]"
            />
            <p className="mt-1.5 text-[11px] text-gray-500">
              公式表記の通りに入力してください
            </p>
          </div>

          {!isMemberRequest && (
            <>
              <div>
                <label
                  htmlFor="profile_oshi_request_genre"
                  className="block text-[13px] font-bold text-gray-900"
                >
                  ジャンル <span className="text-gray-500">（任意）</span>
                </label>
                <select
                  id="profile_oshi_request_genre"
                  value={genreId}
                  onChange={(e) => setGenreId(e.target.value)}
                  className="mt-2 block w-full rounded-xl border border-[#3a324a14] bg-white px-4 py-3 text-base text-gray-900 focus:border-[#a695d8] focus:outline-none focus:ring-1 focus:ring-[#a695d855]"
                >
                  <option value="">選択しない</option>
                  {genres.map((g) => (
                    <option key={g.id} value={g.id}>
                      {g.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-[13px] font-bold text-gray-900">
                  種類 <span className="text-gray-500">（任意）</span>
                </label>
                <div className="mt-2 grid grid-cols-3 gap-2">
                  {REQUEST_KINDS.map((requestKind) => {
                    const active = kind === requestKind.value;
                    return (
                      <button
                        key={requestKind.value}
                        type="button"
                        onClick={() =>
                          setKind(active ? "" : requestKind.value)
                        }
                        className={`rounded-xl border-[1.5px] border-solid py-2.5 text-[13px] transition-all duration-150 active:scale-[0.97] ${
                          active
                            ? "border-[#a695d8] bg-[#a695d814] font-bold text-gray-900"
                            : "border-[#3a324a14] bg-white font-medium text-gray-900 hover:border-[#3a324a26]"
                        }`}
                      >
                        {requestKind.label}
                      </button>
                    );
                  })}
                </div>
              </div>
            </>
          )}

          <div>
            <label
              htmlFor="profile_oshi_request_note"
              className="block text-[13px] font-bold text-gray-900"
            >
              メモ <span className="text-gray-500">（任意）</span>
            </label>
            <textarea
              id="profile_oshi_request_note"
              value={note}
              onChange={(e) => setNote(e.target.value)}
              rows={3}
              placeholder={
                isMemberRequest
                  ? "本名・別名・公式リンクなど"
                  : "公式サイト URL、別名、補足など"
              }
              maxLength={500}
              className="mt-2 block w-full resize-none rounded-xl border border-[#3a324a14] bg-white px-4 py-3 text-sm text-gray-900 placeholder:text-gray-400 focus:border-[#a695d8] focus:outline-none focus:ring-1 focus:ring-[#a695d855]"
            />
            <p className="mt-1.5 text-[11px] text-gray-500">
              {note.length} / 500 文字
            </p>
          </div>

          <div className="rounded-xl bg-[#a695d810] px-4 py-3 text-[11px] leading-relaxed text-gray-700">
            運営が確認後、既存マスタと一致した場合は紐付け、新規の場合はマスタに追加されます。
          </div>

          {error && (
            <p className="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-[11.5px] font-semibold text-red-700">
              {error}
            </p>
          )}

          <div className="grid grid-cols-[0.8fr_1.2fr] gap-2.5 pt-1">
            <button
              type="button"
              disabled={pending}
              onClick={onClose}
              className="rounded-[14px] border-[1.5px] border-[#a695d855] bg-white px-4 py-[13px] text-sm font-bold text-gray-900 transition-all active:scale-[0.97] disabled:opacity-45"
            >
              閉じる
            </button>
            <PrimaryButton
              type="submit"
              disabled={!name.trim()}
              pending={pending}
              pendingLabel="送信中..."
              className="py-[13px]"
            >
              送信する
            </PrimaryButton>
          </div>
        </form>
      </div>
    </div>
  );

  return createPortal(modal, document.body);
}

function sortCharacters<T extends { name: string }>(characters: T[]): T[] {
  return [...characters].sort((a, b) => a.name.localeCompare(b.name, "ja"));
}

function kindLabel(kind: OshiRequestKind): string {
  switch (kind) {
    case "work":
      return "作品";
    case "solo":
      return "ソロ";
    default:
      return "グループ";
  }
}

function isLatin(name: string): boolean {
  return /^[A-Za-z0-9\s\-_!&]+$/.test(name);
}
