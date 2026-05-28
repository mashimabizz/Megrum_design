// ─────────────────────────────────────────────────────────────
// auth-onboarding.jsx — 認証＋オンボーディングフロー（12画面）
// Welcome → Signup → Email verify → Login → Reset → Account delete
// + Onboarding (gender → group → member → AW → done)
// + Google OAuth経由 同意画面
// ─────────────────────────────────────────────────────────────

const AO_C = (t) => ({
  lavender: t.primary,
  sky: t.secondary,
  pink: t.accent,
  ink: '#3a324a',
  mute: 'rgba(58,50,74,0.55)',
  hint: 'rgba(58,50,74,0.4)',
  subtle: 'rgba(58,50,74,0.06)',
  divide: 'rgba(58,50,74,0.08)',
  bg: '#fbf9fc',
  warn: '#d9826b',
  ok: '#7a9a8a',
  danger: '#d44a4a',
});

// ──────────────────────────────
// Shared components
// ──────────────────────────────

function AOLogo({ colors: c, size = 64 }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: size * 0.32,
      background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      color: '#fff', fontWeight: 800, fontSize: size * 0.42, letterSpacing: -1,
      boxShadow: `0 8px 24px ${c.lavender}40`,
      fontFamily: '"Inter Tight", system-ui',
    }}>Mg</div>
  );
}

function AOHeaderBack({ colors: c, title, sub, progress }) {
  return (
    <div style={{
      position: 'absolute', top: 0, left: 0, right: 0,
      padding: '54px 18px 14px',
      background: 'rgba(255,255,255,0.94)',
      backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
      borderBottom: `0.5px solid ${c.divide}`,
      zIndex: 10,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <svg width="10" height="16" viewBox="0 0 10 16" style={{ flex: '0 0 auto' }}>
          <path d="M8 1L2 8l6 7" stroke={c.ink} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 15, fontWeight: 700, color: c.ink }}>{title}</div>
          {sub && <div style={{ fontSize: 11, color: c.mute, marginTop: 1 }}>{sub}</div>}
        </div>
        {progress && (
          <div style={{ fontSize: 11, color: c.mute, fontVariantNumeric: 'tabular-nums' }}>{progress}</div>
        )}
      </div>
    </div>
  );
}

function AOInput({ colors: c, label, placeholder, type = 'text', value, hint, error }) {
  return (
    <div style={{ marginBottom: 14 }}>
      {label && <div style={{ fontSize: 12, fontWeight: 600, color: c.ink, marginBottom: 6 }}>{label}</div>}
      <div style={{
        background: '#fff',
        border: `0.5px solid ${error ? c.danger : c.divide}`,
        borderRadius: 12,
        padding: '14px 16px', fontSize: 14,
        display: 'flex', alignItems: 'center', gap: 8,
      }}>
        <span style={{ flex: 1, color: value ? c.ink : c.hint }}>{value || placeholder}</span>
        {type === 'password' && (
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke={c.mute} strokeWidth="1.4">
            <path d="M1 8s2.5-5 7-5 7 5 7 5-2.5 5-7 5-7-5-7-5z"/>
            <circle cx="8" cy="8" r="2"/>
          </svg>
        )}
      </div>
      {error && <div style={{ fontSize: 11, color: c.danger, marginTop: 5 }}>{error}</div>}
      {hint && !error && <div style={{ fontSize: 11, color: c.mute, marginTop: 5 }}>{hint}</div>}
    </div>
  );
}

