import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import {
  AppState,
  ActivityIndicator,
  BackHandler,
  Image,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import * as ImagePicker from "expo-image-picker";
import { router, useLocalSearchParams } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { ChatGradientBubble } from "../src/components/ChatGradientBubble";
import { IconSymbol } from "../src/components/IconSymbol";
import { MeguriAvatarFace } from "../src/components/meguri/MeguriAvatarFace";
import { Screen } from "../src/components/Screen";
import { useAuth } from "../src/auth/AuthProvider";
import { useKeyboardInset } from "../src/lib/useKeyboardInset";
import { ihubColors } from "../src/theme/tokens";
import {
  FREE_SEND_LIMIT,
  LETTERS,
  PLUS_SEND_LIMIT,
  PlusModal,
  USERS,
  type Letter,
  type MeguriUser,
} from "./(tabs)/encounters";
import {
  incrementMeguriSendUsage,
  loadMeguriSendUsage,
  loadMeguriPlusState,
  saveMeguriPlusReviewOverride,
} from "../src/lib/meguriPlus";
import {
  appendMeguriThreadMessage,
  loadMeguriGroomReplies,
  loadMeguriMessageReadState,
  loadMeguriThreadMessages,
  markMeguriGroomRepliesRead,
  markMeguriLetterRead,
  markMeguriThreadMessagesRead,
  unreadMeguriMessageCount,
  type MeguriGroomReply,
  type MeguriMessageReadState,
  type MeguriThreadMessage,
} from "../src/lib/meguriMessages";

type MessageConversation = {
  id: string;
  letter: Letter;
  lastAt: string;
  muted?: boolean;
  pinned?: boolean;
  unread: number;
};

type ChatMessage = {
  id: string;
  body: string;
  groomReply?: {
    caption?: string;
    imageUri: string;
  };
  imageUri?: string;
  mine: boolean;
  locked?: boolean;
  sentAt?: number;
  time: string;
};

const CONVERSATION_TIMES = ["0:24", "昨日", "0:09", "土曜日", "土曜日", "金曜日", "木曜日", "水曜日", "月曜日", "先週"];
const EXTRA_MESSAGE_BODIES = [
  "さっき同じ曲の話をしていた気がして、うれしくなりました。",
  "今日の現場、空気感が最高でしたね。またどこかでめぐれたらうれしいです。",
  "同じ推しのグッズを見かけて、思わず声をかけたくなりました。",
  "写真集の新ビジュ、私もかなり好きです。",
  "次のイベントでも同じエリアにいたら、またゆるく話せたらうれしいです。",
  "今日のひとこと、すごく分かります。",
  "同じ作品の話ができる人を探していました。",
];
const INITIAL_FREE_SEND_USED = 0;
const MESSAGE_ACTIVE = ihubColors.lavender;

export default function MeguriLettersScreen() {
  const { previewMode, profile } = useAuth();
  const insets = useSafeAreaInsets();
  const params = useLocalSearchParams<{
    open?: string | string[];
    userId?: string | string[];
  }>();
  const [selectedConversation, setSelectedConversation] = useState<MessageConversation | null>(null);
  const [plusOpen, setPlusOpen] = useState(false);
  const [subscribed, setSubscribed] = useState(false);
  const [canUsePlusReviewToggle, setCanUsePlusReviewToggle] = useState(false);
  const [sendUsed, setSendUsed] = useState(INITIAL_FREE_SEND_USED);
  const [draft, setDraft] = useState("");
  const [threadMessages, setThreadMessages] = useState<MeguriThreadMessage[]>([]);
  const [groomReplies, setGroomReplies] = useState<MeguriGroomReply[]>([]);
  const [readState, setReadState] = useState<MeguriMessageReadState>({});
  const [messagesReady, setMessagesReady] = useState(false);
  const messageLetters = useMemo(
    () => createMessageLetters(groomReplies, threadMessages, previewMode),
    [groomReplies, previewMode, threadMessages],
  );
  const openParam = Array.isArray(params.open) ? params.open[0] : params.open;
  const userIdParam = Array.isArray(params.userId) ? params.userId[0] : params.userId;
  const conversations = useMemo(
    () => {
      const groomUnreadByConversation = unreadGroomRepliesByConversation(groomReplies, messageLetters);
      const threadUnreadByConversation = unreadThreadMessagesByConversation(threadMessages, messageLetters);
      const rows = messageLetters.map((letter, index) => {
        const id = `message-${letter.id}`;
        const latestAt = latestConversationTimestamp(letter, groomReplies, threadMessages);
        return {
          id,
          letter,
          lastAt: latestAt ? formatConversationTime(latestAt) : CONVERSATION_TIMES[index] ?? "先週",
          muted: previewMode && index === 1,
          pinned: previewMode && (index === 0 || index === 4),
          unread:
            unreadMeguriMessageCount(letter, readState) +
            (groomUnreadByConversation[id] ?? 0) +
            (threadUnreadByConversation[id] ?? 0),
        };
      });
      if (!userIdParam) return rows;
      return [...rows].sort((a, b) => {
        if (a.letter.from.id === userIdParam) return -1;
        if (b.letter.from.id === userIdParam) return 1;
        return 0;
      });
    },
    [groomReplies, messageLetters, previewMode, readState, threadMessages, userIdParam],
  );
  const groomReplyMessages = useMemo(
    () => groupGroomRepliesByConversation(groomReplies, messageLetters),
    [groomReplies, messageLetters],
  );
  const threadSentMessages = useMemo(
    () => mergeThreadMessages(groomReplyMessages, groupThreadMessagesByConversation(threadMessages, messageLetters)),
    [groomReplyMessages, messageLetters, threadMessages],
  );
  const unreadCount = conversations.reduce((sum, item) => sum + item.unread, 0);
  const activeSendLimit = subscribed ? PLUS_SEND_LIMIT : FREE_SEND_LIMIT;
  const remainingSends = Math.max(0, activeSendLimit - sendUsed);

  useEffect(() => {
    let mounted = true;
    setMessagesReady(false);
    Promise.all([
      loadMeguriPlusState(profile).catch(() => null),
      loadMeguriMessageReadState().catch(() => ({})),
      loadMeguriGroomReplies().catch(() => []),
      loadMeguriThreadMessages().catch(() => []),
    ])
      .then(async ([plus, nextReadState, replies, messages]) => {
        const nextSubscribed = plus?.active ?? false;
        const usage = await loadMeguriSendUsage(profile, nextSubscribed).catch(() => null);
        if (!mounted) return;
        if (plus) {
          setSubscribed(plus.active);
          setCanUsePlusReviewToggle(plus.canUseReviewToggle);
        }
        setSendUsed(usage?.used ?? INITIAL_FREE_SEND_USED);
        setReadState(nextReadState);
        setGroomReplies(replies);
        setThreadMessages(messages);
      })
      .finally(() => {
        if (mounted) setMessagesReady(true);
      });
    return () => {
      mounted = false;
    };
  }, [profile?.handle]);

  useEffect(() => {
    const subscription = AppState.addEventListener("change", (state) => {
      if (state !== "active") return;
      Promise.all([loadMeguriGroomReplies(), loadMeguriThreadMessages()])
        .then(([replies, messages]) => {
          setGroomReplies(replies);
          setThreadMessages(messages);
        })
        .catch(() => undefined);
    });
    return () => subscription.remove();
  }, []);

  const openConversation = useCallback((conversation: MessageConversation) => {
    setSelectedConversation(conversation);
    if (conversation.unread <= 0) return;
    markMeguriLetterRead(conversation.letter.id)
      .then(setReadState)
      .catch(() => undefined);
    markMeguriGroomRepliesRead(conversation.letter.from.id)
      .then(() => loadMeguriGroomReplies().then(setGroomReplies))
      .catch(() => undefined);
    markMeguriThreadMessagesRead(conversation.letter.from.id)
      .then(() => loadMeguriThreadMessages().then(setThreadMessages))
      .catch(() => undefined);
  }, []);

  useEffect(() => {
    if (!selectedConversation) return undefined;
    const subscription = BackHandler.addEventListener("hardwareBackPress", () => {
      setSelectedConversation(null);
      return true;
    });
    return () => subscription.remove();
  }, [selectedConversation]);

  useEffect(() => {
    if (openParam !== "1" || !userIdParam || selectedConversation) return;
    const target = conversations.find(
      (conversation) => conversation.letter.from.id === userIdParam,
    );
    if (target) openConversation(target);
  }, [conversations, openConversation, openParam, selectedConversation, userIdParam]);

  async function toggleSubscribed() {
    const next = !subscribed;
    const saved = await saveMeguriPlusReviewOverride(profile, next);
    if (!saved) return;
    setSubscribed(next);
  }

  async function sendMessage() {
    if (!draft.trim() || !selectedConversation) return;
    const canSend = remainingSends > 0;
    if (!canSend) {
      setPlusOpen(true);
      return;
    }
    const body = draft.trim();
    setDraft("");
    const message = await appendMeguriThreadMessage({
      body,
      peerId: selectedConversation.letter.from.id,
      peerName: selectedConversation.letter.from.name,
    });
    setThreadMessages((current) => mergeThreadMessageList(current, [message]));
    const usage = await incrementMeguriSendUsage(profile, subscribed);
    setSendUsed(usage.used);
  }

  async function sendImage() {
    if (!selectedConversation) return;
    const canSend = remainingSends > 0;
    if (!canSend) {
      setPlusOpen(true);
      return;
    }

    const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) return;
    const result = await ImagePicker.launchImageLibraryAsync({
      allowsEditing: false,
      mediaTypes: ["images"],
      quality: 0.84,
    });
    if (result.canceled || !result.assets[0]?.uri) return;

    const message = await appendMeguriThreadMessage({
      body: "画像を送信しました",
      imageUri: result.assets[0].uri,
      peerId: selectedConversation.letter.from.id,
      peerName: selectedConversation.letter.from.name,
    });
    setThreadMessages((current) => mergeThreadMessageList(current, [message]));
    const usage = await incrementMeguriSendUsage(profile, subscribed);
    setSendUsed(usage.used);
  }

  if (selectedConversation) {
    return (
      <MessageThreadScreen
        conversation={selectedConversation}
        draft={draft}
        insetsBottom={Math.max(insets.bottom, 10)}
        insetsTop={Math.max(insets.top, 12)}
        canUseReviewToggle={canUsePlusReviewToggle}
        onBack={() => setSelectedConversation(null)}
        onChangeDraft={setDraft}
        onOpenPlan={() => setPlusOpen(true)}
        onPickImage={sendImage}
        onSend={sendMessage}
        onToggleReviewPlan={toggleSubscribed}
        remainingSends={remainingSends}
        sendUsed={sendUsed}
        sentMessages={threadSentMessages[selectedConversation.id] ?? []}
        showPreviewReply={previewMode}
        subscribed={subscribed}
      >
        <PlusModal
          open={plusOpen}
          subscribed={subscribed}
          onClose={() => setPlusOpen(false)}
          onToggle={toggleSubscribed}
          canUseReviewToggle={canUsePlusReviewToggle}
        />
      </MessageThreadScreen>
    );
  }

  return (
    <Screen bottomInset={false} contentStyle={styles.lineRoot} scroll={false} topInset={false}>
      <View style={[styles.messageHeader, { paddingTop: Math.max(insets.top, 12) + 12 }]}>
        <View style={styles.messageHeaderSide}>
          <Pressable
            accessibilityLabel="戻る"
            accessibilityRole="button"
            onPress={() => {
              if (router.canGoBack()) router.back();
              else router.replace("/encounters");
            }}
            style={styles.messageBackButton}
          >
            <IconSymbol name="chevron-back" color={ihubColors.ink} size={22} />
          </Pressable>
        </View>
        <Text style={styles.messageHeaderTitle}>メッセージ</Text>
        <View style={[styles.messageHeaderSide, styles.messageHeaderSideRight]}>
          {canUsePlusReviewToggle ? (
            <ReviewPlanToggleButton active={subscribed} onPress={toggleSubscribed} />
          ) : null}
        </View>
      </View>

      <ScrollView
        contentContainerStyle={[styles.talkListContent, { paddingBottom: Math.max(insets.bottom, 10) + 82 }]}
        showsVerticalScrollIndicator={false}
        style={styles.talkList}
      >
        {!messagesReady ? (
          <View style={styles.messageLoading}>
            <ActivityIndicator color={ihubColors.lavender} />
          </View>
        ) : null}
        {messagesReady && conversations.length === 0 ? (
          <View style={styles.messageEmpty}>
            <Text style={styles.messageEmptyTitle}>まだメッセージはありません</Text>
            <Text style={styles.messageEmptyText}>
              グルームへの返信や、めぐりあいメッセージが届くとここに表示されます。
            </Text>
          </View>
        ) : null}
        {messagesReady && conversations.map((conversation) => (
          <ConversationRow
            key={conversation.id}
            conversation={conversation}
            highlighted={conversation.letter.from.id === userIdParam}
            latestSent={lastMessage(threadSentMessages[conversation.id])}
            onPress={() => openConversation(conversation)}
          />
        ))}
      </ScrollView>

      <MegrimBottomNav bottomInset={Math.max(insets.bottom, 10)} unreadCount={unreadCount} />

      <PlusModal
        open={plusOpen}
        subscribed={subscribed}
        onClose={() => setPlusOpen(false)}
        onToggle={toggleSubscribed}
        canUseReviewToggle={canUsePlusReviewToggle}
      />
    </Screen>
  );
}

