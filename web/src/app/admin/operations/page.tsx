import { notFound } from "next/navigation";
import {
  AdminMetric,
  AdminPanel,
  AdminSelect,
  AdminTextInput,
  AdminTextarea,
  StatusPill,
  SubmitButton,
  formatDateTime,
  formatFullDateTime,
} from "../_components";
import {
  approveCharacterRequestAsNew,
  approveOshiRequestAsNew,
  mergeCharacterRequestIntoCharacter,
  mergeOshiRequestIntoGroup,
  rejectCharacterRequest,
  rejectOshiRequest,
  sendAdminNotification,
  updateModerationReportStatus,
} from "../actions";
import {
  getAdminContext,
  hasAdminPermission,
} from "@/lib/admin/permissions";
import { createServiceRoleClient } from "@/lib/supabase/server";

type UserLite = {
  id: string;
  handle: string;
  display_name: string;
  account_status: string;
};

type GeneralReportRow = {
  id: string;
  reporter_id: string;
  target_user_id: string | null;
  target_proposal_id: string | null;
  target_message_id: string | null;
  category: string;
  description: string | null;
  evidence_urls: string[];
  status: string;
  resolved_at: string | null;
  created_at: string;
};

type GoodsReportRow = {
  id: string;
  reporter_id: string;
  goods_inventory_id: string;
  reported_user_id: string;
  reason: string;
  note: string | null;
  status: string;
  created_at: string;
};

type GroomReportRow = {
  id: string;
  reporter_id: string;
  groom_post_id: string;
  reported_user_id: string;
  reason: string;
  note: string | null;
  status: string;
  created_at: string;
};

type BoardReportRow = {
  id: string;
  thread_id: string | null;
  reply_id: string | null;
  reporter_id: string;
  reason: string;
  body: string | null;
  status: string;
  created_at: string;
};

type DisputeRow = {
  id: string;
  proposal_id: string;
  reporter_id: string;
  respondent_id: string;
  category: string;
  fact_memo: string | null;
  evidence_photo_urls: string[];
  status: string;
  outcome: string | null;
  operator_comment: string | null;
  ticket_no: string;
  submitted_at: string;
};

type OshiRequestRow = {
  id: string;
  user_id: string;
  requested_name: string;
  requested_genre_id: string | null;
  requested_kind: string | null;
  note: string | null;
  status: string;
  approved_group_id: string | null;
  approved_at: string | null;
  rejection_reason: string | null;
  created_at: string;
};

type CharacterRequestRow = {
  id: string;
  user_id: string;
  group_id: string | null;
  oshi_request_id: string | null;
  requested_name: string;
  note: string | null;
  status: string;
  approved_character_id: string | null;
  approved_at: string | null;
  rejection_reason: string | null;
  created_at: string;
};

type GenreRow = {
  id: string;
  name: string;
  kind: string;
  display_order: number;
};

type GroupRow = {
  id: string;
  name: string;
  genre_id: string;
  kind: string;
  display_order: number;
};

type CharacterRow = {
  id: string;
  name: string;
  group_id: string;
  aliases: string[] | null;
};

type AdminNotificationRow = {
  id: string;
  user_id: string;
  title: string;
  body: string | null;
  link_path: string | null;
  created_at: string;
};

type ModerationRow = {
  source: "reports" | "goods_reports" | "groom_reports" | "meguri_board_reports" | "disputes";
  id: string;
  label: string;
  status: string;
  reporterId: string;
  targetUserId?: string | null;
  targetSummary: string;
  reason: string;
  note?: string | null;
  evidenceUrls?: string[];
  createdAt: string;
  outcome?: string | null;
  operatorComment?: string | null;
};

const REPORT_STATUS_OPTIONS = {
  reports: ["open", "reviewing", "resolved", "dismissed"],
  goods_reports: ["open", "reviewing", "resolved", "dismissed"],
  groom_reports: ["open", "reviewing", "resolved", "dismissed"],
  meguri_board_reports: ["open", "reviewing", "resolved", "rejected"],
  disputes: ["submitted", "response_pending", "arbitrating", "closed"],
} as const;