function AOPrimaryButton({ colors: c, label, disabled, danger }) {
  return (
    <button style={{
      width: '100%', padding: '15px 24px', borderRadius: 14,
      background: disabled
        ? `${c.lavender}55`
        : danger
          ? c.danger
          : `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
      color: '#fff', border: 0, fontFamily: 'inherit',
      fontSize: 14, fontWeight: 700,
      boxShadow: disabled ? 'none' : danger ? `0 4px 14px ${c.danger}55` : `0 4px 14px ${c.lavender}55`,
      letterSpacing: 0.3, cursor: 'pointer',
    }}>{label}</button>
  );
}

function AOSecondaryButton({ colors: c, label, icon }) {
  return (
    <button style={{
      width: '100%', padding: '13px 24px', borderRadius: 14,
      background: '#fff', color: c.ink, border: `1px solid ${c.divide}`,
      fontFamily: 'inherit', fontSize: 14, fontWeight: 600,
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      cursor: 'pointer',
    }}>
      {icon}
      {label}
    </button>
  );
}

function AOGoogleIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18">
      <path d="M17.6 9.2c0-.6-.05-1.2-.15-1.7H9v3.3h4.85c-.21 1.13-.85 2.08-1.81 2.72v2.26h2.92c1.71-1.57 2.69-3.88 2.69-6.58z" fill="#4285F4"/>
      <path d="M9 18c2.43 0 4.47-.81 5.96-2.18l-2.92-2.26c-.81.54-1.83.86-3.04.86-2.34 0-4.32-1.58-5.03-3.7H.97v2.32C2.45 15.98 5.48 18 9 18z" fill="#34A853"/>
      <path d="M3.97 10.7c-.18-.54-.28-1.12-.28-1.7s.1-1.16.28-1.7V4.96H.97C.35 6.18 0 7.55 0 9s.35 2.82.97 4.04l3-2.32V10.7z" fill="#FBBC05"/>
      <path d="M9 3.58c1.32 0 2.5.45 3.44 1.35l2.58-2.58C13.46.89 11.42 0 9 0 5.48 0 2.45 2.02.97 4.96l3 2.32C4.68 5.16 6.66 3.58 9 3.58z" fill="#EA4335"/>
    </svg>
  );
}

function AOCheckbox({ colors: c, checked, label, link }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'flex-start', gap: 10,
      padding: '8px 0', cursor: 'pointer',
    }}>
      <div style={{
        width: 18, height: 18, borderRadius: 5, flex: '0 0 auto',
        marginTop: 1,
        background: checked ? c.lavender : '#fff',
        border: `1.5px solid ${checked ? c.lavender : c.divide}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {checked && (
          <svg width="10" height="10" viewBox="0 0 10 10">
            <path d="M2 5l2 2 4-5" stroke="#fff" strokeWidth="1.8" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        )}
      </div>
      <div style={{ fontSize: 12, color: c.ink, lineHeight: 1.5 }}>
        {link ? (
          <span><span style={{ color: c.lavender, textDecoration: 'underline' }}>利用規約</span>と<span style={{ color: c.lavender, textDecoration: 'underline' }}>プライバシーポリシー</span>に同意する</span>
        ) : label}
      </div>
    </div>
  );
}

function AOProgressDots({ colors: c, current, total }) {
  return (
    <div style={{ display: 'flex', gap: 5, justifyContent: 'center', marginBottom: 18 }}>
      {Array.from({ length: total }).map((_, i) => (
        <div key={i} style={{
          width: i === current ? 22 : 6, height: 6, borderRadius: 3,
          background: i <= current ? c.lavender : c.subtle,
          transition: 'all .2s',
        }} />
      ))}
    </div>
  );
}

// ──────────────────────────────
// 1. Welcome / Splash
// ──────────────────────────────
function AOWelcome({ tweaks }) {
  const c = AO_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: `linear-gradient(180deg, ${c.lavender}22 0%, ${c.sky}14 45%, #fff 100%)`,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, padding: '88px 28px 30px', boxSizing: 'border-box',
      display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
        <AOLogo colors={c} size={88} />
        <div style={{ fontSize: 34, fontWeight: 800, marginTop: 24, letterSpacing: 0.5 }}>Megrum</div>
        <div style={{ fontSize: 13, color: c.mute, marginTop: 10, textAlign: 'center', lineHeight: 1.7, maxWidth: 280 }}>
          グッズ交換を、<br/>現地で、もっと簡単に。
        </div>
      </div>
      <div>
        <AOPrimaryButton colors={c} label="メールアドレスで新規登録" />
        <div style={{ height: 10 }} />
        <AOSecondaryButton colors={c} label="Googleで新規登録" icon={<AOGoogleIcon />} />
        <div style={{ textAlign: 'center', fontSize: 13, color: c.mute, marginTop: 22 }}>
          すでにアカウントをお持ちの方は <span style={{ color: c.lavender, fontWeight: 700 }}>ログイン</span>
        </div>
      </div>
    </div>
  );
}

// ──────────────────────────────
// 2. Signup (email)
// ──────────────────────────────
function AOSignup({ tweaks }) {
  const c = AO_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      <AOHeaderBack colors={c} title="新規登録" />
      <div style={{ padding: '0 22px' }}>
        <div style={{ fontSize: 22, fontWeight: 800, marginBottom: 6 }}>はじめまして</div>
        <div style={{ fontSize: 12, color: c.mute, marginBottom: 22, lineHeight: 1.6 }}>
          メールアドレスとパスワードを設定して、Megrum を始めましょう
        </div>
        <AOInput colors={c} label="ハンドル名" placeholder="@megrum_xx" hint="@から始まる英数字、後から変更可能" />
        <AOInput colors={c} label="メールアドレス" placeholder="example@email.com" />
        <AOInput colors={c} label="パスワード" placeholder="8文字以上、英数字混在" type="password" />
        <div style={{
          display: 'flex', gap: 4, marginTop: -10, marginBottom: 14,
          paddingLeft: 2,
        }}>
          {[1,2,3,4].map(i => (
            <div key={i} style={{
              flex: 1, height: 3, borderRadius: 2,
              background: i <= 3 ? c.ok : c.subtle,
            }} />
          ))}
          <span style={{ fontSize: 10, color: c.ok, fontWeight: 600, marginLeft: 6 }}>強い</span>
        </div>
        <AOInput colors={c} label="パスワード（確認）" placeholder="もう一度入力" type="password" />
        <div style={{ height: 4 }} />
        <AOCheckbox colors={c} checked={true} link />
        <div style={{ height: 18 }} />
        <AOPrimaryButton colors={c} label="次へ" />
      </div>
    </div>
  );
}

