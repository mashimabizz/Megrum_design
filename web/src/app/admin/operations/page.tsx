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

export default async function AdminOperationsPage() {
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
    const [oshiResult, characterResult, genresResult, groupsResult] =
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
      ]);
    for (const result of [oshiResult, characterResult, genresResult, groupsResult]) {
      if (result.error) throw new Error(result.error.message);
    }
    oshiRequests = (oshiResult.data ?? []) as OshiRequestRow[];
    characterRequests = (characterResult.data ?? []) as CharacterRequestRow[];
    genres = (genresResult.data ?? []) as GenreRow[];
    groups = (groupsResult.data ?? []) as GroupRow[];

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
          genreById={genreById}
          groupById={groupById}
          canManage={canManageOshiRequests}
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
                <th className="border-b border-slate-200 px-3 py-2">内容</th>
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
                    {row.note && (
                      <p className="mt-2 max-w-[260px] whitespace-pre-wrap text-[12px] font-semibold leading-relaxed text-slate-600">
                        {row.note}
                      </p>
                    )}
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
  genreById,
  groupById,
  canManage,
}: {
  oshiRequests: OshiRequestRow[];
  characterRequests: CharacterRequestRow[];
  usersById: Map<string, UserLite>;
  genres: GenreRow[];
  groups: GroupRow[];
  genreById: Map<string, GenreRow>;
  groupById: Map<string, GroupRow>;
  canManage: boolean;
}) {
  return (
    <div className="grid gap-5 xl:grid-cols-2">
      <AdminPanel
        title={`推しL1追加リクエスト ${oshiRequests.length}件`}
        description="ユーザーから届いたグループ/作品/ソロの追加希望をマスタへ登録します。"
      >
        <div className="space-y-4">
          {oshiRequests.length === 0 ? (
            <p className="text-[12px] font-semibold text-slate-500">
              pending のL1リクエストはありません。
            </p>
          ) : (
            oshiRequests.map((request) => (
              <div key={request.id} className="rounded-lg border border-slate-200 p-3">
                <RequestHeader
                  title={request.requested_name}
                  status={request.status}
                  user={userLabel(usersById, request.user_id)}
                  createdAt={request.created_at}
                />
                <div className="mt-2 grid gap-1 text-[11px] font-semibold text-slate-500">
                  <div>希望ジャンル: {request.requested_genre_id ? genreById.get(request.requested_genre_id)?.name ?? request.requested_genre_id : "未指定"}</div>
                  <div>種別: {request.requested_kind ?? "未指定"}</div>
                  {request.note && <div className="whitespace-pre-wrap">メモ: {request.note}</div>}
                  <div className="font-mono text-[10px] text-slate-400">{request.id}</div>
                </div>

                {canManage && (
                  <div className="mt-3 grid gap-3">
                    <form action={approveOshiRequestAsNew} className="grid gap-2 rounded-lg bg-slate-50 p-3">
                      <input type="hidden" name="request_id" value={request.id} />
                      <input type="hidden" name="return_to" value="/admin/operations" />
                      <AdminTextInput
                        name="name"
                        label="新規L1名"
                        defaultValue={request.requested_name}
                        required
                      />
                      <div className="grid gap-2 sm:grid-cols-2">
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
                        <AdminSelect
                          name="kind"
                          label="種別"
                          defaultValue={request.requested_kind ?? "group"}
                        >
                          <option value="group">group</option>
                          <option value="work">work</option>
                          <option value="solo">solo</option>
                        </AdminSelect>
                      </div>
                      <div className="grid gap-2 sm:grid-cols-2">
                        <AdminTextInput name="aliases" label="別名" placeholder="カンマ区切り" />
                        <AdminTextInput name="display_order" label="表示順" type="number" defaultValue="0" />
                      </div>
                      <AdminTextInput name="reason" label="承認理由" required />
                      <SubmitButton>新規L1として登録</SubmitButton>
                    </form>

                    <form action={mergeOshiRequestIntoGroup} className="grid gap-2 rounded-lg border border-slate-100 p-3">
                      <input type="hidden" name="request_id" value={request.id} />
                      <input type="hidden" name="return_to" value="/admin/operations" />
                      <AdminTextInput
                        name="approved_group_id"
                        label="既存L1 IDへ統合"
                        placeholder="groups_master.id"
                        required
                      />
                      <AdminTextInput name="reason" label="統合理由" required />
                      <SubmitButton>既存L1に統合</SubmitButton>
                    </form>

                    <form action={rejectOshiRequest} className="grid gap-2 rounded-lg border border-rose-100 p-3">
                      <input type="hidden" name="request_id" value={request.id} />
                      <input type="hidden" name="return_to" value="/admin/operations" />
                      <AdminTextInput name="reason" label="却下理由" required />
                      <SubmitButton>却下する</SubmitButton>
                    </form>
                  </div>
                )}
              </div>
            ))
          )}
        </div>
      </AdminPanel>

      <AdminPanel
        title={`推しL2追加リクエスト ${characterRequests.length}件`}
        description="メンバー/キャラクターの追加希望を、所属L1の下へ登録します。"
      >
        <div className="space-y-4">
          {characterRequests.length === 0 ? (
            <p className="text-[12px] font-semibold text-slate-500">
              pending のL2リクエストはありません。
            </p>
          ) : (
            characterRequests.map((request) => {
              const group = request.group_id ? groupById.get(request.group_id) : null;
              return (
                <div key={request.id} className="rounded-lg border border-slate-200 p-3">
                  <RequestHeader
                    title={request.requested_name}
                    status={request.status}
                    user={userLabel(usersById, request.user_id)}
                    createdAt={request.created_at}
                  />
                  <div className="mt-2 grid gap-1 text-[11px] font-semibold text-slate-500">
                    <div>所属L1: {group ? `${group.name} / ${genreById.get(group.genre_id)?.name ?? "genre未取得"}` : request.oshi_request_id ? `未承認L1 request ${shortId(request.oshi_request_id)}` : "未指定"}</div>
                    {request.note && <div className="whitespace-pre-wrap">メモ: {request.note}</div>}
                    <div className="font-mono text-[10px] text-slate-400">{request.id}</div>
                  </div>

                  {canManage && (
                    <div className="mt-3 grid gap-3">
                      <form action={approveCharacterRequestAsNew} className="grid gap-2 rounded-lg bg-slate-50 p-3">
                        <input type="hidden" name="request_id" value={request.id} />
                        <input type="hidden" name="return_to" value="/admin/operations" />
                        <AdminTextInput
                          name="name"
                          label="新規L2名"
                          defaultValue={request.requested_name}
                          required
                        />
                        <AdminSelect name="group_id" label="所属L1" defaultValue={request.group_id ?? ""}>
                          <option value="">選択してください</option>
                          {groups.map((candidate) => (
                            <option key={candidate.id} value={candidate.id}>
                              {candidate.name} / {genreById.get(candidate.genre_id)?.name ?? "genre未取得"}
                            </option>
                          ))}
                        </AdminSelect>
                        <div className="grid gap-2 sm:grid-cols-2">
                          <AdminTextInput name="aliases" label="別名" placeholder="カンマ区切り" />
                          <AdminTextInput name="display_order" label="表示順" type="number" defaultValue="0" />
                        </div>
                        <AdminTextInput name="reason" label="承認理由" required />
                        <SubmitButton>新規L2として登録</SubmitButton>
                      </form>

                      <form action={mergeCharacterRequestIntoCharacter} className="grid gap-2 rounded-lg border border-slate-100 p-3">
                        <input type="hidden" name="request_id" value={request.id} />
                        <input type="hidden" name="return_to" value="/admin/operations" />
                        <AdminTextInput
                          name="approved_character_id"
                          label="既存L2 IDへ統合"
                          placeholder="characters_master.id"
                          required
                        />
                        <AdminTextInput name="reason" label="統合理由" required />
                        <SubmitButton>既存L2に統合</SubmitButton>
                      </form>

                      <form action={rejectCharacterRequest} className="grid gap-2 rounded-lg border border-rose-100 p-3">
                        <input type="hidden" name="request_id" value={request.id} />
                        <input type="hidden" name="return_to" value="/admin/operations" />
                        <AdminTextInput name="reason" label="却下理由" required />
                        <SubmitButton>却下する</SubmitButton>
                      </form>
                    </div>
                  )}
                </div>
              );
            })
          )}
        </div>
      </AdminPanel>
    </div>
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

function RequestHeader({
  title,
  status,
  user,
  createdAt,
}: {
  title: string;
  status: string;
  user: string;
  createdAt: string;
}) {
  return (
    <div className="flex items-start justify-between gap-3">
      <div>
        <div className="text-[13px] font-black text-slate-900">{title}</div>
        <div className="mt-1 text-[11px] font-semibold text-slate-500">
          {user} · {formatFullDateTime(createdAt)}
        </div>
      </div>
      <StatusPill tone={reportTone(status)}>{status}</StatusPill>
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