export default async function AdminOperationsPage({
  searchParams,
}: {
  searchParams?: Promise<{ master_q?: string }>;
}) {
  const masterQuery = ((await searchParams)?.master_q ?? "").trim();
  const context = await getAdminContext();
  const canReadReports = hasAdminPermission(context, "reports.read");
  const canModerateReports = hasAdminPermission(context, "reports.moderate");
  const canReadOshiRequests = hasAdminPermission(context, "oshi_requests.read");
  const canManageOshiRequests = hasAdminPermission(context, "oshi_requests.manage");
  const canSendNotifications = hasAdminPermission(context, "notifications.send");

  if (!canReadReports && !canReadOshiRequests && !canSendNotifications) {
    notFound();
  }

  const adminSupabase = createServiceRoleClient();
  const userIds = new Set<string>();

  let generalReports: GeneralReportRow[] = [];
  let goodsReports: GoodsReportRow[] = [];
  let groomReports: GroomReportRow[] = [];
  let boardReports: BoardReportRow[] = [];
  let disputes: DisputeRow[] = [];
  let oshiRequests: OshiRequestRow[] = [];
  let characterRequests: CharacterRequestRow[] = [];
  let genres: GenreRow[] = [];
  let groups: GroupRow[] = [];
  let characters: CharacterRow[] = [];
  let recentAdminNotifications: AdminNotificationRow[] = [];

  if (canReadReports) {
    const [
      generalReportsResult,
      goodsReportsResult,
      groomReportsResult,
      boardReportsResult,
      disputesResult,
    ] = await Promise.all([
      adminSupabase
        .from("reports")
        .select("id, reporter_id, target_user_id, target_proposal_id, target_message_id, category, description, evidence_urls, status, resolved_at, created_at")
        .order("created_at", { ascending: false })
        .limit(80),
      adminSupabase
        .from("goods_reports")
        .select("id, reporter_id, goods_inventory_id, reported_user_id, reason, note, status, created_at")
        .order("created_at", { ascending: false })
        .limit(80),
      adminSupabase
        .from("groom_reports")
        .select("id, reporter_id, groom_post_id, reported_user_id, reason, note, status, created_at")
        .order("created_at", { ascending: false })
        .limit(80),
      adminSupabase
        .from("meguri_board_reports")
        .select("id, thread_id, reply_id, reporter_id, reason, body, status, created_at")
        .order("created_at", { ascending: false })
        .limit(80),
      adminSupabase
        .from("disputes")
        .select("id, proposal_id, reporter_id, respondent_id, category, fact_memo, evidence_photo_urls, status, outcome, operator_comment, ticket_no, submitted_at")
        .order("submitted_at", { ascending: false })
        .limit(80),
    ]);
    for (const result of [
      generalReportsResult,
      goodsReportsResult,
      groomReportsResult,
      boardReportsResult,
      disputesResult,
    ]) {
      if (result.error) throw new Error(result.error.message);
    }
    generalReports = (generalReportsResult.data ?? []) as GeneralReportRow[];
    goodsReports = (goodsReportsResult.data ?? []) as GoodsReportRow[];
    groomReports = (groomReportsResult.data ?? []) as GroomReportRow[];
    boardReports = (boardReportsResult.data ?? []) as BoardReportRow[];
    disputes = (disputesResult.data ?? []) as DisputeRow[];

    for (const row of generalReports) {
      userIds.add(row.reporter_id);
      if (row.target_user_id) userIds.add(row.target_user_id);
    }
    for (const row of goodsReports) {
      userIds.add(row.reporter_id);
      userIds.add(row.reported_user_id);
    }
    for (const row of groomReports) {
      userIds.add(row.reporter_id);
      userIds.add(row.reported_user_id);
    }
    for (const row of boardReports) {
      userIds.add(row.reporter_id);
    }
    for (const row of disputes) {
      userIds.add(row.reporter_id);
      userIds.add(row.respondent_id);
    }
  }

  if (canReadOshiRequests) {
    const [oshiResult, characterResult, genresResult, groupsResult, charactersResult] =
      await Promise.all([
        adminSupabase
          .from("oshi_requests")
          .select("id, user_id, requested_name, requested_genre_id, requested_kind, note, status, approved_group_id, approved_at, rejection_reason, created_at")
          .order("created_at", { ascending: false })
          .limit(120),
        adminSupabase
          .from("character_requests")
          .select("id, user_id, group_id, oshi_request_id, requested_name, note, status, approved_character_id, approved_at, rejection_reason, created_at")
          .order("created_at", { ascending: false })
          .limit(120),
        adminSupabase
          .from("genres_master")
          .select("id, name, kind, display_order")
          .order("display_order", { ascending: true })
          .limit(200),
        adminSupabase
          .from("groups_master")
          .select("id, name, genre_id, kind, display_order")
          .order("display_order", { ascending: true })
          .limit(600),
        adminSupabase
          .from("characters_master")
          .select("id, name, group_id, aliases")
          .order("display_order", { ascending: true })
          .limit(3000),
      ]);
    for (const result of [oshiResult, characterResult, genresResult, groupsResult, charactersResult]) {
      if (result.error) throw new Error(result.error.message);
    }
    oshiRequests = (oshiResult.data ?? []) as OshiRequestRow[];
    characterRequests = (characterResult.data ?? []) as CharacterRequestRow[];
    genres = (genresResult.data ?? []) as GenreRow[];
    groups = (groupsResult.data ?? []) as GroupRow[];
    characters = (charactersResult.data ?? []) as CharacterRow[];

    for (const row of oshiRequests) {
      userIds.add(row.user_id);
    }
    for (const row of characterRequests) {
      userIds.add(row.user_id);
    }
  }

  if (canSendNotifications) {
    const { data, error } = await adminSupabase
      .from("notifications")
      .select("id, user_id, title, body, link_path, created_at")
      .eq("kind", "admin_announcement")
      .order("created_at", { ascending: false })
      .limit(30);
    if (error) throw new Error(error.message);
    recentAdminNotifications = (data ?? []) as AdminNotificationRow[];
    for (const row of recentAdminNotifications) {
      userIds.add(row.user_id);
    }
  }

  const usersById = await loadUsersById(adminSupabase, Array.from(userIds));
  const groupById = new Map(groups.map((group) => [group.id, group]));
  const genreById = new Map(genres.map((genre) => [genre.id, genre]));
  const moderationRows = buildModerationRows({
    generalReports,
    goodsReports,
    groomReports,
    boardReports,
    disputes,
  });
  const pendingOshiRequests = oshiRequests.filter((request) => request.status === "pending");
  const pendingCharacterRequests = characterRequests.filter(
    (request) => request.status === "pending",
  );

  return (
    <div className="space-y-5">
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <AdminMetric
          label="未対応の通報"
          value={moderationRows.filter((row) => isOpenReportStatus(row.status)).length}
          tone="warn"
        />
        <AdminMetric
          label="L1追加リクエスト"
          value={pendingOshiRequests.length}
        />
        <AdminMetric
          label="L2追加リクエスト"
          value={pendingCharacterRequests.length}
        />
        <AdminMetric
          label="運営通知"
          value={recentAdminNotifications.length}
          tone="ok"
        />
      </div>

      {canReadReports && (
        <ReportsPanel
          rows={moderationRows}
          usersById={usersById}
          canModerate={canModerateReports}
        />
      )}

      {canReadOshiRequests && (
        <OshiRequestsPanel
          oshiRequests={pendingOshiRequests}
          characterRequests={pendingCharacterRequests}
          usersById={usersById}
          genres={genres}
          groups={groups}
          characters={characters}
          genreById={genreById}
          groupById={groupById}
          canManage={canManageOshiRequests}
        />
      )}

      {canReadOshiRequests && (
        <MasterSearchPanel
          query={masterQuery}
          groups={groups}
          characters={characters}
          genreById={genreById}
          groupById={groupById}
        />
      )}

      {canSendNotifications && (
        <AdminNotificationsPanel
          notifications={recentAdminNotifications}
          usersById={usersById}
        />
      )}
    </div>
  );
}

