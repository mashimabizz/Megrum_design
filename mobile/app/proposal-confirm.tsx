import { router, useLocalSearchParams } from "expo-router";
import { useEffect, useMemo, useState } from "react";
import {
  Image,
  Pressable,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  View,
} from "react-native";
import { PrimaryButton } from "../src/components/PrimaryButton";
import { Screen } from "../src/components/Screen";
import { StatusPill } from "../src/components/StatusPill";
import {
  NativeMapPreview,
  type MapCoordinate,
} from "../src/components/NativeMapPreview";
import {
  buildProposalCatalogOverrides,
  buildProposalThumbs,
  parseProposalIdList,
  type ProposalInventoryRow,
  type ProposalThumbItem,
} from "../src/data/proposalItems";
import { supabase } from "../src/lib/supabase";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

type MeetupCandidate = {
  id: string;
  label: string;
  time: string;
  startAt?: string;
  endAt?: string;
  place: string;
  coordinate: MapCoordinate;
};

const MEETUP_CANDIDATES: MeetupCandidate[] = [
  {
    id: "candidate-1",
    label: "候補1",
    time: "5月17日 14:00 - 15:00",
    place: "横浜アリーナ 北口",
    coordinate: {
      latitude: 35.5075,
      longitude: 139.6174,
    },
  },
  {
    id: "candidate-2",
    label: "候補2",
    time: "5月18日 16:00 - 17:00",
    place: "新横浜駅 中央改札",
    coordinate: {
      latitude: 35.5079,
      longitude: 139.6179,
    },
  },
];

