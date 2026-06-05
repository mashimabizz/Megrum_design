import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type PropsWithChildren,
} from "react";
import { Linking } from "react-native";
import type { Session, User } from "@supabase/supabase-js";
import { hasSupabaseConfig, supabase } from "../lib/supabase";
import {
  getMobileAuthEmailRedirectTo,
  getMobileAuthOAuthRedirectTo,
} from "./redirects";

type SignUpProfile = {
  handle?: string;
  displayName?: string;
};

export type AuthProfile = {
  accountStatus: string | null;
  avatarUrl: string | null;
  displayName: string | null;
  gender: string | null;
  hasOshi: boolean;
  handle: string | null;
  primaryArea: string | null;
};

type AuthContextValue = {
  configured: boolean;
  loading: boolean;
  profileLoading: boolean;
  previewMode: boolean;
  session: Session | null;
  user: User | null;
  profile: AuthProfile | null;
  needsOnboarding: boolean;
  onboardingPath: "/onboarding/gender" | "/onboarding/oshi" | "/onboarding/members" | null;
  enterPreview: () => void;
  exitPreview: () => void;
  refreshProfile: () => Promise<AuthProfile | null>;
  signIn: (email: string, password: string) => Promise<string | null>;
  signInWithAppleIdToken: (identityToken: string) => Promise<string | null>;
  signInWithGoogleOAuth: () => Promise<string | null>;
  signUp: (
    email: string,
    password: string,
    profile?: SignUpProfile,
  ) => Promise<string | null>;
  signOut: () => Promise<string | null>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: PropsWithChildren) {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(hasSupabaseConfig);
  const [profile, setProfile] = useState<AuthProfile | null>(null);
  const [profileLoading, setProfileLoading] = useState(hasSupabaseConfig);
  const [previewMode, setPreviewMode] = useState(shouldStartVisualPreviewMode);

  useEffect(() => {
    if (!supabase) {
      setLoading(false);
      setProfileLoading(false);
      return;
    }

    let mounted = true;

    supabase.auth.getSession().then(({ data }) => {
      if (!mounted) return;
      setProfileLoading(!!data.session);
      setSession(data.session);
      if (data.session) setPreviewMode(false);
      setLoading(false);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setProfileLoading(!!nextSession);
      setSession(nextSession);
      setLoading(false);
      if (nextSession) setPreviewMode(false);
      if (!nextSession) setProfile(null);
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  const effectivePreviewMode = previewMode && !session;

  const refreshProfile = useCallback(async () => {
    if (!supabase) {
      setProfile(null);
      setProfileLoading(false);
      return null;
    }

    const userId =
      session?.user.id ??
      (await supabase.auth.getUser()).data.user?.id ??
      null;
    if (!userId) {
      setProfile(null);
      setProfileLoading(false);
      return null;
    }

    setProfileLoading(true);
    const [{ data, error }, { count, error: oshiError }] = await Promise.all([
      supabase
        .from("users")
        .select("account_status, avatar_url, display_name, gender, handle, primary_area")
        .eq("id", userId)
        .maybeSingle(),
      supabase
        .from("user_oshi")
        .select("id", { count: "exact", head: true })
        .eq("user_id", userId),
    ]);
    if (error) {
      setProfile(null);
      setProfileLoading(false);
      return null;
    }

    const nextProfile: AuthProfile = {
      accountStatus:
        typeof data?.account_status === "string" ? data.account_status : null,
      avatarUrl: typeof data?.avatar_url === "string" ? data.avatar_url : null,
      displayName:
        typeof data?.display_name === "string" ? data.display_name : null,
      gender: typeof data?.gender === "string" ? data.gender : null,
      hasOshi: !oshiError && typeof count === "number" ? count > 0 : false,
      handle: typeof data?.handle === "string" ? data.handle : null,
      primaryArea:
        typeof data?.primary_area === "string" ? data.primary_area : null,
    };
    setProfile(nextProfile);
    setProfileLoading(false);
    return nextProfile;
  }, [session?.user.id]);

  useEffect(() => {
    void refreshProfile();
  }, [refreshProfile]);

  const signIn = useCallback(async (email: string, password: string) => {
    if (!supabase) return "Supabaseの環境変数が未設定です";
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (!error) {
      if (data.user) await ensureUserProfile(data.user);
      setProfileLoading(true);
      setSession(data.session);
      setPreviewMode(false);
    }
    return error?.message ?? null;
  }, []);

  const signInWithAppleIdToken = useCallback(async (identityToken: string) => {
    if (!supabase) return "Supabaseの環境変数が未設定です";
    const { data, error } = await supabase.auth.signInWithIdToken({
      provider: "apple",
      token: identityToken,
    });
    if (!error) {
      if (data.user) await ensureUserProfile(data.user);
      setProfileLoading(true);
      setSession(data.session);
      setPreviewMode(false);
    }
    return error?.message ?? null;
  }, []);

  const signInWithGoogleOAuth = useCallback(async () => {
    if (!supabase) return "Supabaseの環境変数が未設定です";
    const { data, error } = await supabase.auth.signInWithOAuth({
      provider: "google",
      options: {
        redirectTo: getMobileAuthOAuthRedirectTo("google"),
        skipBrowserRedirect: true,
        queryParams: {
          prompt: "select_account",
        },
      },
    });
    if (error) return error.message;
    if (!data?.url) return "Google認証画面を開けませんでした";

    setPreviewMode(false);
    try {
      await Linking.openURL(data.url);
      return null;
    } catch {
      return "Google認証画面を開けませんでした。もう一度お試しください";
    }
  }, []);

  const signUp = useCallback(
    async (email: string, password: string, profile?: SignUpProfile) => {
      if (!supabase) return "Supabaseの環境変数が未設定です";
      const { error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          emailRedirectTo: getMobileAuthEmailRedirectTo(),
          data: {
            handle: profile?.handle,
            display_name: profile?.displayName ?? profile?.handle,
          },
        },
      });
      if (!error) setPreviewMode(false);
      return error?.message ?? null;
    },
    [],
  );

  const signOut = useCallback(async () => {
    setPreviewMode(false);
    if (!supabase) return "Supabaseの環境変数が未設定です";
    const { error } = await supabase.auth.signOut();
    if (!error) {
      setSession(null);
      setProfile(null);
      setProfileLoading(false);
    }
    return error?.message ?? null;
  }, []);

  const onboardingPath = useMemo(() => {
    if (!hasSupabaseConfig || effectivePreviewMode || !session || profileLoading) {
      return null;
    }
    if (!profile?.gender) return "/onboarding/gender";
    if (!profile.hasOshi) return "/onboarding/oshi";
    if (profile.accountStatus !== "active") return "/onboarding/members";
    return null;
  }, [effectivePreviewMode, profile, profileLoading, session]);

  const needsOnboarding = useMemo(() => {
    if (!hasSupabaseConfig || effectivePreviewMode || !session || profileLoading) {
      return false;
    }
    if (!profile) return true;
    if (profile.accountStatus === "active") {
      return !profile.gender || !profile.hasOshi;
    }
    if (
      profile.accountStatus === "registered" ||
      profile.accountStatus === "verified" ||
      profile.accountStatus === "onboarding"
    ) {
      return true;
    }
    return !profile.gender || !profile.hasOshi;
  }, [effectivePreviewMode, profile, profileLoading, session]);

  const value = useMemo<AuthContextValue>(
    () => ({
      configured: hasSupabaseConfig,
      loading,
      profileLoading,
      previewMode: effectivePreviewMode,
      session,
      user: session?.user ?? null,
      profile,
      needsOnboarding,
      onboardingPath,
      enterPreview: () => setPreviewMode(true),
      exitPreview: () => setPreviewMode(false),
      refreshProfile,
      signIn,
      signInWithAppleIdToken,
      signInWithGoogleOAuth,
      signUp,
      signOut,
    }),
    [
      loading,
      needsOnboarding,
      onboardingPath,
      effectivePreviewMode,
      profile,
      profileLoading,
      refreshProfile,
      session,
      signIn,
      signInWithAppleIdToken,
      signInWithGoogleOAuth,
      signOut,
      signUp,
    ],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const value = useContext(AuthContext);
  if (!value) {
    throw new Error("useAuth must be used inside AuthProvider");
  }
  return value;
}

async function ensureUserProfile(user: User) {
  if (!supabase) return;

  const { data } = await supabase
    .from("users")
    .select("id")
    .eq("id", user.id)
    .maybeSingle();

  const now = new Date().toISOString();
  if (!data) {
    const fallbackHandle = buildFallbackHandle(user);
    const profilePayload = {
      id: user.id,
      handle: fallbackHandle,
      display_name:
        stringMetadata(user.user_metadata?.display_name) ??
        stringMetadata(user.user_metadata?.name) ??
        fallbackHandle,
      account_status: user.email_confirmed_at ? "verified" : "registered",
      email_verified_at: user.email_confirmed_at,
      last_login_at: now,
    };
    const { error } = await supabase.from("users").insert(profilePayload);
    if (error && fallbackHandle !== buildIdHandle(user.id)) {
      await supabase
        .from("users")
        .insert({ ...profilePayload, handle: buildIdHandle(user.id) });
    }
    return;
  }

  await supabase
    .from("users")
    .update({ last_login_at: now })
    .eq("id", user.id);
}

function buildFallbackHandle(user: User) {
  const metadataHandle = stringMetadata(user.user_metadata?.handle);
  if (metadataHandle && /^[a-z0-9_]{3,20}$/.test(metadataHandle)) {
    return metadataHandle;
  }

  const emailPrefix = user.email?.split("@")[0]?.toLowerCase() ?? "";
  const normalized = emailPrefix.replace(/[^a-z0-9_]/g, "_").slice(0, 20);
  if (/^[a-z0-9_]{3,20}$/.test(normalized)) return normalized;

  return buildIdHandle(user.id);
}

function shouldStartVisualPreviewMode() {
  const location = globalThis.location;
  if (!location?.search) return false;
  return new URLSearchParams(location.search).get("visualPreview") === "1";
}


function buildIdHandle(userId: string) {
  return `user_${userId.replace(/-/g, "").slice(0, 8)}`;
}

function stringMetadata(value: unknown) {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}