function ConversationRow({
  conversation,
  highlighted,
  latestSent,
  onPress,
}: {
  conversation: MessageConversation;
  highlighted?: boolean;
  latestSent?: ChatMessage;
  onPress: () => void;
}) {
  const { letter } = conversation;
  const hasSentMessage = !!latestSent;
  const unreplied = !hasSentMessage;
  const preview = latestSent?.body
    ? latestSent.body
    : latestSent?.imageUri
      ? "画像を送信しました"
      : "";
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={[
        styles.conversationRow,
        unreplied ? styles.conversationRowUnreplied : null,
        highlighted ? styles.conversationRowHighlighted : null,
      ]}
    >
      <View style={styles.avatar}>
        <MeguriAvatarFace
          animalType={letter.from.animalType}
          furColor={letter.from.furColor}
          hue={letter.from.hue}
          size={52}
        />
        {conversation.pinned ? (
          <View style={styles.pinBadge}>
            <Text style={styles.pinText}>↗</Text>
          </View>
        ) : null}
      </View>
      <View style={styles.conversationCopy}>
        <View style={styles.conversationTop}>
          <Text numberOfLines={1} style={styles.conversationName}>
            {letter.from.name}
          </Text>
          {conversation.muted ? <Text style={styles.muteMark}>◼</Text> : null}
        </View>
        {unreplied ? (
          <Text numberOfLines={1} style={styles.conversationPreview}>
            <Text style={styles.conversationPendingWord}>未返信</Text>
            <Text style={styles.conversationPendingMessage}>　メッセージが届いています！</Text>
          </Text>
        ) : (
          <Text numberOfLines={1} style={[styles.conversationPreview, styles.conversationSentPreview]}>
            {preview}
          </Text>
        )}
      </View>
      <View style={styles.conversationMeta}>
        <Text style={styles.conversationTime}>{conversation.lastAt}</Text>
        {conversation.unread > 0 ? (
          <View style={styles.unreadBadge}>
            <Text style={styles.unreadText}>{conversation.unread}</Text>
          </View>
        ) : null}
      </View>
    </Pressable>
  );
}