// ──────────────────────────────
// 3. Email verification - sent
// ──────────────────────────────
function AOEmailSent({ tweaks }) {
  const c = AO_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box',
    }}>
      <AOHeaderBack colors={c} title="メール認証" />
      <div style={{ padding: '40px 28px', textAlign: 'center' }}>
        <div style={{
          width: 80, height: 80, borderRadius: 40, margin: '0 auto 20px',
          background: `linear-gradient(135deg, ${c.lavender}22, ${c.sky}22)`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="40" height="40" viewBox="0 0 40 40" fill="none" stroke={c.lavender} strokeWidth="1.8">
            <rect x="6" y="10" width="28" height="20" rx="3"/>
            <path d="M6 13l14 9 14-9"/>
          </svg>
        </div>
        <div style={{ fontSize: 20, fontWeight: 800, marginBottom: 8 }}>確認メールを送りました</div>
        <div style={{ fontSize: 13, color: c.mute, marginBottom: 24, lineHeight: 1.7 }}>
          下記のメールアドレスに認証用のリンクを送りました。<br/>
          メール内のリンクをタップして、認証を完了してください。
        </div>
        <div style={{
          padding: '12px 16px', borderRadius: 12,
          background: '#fff', border: `0.5px solid ${c.divide}`,
          fontSize: 13, fontWeight: 600, marginBottom: 20,
          display: 'inline-block',
        }}>
          hana@example.com
        </div>
        <div style={{
          padding: '12px 14px', borderRadius: 10,
          background: `${c.pink}14`,
          fontSize: 11, color: c.ink, lineHeight: 1.5,
          marginBottom: 24, textAlign: 'left',
        }}>
          <b>📧 メールが届かない場合</b><br/>
          迷惑メールフォルダもご確認ください。それでも見つからない場合は、再送信または別のメールアドレスをお試しください。
        </div>
        <AOSecondaryButton colors={c} label="再送信する（あと 60 秒）" />
        <div style={{ height: 10 }} />
        <button style={{
          background: 'transparent', border: 0, color: c.lavender,
          fontFamily: 'inherit', fontSize: 13, fontWeight: 600,
          padding: 8, cursor: 'pointer',
        }}>
          メールアドレスを変更する
        </button>
      </div>
    </div>
  );
}