export default function ProposalConfirmScreen() {
  const params = useLocalSearchParams<{
    meetups?: string | string[];
    gives?: string | string[];
    receives?: string | string[];
    listings?: string | string[];
    partnerId?: string | string[];
    partnerHandle?: string | string[];
    matchType?: string | string[];
  }>();
  const meetupsParam = one(params.meetups);
  const givesParam = one(params.gives);
  const receivesParam = one(params.receives);
  const listingsParam = one(params.listings);
  const partnerId = one(params.partnerId);
  const partnerHandle = one(params.partnerHandle) ?? PARTNER_HANDLE;
  const matchType = normalizeProposalMatchType(one(params.matchType));
  const giveIds = useMemo(() => parseProposalIdList(givesParam), [givesParam]);
  const receiveIds = useMemo(
    () => parseProposalIdList(receivesParam),
    [receivesParam],
  );
  const listingIds = useMemo(
    () => parseProposalIdList(listingsParam),
    [listingsParam],
  );
  const [catalogOverrides, setCatalogOverrides] = useState<
    ReturnType<typeof buildProposalCatalogOverrides>
  >(() => new Map());
  const meetupCandidates = useMemo(
    () => parseMeetups(meetupsParam),
    [meetupsParam],
  );
  const myItems = useMemo(
    () => buildProposalThumbs(giveIds, "give", catalogOverrides),
    [catalogOverrides, giveIds],
  );
  const theirItems = useMemo(
    () => buildProposalThumbs(receiveIds, "receive", catalogOverrides),
    [catalogOverrides, receiveIds],
  );
  const [message, setMessage] = useState("");
  const [shareSchedule, setShareSchedule] = useState(true);
  const [submitted, setSubmitted] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  useEffect(() => {
    if (!supabase) return;
    const ids = Array.from(new Set([...giveIds, ...receiveIds]));
    if (ids.length === 0) {
      setCatalogOverrides(new Map());
      return;
    }

    let active = true;
    supabase
      .from("goods_inventory")
      .select(
        "id, title, photo_urls, hue, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
      )
      .in("id", ids)
      .then(({ data }) => {
        if (!active) return;
        setCatalogOverrides(
          buildProposalCatalogOverrides((data as ProposalInventoryRow[] | null) ?? []),
        );
      });

    return () => {
      active = false;
    };
  }, [giveIds, receiveIds]);

  if (submitted) {
    return <ProposalCompleteScreen partnerHandle={partnerHandle} />;
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
          <Text style={styles.kicker}>PROPOSAL</Text>
          <Text style={styles.title}>送信確認</Text>
        </View>
        <StatusPill label="STEP 2/2" tone="sky" />
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.content}
      >
        <View style={styles.notice}>
          <Text style={styles.noticeBadge}>送信確認</Text>
          <Text style={styles.noticeText}>
            @{partnerHandle} に下記の内容で打診を送ります。
          </Text>
        </View>

        <Section title="交換内容">
          <ExchangeCard theirItems={theirItems} myItems={myItems} />
        </Section>

        <Section title="交換できる候補">
          <MeetupMapCard candidates={meetupCandidates} />
        </Section>

        <Section title="メッセージ（任意）" right={`${message.length} / 400`}>
          <TextInput
            value={message}
            onChangeText={setMessage}
            maxLength={400}
            multiline
            placeholderTextColor="rgba(58,50,74,0.32)"
            style={styles.messageInput}
            textAlignVertical="top"
          />
        </Section>

        <Pressable
          onPress={() => setShareSchedule((current) => !current)}
          style={[
            styles.scheduleCard,
            shareSchedule ? styles.scheduleCardOn : null,
          ]}
        >
          <View style={styles.scheduleCopy}>
            <Text style={styles.scheduleTitle}>スケジュールを共有する</Text>
            <Text style={styles.scheduleSub}>
              {shareSchedule ? "ON" : "OFF"}
            </Text>
          </View>
          <Switch
            value={shareSchedule}
            onValueChange={setShareSchedule}
            trackColor={{
              false: "rgba(58,50,74,0.14)",
              true: "rgba(166,149,216,0.46)",
            }}
            thumbColor={shareSchedule ? megrumColors.lavender : megrumColors.surface}
          />
        </Pressable>
      </ScrollView>

      {submitError ? <Text style={styles.submitError}>{submitError}</Text> : null}
      <PrimaryButton loading={submitting} onPress={handleSubmit}>
        この内容で打診を送信
      </PrimaryButton>
    </Screen>
  );

  async function handleSubmit() {
    setSubmitError(null);
    if (!partnerId || !supabase) {
      setSubmitted(true);
      return;
    }
    const primary = meetupCandidates[0];
    const sendableMeetups = meetupCandidates
      .filter((candidate) => candidate.startAt && candidate.endAt && candidate.place)
      .slice(0, 3);
    if (!primary || sendableMeetups.length === 0) {
      setSubmitError("交換できる時間と場所を設定してください");
      return;
    }
    if (giveIds.length === 0 || receiveIds.length === 0) {
      setSubmitError("提示するグッズを確認してください");
      return;
    }

    setSubmitting(true);
    try {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) {
        setSubmitError("ログイン状態を確認してください");
        return;
      }

      const now = new Date();
      const expires = new Date(now.getTime() + 7 * 24 * 60 * 60_000);
      const meetupPayloads = sendableMeetups.map((candidate) => ({
        startAt: candidate.startAt!,
        endAt: candidate.endAt!,
        placeName: candidate.place,
        lat: candidate.coordinate.latitude,
        lng: candidate.coordinate.longitude,
        mode: "scheduled",
      }));
      const insertFields: Record<string, unknown> = {
        sender_id: user.id,
        receiver_id: partnerId,
        match_type: matchType,
        sender_have_ids: giveIds,
        sender_have_qtys: giveIds.map(() => 1),
        receiver_have_ids: receiveIds,
        receiver_have_qtys: receiveIds.map(() => 1),
        message: message.trim(),
        message_tone: "standard",
        status: "sent",
        agreed_by_sender: true,
        agreed_by_receiver: false,
        last_action_at: now.toISOString(),
        expires_at: expires.toISOString(),
        meetup_start_at: meetupPayloads[0].startAt,
        meetup_end_at: meetupPayloads[0].endAt,
        meetup_place_name: meetupPayloads[0].placeName,
        meetup_lat: meetupPayloads[0].lat,
        meetup_lng: meetupPayloads[0].lng,
        meetup_candidates: meetupPayloads,
        expose_calendar: shareSchedule,
        listing_id: listingIds.length === 1 ? listingIds[0] : null,
        cash_offer: false,
        cash_amount: null,
      };

      const { error } = await insertProposalWithSchemaFallback(insertFields);
      if (error) {
        setSubmitError(formatProposalSubmitError(error));
        return;
      }
      setSubmitted(true);
    } finally {
      setSubmitting(false);
    }
  }
}