function MessageThreadScreen({
  canUseReviewToggle,
  children,
  conversation,
  draft,
  insetsBottom,
  insetsTop,
  onBack,
  onChangeDraft,
  onOpenPlan,
  onPickImage,
  onSend,
  onToggleReviewPlan,
  remainingSends,
  sendUsed,
  sentMessages,
  showPreviewReply,
  subscribed,
}: {
  canUseReviewToggle: boolean;
  children: ReactNode;
  conversation: MessageConversation;
  draft: string;
  insetsBottom: number;
  insetsTop: number;
  onBack: () => void;
  onChangeDraft: (value: string) => void;
  onOpenPlan: () => void;
  onPickImage: () => void;
  onSend: () => void;
  onToggleReviewPlan: () => void;
  remainingSends: number;
  sendUsed: number;
  sentMessages: ChatMessage[];
  showPreviewReply: boolean;
  subscribed: boolean;
}) {
  const { letter } = conversation;
  const canRead = subscribed;
  const messages = buildMessages(letter, canRead, sentMessages, showPreviewReply);
  const chatScrollRef = useRef<ScrollView>(null);
  const lastMessageId = messages[messages.length - 1]?.id ?? null;
  const canSend = remainingSends > 0;
  const lockedByPlan = !canRead;
  const sendLockedByPlan = !canSend;
  const composerPlaceholder = lockedByPlan
    ? "メッセージを入力"
    : sendLockedByPlan
      ? subscribed
        ? `めぐりPlusは月${PLUS_SEND_LIMIT}通まで`
        : `無料は月${FREE_SEND_LIMIT}通まで`
      : "メッセージを入力";
  const keyboardInset = useKeyboardInset();
  const composerBottomInset = keyboardInset > 0 ? 8 : insetsBottom;

  useEffect(() => {
    if (!lastMessageId) return;
    const timer = setTimeout(() => {
      chatScrollRef.current?.scrollToEnd({ animated: true });
    }, 90);
    return () => clearTimeout(timer);
  }, [lastMessageId]);

  return (
    <View style={styles.chatKeyboardRoot}>
    <Screen bottomInset={false} contentStyle={styles.chatRoot} scroll={false} topInset={false}>
      <View style={[styles.chatHeader, { paddingTop: insetsTop }]}>
        <View style={styles.chatHeaderSide}>
          <Pressable accessibilityRole="button" onPress={onBack} style={styles.chatBack}>
            <IconSymbol name="chevron-back" color={ihubColors.ink} size={26} />
          </Pressable>
        </View>
        <View style={styles.chatHeaderCenter}>
          <Text numberOfLines={1} style={styles.chatTitle}>{letter.from.name}</Text>
          <Text numberOfLines={1} style={styles.chatSubTitle}>
            めぐりあい
          </Text>
        </View>
        <View style={[styles.chatHeaderSide, styles.chatHeaderSideRight]}>
          {canUseReviewToggle ? (
            <ReviewPlanToggleButton active={subscribed} onPress={onToggleReviewPlan} />
          ) : (
            <Pressable accessibilityRole="button" style={styles.chatMenu}>
              <IconSymbol name="ellipsis-horizontal" color={ihubColors.ink} size={24} />
            </Pressable>
          )}
        </View>
      </View>

      <Pressable
        accessibilityRole="button"
        onPress={() =>
          router.push({
            pathname: "/meguri-profile",
            params: { id: letter.from.id },
          })
        }
        style={({ pressed }) => [
          styles.meguriPartnerStrip,
          pressed ? styles.meguriPartnerStripPressed : null,
        ]}
      >
        <View style={styles.meguriPartnerAvatar}>
          <MeguriAvatarFace
            animalType={letter.from.animalType}
            furColor={letter.from.furColor}
            hue={letter.from.hue}
            size={48}
          />
        </View>
        <View style={styles.meguriPartnerCopy}>
          <Text numberOfLines={1} style={styles.meguriPartnerName}>
            {letter.from.name}
          </Text>
          <Text numberOfLines={1} style={styles.meguriPartnerMeta}>
            {letter.placeHint} / {letter.timeHint}
          </Text>
        </View>
        <IconSymbol name="chevron-forward" color="rgba(58,50,74,0.28)" size={16} />
      </Pressable>

      <ScrollView
        ref={chatScrollRef}
        contentContainerStyle={[styles.chatContent, { paddingBottom: 18 }]}
        showsVerticalScrollIndicator={false}
        style={styles.chatScroll}
      >
        <Text style={styles.dateChip}>今日</Text>
        {lockedByPlan || sendLockedByPlan ? (
          <View style={styles.systemNotice}>
            <Text style={styles.systemNoticeTitle}>
              {lockedByPlan
                ? "メッセージが届いています！"
                : subscribed
                  ? "今月のめぐりPlus送信枠を使い切りました"
                  : "無料送信枠を使い切りました"}
            </Text>
            <Text style={styles.systemNoticeText}>
              {lockedByPlan
                ? "本文の開封と返信にはめぐりPlusが必要です。"
                : subscribed
                  ? `めぐりPlusは月${PLUS_SEND_LIMIT}通まで新規メッセージを送れます。現在 ${sendUsed}/${PLUS_SEND_LIMIT} 通使用済み。`
                  : `無料は月${FREE_SEND_LIMIT}通まで。${FREE_SEND_LIMIT + 1}通目以降はめぐりPlusで送信できます。現在 ${sendUsed}/${FREE_SEND_LIMIT} 通使用済み。`}
            </Text>
            <Pressable onPress={onOpenPlan} style={styles.systemNoticeButton}>
              <Text style={styles.systemNoticeButtonText}>めぐりPlusを見る</Text>
            </Pressable>
          </View>
        ) : null}

        {messages.map((message) => (
          <View
            key={message.id}
            style={[styles.messageLine, message.mine ? styles.messageLineMine : null]}
          >
            {!message.mine ? (
              <View style={styles.smallAvatar}>
                <MeguriAvatarFace
                  animalType={letter.from.animalType}
                  furColor={letter.from.furColor}
                  hue={letter.from.hue}
                  size={36}
                />
              </View>
            ) : null}
            <View style={message.mine ? styles.mineBubbleWrap : styles.theirBubbleWrap}>
              {message.mine ? (
                <View style={styles.messageMetaOutside}>
                  <Text style={styles.messageMetaText}>{message.time}</Text>
                </View>
              ) : null}
              <View style={message.mine ? styles.mineMessagePayload : null}>
                {message.groomReply ? (
                  <View style={styles.groomReplyAttachment}>
                    <Text style={styles.groomReplyAttachmentLabel}>
                      この人のストーリーズに返信しました
                    </Text>
                    <Image
                      source={{ uri: message.groomReply.imageUri }}
                      style={styles.groomReplyAttachmentImage}
                    />
                  </View>
                ) : null}
                <ChatGradientBubble
                  mine={message.mine}
                  style={[styles.bubble, message.mine ? styles.mineBubble : styles.theirBubble]}
                >
                  {message.locked ? (
                    <LockedMessageMosaic onPress={onOpenPlan} />
                  ) : message.imageUri ? (
                    <Image source={{ uri: message.imageUri }} style={styles.messageImage} />
                  ) : message.body ? (
                    <Text style={[styles.bubbleText, message.mine ? styles.mineBubbleText : null]}>
                      {message.body}
                    </Text>
                  ) : null}
                </ChatGradientBubble>
              </View>
              {!message.mine ? (
                <View style={styles.messageMetaOutside}>
                  <Text style={styles.messageMetaText}>{message.time}</Text>
                </View>
              ) : null}
            </View>
          </View>
        ))}
      </ScrollView>

      <View
        style={[
          styles.composerBar,
          { marginBottom: keyboardInset, paddingBottom: composerBottomInset },
        ]}
      >
        <Pressable accessibilityRole="button" onPress={onPickImage} style={styles.composerIcon}>
          <IconSymbol name="add-circle-outline" color={ihubColors.ink} size={25} />
        </Pressable>
        <TextInput
          editable={canSend}
          multiline
          onChangeText={onChangeDraft}
          placeholder={composerPlaceholder}
          placeholderTextColor="rgba(0,0,0,0.36)"
          scrollEnabled
          style={[styles.composerInput, !canSend ? styles.composerInputDisabled : null]}
          textAlignVertical="top"
          value={draft}
        />
        <Pressable
          accessibilityRole="button"
          onPress={canSend ? onSend : onOpenPlan}
          style={[styles.sendRound, draft.trim() && canSend ? styles.sendRoundActive : null]}
        >
          <IconSymbol
            name={canSend ? "send-outline" : "lock-closed-outline"}
            color={draft.trim() && canSend ? "#fff" : "#666"}
            size={18}
          />
        </Pressable>
      </View>
      {children}
    </Screen>
    </View>
  );
}

