"use client";

import { useState } from "react";
import Link from "next/link";
import { signup } from "@/app/auth/actions";
import { PrimaryButton } from "@/components/auth/PrimaryButton";

// パスワード強度判定（モックアップ準拠：4段階バー）
function getPasswordStrength(pw: string): {
  level: number;
  label: string;
  color: string;
  textColor: string;
} {
  if (!pw)
    return { level: 0, label: "", color: "bg-gray-200", textColor: "" };
  if (pw.length < 8)
    return {
      level: 1,
      label: "弱い",
      color: "bg-red-400",
      textColor: "text-red-500",
    };

  const hasLetter = /[a-zA-Z]/.test(pw);
  const hasDigit = /\d/.test(pw);
  const hasSymbol = /[^a-zA-Z\d]/.test(pw);

  if (hasLetter && hasDigit && hasSymbol && pw.length >= 12)
    return {
      level: 4,
      label: "最強",
      color: "bg-emerald-500",
      textColor: "text-emerald-600",
    };
  if (hasLetter && hasDigit)
    return {
      level: 3,
      label: "強い",
      color: "bg-emerald-500",
      textColor: "text-emerald-600",
    };
  if (hasLetter || hasDigit)
    return {
      level: 2,
      label: "普通",
      color: "bg-yellow-400",
      textColor: "text-yellow-600",
    };
  return {
    level: 1,
    label: "弱い",
    color: "bg-red-400",
    textColor: "text-red-500",
  };
}