const PARTNER_HANDLE = "michilion";

function ProposalCompleteScreen({ partnerHandle }: { partnerHandle: string }) {
  return (
    <Screen contentStyle={styles.completeScreen}>
      <View style={styles.completeHero}>
        <View style={styles.completeSparkOne} />
        <View style={styles.completeSparkTwo} />
        <View style={styles.completeSparkThree} />
        <View style={styles.completeIcon}>
          <Text style={styles.completeIconText}>✓</Text>
        </View>
        <Text style={styles.completeTitle}>打診が完了しました</Text>
        <Text style={styles.completeText}>
          @{partnerHandle} に打診を送りました。返事が届いたら通知と打診一覧で確認できます。
        </Text>
      </View>

      <View style={styles.completeActions}>
        <PrimaryButton
          variant="secondary"
          onPress={() => router.replace("/")}
        >
          まだ他に探す
        </PrimaryButton>
        <PrimaryButton
          onPress={() => router.replace("/transactions")}
        >
          打診一覧に飛ぶ
        </PrimaryButton>
      </View>
    </Screen>
  );
}

function Section({
  title,
  right,
  children,
}: {
  title: string;
  right?: string;
  children: React.ReactNode;
}) {
  return (
    <View style={styles.section}>
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>{title}</Text>
        {right ? <Text style={styles.sectionRight}>{right}</Text> : null}
      </View>
      {children}
    </View>
  );
}

function ExchangeCard({
  theirItems,
  myItems,
}: {
  theirItems: ProposalThumbItem[];
  myItems: ProposalThumbItem[];
}) {
  return (
    <View style={styles.exchangeCard}>
      <SidePanel label={`相手の譲（${theirItems.length}）`} items={theirItems} />
      <View style={styles.swapColumn}>
        <ArrowDot color={megrumColors.lavender} direction="right" />
        <ArrowDot color={megrumColors.sky} direction="left" />
      </View>
      <SidePanel label={`あなたの譲（${myItems.length}）`} items={myItems} alignRight />
    </View>
  );
}

function SidePanel({
  label,
  items,
  alignRight,
}: {
  label: string;
  items: ProposalThumbItem[];
  alignRight?: boolean;
}) {
  return (
    <View style={[styles.sidePanel, alignRight ? styles.sidePanelRight : null]}>
      <Text style={[styles.sideLabel, alignRight ? styles.sideLabelRight : null]}>
        {label}
      </Text>
      <View style={[styles.thumbRow, alignRight ? styles.thumbRowRight : null]}>
        {items.map((item) => (
          <View key={item.id} style={[styles.thumb, { backgroundColor: item.color }]}>
            {item.photoUrl ? (
              <Image source={{ uri: item.photoUrl }} style={styles.thumbPhoto} />
            ) : (
              <>
                <View style={styles.thumbShine} />
                <Text style={styles.thumbGlyph}>{item.glyph}</Text>
              </>
            )}
          </View>
        ))}
      </View>
    </View>
  );
}

function ArrowDot({ color, direction }: { color: string; direction: "left" | "right" }) {
  return (
    <View style={[styles.arrowDot, { backgroundColor: color }]}>
      <Text style={styles.arrowDotText}>{direction === "right" ? "→" : "←"}</Text>
    </View>
  );
}

function MeetupMapCard({ candidates }: { candidates: MeetupCandidate[] }) {
  const center = getMapCenter(candidates);
  return (
    <View style={styles.meetupCard}>
      <View style={styles.meetupCardHeader}>
        <Text style={styles.meetupCardTitle}>待ち合わせ候補</Text>
        <View style={styles.meetupCardCount}>
          <Text style={styles.meetupCardCountText}>{candidates.length}件</Text>
        </View>
      </View>

      <View style={styles.mapPanel}>
        <NativeMapPreview
          center={center}
          height={204}
          markers={candidates.map((candidate, index) => ({
            id: candidate.id,
            coordinate: candidate.coordinate,
            label: String(index + 1),
            title: candidate.place,
          }))}
        />
      </View>

      <View style={styles.meetupList}>
        {candidates.map((candidate, index) => (
          <View key={candidate.id} style={styles.meetupRow}>
            <View style={styles.meetupNumber}>
              <Text style={styles.meetupNumberText}>{index + 1}</Text>
            </View>
            <View style={styles.meetupCopy}>
              <Text numberOfLines={1} style={styles.meetupTime}>
                {candidate.time}
              </Text>
              <Text numberOfLines={1} style={styles.meetupPlace}>
                {candidate.place}
              </Text>
            </View>
          </View>
        ))}
      </View>
    </View>
  );
}