function MegrimBottomNav({ bottomInset, unreadCount }: { bottomInset: number; unreadCount: number }) {
  return (
    <View style={[styles.appTabBar, { paddingBottom: bottomInset }]}>
      <AppTabItem glyph="⌂" label="ホーム" onPress={() => router.replace("/")} />
      <AppTabItem glyph="□" label="在庫" onPress={() => router.replace("/inventory")} />
      <AppTabItem glyph="♡" label="Wish" onPress={() => router.replace("/wishes")} />
      <AppTabItem active badge={unreadCount} glyph="◌" label="めぐり" onPress={() => router.replace("/encounters")} />
      <AppTabItem glyph="⇄" label="取引" onPress={() => router.replace("/transactions")} />
    </View>
  );
}

function AppTabItem({
  active = false,
  badge,
  glyph,
  label,
  onPress,
}: {
  active?: boolean;
  badge?: number;
  glyph: string;
  label: string;
  onPress: () => void;
}) {
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={styles.appTabItem}>
      <View style={styles.appTabGlyphWrap}>
        <Text style={[styles.appTabGlyph, active ? styles.appTabGlyphActive : null]}>{glyph}</Text>
        {badge ? (
          <View style={styles.appTabBadge}>
            <Text style={styles.appTabBadgeText}>{badge}</Text>
          </View>
        ) : null}
      </View>
      <Text style={[styles.appTabLabel, active ? styles.appTabLabelActive : null]}>{label}</Text>
    </Pressable>
  );
}

function ReviewPlanToggleButton({
  active,
  onPress,
}: {
  active: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityLabel={active ? "無料会員に切り替える" : "めぐりPlus会員に切り替える"}
      accessibilityRole="button"
      onPress={onPress}
      style={[styles.reviewPlanToggle, active ? styles.reviewPlanToggleActive : null]}
    >
      <Text style={[styles.reviewPlanToggleText, active ? styles.reviewPlanToggleTextActive : null]}>
        {active ? "無料へ" : "Plusへ"}
      </Text>
    </Pressable>
  );
}