// ──────────────────────────────
// 4. Email verification - confirmed
// ──────────────────────────────
function AOEmailConfirmed({ tweaks }) {
  const c = AO_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: `linear-gradient(180deg, ${c.lavender}18 0%, ${c.sky}10 50%, #fff 100%)`,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, padding: '88px 28px 30px', boxSizing: 'border-box',
      display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', textAlign: 'center' }}>
        <div style={{
          width: 100, height: 100, borderRadius: 50, marginBottom: 24,
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 12px 32px ${c.lavender}55`,
        }}>
          <svg width="50" height="50" viewBox="0 0 50 50" fill="none" stroke="#fff" strokeWidth="3">
            <path d="M14 26l8 8 16-18" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
        <div style={{ fontSize: 24, fontWeight: 800, marginBottom: 10 }}>認証完了！</div>
        <div style={{ fontSize: 13, color: c.mute, lineHeight: 1.7, maxWidth: 280 }}>
          メールアドレスの認証が完了しました。<br/>
          続けてプロフィールを設定しましょう。
        </div>
      </div>
      <div>
        <AOPrimaryButton colors={c} label="プロフィール設定へ進む" />
      </div>
    </div>
  );
}

// ──────────────────────────────
// 5. Login
// ──────────────────────────────
function AOLogin({ tweaks }) {
  const c = AO_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      <AOHeaderBack colors={c} title="ログイン" />
      <div style={{ padding: '32px 22px 0' }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', marginBottom: 28 }}>
          <AOLogo colors={c} size={60} />
          <div style={{ fontSize: 13, color: c.mute, marginTop: 14 }}>おかえりなさい</div>
        </div>
        <AOInput colors={c} label="メールアドレス" placeholder="example@email.com" value="hana@example.com" />
        <AOInput colors={c} label="パスワード" placeholder="パスワードを入力" type="password" value="••••••••••" />
        <div style={{ textAlign: 'right', marginTop: -8, marginBottom: 18 }}>
          <span style={{ color: c.lavender, fontSize: 12, fontWeight: 600 }}>パスワードを忘れた方</span>
        </div>
        <AOPrimaryButton colors={c} label="ログイン" />
        <div style={{
          display: 'flex', alignItems: 'center', gap: 12,
          margin: '20px 0',
        }}>
          <div style={{ flex: 1, height: 1, background: c.divide }} />
          <span style={{ fontSize: 11, color: c.mute }}>または</span>
          <div style={{ flex: 1, height: 1, background: c.divide }} />
        </div>
        <AOSecondaryButton colors={c} label="Googleでログイン" icon={<AOGoogleIcon />} />
        <div style={{ textAlign: 'center', fontSize: 13, color: c.mute, marginTop: 24 }}>
          アカウントをお持ちでない方は <span style={{ color: c.lavender, fontWeight: 700 }}>新規登録</span>
        </div>
      </div>
    </div>
  );
}

// ──────────────────────────────
// 6. Password Reset
// ──────────────────────────────
function AOPasswordReset({ tweaks }) {
  const c = AO_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box',
    }}>
      <AOHeaderBack colors={c} title="パスワードリセット" />
      <div style={{ padding: '32px 22px 0' }}>
        <div style={{ fontSize: 20, fontWeight: 800, marginBottom: 10 }}>
          パスワードを再設定します
        </div>
        <div style={{ fontSize: 12, color: c.mute, marginBottom: 22, lineHeight: 1.7 }}>
          ご登録のメールアドレスを入力してください。<br/>
          パスワードリセット用のリンクをお送りします。
        </div>
        <AOInput colors={c} label="メールアドレス" placeholder="example@email.com" />
        <div style={{ height: 6 }} />
        <AOPrimaryButton colors={c} label="リセットメールを送信" />
      </div>
    </div>
  );
}

// ──────────────────────────────
// 7. Account Delete (2-step confirmation)
// ──────────────────────────────
function AOAccountDelete({ tweaks }) {
  const c = AO_C(tweaks);
  const reasons = [
    'Megrum をあまり使わなくなった',
    '別のアカウントを作りたい',
    'プライバシーが心配',
    '機能に不満がある',
    'その他',
  ];
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      <AOHeaderBack colors={c} title="アカウント削除" sub="ステップ 1/2" />
      <div style={{ padding: '20px 22px 0' }}>
        <div style={{
          padding: 14, borderRadius: 12,
          background: `${c.warn}18`,
          border: `1px solid ${c.warn}55`,
          fontSize: 12, color: c.ink, lineHeight: 1.6,
          marginBottom: 18,
        }}>
          <b style={{ color: c.warn }}>⚠️ 削除すると元に戻せません</b><br/>
          取引履歴・コレクション・wish・登録した在庫がすべて消えます。
        </div>
        <div style={{ fontSize: 13, fontWeight: 700, marginBottom: 12 }}>
          差し支えなければ理由を教えてください（任意・複数選択可）
        </div>
        {reasons.map((r, i) => (
          <div key={i} style={{
            padding: '12px 14px', borderRadius: 12,
            background: '#fff', border: `0.5px solid ${i === 0 ? c.warn : c.divide}`,
            fontSize: 13, marginBottom: 8,
            display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <div style={{
              width: 18, height: 18, borderRadius: 5,
              background: i === 0 ? c.warn : '#fff',
              border: `1.5px solid ${i === 0 ? c.warn : c.divide}`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              {i === 0 && <svg width="10" height="10" viewBox="0 0 10 10"><path d="M2 5l2 2 4-5" stroke="#fff" strokeWidth="1.8" fill="none"/></svg>}
            </div>
            {r}
          </div>
        ))}
        <div style={{ height: 16 }} />
        <AOPrimaryButton colors={c} label="次へ" danger />
      </div>
    </div>
  );
}

// ──────────────────────────────
// 8. Onboarding - Gender selection
// ──────────────────────────────
function AOOnboardGender({ tweaks }) {
  const c = AO_C(tweaks);
  const opts = ['女性', '男性', 'その他', '回答しない'];
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box',
      display: 'flex', flexDirection: 'column',
    }}>
      <AOHeaderBack colors={c} title="プロフィール設定" sub="マッチングの安全性のため" progress="1/4" />
      <div style={{ padding: '24px 22px 0', flex: 1 }}>
        <AOProgressDots colors={c} current={0} total={4} />
        <div style={{ fontSize: 22, fontWeight: 800, marginBottom: 8 }}>
          性別を教えてください
        </div>
        <div style={{ fontSize: 12, color: c.mute, marginBottom: 24, lineHeight: 1.6 }}>
          マッチング前のプロフィールに表示されます。<br/>
          現地交換時の安全性のために必要な情報です。
        </div>
        {opts.map((o, i) => (
          <div key={i} style={{
            padding: '16px 18px', borderRadius: 14,
            background: i === 0 ? `${c.lavender}14` : '#fff',
            border: `1.5px solid ${i === 0 ? c.lavender : c.divide}`,
            fontSize: 14, fontWeight: i === 0 ? 700 : 500,
            marginBottom: 10,
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{
              width: 22, height: 22, borderRadius: 11,
              background: i === 0 ? c.lavender : '#fff',
              border: `1.8px solid ${i === 0 ? c.lavender : c.divide}`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              {i === 0 && <div style={{ width: 8, height: 8, borderRadius: 4, background: '#fff' }} />}
            </div>
            {o}
          </div>
        ))}
      </div>
      <div style={{ padding: '0 22px' }}>
        <AOPrimaryButton colors={c} label="次へ" />
      </div>
    </div>
  );
}

// ──────────────────────────────
// 9. Onboarding - Oshi selection (cross-genre: groups + works)
// ──────────────────────────────
function AOOnboardGroup({ tweaks }) {
  const c = AO_C(tweaks);
  const genres = [
    { id: 'all', label: 'すべて', active: true },
    { id: 'kpop', label: 'K-POP' },
    { id: 'anime', label: 'アニメ' },
    { id: 'game', label: 'ゲーム' },
    { id: '25d', label: '2.5次元' },
    { id: 'vtuber', label: 'VTuber' },
    { id: 'jp', label: '邦アイ' },
  ];
  const oshis = [
    { name: 'LUMENA', sub: 'K-POP・グループ', genre: 'kpop', selected: true, popular: true, latin: true },
    { name: '呪術廻戦', sub: 'アニメ・作品', genre: 'anime', popular: true },
    { name: '推しの子', sub: 'アニメ・作品', genre: 'anime', popular: true },
    { name: 'BTS', sub: 'K-POP・グループ', genre: 'kpop', popular: true, latin: true },
    { name: 'ハイキュー!! 舞台', sub: '2.5次元・舞台作品', genre: '25d' },
    { name: 'ホロライブ', sub: 'VTuber・事務所', genre: 'vtuber', popular: true },
    { name: '原神', sub: 'ゲーム・作品', genre: 'game' },
    { name: 'TWICE', sub: 'K-POP・グループ', genre: 'kpop', latin: true },
    { name: 'NewJeans', sub: 'K-POP・グループ', genre: 'kpop', latin: true },
    { name: 'にじさんじ', sub: 'VTuber・事務所', genre: 'vtuber' },
  ];
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box',
      display: 'flex', flexDirection: 'column',
    }}>
      <AOHeaderBack colors={c} title="プロフィール設定" sub="あなたの推し（複数選択可）" progress="2/4" />
      <div style={{ padding: '24px 22px 0', flex: 1, overflowY: 'auto' }}>
        <AOProgressDots colors={c} current={1} total={4} />
        <div style={{ fontSize: 22, fontWeight: 800, marginBottom: 8 }}>
          推しは？
        </div>
        <div style={{ fontSize: 12, color: c.mute, marginBottom: 18, lineHeight: 1.6 }}>
          グループ・作品・配信者など、ジャンル横断で選べます
        </div>
        <div style={{
          background: '#fff', borderRadius: 12, padding: '12px 14px',
          fontSize: 13, color: c.mute, marginBottom: 12,
          border: `0.5px solid ${c.divide}`,
          display: 'flex', alignItems: 'center', gap: 8,
        }}>
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke={c.mute} strokeWidth="1.4">
            <circle cx="6" cy="6" r="4.5"/><path d="M9.5 9.5L13 13"/>
          </svg>
          グループ名・作品名で検索
        </div>
        {/* Genre filter chips */}
        <div style={{
          display: 'flex', gap: 6, overflowX: 'auto',
          marginBottom: 14, marginLeft: -22, marginRight: -22,
          padding: '4px 22px 4px',
        }}>
          {genres.map((g, i) => (
            <div key={i} style={{
              padding: '6px 14px', borderRadius: 999,
              background: g.active ? c.lavender : '#fff',
              border: `1px solid ${g.active ? c.lavender : c.divide}`,
              color: g.active ? '#fff' : c.ink,
              fontSize: 12, fontWeight: g.active ? 700 : 500,
              flexShrink: 0, whiteSpace: 'nowrap',
            }}>
              {g.label}
            </div>
          ))}
        </div>
        {oshis.map((o, i) => (
          <div key={i} style={{
            padding: '14px 16px', borderRadius: 14,
            background: o.selected ? `${c.lavender}14` : '#fff',
            border: `1.5px solid ${o.selected ? c.lavender : c.divide}`,
            marginBottom: 8,
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10,
              background: o.selected
                ? `linear-gradient(135deg, ${c.lavender}, ${c.sky})`
                : `${c.lavender}22`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 14, fontWeight: 800,
              color: o.selected ? '#fff' : c.lavender,
              fontFamily: o.latin ? '"Inter Tight", system-ui' : 'inherit',
            }}>
              {o.name[0]}
            </div>
            <div style={{ flex: 1 }}>
              <div style={{
                fontSize: 14, fontWeight: 700,
                fontFamily: o.latin ? '"Inter Tight", system-ui' : 'inherit',
                letterSpacing: o.latin ? 0.3 : 0,
              }}>
                {o.name}
                {o.popular && <span style={{ marginLeft: 8, fontSize: 9, color: c.warn, fontWeight: 700, fontFamily: 'inherit' }}>人気</span>}
              </div>
              <div style={{ fontSize: 11, color: c.mute, marginTop: 1 }}>{o.sub}</div>
            </div>
            <div style={{
              width: 22, height: 22, borderRadius: 11,
              background: o.selected ? c.lavender : '#fff',
              border: `1.8px solid ${o.selected ? c.lavender : c.divide}`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              {o.selected && <svg width="11" height="11" viewBox="0 0 11 11"><path d="M2 5.5l2.5 2.5L9 3" stroke="#fff" strokeWidth="1.8" fill="none" strokeLinecap="round"/></svg>}
            </div>
          </div>
        ))}
        <div style={{
          padding: '12px 14px', borderRadius: 12,
          background: 'transparent',
          border: `1px dashed ${c.divide}`,
          fontSize: 12, color: c.mute, textAlign: 'center',
          marginTop: 6, marginBottom: 18,
        }}>
          + 見つからない場合は運営に追加リクエスト
        </div>
      </div>
      <div style={{ padding: '0 22px' }}>
        <AOPrimaryButton colors={c} label="次へ" />
      </div>
    </div>
  );
}

// ──────────────────────────────
// 10. Onboarding - Character/Member selection (cross-source)
// ──────────────────────────────
function AOOnboardMember({ tweaks }) {
  const c = AO_C(tweaks);
  const sections = [
    {
      oshi: 'LUMENA',
      type: 'K-POP',
      latin: true,
      members: [
        { name: 'スア', en: 'Sua', selected: true, color: c.pink },
        { name: 'ヒナ', en: 'Hina', selected: true, color: c.sky },
        { name: 'リナ', en: 'Rina', color: '#c4a8d8' },
        { name: 'チェ', en: 'Che', color: '#d8c5a8' },
        { name: 'ナナ', en: 'Nana', color: '#a8d8b5' },
        { name: 'ジュン', en: 'Jun', color: '#d8a8c0' },
      ],
    },
    {
      oshi: '呪術廻戦',
      type: 'アニメ',
      members: [
        { name: '五条悟', en: 'Gojo', color: '#a8c5d8' },
        { name: '虎杖悠仁', en: 'Itadori', color: '#d8b5a8' },
        { name: '伏黒恵', en: 'Megumi', color: '#a8d8c5' },
      ],
    },
  ];
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box',
      display: 'flex', flexDirection: 'column',
    }}>
      <AOHeaderBack colors={c} title="プロフィール設定" sub="推しキャラ・推しメン" progress="3/4" />
      <div style={{ padding: '24px 22px 0', flex: 1, overflowY: 'auto' }}>
        <AOProgressDots colors={c} current={2} total={4} />
        <div style={{ fontSize: 22, fontWeight: 800, marginBottom: 8 }}>
          推しキャラ・推しメンは？
        </div>
        <div style={{ fontSize: 12, color: c.mute, marginBottom: 20, lineHeight: 1.6 }}>
          選んだ推しから複数選択可・後から変更可能
        </div>
        {sections.map((sec, si) => (
          <div key={si} style={{ marginBottom: 18 }}>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 8,
              marginBottom: 10, paddingLeft: 2,
            }}>
              <span style={{
                fontSize: 12, fontWeight: 700,
                fontFamily: sec.latin ? '"Inter Tight"' : 'inherit',
                letterSpacing: sec.latin ? 0.3 : 0,
                color: c.ink,
              }}>{sec.oshi}</span>
              <span style={{
                fontSize: 10, color: c.mute, fontWeight: 600,
                padding: '2px 8px', borderRadius: 999,
                background: c.subtle,
              }}>{sec.type}</span>
            </div>
            <div style={{
              display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10,
            }}>
              {sec.members.map((m, i) => (
                <div key={i} style={{
                  padding: 12, borderRadius: 14,
                  background: m.selected ? `${c.lavender}14` : '#fff',
                  border: `1.5px solid ${m.selected ? c.lavender : c.divide}`,
                  textAlign: 'center', position: 'relative',
                }}>
                  <div style={{
                    width: 52, height: 52, borderRadius: 26, margin: '0 auto 6px',
                    background: `linear-gradient(135deg, ${m.color}aa, ${m.color}55)`,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 14, fontWeight: 800, color: c.ink,
                  }}>{m.name[0]}</div>
                  <div style={{ fontSize: 12, fontWeight: 700, lineHeight: 1.2 }}>{m.name}</div>
                  <div style={{ fontSize: 9, color: c.mute, fontFamily: '"Inter Tight"', marginTop: 1 }}>{m.en}</div>
                  {m.selected && (
                    <div style={{
                      position: 'absolute', top: 6, right: 6,
                      width: 18, height: 18, borderRadius: 9,
                      background: c.lavender,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                      <svg width="9" height="9" viewBox="0 0 9 9"><path d="M1.5 4.5l2 2 4-5" stroke="#fff" strokeWidth="1.8" fill="none" strokeLinecap="round"/></svg>
                    </div>
                  )}
                </div>
              ))}
            </div>
            <button style={{
              width: '100%', padding: '8px 12px', borderRadius: 10,
              background: 'transparent', border: `1px dashed ${c.lavender}55`,
              color: c.lavender, fontFamily: 'inherit',
              fontSize: 11, fontWeight: 600, cursor: 'pointer',
              marginTop: 8,
            }}>
              ✦ {sec.oshi} の全員を推しに（箱推し）
            </button>
          </div>
        ))}
      </div>
      <div style={{ padding: '0 22px' }}>
        <AOPrimaryButton colors={c} label="次へ" />
      </div>
    </div>
  );
}

// ──────────────────────────────
// 11. Onboarding - AW initial setup (optional)
// ──────────────────────────────
function AOOnboardAW({ tweaks }) {
  const c = AO_C(tweaks);
  const areas = ['東京', '神奈川', '千葉', '埼玉', '大阪', '愛知', '福岡', 'その他'];
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box',
      display: 'flex', flexDirection: 'column',
    }}>
      <AOHeaderBack colors={c} title="プロフィール設定" sub="主な活動エリア（任意）" progress="4/4" />
      <div style={{ padding: '24px 22px 0', flex: 1 }}>
        <AOProgressDots colors={c} current={3} total={4} />
        <div style={{ fontSize: 22, fontWeight: 800, marginBottom: 8 }}>
          よく行くエリアは？
        </div>
        <div style={{ fontSize: 12, color: c.mute, marginBottom: 20, lineHeight: 1.6 }}>
          現地交換のマッチングに使います。<br/>
          ライブ・イベントごとの詳細はあとで設定できます。
        </div>
        <div style={{ fontSize: 12, fontWeight: 600, color: c.ink, marginBottom: 10 }}>
          活動エリア（複数選択可）
        </div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 22 }}>
          {areas.map((a, i) => (
            <div key={i} style={{
              padding: '8px 14px', borderRadius: 999,
              background: i === 0 ? `${c.lavender}14` : '#fff',
              border: `1.5px solid ${i === 0 ? c.lavender : c.divide}`,
              fontSize: 13, fontWeight: i === 0 ? 700 : 500,
              color: i === 0 ? c.lavender : c.ink,
            }}>
              {a}
            </div>
          ))}
        </div>
        <div style={{
          padding: '14px 16px', borderRadius: 12,
          background: `${c.sky}14`, border: `1px solid ${c.sky}55`,
          fontSize: 12, color: c.ink, lineHeight: 1.6,
        }}>
          <b>💡 ヒント</b><br/>
          AW（合流可能枠）はあとで「プロフ → 自分のAW一覧」から、ライブや物販イベントごとに細かく設定できます。
        </div>
      </div>
      <div style={{ padding: '0 22px' }}>
        <AOPrimaryButton colors={c} label="完了" />
        <div style={{ height: 8 }} />
        <button style={{
          width: '100%', padding: '12px',
          background: 'transparent', border: 0,
          color: c.mute, fontFamily: 'inherit',
          fontSize: 13, fontWeight: 600, cursor: 'pointer',
        }}>
          あとで設定する
        </button>
      </div>
    </div>
  );
}

// ──────────────────────────────
// 12. Onboarding - Done
// ──────────────────────────────
function AOOnboardDone({ tweaks }) {
  const c = AO_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: `linear-gradient(180deg, ${c.lavender}22 0%, ${c.sky}14 50%, #fff 100%)`,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, padding: '70px 22px 30px', boxSizing: 'border-box',
      display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ fontSize: 48, marginBottom: 12 }}>✨</div>
        <div style={{ fontSize: 26, fontWeight: 800, marginBottom: 8, textAlign: 'center' }}>
          Megrum へようこそ！
        </div>
        <div style={{ fontSize: 13, color: c.mute, marginBottom: 26, lineHeight: 1.7, textAlign: 'center' }}>
          @hana_lumi さんのプロフィール設定が完了しました
        </div>
        <div style={{
          padding: 16, borderRadius: 14,
          background: '#fff', border: `0.5px solid ${c.divide}`,
          width: '100%', maxWidth: 320, marginBottom: 24,
        }}>
          <div style={{ fontSize: 11, color: c.mute, fontWeight: 600, marginBottom: 8 }}>あなたの設定</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6, fontSize: 13 }}>
            <span style={{ color: c.mute, fontSize: 11 }}>推し</span>
            <span style={{ fontWeight: 700, fontFamily: '"Inter Tight"', letterSpacing: 0.3 }}>LUMENA</span>
            <span style={{ color: c.mute }}>·</span>
            <span style={{ fontWeight: 600 }}>スア / ヒナ</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13 }}>
            <span style={{ color: c.mute, fontSize: 11 }}>エリア</span>
            <span style={{ fontWeight: 600 }}>東京</span>
          </div>
        </div>
        <div style={{ width: '100%' }}>
          <div style={{ fontSize: 11, color: c.mute, fontWeight: 600, marginBottom: 8, textAlign: 'left' }}>次は何をする？</div>
          {[
            { icon: '🔍', label: 'マッチを探す', sub: 'ホーム画面で交換相手を見つける' },
            { icon: '📦', label: '在庫を登録する', sub: 'グッズを撮影して登録' },
            { icon: '⭐', label: 'wish を登録する', sub: '欲しいグッズを登録' },
          ].map((g, i) => (
            <div key={i} style={{
              padding: '12px 14px', borderRadius: 12,
              background: '#fff', border: `0.5px solid ${c.divide}`,
              fontSize: 13, marginBottom: 8,
              display: 'flex', alignItems: 'center', gap: 12,
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10,
                background: `linear-gradient(135deg, ${c.lavender}22, ${c.sky}22)`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 18,
              }}>{g.icon}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 700 }}>{g.label}</div>
                <div style={{ fontSize: 11, color: c.mute, marginTop: 1 }}>{g.sub}</div>
              </div>
              <svg width="8" height="14" viewBox="0 0 8 14" fill="none" stroke={c.mute} strokeWidth="1.4"><path d="M1 1l6 6-6 6"/></svg>
            </div>
          ))}
        </div>
      </div>
      <div>
        <AOPrimaryButton colors={c} label="ホームに進む" />
      </div>
    </div>
  );
}

