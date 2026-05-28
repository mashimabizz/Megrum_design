import { router, Stack, useLocalSearchParams } from "expo-router";
import {
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import {
  ActivityIndicator,
  Image,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { PrimaryButton } from "../src/components/PrimaryButton";
import { Screen } from "../src/components/Screen";
import { StatusPill } from "../src/components/StatusPill";
import { useAuth } from "../src/auth/AuthProvider";
import { hasSupabaseConfig, supabase } from "../src/lib/supabase";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

type ListingMode = "create" | "edit";
type ListingLogic = "and" | "or";
type ListingStatus = "active" | "paused" | "matched" | "closed";
type ExchangeType = "same_kind" | "cross_kind" | "any";
type SelectedItem = { id: string; qty: number };

type InventoryOpt = {
  id: string;
  title: string;
  photoUrl: string | null;
  groupId: string | null;
  goodsTypeId: string | null;
  groupName: string | null;
  characterName: string | null;
  goodsTypeName: string | null;
  hue: number;
  availableQty: number;
};

type WishOpt = {
  id: string;
  title: string;
  exchangeType?: ExchangeType;
  groupId: string | null;
  goodsTypeId: string | null;
  groupName: string | null;
  characterName: string | null;
  goodsTypeName: string | null;
  photoUrl: string | null;
};

type WishOptionState = {
  position: number;
  groupId: string | null;
  goodsTypeId: string | null;
  groupCustomized: boolean;
  goodsTypeCustomized: boolean;
  selected: SelectedItem[];
  logic: ListingLogic;
  exchangeType: ExchangeType;
  isCashOffer: boolean;
  cashAmount: number | null;
};

type ListingEditorData = {
  inventoryItems: InventoryOpt[];
  wishItems: WishOpt[];
  inventoryGroups: SelectOption[];
  inventoryGoodsTypes: SelectOption[];
  wishGroups: SelectOption[];
  wishGoodsTypes: SelectOption[];
  initialValues: ListingInitialValues | null;
  listingStatus: ListingStatus | null;
  locked: boolean;
};

type ListingInitialValues = {
  haveGroupId: string | null;
  haveGoodsTypeId: string | null;
  selectedHaves: SelectedItem[];
  haveLogic: ListingLogic;
  options: WishOptionState[];
  note: string;
};

type SelectOption = { id: string; name: string };

type InventoryRow = {
  id: string;
  title: string;
  photo_urls: string[] | null;
  hue: number | string | null;
  quantity: number | null;
  group_id: string | null;
  goods_type_id: string | null;
  group: RelationName;
  character: RelationName;
  goods_type: RelationName;
};

type InventoryCheckRow = {
  id: string;
  user_id: string;
  kind: string;
  status: string;
  quantity: number | null;
  title: string | null;
  group: RelationName;
  character: RelationName;
  goods_type: RelationName;
};

type WishRow = {
  id: string;
  title: string;
  exchange_type?: ExchangeType | null;
  group_id: string | null;
  goods_type_id: string | null;
  photo_urls: string[] | null;
  group: RelationName;
  character: RelationName;
  goods_type: RelationName;
};

type ListingRow = {
  id: string;
  user_id: string;
  status: ListingStatus;
  have_ids: string[] | null;
  have_qtys: number[] | null;
  have_logic: ListingLogic | null;
  have_group_id: string | null;
  have_goods_type_id: string | null;
  note: string | null;
};

type OptionRow = {
  id: string;
  position: number;
  wish_ids: string[] | null;
  wish_qtys: number[] | null;
  logic: ListingLogic | null;
  exchange_type: ExchangeType | null;
  is_cash_offer: boolean | null;
  cash_amount: number | null;
  wish_group_id: string | null;
  wish_goods_type_id: string | null;
};

type ProposalReservationRow = {
  sender_have_ids: string[] | null;
  sender_have_qtys: number[] | null;
  receiver_have_ids: string[] | null;
  receiver_have_qtys: number[] | null;
  approved_by_sender?: boolean | null;
  approved_by_receiver?: boolean | null;
};

type RelationName =
  | { name: string | null }
  | { name: string | null }[]
  | null
  | undefined;

const MAX_OPTIONS = 5;
const PREVIEW_INVENTORY: InventoryOpt[] = [
  {
    id: "preview-have-1",
    title: "スア 春ver.",
    photoUrl: null,
    groupId: "grp-lumena",
    goodsTypeId: "type-card",
    groupName: "LUMENA",
    characterName: "スア",
    goodsTypeName: "トレカ",
    hue: 260,
    availableQty: 2,
  },
  {
    id: "preview-have-2",
    title: "ジョンウ ラキドロ",
    photoUrl: null,
    groupId: "grp-lumena",
    goodsTypeId: "type-card",
    groupName: "LUMENA",
    characterName: "ジョンウ",
    goodsTypeName: "トレカ",
    hue: 198,
    availableQty: 1,
  },
  {
    id: "preview-have-3",
    title: "ニンニン アクスタ",
    photoUrl: null,
    groupId: "grp-aespa",
    goodsTypeId: "type-stand",
    groupName: "aespa",
    characterName: "ニンニン",
    goodsTypeName: "アクスタ",
    hue: 322,
    availableQty: 1,
  },
];
const PREVIEW_WISHES: WishOpt[] = [
  {
    id: "preview-wish-1",
    title: "スア ラキドロ",
    groupId: "grp-lumena",
    goodsTypeId: "type-card",
    groupName: "LUMENA",
    characterName: "スア",
    goodsTypeName: "トレカ",
    photoUrl: null,
    exchangeType: "any",
  },
  {
    id: "preview-wish-2",
    title: "ニンニン 制服",
    groupId: "grp-aespa",
    goodsTypeId: "type-stand",
    groupName: "aespa",
    characterName: "ニンニン",
    goodsTypeName: "アクスタ",
    photoUrl: null,
    exchangeType: "same_kind",
  },
  {
    id: "preview-wish-3",
    title: "ウィンター 缶バッジ",
    groupId: "grp-aespa",
    goodsTypeId: "type-badge",
    groupName: "aespa",
    characterName: "ウィンター",
    goodsTypeName: "缶バッジ",
    photoUrl: null,
    exchangeType: "any",
  },
];

export default function ListingEditorScreen() {
  const { user, previewMode } = useAuth();
  const params = useLocalSearchParams<{
    mode?: ListingMode | ListingMode[];
    id?: string | string[];
    wishId?: string | string[];
    want?: string | string[];
  }>();
  const mode = (one(params.mode) as ListingMode | undefined) ?? "create";
  const listingId = one(params.id) ?? null;
  const preselectWishId = one(params.wishId) ?? null;
  const usePreviewData = previewMode || !hasSupabaseConfig;
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [data, setData] = useState<ListingEditorData | null>(null);

  const inventoryItemById = useMemo(
    () => new Map((data?.inventoryItems ?? []).map((item) => [item.id, item] as const)),
    [data?.inventoryItems],
  );
  const wishItemById = useMemo(
    () => new Map((data?.wishItems ?? []).map((item) => [item.id, item] as const)),
    [data?.wishItems],
  );
  const [haveGroupId, setHaveGroupId] = useState<string | null>(null);
  const [haveGoodsTypeId, setHaveGoodsTypeId] = useState<string | null>(null);
  const [selectedHaves, setSelectedHaves] = useState<SelectedItem[]>([]);
  const [haveLogic, setHaveLogic] = useState<ListingLogic>("and");
  const [options, setOptions] = useState<WishOptionState[]>([blankOption(1)]);
  const [note, setNote] = useState("");
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    setLoading(true);
    setLoadError(null);
    fetchEditorData({
      userId: user?.id ?? null,
      mode,
      listingId,
      preselectWishId,
      preview: usePreviewData,
      fallbackWishTitle: one(params.want) ?? null,
    })
      .then((nextData) => {
        if (!active) return;
        setData(nextData);
        applyInitialValues(nextData.initialValues, nextData.wishItems, preselectWishId);
      })
      .catch((error: unknown) => {
        if (!active) return;
        setLoadError(error instanceof Error ? error.message : "読み込みに失敗しました");
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [listingId, mode, params.want, preselectWishId, usePreviewData, user?.id]);

  function applyInitialValues(
    initialValues: ListingInitialValues | null,
    wishItems: WishOpt[],
    wishId: string | null,
  ) {
    if (initialValues) {
      setHaveGroupId(initialValues.haveGroupId);
      setHaveGoodsTypeId(initialValues.haveGoodsTypeId);
      setSelectedHaves(initialValues.selectedHaves);
      setHaveLogic(initialValues.haveLogic);
      setOptions(initialValues.options.length > 0 ? initialValues.options : [blankOption(1)]);
      setNote(initialValues.note);
      return;
    }
    const preselectWish = wishId ? wishItems.find((wish) => wish.id === wishId) ?? null : null;
    setHaveGroupId(preselectWish?.groupId ?? null);
    setHaveGoodsTypeId(preselectWish?.goodsTypeId ?? null);
    setSelectedHaves([]);
    setHaveLogic("and");
    setOptions([
      preselectWish
        ? {
            ...blankOption(1),
            groupId: preselectWish.groupId,
            goodsTypeId: preselectWish.goodsTypeId,
            groupCustomized: true,
            goodsTypeCustomized: true,
            selected: [{ id: preselectWish.id, qty: 1 }],
          }
        : blankOption(1),
    ]);
    setNote("");
  }

  const filteredHaves = useMemo(() => {
    if (!data || !haveGroupId || !haveGoodsTypeId) return [];
    return data.inventoryItems.filter(
      (item) => item.groupId === haveGroupId && item.goodsTypeId === haveGoodsTypeId,
    );
  }, [data, haveGoodsTypeId, haveGroupId]);

  function showToast(message: string) {
    setToast(message);
    setTimeout(() => setToast(null), 2200);
  }

  function changeHaveGroup(nextId: string | null) {
    setHaveGroupId(nextId);
    setSelectedHaves([]);
    setOptions((current) =>
      current.map((option) =>
        option.groupCustomized || option.isCashOffer
          ? option
          : { ...option, groupId: nextId, selected: [] },
      ),
    );
  }

  function changeHaveGoodsType(nextId: string | null) {
    setHaveGoodsTypeId(nextId);
    setSelectedHaves([]);
    setOptions((current) =>
      current.map((option) =>
        option.goodsTypeCustomized || option.isCashOffer
          ? option
          : { ...option, goodsTypeId: nextId, selected: [] },
      ),
    );
  }

  function toggleHave(id: string) {
    setSelectedHaves((current) => {
      const existing = current.find((item) => item.id === id);
      if (existing) return current.filter((item) => item.id !== id);
      const cap = inventoryItemById.get(id)?.availableQty ?? 1;
      if (cap < 1) {
        showToast("このグッズは在庫がありません");
        return current;
      }
      return [...current, { id, qty: 1 }];
    });
  }

  function setHaveQty(id: string, delta: number) {
    const cap = inventoryItemById.get(id)?.availableQty ?? 1;
    setSelectedHaves((current) =>
      current.map((item) => {
        if (item.id !== id) return item;
        const next = item.qty + delta;
        if (delta > 0 && next > cap) {
          showToast(`市場残数（${cap}）が上限です`);
          return { ...item, qty: cap };
        }
        return { ...item, qty: Math.max(1, Math.min(cap, next)) };
      }),
    );
  }

  function patchOption(index: number, patch: Partial<WishOptionState>) {
    setOptions((current) =>
      current.map((option, i) => (i === index ? { ...option, ...patch } : option)),
    );
  }

  function toggleOptionWish(index: number, wishId: string) {
    setOptions((current) =>
      current.map((option, i) => {
        if (i !== index) return option;
        const exists = option.selected.some((item) => item.id === wishId);
        return {
          ...option,
          selected: exists
            ? option.selected.filter((item) => item.id !== wishId)
            : [...option.selected, { id: wishId, qty: 1 }],
        };
      }),
    );
  }

  function setOptionWishQty(index: number, wishId: string, delta: number) {
    setOptions((current) =>
      current.map((option, i) => {
        if (i !== index) return option;
        return {
          ...option,
          selected: option.selected.map((item) =>
            item.id === wishId
              ? { ...item, qty: Math.max(1, Math.min(99, item.qty + delta)) }
              : item,
          ),
        };
      }),
    );
  }

  function addOption() {
    if (options.length >= MAX_OPTIONS) return;
    setOptions((current) => [
      ...current,
      {
        ...blankOption(current.length + 1),
        groupId: haveGroupId,
        goodsTypeId: haveGoodsTypeId,
      },
    ]);
  }

  function toggleCashOffer(enabled: boolean) {
    setOptions((current) => {
      const normalized = current.filter((option) => !option.isCashOffer);
      if (!enabled) {
        return (normalized.length > 0 ? normalized : [blankOption(1)]).map((option, index) => ({
          ...option,
          position: index + 1,
        }));
      }
      if (current.some((option) => option.isCashOffer)) return current;
      const cashOption = {
        ...blankOption(normalized.length + 1),
        isCashOffer: true,
        cashAmount: 1000,
      };
      if (normalized.length >= MAX_OPTIONS) {
        showToast(`選択肢は最大${MAX_OPTIONS}件です`);
        return current;
      }
      if (normalized.length === 1 && isBlankWishOption(normalized[0])) {
        return [{ ...cashOption, position: 1 }];
      }
      return [...normalized, cashOption].map((option, index) => ({
        ...option,
        position: index + 1,
      }));
    });
  }

  function setCashOfferAmount(rawValue: string) {
    const cleaned = rawValue.replace(/[^\d]/g, "");
    const next = cleaned ? Number(cleaned) : null;
    setOptions((current) =>
      current.map((option) =>
        option.isCashOffer
          ? { ...option, cashAmount: Number.isFinite(next) ? next : null }
          : option,
      ),
    );
  }

  function removeOption(index: number) {
    setOptions((current) =>
      current
        .filter((_, i) => i !== index)
        .map((option, i) => ({ ...option, position: i + 1 })),
    );
  }

  async function handleSubmit() {
    if (!data) return;
    setFormError(null);
    const submittableHaves = selectedHaves.flatMap((item) => {
      const source = inventoryItemById.get(item.id);
      if (!source || source.availableQty < 1) return [];
      return [
        {
          id: item.id,
          qty: Math.min(Math.max(1, item.qty), source.availableQty),
        },
      ];
    });
    const validationError = validateListingForm({
      haveGroupId,
      haveGoodsTypeId,
      haveIds: submittableHaves.map((item) => item.id),
      haveQtys: submittableHaves.map((item) => item.qty),
      haveLogic,
      options,
    });
    if (validationError) {
      setFormError(validationError);
      return;
    }

    if (!supabase || usePreviewData || !user) {
      router.back();
      return;
    }

    setSaving(true);
    const result =
      mode === "edit" && listingId
        ? await updateListingFullMobile({
            userId: user.id,
            listingId,
            haveIds: submittableHaves.map((item) => item.id),
            haveQtys: submittableHaves.map((item) => item.qty),
            haveLogic,
            options,
            note,
          })
        : await createListingMobile({
            userId: user.id,
            haveIds: submittableHaves.map((item) => item.id),
            haveQtys: submittableHaves.map((item) => item.qty),
            haveLogic,
            options,
            note,
          });
    setSaving(false);
    if (result?.error) {
      setFormError(result.error);
      return;
    }
    router.replace({
      pathname: "/wishes",
      params: { tab: "listings", refresh: String(Date.now()) },
    });
  }

  if (loading) {
    return (
      <Screen contentStyle={styles.centerScreen} topInset={false}>
        <NativeListingHeader title={mode === "create" ? "個別募集を作成" : "個別募集を編集"} />
        <ActivityIndicator color={megrumColors.lavender} />
        <Text style={styles.loadingText}>個別募集を読み込み中…</Text>
      </Screen>
    );
  }

  if (loadError || !data) {
    return (
      <Screen contentStyle={styles.screen} topInset={false}>
        <NativeListingHeader title={mode === "create" ? "個別募集を作成" : "個別募集を編集"} />
        <View style={styles.emptyNotice}>
          <Text style={styles.emptyTitle}>読み込みに失敗しました</Text>
          <Text style={styles.emptyText}>{loadError ?? "データが見つかりません"}</Text>
        </View>
      </Screen>
    );
  }

  const cashOffer = options.find((option) => option.isCashOffer) ?? null;
  const canCreate = data.inventoryItems.length > 0;
  const locked = data.locked;

  return (
    <Screen contentStyle={styles.screen} topInset={false}>
      <NativeListingHeader title={mode === "create" ? "個別募集を作成" : "個別募集を編集"} />

      {locked ? (
        <View style={styles.emptyNotice}>
          <Text style={styles.emptyTitle}>この個別募集は編集できません</Text>
          <Text style={styles.emptyText}>
            成立／完了した個別募集は、取引履歴との整合性を保つため編集できません。
          </Text>
        </View>
      ) : null}

      {!locked && !canCreate ? (
        <View style={styles.emptyNotice}>
          <Text style={styles.emptyTitle}>譲る候補が必要です</Text>
          <Text style={styles.emptyText}>
            個別募集を作るには、まず譲る候補を登録してください。求めるものは Wish か定価で設定できます。
          </Text>
        </View>
      ) : null}

      {!locked && canCreate ? (
        <>
          <PreviewCard
            haves={selectedHaves}
            options={options}
            inventoryById={inventoryItemById}
            wishById={wishItemById}
          />

          <View style={styles.form}>
            <FormSection
              label="譲るグッズ"
              right={
                selectedHaves.length > 0
                  ? `${selectedHaves.length}件選択中`
                  : "必須"
              }
            >
              <View style={styles.twoColumn}>
                <ChoiceRow
                  label="グループ"
                  value={haveGroupId}
                  options={data.inventoryGroups}
                  onChange={changeHaveGroup}
                />
                <ChoiceRow
                  label="種別"
                  value={haveGoodsTypeId}
                  options={data.inventoryGoodsTypes}
                  onChange={changeHaveGoodsType}
                />
              </View>
              <View style={styles.noticeBox}>
                <Text style={styles.noticeText}>
                  複数選ぶ場合は同じシリーズに限定してください。シリーズが混ざると、同種 / 異種の判定が曖昧になります。
                </Text>
              </View>
              {!haveGroupId || !haveGoodsTypeId ? (
                <EmptyBox label="先にグループと種別を選んでください" />
              ) : filteredHaves.length === 0 ? (
                <EmptyBox label="この組み合わせの譲がありません" />
              ) : (
                <View style={styles.cardGrid}>
                  {filteredHaves.map((item) => {
                    const selected = selectedHaves.find((s) => s.id === item.id);
                    return (
                      <GoodsPanelCard
                        key={item.id}
                        item={item}
                        selected={!!selected}
                        qty={selected?.qty ?? 0}
                        onPress={() => toggleHave(item.id)}
                        onQty={(delta) => setHaveQty(item.id, delta)}
                      />
                    );
                  })}
                </View>
              )}
              {selectedHaves.length > 1 ? (
                <LogicToggle
                  label="この複数の譲は…"
                  value={haveLogic}
                  onChange={setHaveLogic}
                />
              ) : null}
              <CashOfferControl
                amount={cashOffer?.cashAmount ?? null}
                enabled={!!cashOffer}
                onAmountChange={setCashOfferAmount}
                onToggle={toggleCashOffer}
              />
            </FormSection>

            <View style={styles.optionHeader}>
              <View>
                <Text style={styles.optionHeaderLabel}>求める — 選択肢</Text>
                <Text style={styles.optionHeaderSub}>
                  複数なら相手がどれか1つ選びます
                </Text>
              </View>
              <Text style={styles.optionCounter}>
                {options.length} / {MAX_OPTIONS}
              </Text>
            </View>

            {options.map((option, index) => (
              <OptionEditor
                key={`${option.position}-${index}`}
                option={option}
                index={index}
                wishItems={data.wishItems}
                groups={data.wishGroups}
                goodsTypes={data.wishGoodsTypes}
                defaultGroupId={haveGroupId}
                defaultGoodsTypeId={haveGoodsTypeId}
                parentHaveLogic={haveLogic}
                parentHaveCount={selectedHaves.length}
                onPatch={(patch) => patchOption(index, patch)}
                onToggleWish={(wishId) => toggleOptionWish(index, wishId)}
                onWishQty={(wishId, delta) => setOptionWishQty(index, wishId, delta)}
                onRemove={options.length > 1 ? () => removeOption(index) : undefined}
              />
            ))}

            {options.length < MAX_OPTIONS ? (
              <Pressable onPress={addOption} style={styles.addOptionButton}>
                <Text style={styles.addOptionText}>
                  + 選択肢を追加（{options.length} / {MAX_OPTIONS}）
                </Text>
              </Pressable>
            ) : null}

            <FormSection label="メモ" right={`${note.length} / 500`}>
              <TextInput
                value={note}
                maxLength={500}
                multiline
                onChangeText={setNote}
                placeholder="例: 同会場で取引できる方優先"
                placeholderTextColor="rgba(58,50,74,0.35)"
                style={styles.noteInput}
                textAlignVertical="top"
              />
            </FormSection>

            {formError ? (
              <View style={styles.errorBox}>
                <Text style={styles.errorText}>{formError}</Text>
              </View>
            ) : null}

            <PrimaryButton loading={saving} onPress={handleSubmit}>
              {mode === "edit" ? "個別募集を更新" : "個別募集を作成"}
            </PrimaryButton>
          </View>
        </>
      ) : null}

      {toast ? (
        <View style={styles.toast}>
          <Text style={styles.toastText}>{toast}</Text>
        </View>
      ) : null}
    </Screen>
  );
}

function NativeListingHeader({ title }: { title: string }) {
  return (
    <Stack.Screen
      options={{
        headerShown: true,
        title,
        headerBackButtonDisplayMode: "minimal",
        headerBlurEffect: "systemMaterial",
        headerTintColor: megrumColors.lavender,
        headerRight: () => <StatusPill label="条件設定" tone="lavender" />,
      }}
    />
  );
}

function PreviewCard({
  haves,
  options,
  inventoryById,
  wishById,
}: {
  haves: SelectedItem[];
  options: WishOptionState[];
  inventoryById: Map<string, InventoryOpt>;
  wishById: Map<string, WishOpt>;
}) {
  const haveItems = haves.flatMap((item) => {
    const source = inventoryById.get(item.id);
    return source ? [source] : [];
  });
  const wishItems = options.flatMap((option) => {
    if (option.isCashOffer) return [];
    return option.selected.flatMap((item) => {
      const source = wishById.get(item.id);
      return source ? [source] : [];
    });
  });
  const cash = options.find((option) => option.isCashOffer);
  return (
    <View style={styles.preview}>
      <View style={styles.previewHeader}>
        <Text style={styles.previewTitle}>交換条件</Text>
        {cash ? (
          <Text style={styles.previewCash}>定価 {cash.cashAmount ?? 0}円あり</Text>
        ) : null}
      </View>
      <View style={styles.previewLine}>
        <PreviewSide label="譲る" items={haveItems} fallback="譲るグッズ" />
        <View style={styles.previewCord}>
          <View style={styles.previewCordLine} />
          <View style={styles.previewKnot}>
            <Text style={styles.previewKnotText}>∿</Text>
          </View>
        </View>
        <PreviewSide label="求める" items={wishItems} fallback="求めるWish" />
      </View>
    </View>
  );
}

function PreviewSide({
  label,
  items,
  fallback,
}: {
  label: string;
  items: Array<InventoryOpt | WishOpt>;
  fallback: string;
}) {
  const visible = items.slice(0, 3);
  return (
    <View style={styles.previewSide}>
      <Text style={styles.previewSideLabel}>{label}</Text>
      <View style={styles.previewBubbles}>
        {(visible.length > 0 ? visible : [{ title: fallback }]).map((item, index) => {
          const title = "characterName" in item
            ? item.characterName ?? item.groupName ?? item.title
            : item.title;
          const hue = "hue" in item ? item.hue : nameToHue(title);
          const photoUrl = "photoUrl" in item ? item.photoUrl : null;
          return (
            <View
              key={`${title}-${index}`}
              style={[
                styles.previewBubble,
                {
                  backgroundColor: photoUrl ? megrumColors.ink : `hsl(${hue}, 55%, 78%)`,
                  marginTop: index === 1 ? -8 : index === 2 ? 6 : 0,
                },
              ]}
            >
              {photoUrl ? (
                <Image source={{ uri: photoUrl }} style={styles.previewBubbleImage} />
              ) : (
                <Text style={styles.previewBubbleText}>{title.slice(0, 1)}</Text>
              )}
            </View>
          );
        })}
        {items.length > visible.length ? (
          <View style={styles.previewMore}>
            <Text style={styles.previewMoreText}>+{items.length - visible.length}</Text>
          </View>
        ) : null}
      </View>
    </View>
  );
}

function FormSection({
  label,
  right,
  children,
}: {
  label: string;
  right?: string;
  children: ReactNode;
}) {
  return (
    <View style={styles.section}>
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionLabel}>{label}</Text>
        {right ? <Text style={styles.sectionRight}>{right}</Text> : null}
      </View>
      <View style={styles.sectionBody}>{children}</View>
    </View>
  );
}

function ChoiceRow({
  label,
  value,
  options,
  onChange,
}: {
  label: string;
  value: string | null;
  options: SelectOption[];
  onChange: (value: string | null) => void;
}) {
  return (
    <View style={styles.choiceBlock}>
      <Text style={styles.choiceLabel}>{label}</Text>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.choiceScroller}
      >
        <ChoiceChip label="選択" active={!value} onPress={() => onChange(null)} />
        {options.map((option) => (
          <ChoiceChip
            key={option.id}
            label={option.name}
            active={value === option.id}
            onPress={() => onChange(option.id)}
          />
        ))}
      </ScrollView>
    </View>
  );
}

function ChoiceChip({
  label,
  active,
  onPress,
}: {
  label: string;
  active: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={[styles.choiceChip, active ? styles.choiceChipActive : null]}
    >
      <Text style={[styles.choiceChipText, active ? styles.choiceChipTextActive : null]}>
        {label}
      </Text>
    </Pressable>
  );
}

function CashOfferControl({
  amount,
  enabled,
  onAmountChange,
  onToggle,
}: {
  amount: number | null;
  enabled: boolean;
  onAmountChange: (value: string) => void;
  onToggle: (enabled: boolean) => void;
}) {
  return (
    <View style={[styles.cashOfferBox, enabled ? styles.cashOfferBoxActive : null]}>
      <Pressable
        accessibilityRole="switch"
        accessibilityState={{ checked: enabled }}
        onPress={() => onToggle(!enabled)}
        style={styles.cashOfferHeader}
      >
        <View>
          <Text style={styles.cashOfferTitle}>定価でも譲る</Text>
          <Text style={styles.cashOfferSub}>
            Wishがなくても、相手には定価交換の選択肢として表示します。
          </Text>
        </View>
        <View style={[styles.cashOfferSwitch, enabled ? styles.cashOfferSwitchActive : null]}>
          <View style={[styles.cashOfferKnob, enabled ? styles.cashOfferKnobActive : null]} />
        </View>
      </Pressable>
      {enabled ? (
        <View style={styles.cashOfferAmountRow}>
          <Text style={styles.choiceLabel}>定価（円）</Text>
          <TextInput
            keyboardType="number-pad"
            onChangeText={onAmountChange}
            placeholder="1000"
            placeholderTextColor="rgba(58,50,74,0.35)"
            style={styles.cashInput}
            value={amount ? String(amount) : ""}
          />
        </View>
      ) : null}
    </View>
  );
}

function GoodsPanelCard({
  item,
  selected,
  qty,
  compact = false,
  onPress,
  onQty,
}: {
  item: InventoryOpt | WishOpt;
  selected: boolean;
  qty: number;
  compact?: boolean;
  onPress: () => void;
  onQty: (delta: number) => void;
}) {
  const name = item.characterName ?? item.groupName ?? item.title;
  const hue = "hue" in item ? item.hue : nameToHue(name);
  const hasPhoto = !!item.photoUrl;
  return (
    <View
      style={[
        styles.panelWrap,
        compact ? styles.panelWrapCompact : null,
        selected ? styles.panelWrapSelected : null,
      ]}
    >
      <Pressable
        accessibilityRole="button"
        onPress={onPress}
        style={[
          styles.panelCard,
          {
            backgroundColor: hasPhoto ? megrumColors.ink : `hsl(${hue}, 34%, 82%)`,
          },
        ]}
      >
        {hasPhoto ? (
          <Image source={{ uri: item.photoUrl! }} resizeMode="cover" style={styles.panelImage} />
        ) : (
          <>
            <View style={styles.panelShine} />
            <Text style={styles.panelGlyph}>{name.slice(0, 1)}</Text>
          </>
        )}
        <View style={styles.panelNamePlate}>
          <Text numberOfLines={1} style={styles.panelName}>
            {name}
          </Text>
        </View>
        <View style={styles.panelBottom}>
          <Text numberOfLines={1} style={styles.panelType}>
            {item.goodsTypeName ?? "グッズ"}
          </Text>
        </View>
        {!selected ? (
          <View style={styles.panelAddMark}>
            <Text style={styles.panelAddText}>+</Text>
          </View>
        ) : null}
      </Pressable>
      {selected ? (
        <View style={styles.qtyOverlay}>
          <Pressable
            disabled={qty <= 1}
            onPress={() => onQty(-1)}
            style={styles.qtyButton}
          >
            <Text style={styles.qtyButtonText}>−</Text>
          </Pressable>
          <Text style={styles.qtyText}>×{qty}</Text>
          <Pressable onPress={() => onQty(1)} style={styles.qtyButton}>
            <Text style={styles.qtyButtonText}>＋</Text>
          </Pressable>
        </View>
      ) : null}
    </View>
  );
}

function LogicToggle({
  label,
  value,
  onChange,
}: {
  label: string;
  value: ListingLogic;
  onChange: (value: ListingLogic) => void;
}) {
  return (
    <View style={styles.logicBox}>
      <Text style={styles.logicLabel}>{label}</Text>
      <View style={styles.logicRow}>
        {[
          { value: "and" as const, label: "全部", sub: "セット" },
          { value: "or" as const, label: "1pick", sub: "どれか1つ" },
        ].map((option) => {
          const active = value === option.value;
          return (
            <Pressable
              key={option.value}
              onPress={() => onChange(option.value)}
              style={[styles.logicButton, active ? styles.logicButtonActive : null]}
            >
              <Text
                style={[styles.logicButtonText, active ? styles.logicButtonTextActive : null]}
              >
                {option.label}
              </Text>
              <Text
                style={[styles.logicButtonSub, active ? styles.logicButtonSubActive : null]}
              >
                {option.sub}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

function OptionEditor({
  option,
  index,
  wishItems,
  groups,
  goodsTypes,
  defaultGroupId,
  defaultGoodsTypeId,
  parentHaveLogic,
  parentHaveCount,
  onPatch,
  onToggleWish,
  onWishQty,
  onRemove,
}: {
  option: WishOptionState;
  index: number;
  wishItems: WishOpt[];
  groups: SelectOption[];
  goodsTypes: SelectOption[];
  defaultGroupId: string | null;
  defaultGoodsTypeId: string | null;
  parentHaveLogic: ListingLogic;
  parentHaveCount: number;
  onPatch: (patch: Partial<WishOptionState>) => void;
  onToggleWish: (wishId: string) => void;
  onWishQty: (wishId: string, delta: number) => void;
  onRemove?: () => void;
}) {
  const filteredWishes = useMemo(() => {
    if (option.isCashOffer || !option.groupId || !option.goodsTypeId) return [];
    return wishItems.filter(
      (wish) => wish.groupId === option.groupId && wish.goodsTypeId === option.goodsTypeId,
    );
  }, [option.goodsTypeId, option.groupId, option.isCashOffer, wishItems]);
  const allSelectedHaveImages =
    !option.isCashOffer &&
    option.selected.length > 0 &&
    option.selected.every((selected) => {
      const wish = wishItems.find((item) => item.id === selected.id);
      return !!wish?.photoUrl;
    });
  const orOrViolation =
    !option.isCashOffer &&
    parentHaveLogic === "or" &&
    option.logic === "or" &&
    parentHaveCount > 1 &&
    option.selected.length > 1;

  useEffect(() => {
    if (allSelectedHaveImages && option.exchangeType !== "any") {
      onPatch({ exchangeType: "any" });
    }
  }, [allSelectedHaveImages, onPatch, option.exchangeType]);

  return (
    <View style={styles.optionCard}>
      <View style={styles.optionTop}>
        <Text style={styles.optionBadge}>選択肢 {index + 1}</Text>
        <Pressable
          onPress={() =>
            onPatch({
              isCashOffer: !option.isCashOffer,
              groupId: option.isCashOffer ? defaultGroupId : null,
              goodsTypeId: option.isCashOffer ? defaultGoodsTypeId : null,
              selected: [],
              cashAmount: option.isCashOffer ? null : 1000,
            })
          }
          style={[
            styles.cashToggle,
            option.isCashOffer ? styles.cashToggleActive : null,
          ]}
        >
          <Text
            style={[
              styles.cashToggleText,
              option.isCashOffer ? styles.cashToggleTextActive : null,
            ]}
          >
            定価交換
          </Text>
        </Pressable>
        {onRemove ? (
          <Pressable onPress={onRemove} style={styles.removeButton}>
            <Text style={styles.removeButtonText}>削除</Text>
          </Pressable>
        ) : null}
      </View>

      {option.isCashOffer ? (
        <View style={styles.cashEditor}>
          <Text style={styles.choiceLabel}>希望金額（円）</Text>
          <TextInput
            value={String(option.cashAmount ?? "")}
            onChangeText={(value) => {
              const numeric = Number(value.replace(/[^\d]/g, ""));
              onPatch({ cashAmount: Number.isFinite(numeric) ? numeric : null });
            }}
            keyboardType="number-pad"
            placeholder="1000"
            placeholderTextColor="rgba(58,50,74,0.35)"
            style={styles.cashInput}
          />
          <Text style={styles.helpText}>
            この選択肢はマッチング演算には参加せず、定価交換として表示します。
          </Text>
        </View>
      ) : (
        <>
          <View style={styles.twoColumn}>
            <ChoiceRow
              label="グループ"
              value={option.groupId}
              options={groups}
              onChange={(value) =>
                onPatch({
                  groupId: value,
                  groupCustomized: true,
                  selected: [],
                })
              }
            />
            <ChoiceRow
              label="種別"
              value={option.goodsTypeId}
              options={goodsTypes}
              onChange={(value) =>
                onPatch({
                  goodsTypeId: value,
                  goodsTypeCustomized: true,
                  selected: [],
                })
              }
            />
          </View>
          {!option.groupId || !option.goodsTypeId ? (
            <EmptyBox label="先にグループと種別を選んでください" />
          ) : filteredWishes.length === 0 ? (
            <EmptyBox label="この組み合わせのWishがありません" />
          ) : (
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={styles.wishScroller}
            >
              {filteredWishes.map((wish) => {
                const selected = option.selected.find((item) => item.id === wish.id);
                return (
                  <GoodsPanelCard
                    key={wish.id}
                    item={wish}
                    compact
                    selected={!!selected}
                    qty={selected?.qty ?? 0}
                    onPress={() => onToggleWish(wish.id)}
                    onQty={(delta) => onWishQty(wish.id, delta)}
                  />
                );
              })}
            </ScrollView>
          )}

          {option.selected.length > 0 ? (
            allSelectedHaveImages ? (
              <View style={styles.noticeBox}>
                <Text style={styles.noticeText}>
                  画像のあるWishのみ選択中。同種 / 異種の指定は不要です。
                </Text>
              </View>
            ) : (
              <ExchangeTypeToggle
                value={option.exchangeType}
                onChange={(value) => onPatch({ exchangeType: value })}
              />
            )
          ) : null}

          {option.selected.length > 1 ? (
            <LogicToggle
              label="この複数のWishは…"
              value={option.logic}
              onChange={(value) => onPatch({ logic: value })}
            />
          ) : null}

          {orOrViolation ? (
            <View style={styles.warnBox}>
              <Text style={styles.warnText}>
                譲側OR × この選択肢OR × 両側2点以上は曖昧なため指定できません。
              </Text>
            </View>
          ) : null}
        </>
      )}
    </View>
  );
}

function ExchangeTypeToggle({
  value,
  onChange,
}: {
  value: ExchangeType;
  onChange: (value: ExchangeType) => void;
}) {
  return (
    <View>
      <View style={styles.exchangeHeader}>
        <Text style={styles.choiceLabel}>交換タイプ</Text>
        <Text style={styles.exchangeHint}>画像なしWishがあるため指定が必要</Text>
      </View>
      <View style={styles.exchangeRow}>
        {[
          { value: "any" as const, label: "同異種", sub: "どちらでも" },
          { value: "same_kind" as const, label: "同種のみ", sub: "同じ種別" },
          { value: "cross_kind" as const, label: "異種のみ", sub: "別の種別" },
        ].map((option) => {
          const active = value === option.value;
          return (
            <Pressable
              key={option.value}
              onPress={() => onChange(option.value)}
              style={[styles.exchangeButton, active ? styles.exchangeButtonActive : null]}
            >
              <Text
                style={[
                  styles.exchangeButtonText,
                  active ? styles.exchangeButtonTextActive : null,
                ]}
              >
                {option.label}
              </Text>
              <Text
                style={[
                  styles.exchangeButtonSub,
                  active ? styles.exchangeButtonSubActive : null,
                ]}
              >
                {option.sub}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

function EmptyBox({ label }: { label: string }) {
  return (
    <View style={styles.emptyBox}>
      <Text style={styles.emptyBoxText}>{label}</Text>
    </View>
  );
}

async function fetchEditorData(input: {
  userId: string | null;
  mode: ListingMode;
  listingId: string | null;
  preselectWishId: string | null;
  preview: boolean;
  fallbackWishTitle: string | null;
}): Promise<ListingEditorData> {
  if (!supabase || input.preview || !input.userId) {
    return buildPreviewData(input.mode, input.preselectWishId, input.fallbackWishTitle);
  }
  let listing: ListingRow | null = null;
  let optionRows: OptionRow[] = [];
  if (input.mode === "edit") {
    if (!input.listingId) throw new Error("編集対象の個別募集が指定されていません");
    const { data: listingRaw, error: listingError } = await supabase
      .from("listings")
      .select(
        "id, user_id, status, have_ids, have_qtys, have_logic, have_group_id, have_goods_type_id, note",
      )
      .eq("id", input.listingId)
      .maybeSingle();
    if (listingError) throw listingError;
    if (!listingRaw) throw new Error("個別募集が見つかりません");
    listing = listingRaw as ListingRow;
    if (listing.user_id !== input.userId) throw new Error("編集権限がありません");
    const { data: optionsRaw, error: optionsError } = await supabase
      .from("listing_wish_options")
      .select(
        "id, position, wish_ids, wish_qtys, logic, exchange_type, is_cash_offer, cash_amount, wish_group_id, wish_goods_type_id",
      )
      .eq("listing_id", input.listingId)
      .order("position", { ascending: true });
    if (optionsError) throw optionsError;
    optionRows = (optionsRaw as OptionRow[] | null) ?? [];
  }

  const [{ data: inventoryRowsRaw, error: inventoryError }, { data: wishRowsRaw, error: wishError }] =
    await Promise.all([
      supabase
        .from("goods_inventory")
        .select(
          "id, title, photo_urls, hue, quantity, group_id, goods_type_id, group:groups_master(id, name), character:characters_master(id, name), goods_type:goods_types_master(id, name)",
        )
        .eq("user_id", input.userId)
        .eq("kind", "for_trade")
        .eq("status", "active")
        .order("created_at", { ascending: false }),
      supabase
        .from("goods_inventory")
        .select(
          "id, title, exchange_type, group_id, goods_type_id, photo_urls, group:groups_master(id, name), character:characters_master(id, name), goods_type:goods_types_master(id, name)",
        )
        .eq("user_id", input.userId)
        .eq("kind", "wanted")
        .neq("status", "archived")
        .order("created_at", { ascending: false }),
    ]);
  if (inventoryError) throw inventoryError;
  if (wishError) throw wishError;

  const referencedWishIds = new Set<string>();
  for (const option of optionRows) {
    for (const id of option.wish_ids ?? []) referencedWishIds.add(id);
  }
  const existingWishIds = new Set(((wishRowsRaw as WishRow[] | null) ?? []).map((row) => row.id));
  const extraWishIds = Array.from(referencedWishIds).filter((id) => !existingWishIds.has(id));
  const extraWishRows =
    extraWishIds.length > 0
      ? await fetchExtraWishRows(extraWishIds)
      : [];

  const inventoryRows = (inventoryRowsRaw as InventoryRow[] | null) ?? [];
  const reservedQtyByInvId = await getReservedQtyByInvId();
  const marketInventoryRows = inventoryRows
    .map((row) => ({
      ...row,
      quantity: Math.max(0, (row.quantity ?? 1) - (reservedQtyByInvId.get(row.id) ?? 0)),
    }))
    .filter((row) => (row.quantity ?? 0) > 0);
  const inventoryItems = marketInventoryRows.map(toInventoryOpt);
  const wishItems = [...((wishRowsRaw as WishRow[] | null) ?? []), ...extraWishRows].map(toWishOpt);
  const inventoryGroups = uniqueOptions(
    marketInventoryRows.map((row) => ({
      id: row.group_id,
      name: pickName(row.group),
    })),
  );
  const inventoryGoodsTypes = uniqueOptions(
    marketInventoryRows.map((row) => ({
      id: row.goods_type_id,
      name: pickName(row.goods_type),
    })),
  );
  const wishGroups = uniqueOptions(
    [...((wishRowsRaw as WishRow[] | null) ?? []), ...extraWishRows].map((row) => ({
      id: row.group_id,
      name: pickName(row.group),
    })),
  );
  const wishGoodsTypes = uniqueOptions(
    [...((wishRowsRaw as WishRow[] | null) ?? []), ...extraWishRows].map((row) => ({
      id: row.goods_type_id,
      name: pickName(row.goods_type),
    })),
  );
  const initialValues = listing
    ? buildInitialValues(listing, optionRows, inventoryItems, wishItems)
    : null;
  return {
    inventoryItems,
    wishItems,
    inventoryGroups,
    inventoryGoodsTypes,
    wishGroups,
    wishGoodsTypes,
    initialValues,
    listingStatus: listing?.status ?? null,
    locked: listing?.status === "matched" || listing?.status === "closed",
  };
}

async function fetchExtraWishRows(ids: string[]) {
  if (!supabase) return [];
  const { data, error } = await supabase
    .from("goods_inventory")
    .select(
      "id, title, exchange_type, group_id, goods_type_id, photo_urls, group:groups_master(id, name), character:characters_master(id, name), goods_type:goods_types_master(id, name)",
    )
    .in("id", ids);
  if (error) throw error;
  return (data as WishRow[] | null) ?? [];
}

function buildInitialValues(
  listing: ListingRow,
  optionRows: OptionRow[],
  inventoryItems: InventoryOpt[],
  wishItems: WishOpt[],
): ListingInitialValues {
  const inventoryById = new Map(inventoryItems.map((item) => [item.id, item] as const));
  const wishById = new Map(wishItems.map((item) => [item.id, item] as const));
  const haves = listing.have_ids ?? [];
  const qtys = listing.have_qtys ?? [];
  return {
    haveGroupId: inventoryItems.some((item) => item.groupId === listing.have_group_id)
      ? listing.have_group_id
      : null,
    haveGoodsTypeId: inventoryItems.some((item) => item.goodsTypeId === listing.have_goods_type_id)
      ? listing.have_goods_type_id
      : null,
    selectedHaves: haves.flatMap((id, index) => {
      const item = inventoryById.get(id);
      if (!item || item.availableQty < 1) return [];
      return [{ id, qty: Math.min(Math.max(1, qtys[index] ?? 1), item.availableQty) }];
    }),
    haveLogic: listing.have_logic ?? "and",
    options: optionRows.map((row, index) => {
      const firstWish = (row.wish_ids ?? []).flatMap((id) => {
        const wish = wishById.get(id);
        return wish ? [wish] : [];
      })[0];
      return {
        position: row.position || index + 1,
        groupId: row.wish_group_id ?? firstWish?.groupId ?? null,
        goodsTypeId: row.wish_goods_type_id ?? firstWish?.goodsTypeId ?? null,
        groupCustomized: true,
        goodsTypeCustomized: true,
        selected: (row.wish_ids ?? []).flatMap((id, qtyIndex) =>
          wishById.has(id)
            ? [{ id, qty: Math.max(1, (row.wish_qtys ?? [])[qtyIndex] ?? 1) }]
            : [],
        ),
        logic: row.logic ?? "or",
        exchangeType: row.exchange_type ?? "any",
        isCashOffer: !!row.is_cash_offer,
        cashAmount: row.cash_amount,
      };
    }),
    note: listing.note ?? "",
  };
}

function buildPreviewData(
  mode: ListingMode,
  preselectWishId: string | null,
  fallbackWishTitle: string | null,
): ListingEditorData {
  const wishItems = fallbackWishTitle
    ? [
        ...PREVIEW_WISHES,
        {
          ...PREVIEW_WISHES[0],
          id: preselectWishId ?? "preview-param-wish",
          title: fallbackWishTitle,
          characterName: fallbackWishTitle,
        },
      ]
    : PREVIEW_WISHES;
  const preselected = preselectWishId
    ? wishItems.find((wish) => wish.id === preselectWishId) ?? null
    : fallbackWishTitle
      ? wishItems[wishItems.length - 1]
      : null;
  const initialValues =
    mode === "edit"
      ? {
          haveGroupId: "grp-lumena",
          haveGoodsTypeId: "type-card",
          selectedHaves: [{ id: "preview-have-1", qty: 1 }],
          haveLogic: "and" as const,
          options: [
            {
              ...blankOption(1),
              groupId: preselected?.groupId ?? "grp-lumena",
              goodsTypeId: preselected?.goodsTypeId ?? "type-card",
              groupCustomized: true,
              goodsTypeCustomized: true,
              selected: [{ id: preselected?.id ?? "preview-wish-1", qty: 1 }],
            },
          ],
          note: "",
        }
      : null;
  return {
    inventoryItems: PREVIEW_INVENTORY,
    wishItems,
    inventoryGroups: uniqueOptions(
      PREVIEW_INVENTORY.map((item) => ({ id: item.groupId, name: item.groupName })),
    ),
    inventoryGoodsTypes: uniqueOptions(
      PREVIEW_INVENTORY.map((item) => ({ id: item.goodsTypeId, name: item.goodsTypeName })),
    ),
    wishGroups: uniqueOptions(wishItems.map((item) => ({ id: item.groupId, name: item.groupName }))),
    wishGoodsTypes: uniqueOptions(
      wishItems.map((item) => ({ id: item.goodsTypeId, name: item.goodsTypeName })),
    ),
    initialValues,
    listingStatus: mode === "edit" ? "active" : null,
    locked: false,
  };
}

async function getReservedQtyByInvId(inventoryIds?: string[]) {
  const reserved = new Map<string, number>();
  if (!supabase) return reserved;
  const filterIds =
    inventoryIds && inventoryIds.length > 0 ? new Set(inventoryIds) : undefined;
  const { data } = await supabase
    .from("proposals")
    .select(
      "sender_have_ids, sender_have_qtys, receiver_have_ids, receiver_have_qtys, approved_by_sender, approved_by_receiver",
    )
    .eq("status", "agreed");
  for (const row of (data as ProposalReservationRow[] | null) ?? []) {
    if (!row.approved_by_sender) {
      addReserved(reserved, row.sender_have_ids, row.sender_have_qtys, filterIds);
    }
    if (!row.approved_by_receiver) {
      addReserved(reserved, row.receiver_have_ids, row.receiver_have_qtys, filterIds);
    }
  }
  return reserved;
}

function addReserved(
  target: Map<string, number>,
  ids: string[] | null | undefined,
  qtys: number[] | null | undefined,
  filterIds?: Set<string>,
) {
  for (let index = 0; index < (ids?.length ?? 0); index += 1) {
    const id = ids?.[index];
    if (!id || (filterIds && !filterIds.has(id))) continue;
    target.set(id, (target.get(id) ?? 0) + Math.max(1, qtys?.[index] ?? 1));
  }
}

async function createListingMobile(input: {
  userId: string;
  haveIds: string[];
  haveQtys: number[];
  haveLogic: ListingLogic;
  options: WishOptionState[];
  note: string;
}) {
  if (!supabase) return undefined;
  const capacity = await assertListingHavesMarketAvailable(
    input.userId,
    input.haveIds,
    input.haveQtys,
  );
  if (capacity.error) return capacity;
  const { data: listing, error: listingError } = await supabase
    .from("listings")
    .insert({
      user_id: input.userId,
      have_ids: input.haveIds,
      have_qtys: input.haveQtys,
      have_logic: input.haveLogic,
      note: input.note.trim() || null,
    })
    .select("id")
    .single();
  if (listingError || !listing) {
    return { error: listingError?.message ?? "個別募集の作成に失敗しました" };
  }
  const optionError = await insertListingOptions(listing.id as string, input.options);
  if (optionError?.error) {
    await supabase.from("listings").delete().eq("id", listing.id);
    return optionError;
  }
  return undefined;
}

async function updateListingFullMobile(input: {
  userId: string;
  listingId: string;
  haveIds: string[];
  haveQtys: number[];
  haveLogic: ListingLogic;
  options: WishOptionState[];
  note: string;
}) {
  if (!supabase) return undefined;
  const { data: existing } = await supabase
    .from("listings")
    .select("user_id, status")
    .eq("id", input.listingId)
    .maybeSingle();
  const row = existing as { user_id?: string; status?: ListingStatus } | null;
  if (!row) return { error: "個別募集が見つかりません" };
  if (row.user_id !== input.userId) return { error: "編集権限がありません" };
  if (row.status === "matched" || row.status === "closed") {
    return { error: "成立／完了した個別募集は編集できません" };
  }
  const capacity = await assertListingHavesMarketAvailable(
    input.userId,
    input.haveIds,
    input.haveQtys,
  );
  if (capacity.error) return capacity;
  const { error: listingError } = await supabase
    .from("listings")
    .update({
      have_ids: input.haveIds,
      have_qtys: input.haveQtys,
      have_logic: input.haveLogic,
      note: input.note.trim() || null,
    })
    .eq("id", input.listingId)
    .eq("user_id", input.userId);
  if (listingError) return { error: listingError.message };
  const { error: deleteError } = await supabase
    .from("listing_wish_options")
    .delete()
    .eq("listing_id", input.listingId);
  if (deleteError) return { error: deleteError.message };
  return insertListingOptions(input.listingId, input.options);
}

async function assertListingHavesMarketAvailable(
  userId: string,
  haveIds: string[],
  haveQtys: number[],
) {
  if (!supabase || haveIds.length === 0) return {};
  const needed = aggregateNeeded(haveIds, haveQtys);
  const ids = Array.from(needed.keys());
  const [{ data: rows }, reservedQtyByInvId] = await Promise.all([
    supabase
      .from("goods_inventory")
      .select(
        "id, user_id, kind, status, quantity, title, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
      )
      .in("id", ids),
    getReservedQtyByInvId(ids),
  ]);
  const inventoryById = new Map(
    ((rows as InventoryCheckRow[] | null) ?? []).map((row) => [row.id, row] as const),
  );
  const issues: string[] = [];

  for (const [id, qty] of needed) {
    const row = inventoryById.get(id);
    const label = inventoryLabel(row, id);
    if (!row || row.user_id !== userId) {
      issues.push(
        `・「${label}」：${row ? "このアカウントの譲グッズではありません" : "グッズが削除されているか、参照できません"}`,
      );
      continue;
    }
    if (row.kind !== "for_trade") {
      issues.push(`・「${label}」：マイ在庫の分類が「${inventoryKindLabel(row.kind)}」です`);
      continue;
    }
    if (row.status !== "active") {
      issues.push(`・「${label}」：マイ在庫の状態が「${inventoryStatusLabel(row.status)}」です`);
      continue;
    }
    const registered = row.quantity ?? 1;
    const available = Math.max(0, registered - (reservedQtyByInvId.get(id) ?? 0));
    if (qty > available) {
      issues.push(
        `・「${label}」：交換可能数が不足しています（必要 ${qty} / 市場残数 ${available} / 登録数 ${registered}）`,
      );
    }
  }

  if (issues.length === 0) return {};
  const visibleIssues = issues.slice(0, 5).join("\n");
  const extra = issues.length > 5 ? `\nほか ${issues.length - 5} 件あります。` : "";
  return {
    error:
      "交換条件に使えない譲グッズがあります。\n" +
      visibleIssues +
      extra +
      "\n対象のグッズを個別募集から外すか、マイ在庫で状態・在庫数を確認してください。",
  };
}

function aggregateNeeded(ids: string[], qtys: number[]) {
  const result = new Map<string, number>();
  for (let index = 0; index < ids.length; index += 1) {
    const id = ids[index];
    if (!id) continue;
    result.set(id, (result.get(id) ?? 0) + Math.max(1, qtys[index] ?? 1));
  }
  return result;
}

function inventoryLabel(row: InventoryCheckRow | undefined, id: string) {
  if (!row) return `ID: ${id.slice(0, 8)}`;
  const title = row.title?.trim();
  const fallback = [pickName(row.group), pickName(row.character), pickName(row.goods_type)]
    .filter(Boolean)
    .join(" / ");
  return title || fallback || `ID: ${id.slice(0, 8)}`;
}

function inventoryKindLabel(kind: string) {
  if (kind === "for_trade") return "譲る候補";
  if (kind === "wanted") return "Wish";
  if (kind === "keep") return "自分キープ";
  return kind;
}

function inventoryStatusLabel(status: string) {
  if (status === "active") return "交換対象";
  if (status === "keep") return "自分キープ";
  if (status === "traded") return "譲渡済み";
  if (status === "reserved") return "予約中";
  if (status === "archived") return "削除済み";
  return status;
}

async function insertListingOptions(listingId: string, options: WishOptionState[]) {
  if (!supabase) return undefined;
  const { error } = await supabase.from("listing_wish_options").insert(
    options.map((option) => ({
      listing_id: listingId,
      position: option.position,
      wish_ids: option.isCashOffer ? [] : option.selected.map((item) => item.id),
      wish_qtys: option.isCashOffer ? [] : option.selected.map((item) => item.qty),
      logic: option.logic,
      exchange_type: option.exchangeType,
      is_cash_offer: option.isCashOffer,
      cash_amount: option.isCashOffer ? option.cashAmount ?? null : null,
    })),
  );
  if (error) return { error: error.message };
  return undefined;
}

function validateListingForm(input: {
  haveGroupId: string | null;
  haveGoodsTypeId: string | null;
  haveIds: string[];
  haveQtys: number[];
  haveLogic: ListingLogic;
  options: WishOptionState[];
}) {
  if (!input.haveGroupId || !input.haveGoodsTypeId) {
    return "譲るグッズのグループと種別を選んでください";
  }
  if (input.haveIds.length === 0) return "譲るグッズを1件以上選んでください";
  if (input.haveQtys.some((qty) => qty < 1 || qty > 99)) {
    return "譲側の数量は1〜99で指定してください";
  }
  if (input.options.length === 0) return "求める選択肢を1つ以上追加してください";
  if (input.options.length > MAX_OPTIONS) {
    return `求める選択肢は最大${MAX_OPTIONS}件です`;
  }
  for (const option of input.options) {
    if (option.isCashOffer) {
      if (!option.cashAmount || option.cashAmount < 1 || option.cashAmount > 9999999) {
        return `選択肢 ${option.position}：定価交換は金額を入力してください`;
      }
      continue;
    }
    if (!option.groupId || !option.goodsTypeId) {
      return `選択肢 ${option.position}：グループと種別を選んでください`;
    }
    if (option.selected.length === 0) {
      return `選択肢 ${option.position}：Wishを1件以上選んでください`;
    }
    if (option.selected.some((item) => item.qty < 1 || item.qty > 99)) {
      return `選択肢 ${option.position}：数量は1〜99で指定してください`;
    }
    if (
      input.haveLogic === "or" &&
      option.logic === "or" &&
      input.haveIds.length > 1 &&
      option.selected.length > 1
    ) {
      return `選択肢 ${option.position}：譲OR × 求OR × 両側2点以上は曖昧なため指定できません`;
    }
  }
  return null;
}

function blankOption(position: number): WishOptionState {
  return {
    position,
    groupId: null,
    goodsTypeId: null,
    groupCustomized: false,
    goodsTypeCustomized: false,
    selected: [],
    logic: "or",
    exchangeType: "any",
    isCashOffer: false,
    cashAmount: null,
  };
}

function isBlankWishOption(option: WishOptionState | undefined) {
  return (
    !!option &&
    !option.isCashOffer &&
    !option.groupId &&
    !option.goodsTypeId &&
    option.selected.length === 0
  );
}

function toInventoryOpt(row: InventoryRow): InventoryOpt {
  const groupName = pickName(row.group);
  const characterName = pickName(row.character);
  const goodsTypeName = pickName(row.goods_type);
  const seed = characterName ?? groupName ?? row.title;
  return {
    id: row.id,
    title: row.title,
    photoUrl: row.photo_urls?.[0] ?? null,
    groupId: row.group_id,
    goodsTypeId: row.goods_type_id,
    groupName,
    characterName,
    goodsTypeName,
    hue: normalizeHue(row.hue, seed),
    availableQty: row.quantity ?? 1,
  };
}

function toWishOpt(row: WishRow): WishOpt {
  return {
    id: row.id,
    title: row.title,
    exchangeType: row.exchange_type ?? "any",
    groupId: row.group_id,
    goodsTypeId: row.goods_type_id,
    groupName: pickName(row.group),
    characterName: pickName(row.character),
    goodsTypeName: pickName(row.goods_type),
    photoUrl: row.photo_urls?.[0] ?? null,
  };
}

function uniqueOptions(values: { id: string | null; name: string | null }[]) {
  const seen = new Map<string, SelectOption>();
  for (const value of values) {
    if (!value.id || !value.name || seen.has(value.id)) continue;
    seen.set(value.id, { id: value.id, name: value.name });
  }
  return Array.from(seen.values()).sort((a, b) => a.name.localeCompare(b.name, "ja"));
}

function pickName(value: RelationName) {
  if (!value) return null;
  return Array.isArray(value) ? value[0]?.name ?? null : value.name;
}

function normalizeHue(value: number | string | null | undefined, seed: string) {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim()) {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return nameToHue(seed);
}

function nameToHue(name: string) {
  let hash = 0;
  for (let index = 0; index < name.length; index += 1) {
    hash = (hash << 5) - hash + name.charCodeAt(index);
    hash |= 0;
  }
  return Math.abs(hash) % 360;
}

function one(value?: string | string[]) {
  return Array.isArray(value) ? value[0] : value;
}

const styles = StyleSheet.create({
  screen: {
    gap: 16,
  },
  centerScreen: {
    alignItems: "center",
    flex: 1,
    gap: 12,
    justifyContent: "center",
  },
  loadingText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
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
  headerCopy: {
    flex: 1,
  },
  kicker: {
    color: megrumColors.lavender,
    fontSize: 10.5,
    fontWeight: "900",
    letterSpacing: 0.6,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 20,
    fontWeight: "900",
    lineHeight: 25,
  },
  emptyNotice: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 22,
    borderStyle: "dashed",
    borderWidth: 1,
    padding: 18,
  },
  emptyTitle: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "900",
    textAlign: "center",
  },
  emptyText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "700",
    lineHeight: 18,
    marginTop: 8,
    textAlign: "center",
  },
  preview: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.25)",
    borderRadius: 24,
    borderWidth: 1,
    overflow: "hidden",
    padding: 14,
    ...megrumShadow,
  },
  previewHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  previewTitle: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  previewCash: {
    backgroundColor: "rgba(243,197,212,0.26)",
    borderRadius: megrumRadii.pill,
    color: megrumColors.ink,
    fontSize: 10.5,
    fontWeight: "900",
    overflow: "hidden",
    paddingHorizontal: 9,
    paddingVertical: 4,
  },
  previewLine: {
    alignItems: "center",
    flexDirection: "row",
    marginTop: 14,
    minHeight: 132,
  },
  previewSide: {
    alignItems: "center",
    flex: 1,
    gap: 9,
  },
  previewSideLabel: {
    backgroundColor: "rgba(58,50,74,0.05)",
    borderRadius: megrumRadii.pill,
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "900",
    overflow: "hidden",
    paddingHorizontal: 9,
    paddingVertical: 4,
  },
  previewBubbles: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "center",
    minHeight: 96,
  },
  previewBubble: {
    alignItems: "center",
    borderColor: "rgba(255,255,255,0.92)",
    borderRadius: 18,
    borderWidth: 2,
    height: 82,
    justifyContent: "center",
    marginHorizontal: -15,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.13,
    shadowRadius: 14,
    width: 62,
  },
  previewBubbleText: {
    color: megrumColors.surface,
    fontSize: 23,
    fontWeight: "900",
  },
  previewBubbleImage: {
    height: "100%",
    width: "100%",
  },
  previewMore: {
    alignItems: "center",
    backgroundColor: megrumColors.ink,
    borderRadius: megrumRadii.pill,
    height: 24,
    justifyContent: "center",
    marginLeft: -12,
    width: 24,
  },
  previewMoreText: {
    color: megrumColors.surface,
    fontSize: 9,
    fontWeight: "900",
  },
  previewCord: {
    alignItems: "center",
    height: 90,
    justifyContent: "center",
    width: 48,
  },
  previewCordLine: {
    backgroundColor: "rgba(166,149,216,0.34)",
    height: 2,
    position: "absolute",
    width: 64,
  },
  previewKnot: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.42)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    height: 34,
    justifyContent: "center",
    width: 34,
  },
  previewKnotText: {
    color: megrumColors.lavender,
    fontSize: 20,
    fontWeight: "900",
    lineHeight: 22,
  },
  form: {
    gap: 14,
  },
  section: {
    gap: 7,
  },
  sectionHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: 2,
  },
  sectionLabel: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0.5,
  },
  sectionRight: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "800",
  },
  sectionBody: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    gap: 10,
    padding: 13,
  },
  twoColumn: {
    gap: 10,
  },
  choiceBlock: {
    gap: 6,
  },
  choiceLabel: {
    color: megrumColors.ink,
    fontSize: 11,
    fontWeight: "900",
  },
  choiceScroller: {
    gap: 7,
    paddingRight: 10,
  },
  choiceChip: {
    backgroundColor: "rgba(58,50,74,0.055)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  choiceChipActive: {
    backgroundColor: megrumColors.lavender,
    borderColor: megrumColors.lavender,
  },
  choiceChipText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
  },
  choiceChipTextActive: {
    color: megrumColors.surface,
  },
  noticeBox: {
    backgroundColor: "rgba(166,149,216,0.06)",
    borderRadius: 12,
    paddingHorizontal: 11,
    paddingVertical: 9,
  },
  noticeText: {
    color: "rgba(58,50,74,0.68)",
    fontSize: 10.5,
    fontWeight: "700",
    lineHeight: 16,
  },
  cashOfferBox: {
    backgroundColor: "rgba(168,212,230,0.10)",
    borderColor: "rgba(168,212,230,0.24)",
    borderRadius: 15,
    borderWidth: 1,
    gap: 10,
    padding: 11,
  },
  cashOfferBoxActive: {
    backgroundColor: "rgba(166,149,216,0.10)",
    borderColor: "rgba(166,149,216,0.42)",
  },
  cashOfferHeader: {
    alignItems: "center",
    flexDirection: "row",
    gap: 12,
    justifyContent: "space-between",
  },
  cashOfferTitle: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "900",
  },
  cashOfferSub: {
    color: "rgba(58,50,74,0.56)",
    fontSize: 10,
    fontWeight: "700",
    lineHeight: 14,
    marginTop: 3,
    maxWidth: 260,
  },
  cashOfferSwitch: {
    backgroundColor: "rgba(58,50,74,0.14)",
    borderRadius: megrumRadii.pill,
    height: 25,
    justifyContent: "center",
    paddingHorizontal: 3,
    width: 46,
  },
  cashOfferSwitchActive: {
    backgroundColor: megrumColors.lavender,
  },
  cashOfferKnob: {
    backgroundColor: megrumColors.surface,
    borderRadius: megrumRadii.pill,
    height: 19,
    width: 19,
  },
  cashOfferKnobActive: {
    alignSelf: "flex-end",
  },
  cashOfferAmountRow: {
    gap: 7,
  },
  warnBox: {
    backgroundColor: "rgba(245,158,11,0.11)",
    borderColor: "rgba(245,158,11,0.22)",
    borderRadius: 12,
    borderWidth: 1,
    paddingHorizontal: 11,
    paddingVertical: 9,
  },
  warnText: {
    color: "#a16207",
    fontSize: 10.5,
    fontWeight: "800",
    lineHeight: 16,
  },
  cardGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 9,
  },
  panelWrap: {
    borderRadius: 14,
    position: "relative",
    width: "31%",
  },
  panelWrapCompact: {
    flexShrink: 0,
    width: 88,
  },
  panelWrapSelected: {
    shadowColor: megrumColors.lavender,
    shadowOffset: { width: 0, height: 7 },
    shadowOpacity: 0.22,
    shadowRadius: 13,
  },
  panelCard: {
    aspectRatio: 3 / 4,
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: 14,
    borderWidth: 1,
    overflow: "hidden",
  },
  panelImage: {
    height: "100%",
    width: "100%",
  },
  panelShine: {
    backgroundColor: "rgba(255,255,255,0.24)",
    borderRadius: 999,
    height: 58,
    position: "absolute",
    right: -17,
    top: -14,
    width: 58,
  },
  panelGlyph: {
    color: megrumColors.surface,
    fontSize: 27,
    fontWeight: "900",
    left: 0,
    position: "absolute",
    right: 0,
    textAlign: "center",
    textShadowColor: "rgba(58,50,74,0.18)",
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 7,
    top: "38%",
  },
  panelNamePlate: {
    backgroundColor: "rgba(255,255,255,0.84)",
    borderRadius: 7,
    left: 5,
    maxWidth: "76%",
    paddingHorizontal: 5,
    paddingVertical: 3,
    position: "absolute",
    top: 5,
  },
  panelName: {
    color: megrumColors.ink,
    fontSize: 8.5,
    fontWeight: "900",
  },
  panelBottom: {
    backgroundColor: "rgba(255,255,255,0.92)",
    bottom: 0,
    left: 0,
    paddingHorizontal: 6,
    paddingVertical: 5,
    position: "absolute",
    right: 0,
  },
  panelType: {
    color: megrumColors.ink,
    fontSize: 9,
    fontWeight: "900",
  },
  panelAddMark: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.70)",
    borderColor: megrumColors.surface,
    borderRadius: megrumRadii.pill,
    borderWidth: 1.5,
    height: 24,
    justifyContent: "center",
    position: "absolute",
    right: 5,
    top: 5,
    width: 24,
  },
  panelAddText: {
    color: megrumColors.lavender,
    fontSize: 15,
    fontWeight: "900",
    lineHeight: 17,
  },
  qtyOverlay: {
    alignItems: "center",
    alignSelf: "center",
    backgroundColor: "rgba(255,255,255,0.96)",
    borderRadius: megrumRadii.pill,
    bottom: 6,
    flexDirection: "row",
    gap: 3,
    padding: 3,
    position: "absolute",
  },
  qtyButton: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: megrumRadii.pill,
    height: 20,
    justifyContent: "center",
    width: 20,
  },
  qtyButtonText: {
    color: megrumColors.surface,
    fontSize: 12,
    fontWeight: "900",
    lineHeight: 14,
  },
  qtyText: {
    color: megrumColors.ink,
    fontSize: 10,
    fontWeight: "900",
    minWidth: 22,
    textAlign: "center",
  },
  logicBox: {
    backgroundColor: megrumColors.background,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 14,
    borderWidth: 1,
    padding: 9,
  },
  logicLabel: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "900",
    marginBottom: 7,
  },
  logicRow: {
    flexDirection: "row",
    gap: 7,
  },
  logicButton: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderRadius: 11,
    flex: 1,
    paddingVertical: 8,
  },
  logicButtonActive: {
    backgroundColor: megrumColors.lavender,
  },
  logicButtonText: {
    color: megrumColors.ink,
    fontSize: 11.5,
    fontWeight: "900",
  },
  logicButtonTextActive: {
    color: megrumColors.surface,
  },
  logicButtonSub: {
    color: megrumColors.mutedInk,
    fontSize: 9,
    fontWeight: "800",
    marginTop: 2,
  },
  logicButtonSubActive: {
    color: "rgba(255,255,255,0.78)",
  },
  optionHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: 2,
  },
  optionHeaderLabel: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0.5,
  },
  optionHeaderSub: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "700",
    marginTop: 2,
  },
  optionCounter: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "900",
  },
  optionCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.34)",
    borderRadius: 19,
    borderWidth: 1,
    gap: 11,
    overflow: "hidden",
    padding: 13,
  },
  optionTop: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
  },
  optionBadge: {
    backgroundColor: megrumColors.lavender,
    borderRadius: megrumRadii.pill,
    color: megrumColors.surface,
    fontSize: 10,
    fontWeight: "900",
    overflow: "hidden",
    paddingHorizontal: 9,
    paddingVertical: 4,
  },
  cashToggle: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.38)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 9,
    paddingVertical: 5,
  },
  cashToggleActive: {
    backgroundColor: megrumColors.lavender,
  },
  cashToggleText: {
    color: megrumColors.lavender,
    fontSize: 10.5,
    fontWeight: "900",
  },
  cashToggleTextActive: {
    color: megrumColors.surface,
  },
  removeButton: {
    marginLeft: "auto",
  },
  removeButtonText: {
    color: megrumColors.warn,
    fontSize: 11,
    fontWeight: "900",
  },
  cashEditor: {
    gap: 8,
  },
  cashInput: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.12)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
    paddingHorizontal: 14,
    paddingVertical: 11,
  },
  helpText: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "700",
    lineHeight: 16,
  },
  wishScroller: {
    gap: 9,
    paddingRight: 12,
  },
  exchangeHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    marginBottom: 7,
  },
  exchangeHint: {
    color: megrumColors.mutedInk,
    fontSize: 9.5,
    fontWeight: "800",
  },
  exchangeRow: {
    flexDirection: "row",
    gap: 7,
  },
  exchangeButton: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: 12,
    borderWidth: 1,
    flex: 1,
    paddingVertical: 8,
  },
  exchangeButtonActive: {
    backgroundColor: megrumColors.lavender,
    borderColor: megrumColors.lavender,
  },
  exchangeButtonText: {
    color: megrumColors.ink,
    fontSize: 11,
    fontWeight: "900",
  },
  exchangeButtonTextActive: {
    color: megrumColors.surface,
  },
  exchangeButtonSub: {
    color: megrumColors.mutedInk,
    fontSize: 8.5,
    fontWeight: "800",
    marginTop: 2,
  },
  exchangeButtonSubActive: {
    color: "rgba(255,255,255,0.78)",
  },
  addOptionButton: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.38)",
    borderRadius: megrumRadii.md,
    borderStyle: "dashed",
    borderWidth: 1,
    justifyContent: "center",
    minHeight: 46,
  },
  addOptionText: {
    color: megrumColors.lavender,
    fontSize: 12,
    fontWeight: "900",
  },
  noteInput: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.12)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "700",
    minHeight: 86,
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  errorBox: {
    backgroundColor: "rgba(239,68,68,0.08)",
    borderColor: "rgba(239,68,68,0.18)",
    borderRadius: 14,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  errorText: {
    color: "#b91c1c",
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
  },
  emptyBox: {
    backgroundColor: megrumColors.background,
    borderColor: "rgba(58,50,74,0.12)",
    borderRadius: 14,
    borderStyle: "dashed",
    borderWidth: 1,
    padding: 14,
  },
  emptyBoxText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    textAlign: "center",
  },
  toast: {
    alignSelf: "center",
    backgroundColor: megrumColors.ink,
    borderRadius: megrumRadii.pill,
    bottom: 108,
    paddingHorizontal: 14,
    paddingVertical: 10,
    position: "absolute",
  },
  toastText: {
    color: megrumColors.surface,
    fontSize: 12,
    fontWeight: "900",
  },
});