function one(value?: string | string[]) {
  if (Array.isArray(value)) return value[0];
  return value;
}

function parseMeetups(raw?: string): MeetupCandidate[] {
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    const candidates = parsed
      .map((item, index): MeetupCandidate | null => {
        const latitude = Number(item?.latitude);
        const longitude = Number(item?.longitude);
        if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
          return null;
        }
        return {
          id: String(item?.id ?? `candidate-${index + 1}`),
          label: String(item?.label ?? `候補${index + 1}`),
          time: String(item?.time ?? ""),
          startAt: typeof item?.startAt === "string" ? item.startAt : undefined,
          endAt: typeof item?.endAt === "string" ? item.endAt : undefined,
          place: String(item?.place ?? ""),
          coordinate: { latitude, longitude },
        };
      })
      .filter(Boolean) as MeetupCandidate[];
    return candidates;
  } catch {
    return [];
  }
}

function normalizeProposalMatchType(value?: string) {
  if (value === "perfect" || value === "forward" || value === "backward") {
    return value;
  }
  if (value === "complete") return "perfect";
  if (value === "you_want_them") return "forward";
  if (value === "they_want_you") return "backward";
  return "perfect";
}

type ProposalInsertError = {
  code?: string;
  details?: string | null;
  hint?: string | null;
  message?: string;
};

const PROPOSAL_SCHEMA_FALLBACK_COLUMNS = new Set([
  "message_tone",
  "agreed_by_sender",
  "agreed_by_receiver",
  "last_action_at",
  "expires_at",
  "meetup_start_at",
  "meetup_end_at",
  "meetup_place_name",
  "meetup_lat",
  "meetup_lng",
  "meetup_candidates",
  "expose_calendar",
  "listing_id",
  "cash_offer",
  "cash_amount",
]);

async function insertProposalWithSchemaFallback(fields: Record<string, unknown>) {
  if (!supabase) return { error: null as ProposalInsertError | null };
  const currentFields = { ...fields };
  const maxAttempts = PROPOSAL_SCHEMA_FALLBACK_COLUMNS.size + 1;

  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    const { error } = await supabase.from("proposals").insert(currentFields);
    if (!error) return { error: null as ProposalInsertError | null };

    const missingColumn = getMissingProposalColumn(error);
    if (
      missingColumn &&
      PROPOSAL_SCHEMA_FALLBACK_COLUMNS.has(missingColumn) &&
      Object.prototype.hasOwnProperty.call(currentFields, missingColumn)
    ) {
      delete currentFields[missingColumn];
      continue;
    }

    return { error };
  }

  return {
    error: {
      message: "打診送信の互換処理が完了しませんでした。時間を置いて再度お試しください。",
    },
  };
}

function getMissingProposalColumn(error: ProposalInsertError | null) {
  const message = error?.message ?? "";
  const missingColumnMatch = message.match(/'([^']+)' column of 'proposals'/);
  if (missingColumnMatch?.[1]) return missingColumnMatch[1];
  if (error?.code === "PGRST204" && message.includes("schema cache")) {
    const quoted = message.match(/'([^']+)'/);
    return quoted?.[1] ?? null;
  }
  return null;
}

function formatProposalSubmitError(error: ProposalInsertError) {
  const missingColumn = getMissingProposalColumn(error);
  if (missingColumn) {
    return `打診の保存先とアプリの項目が一部ずれています（${missingColumn}）。少し時間を置いてもう一度お試しください。`;
  }
  return error.message ?? "打診を送信できませんでした。時間を置いて再度お試しください。";
}

function getMapCenter(candidates: MeetupCandidate[]): MapCoordinate {
  if (candidates.length === 0) return MEETUP_CANDIDATES[0].coordinate;
  const total = candidates.reduce(
    (acc, candidate) => ({
      latitude: acc.latitude + candidate.coordinate.latitude,
      longitude: acc.longitude + candidate.coordinate.longitude,
    }),
    { latitude: 0, longitude: 0 },
  );
  return {
    latitude: total.latitude / candidates.length,
    longitude: total.longitude / candidates.length,
  };
}

