import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type PropsWithChildren,
} from "react";
import type { Session, User } from "@supabase/supabase-js";
import { hasSupabaseConfig, supabase } from "../lib/supabase";
import { getMobileAuthEmailRedirectTo } from "./redirects";

type SignUpProfile = {
  handle?: string;
  displayName?: string;
};

type AuthProfile = {
  accountStatus: string | null;
  gender: string | null;
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
  enterPreview: () => void;
  exitPreview: () => void;
  refreshProfile: () => Promise<AuthProfile | null>;
  signIn: (email: string, password: string) => Promise<string | null>;
  signInWithAppleIdToken: (identityToken: string) => Promise<string | null>;
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
  const [previewMode, setPreviewMode] = useState(false);

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
      setLoading(false);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setProfileLoading(!!nextSession);
      setSession(nextSession);
      setLoading(false);
      if (!nextSession) setProfile(null);
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  const refreshProfile = useCallback(async () => {
    if (!supabase || !session?.user) {
      setProfile(null);
      setProfileLoading(false);
      return null;
    }

    setProfileLoading(true);
    const { data, error } = await supabase
      .from("users")
      .select("account_status, gender, primary_area")
      .eq("id", session.user.id)
      .maybeSingle();
    if (error) {
      setProfile(null);
      setProfileLoading(false);
      return null;
    }

    const nextProfile: AuthProfile = {
      accountStatus:
        typeof data?.account_status === "string" ? data.account_status : null,
      gender: typeof data?.gender === "string" ? data.gender : null,
      primaryArea:
        typeof data?.primary_area === "string" ? data.primary_area : null,
    };
    setProfile(nextProfile);
    setProfileLoading(false);
    return nextProfile;
  }, [session?.user]);

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
      setProfileLoading(true);
      setSession(data.session);
      setPreviewMode(false);
    }
    return error?.message ?? null;
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

  const needsOnboarding = useMemo(() => {
    if (!hasSupabaseConfig || previewMode || !session || profileLoading) {
      return false;
    }
    if (!profile) return true;
    if (profile.accountStatus === "active") return false;
    if (
      profile.accountStatus === "registered" ||
      profile.accountStatus === "verified" ||
      profile.accountStatus === "onboarding"
    ) {
      return true;
    }
    return !profile.gender;
  }, [previewMode, profile, profileLoading, session]);

  const value = useMemo<AuthContextValue>(
    () => ({
      configured: hasSupabaseConfig,
      loading,
      profileLoading,
      previewMode,
      session,
      user: session?.user ?? null,
      profile,
      needsOnboarding,
      enterPreview: () => setPreviewMode(true),
      exitPreview: () => setPreviewMode(false),
      refreshProfile,
      signIn,
      signInWithAppleIdToken,
      signUp,
      signOut,
    }),
    [
      loading,
      needsOnboarding,
      previewMode,
      profile,
      profileLoading,
      refreshProfile,
      session,
      signIn,
      signInWithAppleIdToken,
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