const LOCKED_MOSAIC_ROWS = [10, 9, 11, 8];
const LOCKED_MOSAIC_COLORS = [
  "rgba(166,149,216,0.28)",
  "rgba(168,212,230,0.34)",
  "rgba(243,197,212,0.3)",
  "rgba(58,50,74,0.12)",
];

function LockedMessageMosaic({ onPress }: { onPress: () => void }) {
  return (
    <Pressable
      accessibilityLabel="めぐりPlusでメッセージを開封"
      accessibilityRole="button"
      onPress={onPress}
      style={styles.lockedMosaic}
    >
      <View pointerEvents="none" style={styles.lockedMosaicGrid}>
        {LOCKED_MOSAIC_ROWS.map((count, rowIndex) => (
          <View key={`row-${rowIndex}`} style={styles.lockedMosaicRow}>
            {Array.from({ length: count }).map((_, tileIndex) => (
              <View
                key={`${rowIndex}-${tileIndex}`}
                style={[
                  styles.lockedMosaicTile,
                  {
                    backgroundColor:
                      LOCKED_MOSAIC_COLORS[
                        (rowIndex * 2 + tileIndex) % LOCKED_MOSAIC_COLORS.length
                      ],
                    opacity: 0.72 - ((rowIndex + tileIndex) % 3) * 0.12,
                  },
                ]}
              />
            ))}
          </View>
        ))}
      </View>
      <View style={styles.lockedMosaicOverlay}>
        <IconSymbol name="lock-closed-outline" color="#fff" size={13} />
        <Text style={styles.lockedMosaicText}>めぐりPlusで開封</Text>
      </View>
    </Pressable>
  );
}

function buildMessages(
  letter: Letter,
  canRead: boolean,
  sentMessages: ChatMessage[],
  showPreviewReply: boolean,
): ChatMessage[] {
  const baseMessages: ChatMessage[] = [
    {
      id: `${letter.id}-hello`,
      body: "今日めぐりあった人から届きました。",
      mine: false,
      time: "0:20",
    },
    {
      id: `${letter.id}-body`,
      body: canRead ? letter.body : "メッセージが届いています！",
      locked: !canRead,
      mine: false,
      time: "0:22",
    },
  ];
  if (canRead && showPreviewReply) {
    baseMessages.push({
      id: `${letter.id}-reply`,
      body: "めぐり、ありがとうございます。また同じ会場で会えたらうれしいです。",
      mine: true,
      time: "0:24",
    });
  }
  return [...baseMessages, ...sentMessages];
}

function createMessageLetters(
  groomReplies: MeguriGroomReply[],
  threadMessages: MeguriThreadMessage[],
  includePreviewRows: boolean,
): Letter[] {
  const previewBase = includePreviewRows ? createPreviewMessageLetters() : [];
  const base = [...previewBase];
  const existingIds = new Set(base.map((letter) => letter.from.id));
  const existingNames = new Set(base.map((letter) => letter.from.name));
  const replyLetters = groomReplies
    .filter(
      (reply, index, all) =>
        !existingIds.has(reply.recipientId) &&
        !existingNames.has(reply.recipientName) &&
        all.findIndex((candidate) => candidate.recipientId === reply.recipientId) === index,
    )
    .map((reply): Letter => ({
      affinity: 76,
      body: "グルームから届いたメッセージです。",
      from: {
        animalType: "cat",
        area: "イベント周辺",
        count: 1,
        furColor: "lavender",
        group: "めぐり",
        hitokoto: reply.groomCaption || reply.body,
        hue: "lav",
        id: reply.recipientId,
        name: reply.recipientName,
        oshi: "推し",
        recent: reply.groomCaption || "グルームでめぐりました",
        since: "今日",
        style: "推し活",
      },
      id: `message-groom-${reply.recipientId}`,
      opened: true,
      placeHint: "同じイベント圏内",
      timeHint: "今日",
    }));
  for (const letter of replyLetters) {
    existingIds.add(letter.from.id);
    existingNames.add(letter.from.name);
  }
  const threadLetters = threadMessages
    .filter(
      (message, index, all) =>
        !existingIds.has(message.peerId) &&
        !existingNames.has(message.peerName) &&
        all.findIndex((candidate) => candidate.peerId === message.peerId) === index,
    )
    .map((message): Letter => ({
      affinity: 76,
      body: message.body || "めぐりあいメッセージです。",
      from: messagePeerToMeguriUser(message),
      id: `message-thread-${message.peerId}`,
      opened: true,
      placeHint: "めぐりあい",
      timeHint: "今日",
    }));
  return [...base, ...replyLetters, ...threadLetters];
}

function createPreviewMessageLetters() {
  const letterUserIds = new Set(LETTERS.map((letter) => letter.from.id));
  const extras = USERS.filter((user) => !letterUserIds.has(user.id))
    .slice(0, 7)
    .map((user, index): Letter => ({
      affinity: 72 + (index % 5) * 4,
      body: EXTRA_MESSAGE_BODIES[index % EXTRA_MESSAGE_BODIES.length],
      from: user,
      id: `message-extra-${user.id}`,
      opened: index % 3 !== 1,
      placeHint: index % 2 === 0 ? "同じイベント圏内" : "最近、近いエリア",
      timeHint: index < 3 ? "今日" : "今週",
    }));
  return [...LETTERS, ...extras];
}

function messagePeerToMeguriUser(message: MeguriThreadMessage): MeguriUser {
  const matched = USERS.find((user) => user.id === message.peerId || user.name === message.peerName);
  if (matched) {
    return {
      ...matched,
      id: message.peerId,
      name: message.peerName || matched.name,
    };
  }
  return {
    animalType: "cat",
    area: "めぐりあい",
    count: 1,
    furColor: "lavender",
    group: "めぐり",
    hitokoto: message.body,
    hue: "lav",
    id: message.peerId,
    name: message.peerName,
    oshi: "推し",
    recent: message.body,
    since: "今日",
    style: "推し活",
  };
}

function latestConversationTimestamp(
  letter: Letter,
  groomReplies: MeguriGroomReply[],
  threadMessages: MeguriThreadMessage[],
) {
  const timestamps = [
    ...groomReplies
      .filter(
        (reply) =>
          reply.recipientId === letter.from.id ||
          reply.recipientName === letter.from.name,
      )
      .map((reply) => reply.sentAt),
    ...threadMessages
      .filter(
        (message) =>
          message.peerId === letter.from.id ||
          message.peerName === letter.from.name,
      )
      .map((message) => message.sentAt),
  ].filter((value) => Number.isFinite(value));
  return timestamps.length > 0 ? Math.max(...timestamps) : null;
}