function ReportsPanel({
  rows,
  usersById,
  canModerate,
}: {
  rows: ModerationRow[];
  usersById: Map<string, UserLite>;
  canModerate: boolean;
}) {
  return (
    <AdminPanel
      title={`通報窓口 ${rows.length}件`}
      description="ユーザー、取引、グッズ、めぐり投稿、掲示板の通報を横断して確認します。"
    >
      {rows.length === 0 ? (
        <p className="text-[12px] font-semibold text-slate-500">
          通報はまだありません。
        </p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full min-w-[1120px] border-separate border-spacing-0 text-left">
            <thead>
              <tr className="text-[11px] font-bold text-slate-500">
                <th className="border-b border-slate-200 px-3 py-2">通報</th>
                <th className="border-b border-slate-200 px-3 py-2">通報者</th>
                <th className="border-b border-slate-200 px-3 py-2">対象</th>
                <th className="border-b border-slate-200 px-3 py-2">通報理由・内容</th>
                <th className="border-b border-slate-200 px-3 py-2">状態</th>
                <th className="border-b border-slate-200 px-3 py-2">操作</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={`${row.source}:${row.id}`} className="align-top">
                  <td className="border-b border-slate-100 px-3 py-3">
                    <div className="text-[12px] font-black text-slate-900">
                      {row.label}
                    </div>
                    <div className="mt-1 font-mono text-[10px] text-slate-400">
                      {row.id}
                    </div>
                    <div className="mt-1 text-[11px] font-semibold text-slate-500">
                      {formatFullDateTime(row.createdAt)}
                    </div>
                  </td>
                  <td className="border-b border-slate-100 px-3 py-3 text-[12px] font-bold text-slate-900">
                    {userLabel(usersById, row.reporterId)}
                    <div className="mt-1 font-mono text-[10px] text-slate-400">
                      {row.reporterId}
                    </div>
                  </td>
                  <td className="border-b border-slate-100 px-3 py-3">
                    <div className="text-[12px] font-bold text-slate-900">
                      {row.targetSummary}
                    </div>
                    {row.targetUserId && (
                      <div className="mt-1 text-[11px] font-semibold text-slate-500">
                        {userLabel(usersById, row.targetUserId)}
                      </div>
                    )}
                  </td>
                  <td className="border-b border-slate-100 px-3 py-3">
                    <StatusPill>{row.reason}</StatusPill>
                    <p className="mt-2 max-w-[300px] whitespace-pre-wrap text-[12px] font-semibold leading-relaxed text-slate-600">
                      {row.note?.trim() ? row.note : "（通報内容の記載なし）"}
                    </p>
                    {(row.evidenceUrls ?? []).length > 0 && (
                      <div className="mt-2 space-y-1">
                        {row.evidenceUrls?.slice(0, 3).map((url) => (
                          <div
                            key={url}
                            className="max-w-[260px] truncate font-mono text-[10px] text-slate-400"
                          >
                            {url}
                          </div>
                        ))}
                      </div>
                    )}
                  </td>
                  <td className="border-b border-slate-100 px-3 py-3">
                    <StatusPill tone={reportTone(row.status)}>
                      {row.status}
                    </StatusPill>
                    {row.outcome && (
                      <div className="mt-1">
                        <StatusPill tone="mute">{row.outcome}</StatusPill>
                      </div>
                    )}
                  </td>
                  <td className="border-b border-slate-100 px-3 py-3">
                    {canModerate ? (
                      <form action={updateModerationReportStatus} className="grid w-[260px] gap-2">
                        <input type="hidden" name="source" value={row.source} />
                        <input type="hidden" name="report_id" value={row.id} />
                        <input type="hidden" name="return_to" value="/admin/operations" />
                        <AdminSelect name="status" label="ステータス" defaultValue={row.status}>
                          {REPORT_STATUS_OPTIONS[row.source].map((status) => (
                            <option key={status} value={status}>
                              {status}
                            </option>
                          ))}
                        </AdminSelect>
                        {row.source === "disputes" && (
                          <>
                            <AdminSelect
                              name="outcome"
                              label="裁定"
                              defaultValue={row.outcome ?? ""}
                            >
                              <option value="">未設定</option>
                              <option value="cancelled">cancelled</option>
                              <option value="upheld">upheld</option>
                              <option value="partial">partial</option>
                            </AdminSelect>
                            <AdminTextarea
                              name="operator_comment"
                              label="運営コメント"
                              defaultValue={row.operatorComment ?? ""}
                              rows={2}
                            />
                          </>
                        )}
                        <AdminTextInput
                          name="reason"
                          label="対応理由"
                          placeholder="例: 内容確認済み"
                          required
                        />
                        <SubmitButton>状態を更新</SubmitButton>
                      </form>
                    ) : (
                      <span className="text-[11px] font-semibold text-slate-400">
                        権限なし
                      </span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </AdminPanel>
  );
}

function OshiRequestsPanel({
  oshiRequests,
  characterRequests,
  usersById,
  genres,
  groups,
  characters,
  genreById,
  groupById,
  canManage,
}: {
  oshiRequests: OshiRequestRow[];
  characterRequests: CharacterRequestRow[];
  usersById: Map<string, UserLite>;
  genres: GenreRow[];
  groups: GroupRow[];
  characters: CharacterRow[];
  genreById: Map<string, GenreRow>;
  groupById: Map<string, GroupRow>;
  canManage: boolean;
}) {
  return (
    <div className="space-y-5">
      <AdminPanel
        title={`推しL1追加リクエスト ${oshiRequests.length}件`}
        description="1リクエスト1行。統合先は既存L1マスタ名から選べます。"
      >
        {oshiRequests.length === 0 ? (
          <p className="text-[12px] font-semibold text-slate-500">
            pending のL1リクエストはありません。
          </p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[1180px] border-separate border-spacing-0 text-left">
              <thead>
                <tr className="text-[11px] font-bold text-slate-500">
                  <th className="border-b border-slate-200 px-3 py-2">リクエスト名</th>
                  <th className="border-b border-slate-200 px-3 py-2">申請者</th>
                  <th className="border-b border-slate-200 px-3 py-2">希望ジャンル / 種別</th>
                  <th className="border-b border-slate-200 px-3 py-2">メモ</th>
                  <th className="border-b border-slate-200 px-3 py-2">日時</th>
                  <th className="border-b border-slate-200 px-3 py-2">操作</th>
                </tr>
              </thead>
              <tbody>
                {oshiRequests.map((request) => (
                  <tr key={request.id} className="align-top">
                    <td className="border-b border-slate-100 px-3 py-3">
                      <div className="text-[13px] font-black text-slate-900">
                        {request.requested_name}
                      </div>
                      <div className="mt-1 font-mono text-[10px] text-slate-400">
                        {shortId(request.id)}
                      </div>
                    </td>
                    <td className="border-b border-slate-100 px-3 py-3 text-[12px] font-bold text-slate-900">
                      {userLabel(usersById, request.user_id)}
                    </td>
                    <td className="border-b border-slate-100 px-3 py-3 text-[12px] font-semibold text-slate-600">
                      {request.requested_genre_id
                        ? genreById.get(request.requested_genre_id)?.name ?? shortId(request.requested_genre_id)
                        : "未指定"}
                      {" / "}
                      {request.requested_kind ?? "未指定"}
                    </td>
                    <td className="border-b border-slate-100 px-3 py-3">
                      <p className="max-w-[220px] whitespace-pre-wrap text-[12px] font-semibold text-slate-600">
                        {request.note?.trim() ? request.note : "—"}
                      </p>
                    </td>
                    <td className="border-b border-slate-100 px-3 py-3 text-[11px] font-semibold text-slate-500">
                      {formatFullDateTime(request.created_at)}
                    </td>
                    <td className="border-b border-slate-100 px-3 py-3">
                      {canManage ? (
                        <div className="grid w-[320px] gap-2">
                          <form action={approveOshiRequestAsNew} className="flex items-end gap-2">
                            <input type="hidden" name="request_id" value={request.id} />
                            <input type="hidden" name="return_to" value="/admin/operations" />
                            <input type="hidden" name="name" value={request.requested_name} />
                            <input type="hidden" name="kind" value={request.requested_kind ?? "group"} />
                            <div className="min-w-[150px] flex-1">
                              <AdminSelect
                                name="genre_id"
                                label="ジャンル"
                                defaultValue={request.requested_genre_id ?? genres[0]?.id}
                              >
                                {genres.map((genre) => (
                                  <option key={genre.id} value={genre.id}>
                                    {genre.name}
                                  </option>
                                ))}
                              </AdminSelect>
                            </div>
                            <SubmitButton>新規L1登録</SubmitButton>
                          </form>
                          <form action={mergeOshiRequestIntoGroup} className="flex items-end gap-2">
                            <input type="hidden" name="request_id" value={request.id} />
                            <input type="hidden" name="return_to" value="/admin/operations" />
                            <div className="min-w-[150px] flex-1">
                              <AdminSelect name="approved_group_id" label="統合先L1（マスタ名）" required>
                                <option value="">選択してください</option>
                                {groups.map((candidate) => (
                                  <option key={candidate.id} value={candidate.id}>
                                    {candidate.name}（{genreById.get(candidate.genre_id)?.name ?? "ジャンル未取得"}）
                                  </option>
                                ))}
                              </AdminSelect>
                            </div>
                            <SubmitButton>統合</SubmitButton>
                          </form>
                          <form action={rejectOshiRequest} className="flex items-end gap-2">
                            <input type="hidden" name="request_id" value={request.id} />
                            <input type="hidden" name="return_to" value="/admin/operations" />
                            <div className="min-w-[150px] flex-1">
                              <AdminTextInput name="reason" label="却下理由" required />
                            </div>
                            <SubmitButton>却下</SubmitButton>
                          </form>
                        </div>
                      ) : (
                        <span className="text-[11px] font-semibold text-slate-400">権限なし</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </AdminPanel>

      <AdminPanel
        title={`推しL2追加リクエスト ${characterRequests.length}件`}
        description="1リクエスト1行。統合先は既存L2マスタ名から選べます。"
      >
        {characterRequests.length === 0 ? (
          <p className="text-[12px] font-semibold text-slate-500">
            pending のL2リクエストはありません。
          </p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[1180px] border-separate border-spacing-0 text-left">
              <thead>
                <tr className="text-[11px] font-bold text-slate-500">
                  <th className="border-b border-slate-200 px-3 py-2">リクエスト名</th>
                  <th className="border-b border-slate-200 px-3 py-2">申請者</th>
                  <th className="border-b border-slate-200 px-3 py-2">所属L1</th>
                  <th className="border-b border-slate-200 px-3 py-2">メモ</th>
                  <th className="border-b border-slate-200 px-3 py-2">日時</th>
                  <th className="border-b border-slate-200 px-3 py-2">操作</th>
                </tr>
              </thead>
              <tbody>
                {characterRequests.map((request) => {
                  const group = request.group_id ? groupById.get(request.group_id) : null;
                  return (
                    <tr key={request.id} className="align-top">
                      <td className="border-b border-slate-100 px-3 py-3">
                        <div className="text-[13px] font-black text-slate-900">
                          {request.requested_name}
                        </div>
                        <div className="mt-1 font-mono text-[10px] text-slate-400">
                          {shortId(request.id)}
                        </div>
                      </td>
                      <td className="border-b border-slate-100 px-3 py-3 text-[12px] font-bold text-slate-900">
                        {userLabel(usersById, request.user_id)}
                      </td>
                      <td className="border-b border-slate-100 px-3 py-3 text-[12px] font-semibold text-slate-600">
                        {group
                          ? `${group.name}（${genreById.get(group.genre_id)?.name ?? "ジャンル未取得"}）`
                          : request.oshi_request_id
                            ? `未承認L1 request ${shortId(request.oshi_request_id)}`
                            : "未指定"}
                      </td>
                      <td className="border-b border-slate-100 px-3 py-3">
                        <p className="max-w-[220px] whitespace-pre-wrap text-[12px] font-semibold text-slate-600">
                          {request.note?.trim() ? request.note : "—"}
                        </p>
                      </td>
                      <td className="border-b border-slate-100 px-3 py-3 text-[11px] font-semibold text-slate-500">
                        {formatFullDateTime(request.created_at)}
                      </td>
                      <td className="border-b border-slate-100 px-3 py-3">
                        {canManage ? (
                          <div className="grid w-[320px] gap-2">
                            <form action={approveCharacterRequestAsNew} className="flex items-end gap-2">
                              <input type="hidden" name="request_id" value={request.id} />
                              <input type="hidden" name="return_to" value="/admin/operations" />
                              <input type="hidden" name="name" value={request.requested_name} />
                              <div className="min-w-[150px] flex-1">
                                <AdminSelect
                                  name="group_id"
                                  label="所属L1（マスタ名）"
                                  defaultValue={request.group_id ?? ""}
                                  required
                                >
                                  <option value="">選択してください</option>
                                  {groups.map((candidate) => (
                                    <option key={candidate.id} value={candidate.id}>
                                      {candidate.name}（{genreById.get(candidate.genre_id)?.name ?? "ジャンル未取得"}）
                                    </option>
                                  ))}
                                </AdminSelect>
                              </div>
                              <SubmitButton>新規L2登録</SubmitButton>
                            </form>
                            <form action={mergeCharacterRequestIntoCharacter} className="flex items-end gap-2">
                              <input type="hidden" name="request_id" value={request.id} />
                              <input type="hidden" name="return_to" value="/admin/operations" />
                              <div className="min-w-[150px] flex-1">
                                <AdminSelect name="approved_character_id" label="統合先L2（マスタ名）" required>
                                  <option value="">選択してください</option>
                                  {characters.map((candidate) => (
                                    <option key={candidate.id} value={candidate.id}>
                                      {candidate.name}（{groupById.get(candidate.group_id)?.name ?? "L1未取得"}）
                                    </option>
                                  ))}
                                </AdminSelect>
                              </div>
                              <SubmitButton>統合</SubmitButton>
                            </form>
                            <form action={rejectCharacterRequest} className="flex items-end gap-2">
                              <input type="hidden" name="request_id" value={request.id} />
                              <input type="hidden" name="return_to" value="/admin/operations" />
                              <div className="min-w-[150px] flex-1">
                                <AdminTextInput name="reason" label="却下理由" required />
                              </div>
                              <SubmitButton>却下</SubmitButton>
                            </form>
                          </div>
                        ) : (
                          <span className="text-[11px] font-semibold text-slate-400">権限なし</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </AdminPanel>
    </div>
  );
}

function MasterSearchPanel({
  query,
  groups,
  characters,
  genreById,
  groupById,
}: {
  query: string;
  groups: GroupRow[];
  characters: CharacterRow[];
  genreById: Map<string, GenreRow>;
  groupById: Map<string, GroupRow>;
}) {
  const normalized = query.toLowerCase();
  const matchedGroups = normalized
    ? groups.filter((group) => group.name.toLowerCase().includes(normalized))
    : [];
  const matchedCharacters = normalized
    ? characters.filter((character) =>
        character.name.toLowerCase().includes(normalized) ||
        (character.aliases ?? []).some((alias) => alias.toLowerCase().includes(normalized)) ||
        (groupById.get(character.group_id)?.name.toLowerCase().includes(normalized) ?? false),
      )
    : [];

  return (
    <AdminPanel
      title="推しマスタ検索（L1 / L2）"
      description="既存マスタの名前を検索して、登録済みのL1/L2とIDを確認できます。"
    >
      <form method="get" action="/admin/operations" className="flex items-end gap-2">
        <div className="w-[280px]">
          <AdminTextInput
            name="master_q"
            label="マスタ名で検索"
            placeholder="例: aespa / カリナ"
            defaultValue={query}
          />
        </div>
        <SubmitButton>検索</SubmitButton>
      </form>

      {query && (
        <div className="mt-4 grid gap-5 xl:grid-cols-2">
          <div>
            <div className="text-[12px] font-black text-slate-900">
              L1マスタ {matchedGroups.length}件
            </div>
            {matchedGroups.length === 0 ? (
              <p className="mt-2 text-[12px] font-semibold text-slate-500">一致するL1はありません。</p>
            ) : (
              <table className="mt-2 w-full border-separate border-spacing-0 text-left">
                <thead>
                  <tr className="text-[11px] font-bold text-slate-500">
                    <th className="border-b border-slate-200 px-2 py-1.5">名前</th>
                    <th className="border-b border-slate-200 px-2 py-1.5">ジャンル / 種別</th>
                    <th className="border-b border-slate-200 px-2 py-1.5">ID</th>
                  </tr>
                </thead>
                <tbody>
                  {matchedGroups.slice(0, 30).map((group) => (
                    <tr key={group.id}>
                      <td className="border-b border-slate-100 px-2 py-2 text-[12px] font-black text-slate-900">
                        {group.name}
                      </td>
                      <td className="border-b border-slate-100 px-2 py-2 text-[12px] font-semibold text-slate-600">
                        {genreById.get(group.genre_id)?.name ?? "—"} / {group.kind}
                      </td>
                      <td className="border-b border-slate-100 px-2 py-2 font-mono text-[10px] text-slate-400">
                        {group.id}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
          <div>
            <div className="text-[12px] font-black text-slate-900">
              L2マスタ {matchedCharacters.length}件
            </div>
            {matchedCharacters.length === 0 ? (
              <p className="mt-2 text-[12px] font-semibold text-slate-500">一致するL2はありません。</p>
            ) : (
              <table className="mt-2 w-full border-separate border-spacing-0 text-left">
                <thead>
                  <tr className="text-[11px] font-bold text-slate-500">
                    <th className="border-b border-slate-200 px-2 py-1.5">名前</th>
                    <th className="border-b border-slate-200 px-2 py-1.5">所属L1</th>
                    <th className="border-b border-slate-200 px-2 py-1.5">ID</th>
                  </tr>
                </thead>
                <tbody>
                  {matchedCharacters.slice(0, 30).map((character) => (
                    <tr key={character.id}>
                      <td className="border-b border-slate-100 px-2 py-2 text-[12px] font-black text-slate-900">
                        {character.name}
                      </td>
                      <td className="border-b border-slate-100 px-2 py-2 text-[12px] font-semibold text-slate-600">
                        {groupById.get(character.group_id)?.name ?? "—"}
                      </td>
                      <td className="border-b border-slate-100 px-2 py-2 font-mono text-[10px] text-slate-400">
                        {character.id}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      )}
    </AdminPanel>
  );
}

function AdminNotificationsPanel({
  notifications,
  usersById,
}: {
  notifications: AdminNotificationRow[];
  usersById: Map<string, UserLite>;
}) {
  return (
    <div className="grid gap-5 lg:grid-cols-[0.9fr_1.1fr]">
      <AdminPanel
        title="運営通知を送信"
        description="notifications に admin_announcement を作成し、既存のモバイル通知配送に乗せます。"
      >
        <form action={sendAdminNotification} className="grid gap-3">
          <input type="hidden" name="return_to" value="/admin/operations" />
          <div className="grid gap-3 sm:grid-cols-2">
            <AdminSelect name="audience" label="宛先" defaultValue="user">
              <option value="user">任意のユーザー</option>
              <option value="all">すべての有効ユーザー</option>
            </AdminSelect>
            <AdminTextInput
              name="recipient_user"
              label="対象ユーザー"
              placeholder="user_id / @handle / email"
            />
          </div>
          <AdminTextInput
            name="title"
            label="タイトル"
            placeholder="例: 運営からのお知らせ"
            required
          />
          <AdminTextarea
            name="body"
            label="本文"
            placeholder="アプリ内通知と端末通知に表示する本文"
            required
            rows={4}
          />
          <AdminTextInput
            name="link_path"
            label="遷移先"
            placeholder="/notifications"
            defaultValue="/notifications"
          />
          <AdminTextInput
            name="reason"
            label="送信理由"
            placeholder="例: 不具合告知、規約更新、個別サポート"
            required
          />
          <SubmitButton>通知を送信</SubmitButton>
        </form>
      </AdminPanel>

      <AdminPanel
        title="直近の運営通知"
        description="最新30件を表示します。全体送信はユーザーごとに通知行が作成されます。"
      >
        <div className="space-y-2">
          {notifications.length === 0 ? (
            <p className="text-[12px] font-semibold text-slate-500">
              まだ運営通知はありません。
            </p>
          ) : (
            notifications.map((notification) => (
              <div
                key={notification.id}
                className="rounded-lg border border-slate-100 px-3 py-2"
              >
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <div className="text-[12px] font-black text-slate-900">
                      {notification.title}
                    </div>
                    {notification.body && (
                      <p className="mt-1 line-clamp-2 text-[11px] font-semibold text-slate-600">
                        {notification.body}
                      </p>
                    )}
                    <div className="mt-1 text-[10.5px] font-semibold text-slate-400">
                      {userLabel(usersById, notification.user_id)} · {notification.link_path ?? "/notifications"}
                    </div>
                  </div>
                  <StatusPill tone="mute">{formatDateTime(notification.created_at)}</StatusPill>
                </div>
              </div>
            ))
          )}
        </div>
      </AdminPanel>
    </div>
  );
}

async function loadUsersById(
  adminSupabase: ReturnType<typeof createServiceRoleClient>,
  userIds: string[],
) {
  if (userIds.length === 0) return new Map<string, UserLite>();
  const { data, error } = await adminSupabase
    .from("users")
    .select("id, handle, display_name, account_status")
    .in("id", userIds);
  if (error) throw new Error(error.message);
  return new Map((data ?? []).map((user) => [user.id as string, user as UserLite]));
}

function buildModerationRows(input: {
  generalReports: GeneralReportRow[];
  goodsReports: GoodsReportRow[];
  groomReports: GroomReportRow[];
  boardReports: BoardReportRow[];
  disputes: DisputeRow[];
}) {
  return [
    ...input.generalReports.map((row): ModerationRow => ({
      source: "reports",
      id: row.id,
      label: "ユーザー/取引通報",
      status: row.status,
      reporterId: row.reporter_id,
      targetUserId: row.target_user_id,
      targetSummary: [
        row.target_user_id ? `user ${shortId(row.target_user_id)}` : null,
        row.target_proposal_id ? `proposal ${shortId(row.target_proposal_id)}` : null,
        row.target_message_id ? `message ${shortId(row.target_message_id)}` : null,
      ].filter(Boolean).join(" / ") || "対象未設定",
      reason: row.category,
      note: row.description,
      evidenceUrls: row.evidence_urls,
      createdAt: row.created_at,
    })),
    ...input.goodsReports.map((row): ModerationRow => ({
      source: "goods_reports",
      id: row.id,
      label: "グッズ通報",
      status: row.status,
      reporterId: row.reporter_id,
      targetUserId: row.reported_user_id,
      targetSummary: `goods ${shortId(row.goods_inventory_id)}`,
      reason: row.reason,
      note: row.note,
      createdAt: row.created_at,
    })),
    ...input.groomReports.map((row): ModerationRow => ({
      source: "groom_reports",
      id: row.id,
      label: "グルーム通報",
      status: row.status,
      reporterId: row.reporter_id,
      targetUserId: row.reported_user_id,
      targetSummary: `groom ${shortId(row.groom_post_id)}`,
      reason: row.reason,
      note: row.note,
      createdAt: row.created_at,
    })),
    ...input.boardReports.map((row): ModerationRow => ({
      source: "meguri_board_reports",
      id: row.id,
      label: "掲示板通報",
      status: row.status,
      reporterId: row.reporter_id,
      targetSummary: row.thread_id
        ? `thread ${shortId(row.thread_id)}`
        : `reply ${shortId(row.reply_id ?? "")}`,
      reason: row.reason,
      note: row.body,
      createdAt: row.created_at,
    })),
    ...input.disputes.map((row): ModerationRow => ({
      source: "disputes",
      id: row.id,
      label: `取引異議 ${row.ticket_no}`,
      status: row.status,
      reporterId: row.reporter_id,
      targetUserId: row.respondent_id,
      targetSummary: `proposal ${shortId(row.proposal_id)}`,
      reason: row.category,
      note: row.fact_memo,
      evidenceUrls: row.evidence_photo_urls,
      createdAt: row.submitted_at,
      outcome: row.outcome,
      operatorComment: row.operator_comment,
    })),
  ].sort(
    (left, right) =>
      new Date(right.createdAt).getTime() - new Date(left.createdAt).getTime(),
  );
}

function userLabel(usersById: Map<string, UserLite>, userId: string) {
  const user = usersById.get(userId);
  if (!user) return userId;
  return `${user.display_name} (@${user.handle})`;
}

function shortId(value: string) {
  return value ? value.slice(0, 8) : "—";
}

function isOpenReportStatus(status: string) {
  return status === "open" || status === "submitted" || status === "response_pending";
}

function reportTone(
  status: string,
): "default" | "warn" | "ok" | "mute" {
  if (
    status === "open" ||
    status === "submitted" ||
    status === "response_pending"
  ) {
    return "warn";
  }
  if (status === "resolved" || status === "closed" || status === "approved") {
    return "ok";
  }
  if (status === "dismissed" || status === "rejected" || status === "merged") {
    return "mute";
  }
  return "default";
}