const styles = StyleSheet.create({
  screen: {
    gap: 12,
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
    ...megrumShadow,
  },
  backText: {
    color: megrumColors.ink,
    fontSize: 31,
    fontWeight: "700",
    lineHeight: 33,
  },
  headerCopy: {
    flex: 1,
  },
  kicker: {
    color: megrumColors.lavender,
    fontSize: 10,
    fontWeight: "900",
    letterSpacing: 0.7,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 23,
    fontWeight: "900",
    lineHeight: 28,
  },
  content: {
    gap: 13,
    paddingBottom: 16,
  },
  notice: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.08)",
    borderRadius: 12,
    flexDirection: "row",
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  noticeBadge: {
    backgroundColor: megrumColors.surface,
    borderRadius: megrumRadii.pill,
    color: megrumColors.lavender,
    fontSize: 9.5,
    fontWeight: "900",
    overflow: "hidden",
    paddingHorizontal: 7,
    paddingVertical: 3,
  },
  noticeText: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 17,
  },
  section: {
    gap: 8,
  },
  sectionHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  sectionTitle: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  sectionRight: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
  },
  exchangeCard: {
    alignItems: "flex-start",
    backgroundColor: "rgba(168,212,230,0.08)",
    borderRadius: 16,
    flexDirection: "row",
    gap: 9,
    padding: 10,
  },
  sidePanel: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.07)",
    borderRadius: 13,
    borderWidth: 1,
    flex: 1,
    minHeight: 108,
    padding: 9,
  },
  sidePanelRight: {
    backgroundColor: "rgba(243,197,212,0.08)",
  },
  sideLabel: {
    color: "#5c8da8",
    fontSize: 10.5,
    fontWeight: "900",
    marginBottom: 8,
  },
  sideLabelRight: {
    color: megrumColors.lavender,
  },
  thumbRow: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 6,
  },
  thumbRowRight: {
    justifyContent: "flex-end",
  },
  thumb: {
    alignItems: "center",
    borderColor: "rgba(255,255,255,0.74)",
    borderRadius: 9,
    borderWidth: 1,
    height: 44,
    justifyContent: "center",
    overflow: "hidden",
    position: "relative",
    width: 44,
  },
  thumbPhoto: {
    height: "100%",
    width: "100%",
  },
  thumbShine: {
    backgroundColor: "rgba(255,255,255,0.24)",
    borderRadius: 999,
    height: 34,
    position: "absolute",
    right: -8,
    top: -8,
    width: 34,
  },
  thumbGlyph: {
    color: megrumColors.surface,
    fontSize: 17,
    fontWeight: "900",
  },
  swapColumn: {
    alignItems: "center",
    gap: 4,
    paddingTop: 24,
  },
  arrowDot: {
    alignItems: "center",
    borderRadius: 999,
    height: 24,
    justifyContent: "center",
    width: 24,
  },
  arrowDotText: {
    color: megrumColors.surface,
    fontSize: 13,
    fontWeight: "900",
    lineHeight: 15,
  },
  meetupCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 18,
    borderWidth: 1,
    overflow: "hidden",
    ...megrumShadow,
  },
  meetupCardHeader: {
    alignItems: "center",
    backgroundColor: "#fbf9fc",
    borderBottomColor: "rgba(58,50,74,0.07)",
    borderBottomWidth: 1,
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  meetupCardTitle: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  meetupCardCount: {
    backgroundColor: "rgba(166,149,216,0.08)",
    borderRadius: 999,
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  meetupCardCountText: {
    color: megrumColors.lavender,
    fontSize: 9.5,
    fontWeight: "900",
  },
  mapPanel: {
    backgroundColor: "#edf3f4",
    borderBottomColor: "rgba(58,50,74,0.08)",
    borderBottomWidth: 1,
    height: 204,
    overflow: "hidden",
    position: "relative",
  },
  mapRoadOne: {
    backgroundColor: "rgba(255,255,255,0.92)",
    height: 20,
    left: -20,
    position: "absolute",
    right: -20,
    top: 72,
    transform: [{ rotate: "-12deg" }],
  },
  mapRoadTwo: {
    backgroundColor: "rgba(255,255,255,0.88)",
    bottom: 36,
    left: -10,
    position: "absolute",
    top: -10,
    transform: [{ rotate: "36deg" }],
    width: 22,
  },
  mapRoadThree: {
    backgroundColor: "rgba(255,255,255,0.76)",
    height: 14,
    left: 24,
    position: "absolute",
    right: 18,
    top: 132,
  },
  mapAreaOne: {
    backgroundColor: "rgba(166,149,216,0.10)",
    borderRadius: 22,
    height: 76,
    left: 22,
    position: "absolute",
    top: 24,
    width: 118,
  },
  mapAreaTwo: {
    backgroundColor: "rgba(168,212,230,0.20)",
    borderRadius: 28,
    bottom: 22,
    height: 86,
    position: "absolute",
    right: 22,
    width: 148,
  },
  mapPin: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderColor: megrumColors.surface,
    borderRadius: 999,
    borderWidth: 3,
    height: 34,
    justifyContent: "center",
    marginLeft: -17,
    marginTop: -17,
    position: "absolute",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.16,
    shadowRadius: 14,
    width: 34,
  },
  mapPinText: {
    color: megrumColors.surface,
    fontSize: 13,
    fontWeight: "900",
  },
  meetupList: {
    gap: 8,
    padding: 12,
  },
  meetupRow: {
    alignItems: "flex-start",
    flexDirection: "row",
    gap: 9,
  },
  meetupNumber: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 999,
    height: 22,
    justifyContent: "center",
    marginTop: 1,
    width: 22,
  },
  meetupNumberText: {
    color: megrumColors.surface,
    fontSize: 11,
    fontWeight: "900",
  },
  meetupCopy: {
    flex: 1,
  },
  meetupTime: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  meetupPlace: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 2,
  },
  messageInput: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 14,
    borderWidth: 1,
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "700",
    minHeight: 110,
    padding: 12,
  },
  submitError: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
    paddingHorizontal: 4,
  },
  scheduleCard: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 16,
    borderWidth: 1,
    flexDirection: "row",
    gap: 12,
    padding: 13,
  },
  scheduleCardOn: {
    backgroundColor: "rgba(166,149,216,0.08)",
    borderColor: "rgba(166,149,216,0.48)",
  },
  scheduleCopy: {
    flex: 1,
  },
  scheduleTitle: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  scheduleSub: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 2,
  },
  completeScreen: {
    gap: 18,
    justifyContent: "center",
  },
  completeHero: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.20)",
    borderRadius: 30,
    borderWidth: 1,
    minHeight: 360,
    overflow: "hidden",
    padding: 26,
    ...megrumShadow,
  },
  completeSparkOne: {
    backgroundColor: "rgba(166,149,216,0.18)",
    borderRadius: 999,
    height: 160,
    left: -54,
    position: "absolute",
    top: -42,
    width: 160,
  },
  completeSparkTwo: {
    backgroundColor: "rgba(168,212,230,0.24)",
    borderRadius: 999,
    bottom: -62,
    height: 178,
    position: "absolute",
    right: -62,
    width: 178,
  },
  completeSparkThree: {
    backgroundColor: "rgba(243,197,212,0.32)",
    borderRadius: 999,
    height: 88,
    position: "absolute",
    right: 58,
    top: 36,
    width: 88,
  },
  completeIcon: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderColor: "rgba(255,255,255,0.90)",
    borderRadius: 42,
    borderWidth: 3,
    height: 84,
    justifyContent: "center",
    marginTop: 58,
    shadowColor: megrumColors.lavender,
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.28,
    shadowRadius: 18,
    width: 84,
  },
  completeIconText: {
    color: megrumColors.surface,
    fontSize: 38,
    fontWeight: "900",
    lineHeight: 42,
  },
  completeTitle: {
    color: megrumColors.ink,
    fontSize: 25,
    fontWeight: "900",
    marginTop: 24,
    textAlign: "center",
  },
  completeText: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "800",
    lineHeight: 20,
    marginTop: 10,
    textAlign: "center",
  },
  completeActions: {
    gap: 10,
  },
});