function formatConversationTime(timestamp: number) {
  const diffMinutes = Math.max(0, Math.floor((Date.now() - timestamp) / 60000));
  if (diffMinutes < 1) return "今";
  if (diffMinutes < 60) return `${diffMinutes}分前`;
  const diffHours = Math.floor(diffMinutes / 60);
  if (diffHours < 24) return `${diffHours}時間前`;
  if (diffHours < 48) return "昨日";
  return new Intl.DateTimeFormat("ja-JP", {
    month: "numeric",
    day: "numeric",
  }).format(new Date(timestamp));
}

function groupGroomRepliesByConversation(
  replies: MeguriGroomReply[],
  letters: Letter[],
): Record<string, ChatMessage[]> {
  const idToConversation = new Map(letters.map((letter) => [letter.from.id, `message-${letter.id}`]));
  const nameToConversation = new Map(letters.map((letter) => [letter.from.name, `message-${letter.id}`]));
  const grouped: Record<string, ChatMessage[]> = {};
  for (const reply of replies) {
    const conversationId =
      idToConversation.get(reply.recipientId) ??
      nameToConversation.get(reply.recipientName);
    if (!conversationId) continue;
    grouped[conversationId] = [
      ...(grouped[conversationId] ?? []),
      {
        body: reply.body,
        groomReply: {
          caption: reply.groomCaption,
          imageUri: reply.groomImageUri,
        },
        id: reply.id,
        mine: reply.mine !== false,
        sentAt: reply.sentAt,
        time: currentTimeLabel(reply.sentAt),
      },
    ];
  }
  return Object.fromEntries(
    Object.entries(grouped).map(([conversationId, messages]) => [
      conversationId,
      sortThreadMessages(messages),
    ]),
  );
}

function groupThreadMessagesByConversation(
  messages: MeguriThreadMessage[],
  letters: Letter[],
): Record<string, ChatMessage[]> {
  const idToConversation = new Map(letters.map((letter) => [letter.from.id, `message-${letter.id}`]));
  const nameToConversation = new Map(letters.map((letter) => [letter.from.name, `message-${letter.id}`]));
  const grouped: Record<string, ChatMessage[]> = {};
  for (const message of messages) {
    const conversationId =
      idToConversation.get(message.peerId) ??
      nameToConversation.get(message.peerName);
    if (!conversationId) continue;
    grouped[conversationId] = [
      ...(grouped[conversationId] ?? []),
      {
        body: message.body,
        id: message.id,
        imageUri: message.imageUri,
        locked: message.locked,
        mine: message.mine !== false,
        sentAt: message.sentAt,
        time: currentTimeLabel(message.sentAt),
      },
    ];
  }
  return Object.fromEntries(
    Object.entries(grouped).map(([conversationId, rows]) => [
      conversationId,
      sortThreadMessages(rows),
    ]),
  );
}

function unreadGroomRepliesByConversation(
  replies: MeguriGroomReply[],
  letters: Letter[],
): Record<string, number> {
  const idToConversation = new Map(letters.map((letter) => [letter.from.id, `message-${letter.id}`]));
  const unread: Record<string, number> = {};
  for (const reply of replies) {
    if (reply.mine !== false || reply.readAt) continue;
    const conversationId = idToConversation.get(reply.recipientId);
    if (!conversationId) continue;
    unread[conversationId] = (unread[conversationId] ?? 0) + 1;
  }
  return unread;
}

function unreadThreadMessagesByConversation(
  messages: MeguriThreadMessage[],
  letters: Letter[],
): Record<string, number> {
  const idToConversation = new Map(letters.map((letter) => [letter.from.id, `message-${letter.id}`]));
  const unread: Record<string, number> = {};
  for (const message of messages) {
    if (message.mine !== false || message.readAt) continue;
    const conversationId = idToConversation.get(message.peerId);
    if (!conversationId) continue;
    unread[conversationId] = (unread[conversationId] ?? 0) + 1;
  }
  return unread;
}

function mergeThreadMessages(
  stored: Record<string, ChatMessage[]>,
  inMemory: Record<string, ChatMessage[]>,
) {
  const keys = new Set([...Object.keys(stored), ...Object.keys(inMemory)]);
  const merged: Record<string, ChatMessage[]> = {};
  for (const key of keys) {
    const byId = new Map<string, ChatMessage>();
    for (const message of [...(stored[key] ?? []), ...(inMemory[key] ?? [])]) {
      byId.set(message.id, message);
    }
    merged[key] = sortThreadMessages(Array.from(byId.values()));
  }
  return merged;
}

function mergeThreadMessageList(
  current: MeguriThreadMessage[],
  incoming: MeguriThreadMessage[],
) {
  const byId = new Map<string, MeguriThreadMessage>();
  for (const message of [...current, ...incoming]) byId.set(message.id, message);
  return Array.from(byId.values()).sort((a, b) => a.sentAt - b.sentAt);
}

function sortThreadMessages(messages: ChatMessage[]) {
  return [...messages].sort((a, b) => (a.sentAt ?? 0) - (b.sentAt ?? 0));
}

function lastMessage(messages?: ChatMessage[]) {
  return messages && messages.length > 0 ? messages[messages.length - 1] : undefined;
}

function currentTimeLabel(value: number = Date.now()) {
  const now = new Date(value);
  const hours = now.getHours();
  const minutes = now.getMinutes().toString().padStart(2, "0");
  return `${hours}:${minutes}`;
}