export function SignUpForm() {
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  const [handle, setHandle] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [passwordConfirm, setPasswordConfirm] = useState("");
  const [acceptedTerms, setAcceptedTerms] = useState(false);

  const strength = getPasswordStrength(password);
  const passwordsMatch =
    passwordConfirm === "" || password === passwordConfirm;
  const canSubmit =
    handle.length >= 3 &&
    email.includes("@") &&
    password.length >= 8 &&
    password === passwordConfirm &&
    acceptedTerms;

  async function onSubmit(formData: FormData) {
    if (!passwordsMatch) {
      setFieldErrors({ password_confirm: "パスワードが一致しません" });
      return;
    }

    setPending(true);
    setError(null);
    setFieldErrors({});

    // display_name はハンドル名で初期化（onboarding で変更可能）
    formData.set("display_name", handle);

    const result = await signup(formData);

    setPending(false);
    if (result?.error) setError(result.error);
    if (result?.fieldErrors) setFieldErrors(result.fieldErrors);
  }

  return (
    <form action={onSubmit} className="space-y-4">
      {/* ハンドル名 */}
      <div>
        <label
          htmlFor="handle"
          className="block text-sm font-bold text-gray-900"
        >
          ハンドル名
        </label>
        <div className="mt-2 flex rounded-xl border border-gray-200 bg-white focus-within:border-purple-400 focus-within:ring-1 focus-within:ring-purple-300">
          <span className="inline-flex items-center pl-4 pr-1 text-base font-medium text-gray-500">
            @
          </span>
          <input
            id="handle"
            name="handle"
            type="text"
            required
            value={handle}
            onChange={(e) => setHandle(e.target.value.toLowerCase())}
            minLength={3}
            maxLength={20}
            pattern="[a-z0-9_]+"
            placeholder="megrum_xx"
            className="block w-full rounded-r-xl px-1 py-3 text-base text-gray-900 placeholder:text-gray-400 focus:outline-none"
          />
        </div>
        <p className="mt-1.5 text-xs text-gray-500">
          @から始まる英数字、後から変更可能
        </p>
        {fieldErrors.handle && (
          <p className="mt-1 text-xs text-red-600">{fieldErrors.handle}</p>
        )}
      </div>

      {/* メールアドレス */}
      <div>
        <label
          htmlFor="email"
          className="block text-sm font-bold text-gray-900"
        >
          メールアドレス
        </label>
        <input
          id="email"
          name="email"
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          autoComplete="email"
          placeholder="example@email.com"
          className="mt-2 block w-full rounded-xl border border-gray-200 bg-white px-4 py-3 text-base text-gray-900 placeholder:text-gray-400 focus:border-purple-400 focus:outline-none focus:ring-1 focus:ring-purple-300"
        />
        {fieldErrors.email && (
          <p className="mt-1 text-xs text-red-600">{fieldErrors.email}</p>
        )}
      </div>

      {/* パスワード */}
      <div>
        <label
          htmlFor="password"
          className="block text-sm font-bold text-gray-900"
        >
          パスワード
        </label>
        <input
          id="password"
          name="password"
          type="password"
          required
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          minLength={8}
          autoComplete="new-password"
          placeholder="8文字以上、英数字混在"
          className="mt-2 block w-full rounded-xl border border-gray-200 bg-white px-4 py-3 text-base text-gray-900 placeholder:text-gray-400 focus:border-purple-400 focus:outline-none focus:ring-1 focus:ring-purple-300"
        />
        {/* 強度メーター（モックアップ準拠：4本バー） */}
        <div className="mt-2 flex items-center gap-1 pl-0.5">
          {[1, 2, 3, 4].map((i) => (
            <div
              key={i}
              className={`h-[3px] flex-1 rounded transition-colors ${
                i <= strength.level ? strength.color : "bg-gray-200"
              }`}
            />
          ))}
          {strength.label && (
            <span
              className={`ml-2 text-[10px] font-semibold ${strength.textColor}`}
            >
              {strength.label}
            </span>
          )}
        </div>
        {fieldErrors.password && (
          <p className="mt-1 text-xs text-red-600">{fieldErrors.password}</p>
        )}
      </div>

      {/* パスワード（確認） */}
      <div>
        <label
          htmlFor="password_confirm"
          className="block text-sm font-bold text-gray-900"
        >
          パスワード（確認）
        </label>
        <input
          id="password_confirm"
          name="password_confirm"
          type="password"
          required
          value={passwordConfirm}
          onChange={(e) => setPasswordConfirm(e.target.value)}
          autoComplete="new-password"
          placeholder="もう一度入力"
          className={`mt-2 block w-full rounded-xl border bg-white px-4 py-3 text-base text-gray-900 placeholder:text-gray-400 focus:outline-none focus:ring-1 ${
            passwordsMatch
              ? "border-gray-200 focus:border-purple-400 focus:ring-purple-300"
              : "border-red-300 focus:border-red-400 focus:ring-red-300"
          }`}
        />
        {!passwordsMatch && (
          <p className="mt-1 text-xs text-red-600">
            パスワードが一致しません
          </p>
        )}
      </div>

      {/* 利用規約同意 */}
      <div className="pt-1">
        <label className="flex items-start gap-2.5 text-sm">
          <input
            type="checkbox"
            name="accepted_terms"
            required
            checked={acceptedTerms}
            onChange={(e) => setAcceptedTerms(e.target.checked)}
            className="mt-0.5 h-4 w-4 rounded border-gray-300 text-purple-500 focus:ring-purple-400"
          />
          <span className="leading-relaxed text-gray-700">
            <Link
              href="/terms"
              target="_blank"
              className="font-medium text-purple-600 underline hover:text-purple-700"
            >
              利用規約
            </Link>
            と
            <Link
              href="/privacy"
              target="_blank"
              className="font-medium text-purple-600 underline hover:text-purple-700"
            >
              プライバシーポリシー
            </Link>
            に同意します
          </span>
        </label>
        {fieldErrors.accepted_terms && (
          <p className="mt-1 text-xs text-red-600">
            {fieldErrors.accepted_terms}
          </p>
        )}
      </div>

      {/* 全体エラー */}
      {error && (
        <div className="rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* 送信ボタン（モックアップ「次へ」） */}
      <PrimaryButton
        type="submit"
        disabled={!canSubmit}
        pending={pending}
        pendingLabel="登録中..."
      >
        次へ
      </PrimaryButton>
    </form>
  );
}
