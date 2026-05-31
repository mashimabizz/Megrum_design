import { useState } from "react";
import { router } from "expo-router";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { AppleAuthButton } from "../../src/components/AppleAuthButton";
import { GoogleAuthButton } from "../../src/components/GoogleAuthButton";
import { MegrumLogo } from "../../src/components/MegrumLogo";
import { PrimaryButton } from "../../src/components/PrimaryButton";
import { Screen } from "../../src/components/Screen";
import { useAuth } from "../../src/auth/AuthProvider";
import { megrumColors, megrumRadii } from "../../src/theme/tokens";

export default function WelcomeScreen() {
  const { configured, enterPreview } = useAuth();
  const [termsAccepted, setTermsAccepted] = useState(false);
  const [termsError, setTermsError] = useState<string | null>(null);

  function toggleTerms() {
    setTermsAccepted((current) => !current);
    setTermsError(null);
  }

  return (
    <Screen bottomInset={false} contentStyle={styles.screen} scroll={false} topInset={false}>
      <View style={styles.hero}>
        <View style={styles.glowLavender} />
        <View style={styles.glowSky} />
        <MegrumLogo size={76} />
        <Text style={styles.title}>Megrum</Text>
        <Text style={styles.copy}>
          グッズ交換を、{"\n"}現地で、もっと簡単に。
        </Text>
      </View>

      <View style={styles.actions}>
        <PrimaryButton onPress={() => router.push("/login")}>
          メールアドレスでログイン
        </PrimaryButton>

        <View style={styles.divider}>
          <View style={styles.dividerLine} />
          <Text style={styles.dividerText}>はじめての方</Text>
          <View style={styles.dividerLine} />
        </View>

        <View style={styles.termsRow}>
          <Pressable
            accessibilityRole="checkbox"
            accessibilityState={{ checked: termsAccepted }}
            onPress={toggleTerms}
            style={styles.checkboxHit}
          >
            <View style={[styles.checkbox, termsAccepted ? styles.checkboxActive : null]}>
              {termsAccepted ? <Text style={styles.checkText}>✓</Text> : null}
            </View>
          </Pressable>
          <Text style={styles.termsText}>
            <Text
              onPress={() => router.push("/legal/terms")}
              style={styles.termsLink}
            >
              利用規約
            </Text>
            と
            <Text
              onPress={() => router.push("/legal/privacy")}
              style={styles.termsLink}
            >
              プライバシーポリシー
            </Text>
            に同意します
          </Text>
        </View>
        {termsError ? <Text style={styles.termsError}>{termsError}</Text> : null}

        <PrimaryButton
          variant="secondary"
          disabled={!termsAccepted}
          onPress={() => router.push({ pathname: "/signup", params: { terms: "1" } })}
        >
          メールアドレスで新規登録
        </PrimaryButton>
        <AppleAuthButton
          disabled={!termsAccepted}
          mode="signUp"
          onError={(message) => setTermsError(message)}
        />
        <GoogleAuthButton
          disabled={!termsAccepted}
          mode="signUp"
          onError={(message) => setTermsError(message)}
        />
        {!configured ? (
          <Pressable
            accessibilityRole="button"
            onPress={() => {
              enterPreview();
            }}
            style={styles.previewButton}
          >
            <Text style={styles.previewText}>画面だけプレビューする</Text>
          </Pressable>
        ) : null}
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    justifyContent: "space-between",
    paddingBottom: 28,
    paddingTop: 58,
  },
  hero: {
    alignItems: "center",
    flex: 1,
    justifyContent: "center",
    minHeight: 254,
    overflow: "hidden",
  },
  glowLavender: {
    backgroundColor: "rgba(166,149,216,0.16)",
    borderRadius: 999,
    height: 230,
    position: "absolute",
    right: -80,
    top: 24,
    width: 230,
  },
  glowSky: {
    backgroundColor: "rgba(168,212,230,0.16)",
    borderRadius: 999,
    bottom: 44,
    height: 250,
    left: -96,
    position: "absolute",
    width: 250,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 32,
    fontWeight: "900",
    letterSpacing: 0,
    marginTop: 18,
  },
  copy: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "800",
    lineHeight: 22,
    marginTop: 8,
    textAlign: "center",
  },
  actions: {
    gap: 8,
  },
  divider: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
    marginVertical: 2,
  },
  dividerLine: {
    backgroundColor: "rgba(58,50,74,0.12)",
    flex: 1,
    height: 1,
  },
  dividerText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
  },
  termsRow: {
    alignItems: "flex-start",
    backgroundColor: "rgba(255,255,255,0.78)",
    borderColor: "rgba(166,149,216,0.22)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    flexDirection: "row",
    gap: 9,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  checkbox: {
    alignItems: "center",
    borderColor: "rgba(58,50,74,0.22)",
    borderRadius: 5,
    borderWidth: 1.5,
    height: 20,
    justifyContent: "center",
    marginTop: 1,
    width: 20,
  },
  checkboxHit: {
    paddingRight: 1,
  },
  checkboxActive: {
    backgroundColor: megrumColors.lavender,
    borderColor: megrumColors.lavender,
  },
  checkText: {
    color: "#fff",
    fontSize: 13,
    fontWeight: "900",
    lineHeight: 16,
  },
  termsText: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
  },
  termsLink: {
    color: megrumColors.lavender,
    fontWeight: "900",
  },
  termsError: {
    color: megrumColors.warn,
    fontSize: 11,
    fontWeight: "900",
    lineHeight: 16,
    marginTop: -3,
    textAlign: "center",
  },
  previewButton: {
    alignItems: "center",
    borderRadius: megrumRadii.md,
    paddingVertical: 8,
  },
  previewText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
});