const styles = StyleSheet.create({
  lineRoot: {
    backgroundColor: "#fff",
    flex: 1,
    paddingHorizontal: 0,
  },
  messageHeader: {
    alignItems: "center",
    backgroundColor: "#fff",
    flexDirection: "row",
    minHeight: 68,
    paddingBottom: 12,
    paddingHorizontal: 14,
  },
  messageHeaderSide: {
    alignItems: "flex-start",
    justifyContent: "center",
    width: 72,
  },
  messageHeaderSideRight: {
    alignItems: "flex-end",
  },
  messageBackButton: {
    alignItems: "center",
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  messageHeaderTitle: {
    color: ihubColors.ink,
    flex: 1,
    fontSize: 22,
    fontWeight: "900",
    textAlign: "center",
  },
  talkList: {
    backgroundColor: "#fff",
    flex: 1,
  },
  talkListContent: {
    paddingTop: 2,
  },
  messageLoading: {
    alignItems: "center",
    minHeight: 180,
    justifyContent: "center",
  },
  messageEmpty: {
    alignItems: "center",
    paddingHorizontal: 28,
    paddingTop: 96,
  },
  messageEmptyTitle: {
    color: ihubColors.ink,
    fontSize: 16,
    fontWeight: "900",
  },
  messageEmptyText: {
    color: "rgba(58,50,74,0.52)",
    fontSize: 12,
    fontWeight: "700",
    lineHeight: 20,
    marginTop: 8,
    textAlign: "center",
  },
  conversationRow: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderColor: "transparent",
    borderRadius: 18,
    borderWidth: 1,
    flexDirection: "row",
    gap: 12,
    marginHorizontal: 10,
    marginVertical: 3,
    minHeight: 74,
    paddingHorizontal: 14,
    paddingVertical: 8,
  },
  conversationRowUnreplied: {
    backgroundColor: "rgba(255,255,255,0.98)",
    borderColor: "rgba(217,73,73,0.52)",
    shadowColor: "#d94949",
    shadowOffset: { width: 0, height: 7 },
    shadowOpacity: 0.12,
    shadowRadius: 14,
  },
  conversationRowHighlighted: {
    backgroundColor: "rgba(166,149,216,0.10)",
  },
  avatar: {
    alignItems: "center",
    borderRadius: 26,
    height: 52,
    justifyContent: "center",
    position: "relative",
    width: 52,
  },
  avatarText: {
    color: ihubColors.ink,
    fontSize: 22,
    fontWeight: "900",
  },
  pinBadge: {
    alignItems: "center",
    backgroundColor: "#4d76f2",
    borderColor: "#fff",
    borderRadius: 999,
    borderWidth: 2,
    bottom: -2,
    height: 21,
    justifyContent: "center",
    position: "absolute",
    right: -2,
    width: 21,
  },
  pinText: {
    color: "#fff",
    fontSize: 12,
    fontWeight: "900",
  },
  conversationCopy: {
    flex: 1,
    gap: 3,
    minWidth: 0,
  },
  conversationTop: {
    alignItems: "center",
    flexDirection: "row",
    gap: 5,
  },
  conversationName: {
    color: ihubColors.ink,
    flexShrink: 1,
    fontSize: 16.5,
    fontWeight: "900",
    letterSpacing: 0,
  },
  muteMark: {
    color: "#a1a1a1",
    fontSize: 12,
    fontWeight: "900",
  },
  conversationPreview: {
    color: ihubColors.mutedInk,
    fontSize: 13.5,
    fontWeight: "700",
    lineHeight: 19,
  },
  conversationPendingWord: {
    color: "#d94949",
    fontWeight: "900",
  },
  conversationPendingMessage: {
    color: ihubColors.ink,
    fontWeight: "900",
  },
  conversationSentPreview: {
    fontWeight: "500",
  },
  conversationMeta: {
    alignItems: "flex-end",
    alignSelf: "stretch",
    gap: 9,
    minWidth: 48,
    paddingTop: 2,
  },
  conversationTime: {
    color: "rgba(58,50,74,0.48)",
    fontSize: 11.5,
    fontWeight: "700",
    textAlign: "right",
  },
  unreadBadge: {
    alignItems: "center",
    backgroundColor: MESSAGE_ACTIVE,
    borderRadius: 999,
    minWidth: 29,
    paddingHorizontal: 8,
    paddingVertical: 5,
  },
  unreadText: {
    color: "#fff",
    fontSize: 14,
    fontWeight: "900",
  },
  appTabBar: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderTopColor: "rgba(58,50,74,0.10)",
    borderTopWidth: StyleSheet.hairlineWidth,
    bottom: 0,
    flexDirection: "row",
    justifyContent: "space-around",
    left: 0,
    paddingTop: 8,
    position: "absolute",
    right: 0,
  },
  appTabItem: {
    alignItems: "center",
    gap: 3,
    minWidth: 58,
  },
  appTabGlyphWrap: {
    position: "relative",
  },
  appTabGlyph: {
    color: "rgba(58,50,74,0.46)",
    fontSize: 25,
    fontWeight: "900",
    lineHeight: 28,
  },
  appTabGlyphActive: {
    color: ihubColors.lavender,
  },
  appTabBadge: {
    alignItems: "center",
    backgroundColor: "#ff3b4f",
    borderRadius: 999,
    minWidth: 22,
    paddingHorizontal: 6,
    paddingVertical: 2,
    position: "absolute",
    right: -16,
    top: -8,
  },
  appTabBadgeText: {
    color: "#fff",
    fontSize: 12,
    fontWeight: "900",
  },
  appTabLabel: {
    color: "rgba(58,50,74,0.56)",
    fontSize: 11,
    fontWeight: "700",
  },
  appTabLabelActive: {
    color: ihubColors.lavender,
    fontWeight: "800",
  },
  chatRoot: {
    backgroundColor: ihubColors.background,
    flex: 1,
    paddingHorizontal: 0,
  },
  chatKeyboardRoot: {
    backgroundColor: ihubColors.background,
    flex: 1,
  },
  chatHeader: {
    alignItems: "center",
    backgroundColor: ihubColors.surface,
    flexDirection: "row",
    minHeight: 86,
    paddingBottom: 9,
    paddingHorizontal: 10,
  },
  chatHeaderSide: {
    alignItems: "flex-start",
    justifyContent: "center",
    width: 72,
  },
  chatHeaderSideRight: {
    alignItems: "flex-end",
  },
  chatBack: {
    alignItems: "center",
    height: 38,
    justifyContent: "center",
    width: 40,
  },
  chatHeaderCenter: {
    alignItems: "center",
    flex: 1,
    paddingHorizontal: 8,
  },
  chatTitle: {
    color: ihubColors.ink,
    fontSize: 17,
    fontWeight: "900",
    maxWidth: "100%",
  },
  chatSubTitle: {
    color: ihubColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 2,
    maxWidth: "100%",
  },
  chatMenu: {
    alignItems: "center",
    height: 38,
    justifyContent: "center",
    width: 40,
  },
  reviewPlanToggle: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.12)",
    borderColor: "rgba(166,149,216,0.26)",
    borderRadius: 999,
    borderWidth: 1,
    minWidth: 62,
    paddingHorizontal: 10,
    paddingVertical: 7,
  },
  reviewPlanToggleActive: {
    backgroundColor: ihubColors.ink,
    borderColor: ihubColors.ink,
  },
  reviewPlanToggleText: {
    color: ihubColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  reviewPlanToggleTextActive: {
    color: "#fff",
  },
  chatScroll: {
    backgroundColor: ihubColors.background,
    flex: 1,
  },
  chatContent: {
    gap: 11,
    paddingHorizontal: 14,
    paddingTop: 12,
  },
  meguriPartnerStrip: {
    alignItems: "center",
    backgroundColor: ihubColors.surface,
    borderBottomColor: "rgba(58,50,74,0.08)",
    borderBottomWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    gap: 11,
    paddingBottom: 12,
    paddingHorizontal: 18,
    paddingTop: 4,
  },
  meguriPartnerStripPressed: {
    backgroundColor: "rgba(166,149,216,0.08)",
  },
  meguriPartnerAvatar: {
    alignItems: "center",
    borderColor: "rgba(255,255,255,0.92)",
    borderRadius: 24,
    borderWidth: 2,
    height: 48,
    justifyContent: "center",
    width: 48,
  },
  meguriPartnerAvatarText: {
    color: ihubColors.ink,
    fontSize: 19,
    fontWeight: "900",
  },
  meguriPartnerCopy: {
    flex: 1,
    gap: 3,
  },
  meguriPartnerName: {
    color: ihubColors.ink,
    fontSize: 15.5,
    fontWeight: "900",
  },
  meguriPartnerMeta: {
    color: ihubColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
  },
  dateChip: {
    alignSelf: "center",
    backgroundColor: "rgba(58,50,74,0.12)",
    borderRadius: 999,
    color: ihubColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
    marginBottom: 3,
    overflow: "hidden",
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  systemNotice: {
    alignSelf: "center",
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderWidth: 1,
    borderRadius: 14,
    maxWidth: "88%",
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  systemNoticeTitle: {
    color: ihubColors.ink,
    fontSize: 12.5,
    fontWeight: "900",
    textAlign: "center",
  },
  systemNoticeText: {
    color: ihubColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    lineHeight: 15,
    marginTop: 4,
    textAlign: "center",
  },
  systemNoticeButton: {
    alignSelf: "center",
    backgroundColor: ihubColors.ink,
    borderRadius: 999,
    marginTop: 8,
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
  systemNoticeButtonText: {
    color: "#fff",
    fontSize: 11,
    fontWeight: "900",
  },
  messageLine: {
    alignItems: "flex-end",
    flexDirection: "row",
    gap: 7,
  },
  messageLineMine: {
    justifyContent: "flex-end",
  },
  smallAvatar: {
    alignItems: "center",
    borderRadius: 18,
    height: 36,
    justifyContent: "center",
    width: 36,
  },
  smallAvatarText: {
    color: "#fff",
    fontSize: 14,
    fontWeight: "900",
  },
  theirBubbleWrap: {
    alignItems: "flex-start",
    maxWidth: "78%",
  },
  mineBubbleWrap: {
    alignItems: "flex-end",
    flexDirection: "row",
    gap: 5,
    justifyContent: "flex-end",
    maxWidth: "88%",
  },
  mineMessagePayload: {
    alignItems: "flex-end",
    gap: 8,
    maxWidth: "100%",
  },
  bubble: {
    borderRadius: 18,
    maxWidth: "100%",
    paddingHorizontal: 13,
    paddingVertical: 9,
  },
  theirBubble: {
    backgroundColor: ihubColors.surface,
    borderBottomLeftRadius: 5,
  },
  mineBubble: {
    backgroundColor: "transparent",
    borderBottomRightRadius: 5,
  },
  bubbleText: {
    color: ihubColors.ink,
    fontSize: 15,
    fontWeight: "700",
    lineHeight: 21,
  },
  mineBubbleText: {
    color: ihubColors.surface,
  },
  messageImage: {
    borderRadius: 14,
    height: 150,
    width: 190,
  },
  lockedMosaic: {
    borderColor: "rgba(166,149,216,0.18)",
    borderRadius: 15,
    borderWidth: 1,
    minHeight: 76,
    overflow: "hidden",
    padding: 9,
    width: 198,
  },
  lockedMosaicGrid: {
    gap: 5,
  },
  lockedMosaicRow: {
    flexDirection: "row",
    gap: 4,
  },
  lockedMosaicTile: {
    borderRadius: 4,
    flex: 1,
    height: 10,
  },
  lockedMosaicOverlay: {
    alignItems: "center",
    alignSelf: "flex-start",
    backgroundColor: ihubColors.ink,
    borderRadius: 999,
    flexDirection: "row",
    gap: 5,
    marginTop: 9,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  lockedMosaicText: {
    color: "#fff",
    fontSize: 11,
    fontWeight: "900",
  },
  groomReplyAttachment: {
    alignItems: "flex-end",
    gap: 8,
  },
  groomReplyAttachmentLabel: {
    color: "rgba(58,50,74,0.58)",
    fontSize: 15,
    fontWeight: "700",
    lineHeight: 20,
    textAlign: "right",
  },
  groomReplyAttachmentImage: {
    borderRadius: 24,
    height: 220,
    width: 156,
  },
  bubblePlanButton: {
    alignSelf: "flex-start",
    backgroundColor: "#111",
    borderRadius: 999,
    marginTop: 8,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  bubblePlanText: {
    color: "#fff",
    fontSize: 11,
    fontWeight: "900",
  },
  messageMetaOutside: {
    alignItems: "flex-start",
    gap: 1,
    minWidth: 28,
    paddingBottom: 3,
  },
  messageMetaText: {
    color: "rgba(58,50,74,0.48)",
    fontSize: 10,
    fontWeight: "700",
    lineHeight: 13,
  },
  bubbleTime: {
    color: "rgba(58,50,74,0.48)",
    fontSize: 10,
    fontWeight: "700",
    lineHeight: 13,
    marginTop: 3,
  },
  bubbleTimeMine: {
    textAlign: "right",
  },
  composerBar: {
    alignItems: "flex-end",
    backgroundColor: ihubColors.surface,
    borderTopColor: "rgba(58,50,74,0.08)",
    borderTopWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    gap: 8,
    paddingHorizontal: 9,
    paddingTop: 8,
  },
  composerIcon: {
    alignItems: "center",
    alignSelf: "flex-end",
    height: 36,
    justifyContent: "center",
    width: 36,
  },
  composerInput: {
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 18,
    color: ihubColors.ink,
    flex: 1,
    fontSize: 15,
    fontWeight: "700",
    lineHeight: 20,
    maxHeight: 156,
    minHeight: 36,
    paddingHorizontal: 14,
    paddingVertical: 8,
  },
  composerInputDisabled: {
    color: "rgba(0,0,0,0.42)",
    opacity: 0.78,
  },
  sendRound: {
    alignItems: "center",
    alignSelf: "flex-end",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 999,
    height: 36,
    justifyContent: "center",
    width: 36,
  },
  sendRoundActive: {
    backgroundColor: MESSAGE_ACTIVE,
  },
});