// ──────────────────────────────
// 13. Google OAuth - Consent screen (after Google auth)
// ──────────────────────────────
function AOGoogleConsent({ tweaks }) {
  const c = AO_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box',
    }}>
      <AOHeaderBack colors={c} title="新規登録（Google）" />
      <div style={{ padding: '24px 22px 0' }}>
        <div style={{
          padding: '14px 16px', borderRadius: 12,
          background: `${c.ok}14`, border: `1px solid ${c.ok}55`,
          fontSize: 13, color: c.ink, marginBottom: 22,
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <div style={{
            width: 28, height: 28, borderRadius: 14,
            background: c.ok, color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0,
          }}>
            <svg width="14" height="14" viewBox="0 0 14 14"><path d="M2 7l3.5 3.5L12 4" stroke="#fff" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
          </div>
          <div>
            <div style={{ fontWeight: 700 }}>Google認証完了</div>
            <div style={{ fontSize: 11, color: c.mute, marginTop: 2 }}>hana@gmail.com として登録</div>
          </div>
        </div>
        <div style={{ fontSize: 18, fontWeight: 800, marginBottom: 6 }}>
          あと一歩です
        </div>
        <div style={{ fontSize: 12, color: c.mute, marginBottom: 22, lineHeight: 1.6 }}>
          ハンドル名を設定して、利用規約にご同意ください
        </div>
        <AOInput colors={c} label="ハンドル名" placeholder="@megrum_xx" hint="@から始まる英数字、後から変更可能" />
        <div style={{ height: 4 }} />
        <AOCheckbox colors={c} checked={true} link />
        <div style={{ height: 18 }} />
        <AOPrimaryButton colors={c} label="プロフィール設定へ進む" />
      </div>
    </div>
  );
}

// Export to window for HTML to pick up
Object.assign(window, {
  AOWelcome, AOSignup, AOEmailSent, AOEmailConfirmed,
  AOLogin, AOPasswordReset, AOAccountDelete,
  AOOnboardGender, AOOnboardGroup, AOOnboardMember,
  AOOnboardAW, AOOnboardDone, AOGoogleConsent,
});
