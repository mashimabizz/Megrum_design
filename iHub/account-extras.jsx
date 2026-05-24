// ─────────────────────────────────────────────────────────────
// account-extras.jsx — Phase 2 補足画面（8画面）
// プロフィール編集 / 推し設定編集 / ブロックリスト
// 他人のプロフィール表示 / 在庫の公開設定 / 本人確認
// アプリ情報 / アカウント削除完了
// ─────────────────────────────────────────────────────────────

const AE_C = (t) => ({
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

// ─── Shared components ───
function AEHeader({ colors: c, title, sub, back = true, right }) {
  return (
    <div style={{
      position: 'absolute', top: 0, left: 0, right: 0,
      padding: '54px 18px 12px',
      background: 'rgba(255,255,255,0.94)',
      backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
      borderBottom: `0.5px solid ${c.divide}`,
      zIndex: 10,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        {back && (
          <svg width="10" height="16" viewBox="0 0 10 16" style={{ flex: '0 0 auto' }}>
            <path d="M8 1L2 8l6 7" stroke={c.ink} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        )}
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 15, fontWeight: 700, color: c.ink }}>{title}</div>
          {sub && <div style={{ fontSize: 11, color: c.mute, marginTop: 1 }}>{sub}</div>}
        </div>
        {right}
      </div>
    </div>
  );
}

function AESection({ children, label, colors: c, hint }) {
  return (
    <div style={{ marginBottom: 22 }}>
      {label && (
        <div style={{
          fontSize: 11, fontWeight: 700, color: c.mute,
          letterSpacing: 0.4, padding: '0 4px', marginBottom: 8,
          textTransform: 'uppercase',
        }}>{label}</div>
      )}
      <div style={{
        background: '#fff', borderRadius: 14,
        border: `0.5px solid ${c.divide}`, overflow: 'hidden',
      }}>{children}</div>
      {hint && <div style={{ fontSize: 11, color: c.mute, padding: '6px 4px 0', lineHeight: 1.6 }}>{hint}</div>}
    </div>
  );
}

function AERow({ children, last, colors: c, padding = '13px 14px' }) {
  return (
    <div style={{
      padding,
      borderBottom: last ? 'none' : `0.5px solid ${c.divide}`,
    }}>{children}</div>
  );
}

function AEInput({ colors: c, label, value, placeholder, multi }) {
  return (
    <div>
      <div style={{ fontSize: 11, color: c.mute, fontWeight: 600, marginBottom: 4 }}>{label}</div>
      {multi ? (
        <div style={{
          fontSize: 13, color: c.ink, lineHeight: 1.6, minHeight: 60,
          padding: '4px 0',
        }}>{value || <span style={{ color: c.hint }}>{placeholder}</span>}</div>
      ) : (
        <div style={{ fontSize: 14, color: c.ink, fontWeight: 500 }}>
          {value || <span style={{ color: c.hint, fontWeight: 400 }}>{placeholder}</span>}
        </div>
      )}
    </div>
  );
}

function AEPrimaryBtn({ colors: c, label, danger }) {
  return (
    <button style={{
      width: '100%', padding: '14px 24px', borderRadius: 14,
      background: danger ? c.danger : `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
      color: '#fff', border: 0, fontFamily: 'inherit',
      fontSize: 14, fontWeight: 700,
      boxShadow: danger ? `0 4px 14px ${c.danger}55` : `0 4px 14px ${c.lavender}55`,
      letterSpacing: 0.3, cursor: 'pointer',
    }}>{label}</button>
  );
}

function AEBottomNav({ colors: c, active }) {
  const items = [
    { id: 'home', l: 'ホーム' }, { id: 'inv', l: '在庫' },
    { id: 'trade', l: '取引' }, { id: 'wish', l: 'ウィッシュ' },
    { id: 'me', l: 'プロフ' },
  ];
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 0,
      paddingBottom: 22, paddingTop: 6,
      background: 'rgba(255,255,255,0.96)',
      backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
      borderTop: `0.5px solid ${c.divide}`,
      display: 'flex', justifyContent: 'space-around',
    }}>
      {items.map(it => (
        <div key={it.id} style={{
          padding: '6px 10px', textAlign: 'center',
          color: active === it.id ? c.lavender : c.mute,
          fontSize: 10, fontWeight: active === it.id ? 700 : 500,
        }}>
          <div style={{
            width: 22, height: 22, margin: '0 auto 3px',
            borderRadius: 6, background: active === it.id ? `${c.lavender}22` : 'transparent',
          }} />
          {it.l}
        </div>
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 1. プロフィール編集
// ─────────────────────────────────────────────────────────────
function ProfileEdit({ tweaks }) {
  const c = AE_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      <AEHeader colors={c} title="プロフィール編集" right={
        <button style={{
          padding: '6px 14px', borderRadius: 999,
          background: c.lavender, color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 12, fontWeight: 700,
        }}>保存</button>
      } />
      <div style={{ padding: '20px 18px 0' }}>
        {/* Avatar */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 16,
          padding: '18px 16px', background: '#fff',
          borderRadius: 14, border: `0.5px solid ${c.divide}`,
          marginBottom: 22,
        }}>
          <div style={{
            width: 64, height: 64, borderRadius: 32,
            background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: '#fff', fontSize: 22, fontWeight: 800,
          }}>H</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13, fontWeight: 700 }}>アイコン画像</div>
            <div style={{ fontSize: 11, color: c.mute, marginTop: 2 }}>タップで写真を変更</div>
          </div>
          <button style={{
            padding: '7px 12px', borderRadius: 10,
            background: '#fff', color: c.lavender,
            border: `1px solid ${c.lavender}55`,
            fontFamily: 'inherit', fontSize: 11, fontWeight: 700,
          }}>変更</button>
        </div>

        <AESection colors={c} label="基本情報">
          <AERow colors={c}>
            <AEInput colors={c} label="ハンドル名" value="@hana_lumi" />
          </AERow>
          <AERow colors={c}>
            <AEInput colors={c} label="表示名" value="ハナ" />
          </AERow>
          <AERow colors={c} last>
            <AEInput colors={c} label="自己紹介" multi
              value="LUMENA推し ・ スア&ヒナ箱推し / 関東でゆるく交換やってます。よろしくお願いします♡" />
          </AERow>
        </AESection>

        <AESection colors={c} label="公開情報" hint="マッチング前に表示されます">
          <AERow colors={c}>
            <AEInput colors={c} label="性別" value="女性" />
          </AERow>
          <AERow colors={c} last>
            <AEInput colors={c} label="主な活動エリア" value="東京・神奈川" />
          </AERow>
        </AESection>

        <AESection colors={c} label="現地交換時の表示">
          <AERow colors={c} last>
            <AEInput colors={c} label="服装写真（直前更新）"
              value="未設定" placeholder="現地で合流する直前に設定" />
          </AERow>
        </AESection>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 2. 推し設定編集
// ─────────────────────────────────────────────────────────────
function OshiEdit({ tweaks }) {
  const c = AE_C(tweaks);
  const oshis = [
    { name: 'LUMENA', sub: 'K-POP・グループ', members: ['スア', 'ヒナ'] },
    { name: '呪術廻戦', sub: 'アニメ・作品', members: ['五条悟'] },
  ];
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      <AEHeader colors={c} title="推し設定" right={
        <button style={{
          padding: '6px 14px', borderRadius: 999,
          background: c.lavender, color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 12, fontWeight: 700,
        }}>+ 追加</button>
      } />
      <div style={{ padding: '20px 18px 0' }}>
        <div style={{
          padding: '12px 14px', borderRadius: 12,
          background: `${c.lavender}10`, border: `1px solid ${c.lavender}30`,
          fontSize: 12, color: c.ink, lineHeight: 1.6,
          marginBottom: 18,
        }}>
          推しを追加すると、マッチング・コレクション・ホームの基準が更新されます。
        </div>

        {oshis.map((o, i) => (
          <div key={i} style={{
            background: '#fff', borderRadius: 14,
            border: `0.5px solid ${c.divide}`, marginBottom: 12,
            overflow: 'hidden',
          }}>
            <div style={{
              padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12,
              borderBottom: `0.5px solid ${c.divide}`,
            }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontWeight: 700 }}>{o.name}</div>
                <div style={{ fontSize: 11, color: c.mute, marginTop: 1 }}>{o.sub}</div>
              </div>
              <button style={{
                padding: '6px 12px', borderRadius: 10,
                background: 'transparent', color: c.mute,
                border: `1px solid ${c.divide}`,
                fontFamily: 'inherit', fontSize: 11, fontWeight: 600,
              }}>削除</button>
            </div>
            <div style={{ padding: '12px 16px' }}>
              <div style={{ fontSize: 11, color: c.mute, fontWeight: 600, marginBottom: 6 }}>
                推しメンバー・推しキャラ ({o.members.length})
              </div>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
                {o.members.map((m, j) => (
                  <div key={j} style={{
                    padding: '4px 10px', borderRadius: 999,
                    background: `${c.lavender}14`, color: c.lavender,
                    fontSize: 12, fontWeight: 700,
                    display: 'inline-flex', alignItems: 'center', gap: 5,
                  }}>
                    {m}
                    <span style={{ color: c.mute, cursor: 'pointer', fontSize: 14, lineHeight: 1 }}>×</span>
                  </div>
                ))}
                <div style={{
                  padding: '4px 10px', borderRadius: 999,
                  background: 'transparent', color: c.mute,
                  border: `1px dashed ${c.divide}`,
                  fontSize: 12, fontWeight: 500,
                }}>+ 追加</div>
              </div>
            </div>
          </div>
        ))}

        <button style={{
          width: '100%', padding: '14px',
          background: 'transparent', border: `1.5px dashed ${c.lavender}55`,
          color: c.lavender, borderRadius: 14,
          fontFamily: 'inherit', fontSize: 13, fontWeight: 700,
          cursor: 'pointer', marginBottom: 12,
        }}>＋ 推しを追加（グループ・作品）</button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 3. ブロックリスト
// ─────────────────────────────────────────────────────────────
function BlockList({ tweaks }) {
  const c = AE_C(tweaks);
  const blocked = [
    { handle: '@kpop_xx', sub: 'ブロック日 2026/04/15', reason: '嫌がらせ' },
    { handle: '@unknown_user_99', sub: 'ブロック日 2026/03/28', reason: 'スパム' },
  ];
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      <AEHeader colors={c} title="ブロックリスト" sub={`${blocked.length}人をブロック中`} />
      <div style={{ padding: '20px 18px 0' }}>
        <div style={{
          padding: '12px 14px', borderRadius: 12,
          background: `${c.lavender}10`,
          fontSize: 12, color: c.ink, lineHeight: 1.7,
          marginBottom: 18,
        }}>
          ブロックしたユーザーからは打診・メッセージが届かなくなり、マッチングからも除外されます。
        </div>

        {blocked.map((u, i) => (
          <div key={i} style={{
            background: '#fff', borderRadius: 14,
            border: `0.5px solid ${c.divide}`,
            padding: '14px 16px', marginBottom: 10,
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{
              width: 36, height: 36, borderRadius: 18,
              background: c.subtle, color: c.mute,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 14, fontWeight: 700,
            }}>{u.handle[1].toUpperCase()}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 700 }}>{u.handle}</div>
              <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>
                {u.sub} ・ {u.reason}
              </div>
            </div>
            <button style={{
              padding: '6px 12px', borderRadius: 999,
              background: '#fff', color: c.warn,
              border: `1px solid ${c.warn}55`,
              fontFamily: 'inherit', fontSize: 11, fontWeight: 700,
            }}>解除</button>
          </div>
        ))}

        {blocked.length === 0 && (
          <div style={{
            padding: '40px 20px', textAlign: 'center',
            color: c.mute, fontSize: 12,
            background: '#fff', borderRadius: 14,
            border: `0.5px solid ${c.divide}`,
          }}>
            ブロックしているユーザーはいません
          </div>
        )}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 4. 他人のプロフィール表示
// ─────────────────────────────────────────────────────────────
function UserProfile({ tweaks }) {
  const c = AE_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      <AEHeader colors={c} title="プロフ" right={
        <svg width="20" height="20" viewBox="0 0 20 20" fill={c.ink}>
          <circle cx="4" cy="10" r="1.5"/><circle cx="10" cy="10" r="1.5"/><circle cx="16" cy="10" r="1.5"/>
        </svg>
      } />
      <div style={{ padding: '20px 18px 0' }}>
        {/* Profile header */}
        <div style={{
          padding: '20px 18px', borderRadius: 16,
          background: `linear-gradient(135deg, ${c.lavender}33, ${c.sky}33)`,
          border: `0.5px solid ${c.lavender}33`,
          marginBottom: 16,
        }}>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 14 }}>
            <div style={{
              width: 64, height: 64, borderRadius: 32,
              background: `linear-gradient(135deg, ${c.pink}, ${c.lavender})`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              color: '#fff', fontSize: 22, fontWeight: 800,
            }}>L</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 17, fontWeight: 800 }}>@lumi_sua</div>
              <div style={{ fontSize: 11, color: c.mute, marginTop: 2 }}>LUMENA推し ・ スア箱推し</div>
              <div style={{
                display: 'flex', gap: 12, marginTop: 8,
                fontSize: 10.5, color: c.ink,
              }}>
                <span>🌸 関東</span>
                <span>取引マナー◎</span>
              </div>
            </div>
          </div>
          <div style={{
            display: 'flex', gap: 8, marginTop: 14,
            background: 'rgba(255,255,255,0.5)', borderRadius: 12,
            padding: '10px 12px',
          }}>
            <div style={{ flex: 1, textAlign: 'center' }}>
              <div style={{ fontSize: 16, fontWeight: 800, color: c.ink, fontVariantNumeric: 'tabular-nums' }}>★4.8</div>
              <div style={{ fontSize: 9, color: c.mute, marginTop: 1 }}>評価</div>
            </div>
            <div style={{ width: 1, background: c.divide }} />
            <div style={{ flex: 1, textAlign: 'center' }}>
              <div style={{ fontSize: 16, fontWeight: 800, color: c.ink, fontVariantNumeric: 'tabular-nums' }}>127</div>
              <div style={{ fontSize: 9, color: c.mute, marginTop: 1 }}>取引</div>
            </div>
            <div style={{ width: 1, background: c.divide }} />
            <div style={{ flex: 1, textAlign: 'center' }}>
              <div style={{ fontSize: 16, fontWeight: 800, color: c.ink, fontVariantNumeric: 'tabular-nums' }}>0</div>
              <div style={{ fontSize: 9, color: c.mute, marginTop: 1 }}>キャンセル</div>
            </div>
          </div>
        </div>

        {/* Self introduction */}
        <AESection colors={c} label="自己紹介">
          <AERow colors={c} last>
            <div style={{ fontSize: 12.5, color: c.ink, lineHeight: 1.7 }}>
              スア推しです。関東でライブ参戦多め。マナー良い方と長くお取引できたら嬉しいです♡
            </div>
          </AERow>
        </AESection>

        {/* AW preview */}
        <AESection colors={c} label="参戦予定 AW">
          <AERow colors={c}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
                <span style={{
                  fontSize: 9, fontWeight: 800, color: '#fff',
                  background: '#5db26c', padding: '2px 7px', borderRadius: 999,
                }}>● LIVE</span>
                <span style={{ fontSize: 11, color: c.mute }}>今日 4/27 (日)</span>
              </div>
              <div style={{ fontSize: 13, fontWeight: 700, marginBottom: 2 }}>横浜アリーナ</div>
              <div style={{ fontSize: 11, color: c.mute }}>LUMENA WORLD TOUR DAY 2 ・ 開演 18:00</div>
            </div>
          </AERow>
          <AERow colors={c} last>
            <div style={{
              fontSize: 11, color: c.lavender, fontWeight: 700,
              padding: '6px 0',
            }}>あなたと2件の AW が重なっています ─ 同公演にいる可能性大</div>
          </AERow>
        </AESection>

        {/* Footer actions */}
        <div style={{ display: 'flex', gap: 8, marginTop: 8, marginBottom: 18 }}>
          <button style={{
            flex: 1, padding: '13px',
            background: '#fff', color: c.ink, borderRadius: 12,
            border: `1px solid ${c.divide}`,
            fontFamily: 'inherit', fontSize: 13, fontWeight: 700,
          }}>フォロー</button>
          <button style={{
            flex: 2, padding: '13px',
            background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
            color: '#fff', borderRadius: 12, border: 0,
            fontFamily: 'inherit', fontSize: 13, fontWeight: 700,
            boxShadow: `0 4px 12px ${c.lavender}55`,
          }}>DMで打診する</button>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 5. 在庫の公開設定
// ─────────────────────────────────────────────────────────────
function InventoryPrivacy({ tweaks }) {
  const c = AE_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      <AEHeader colors={c} title="在庫の公開設定" />
      <div style={{ padding: '20px 18px 0' }}>
        <div style={{
          padding: '14px 16px', borderRadius: 12,
          background: `${c.lavender}10`,
          fontSize: 12, color: c.ink, lineHeight: 1.7,
          marginBottom: 18,
        }}>
          iHub は <b>「全部公開」モデル</b>です。登録した在庫は全員に検索される前提でマッチングが動きます。譲りたくないものは登録しないか、「自分用キープ」として登録してください。
        </div>

        <AESection colors={c} label="公開ステータス">
          <AERow colors={c} last>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div>
                <div style={{ fontSize: 13, fontWeight: 700 }}>在庫を公開する</div>
                <div style={{ fontSize: 11, color: c.mute, marginTop: 2 }}>
                  ON: 譲る候補がマッチング対象になります
                </div>
              </div>
              <div style={{
                width: 48, height: 28, borderRadius: 14,
                background: c.lavender, position: 'relative',
              }}>
                <div style={{
                  position: 'absolute', top: 2, left: 22,
                  width: 24, height: 24, borderRadius: '50%',
                  background: '#fff', boxShadow: '0 2px 4px rgba(0,0,0,0.15)',
                }} />
              </div>
            </div>
          </AERow>
        </AESection>

        <AESection colors={c} label="一時的な非公開" hint="長期不在・体調不良などで取引できない時にON">
          <AERow colors={c} last>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div>
                <div style={{ fontSize: 13, fontWeight: 700 }}>休止モード</div>
                <div style={{ fontSize: 11, color: c.mute, marginTop: 2 }}>
                  ON: マッチング・打診の受付を停止
                </div>
              </div>
              <div style={{
                width: 48, height: 28, borderRadius: 14,
                background: c.subtle, position: 'relative',
              }}>
                <div style={{
                  position: 'absolute', top: 2, left: 2,
                  width: 24, height: 24, borderRadius: '50%',
                  background: '#fff', boxShadow: '0 2px 4px rgba(0,0,0,0.15)',
                }} />
              </div>
            </div>
          </AERow>
        </AESection>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 6. 本人確認
// ─────────────────────────────────────────────────────────────
function IdentityVerification({ tweaks }) {
  const c = AE_C(tweaks);
  const items = [
    { label: 'メールアドレス', sub: 'hana@example.com', verified: true, time: '2026/04/15 認証済' },
    { label: '電話番号', sub: '未登録', verified: false, time: '本人確認の信頼度UP（任意）' },
    { label: 'X連携', sub: '未連携', verified: false, time: 'プロフィール表示に X リンク追加（任意）' },
  ];
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      <AEHeader colors={c} title="本人確認" />
      <div style={{ padding: '20px 18px 0' }}>
        <div style={{
          padding: '16px', borderRadius: 14,
          background: `linear-gradient(135deg, ${c.ok}14, ${c.sky}14)`,
          border: `1px solid ${c.ok}33`,
          marginBottom: 22, textAlign: 'center',
        }}>
          <div style={{
            width: 48, height: 48, borderRadius: 24,
            background: c.ok, color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            margin: '0 auto 10px',
          }}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2.5">
              <path d="M5 12l5 5 9-11" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
          <div style={{ fontSize: 15, fontWeight: 800, marginBottom: 3 }}>本人確認 完了済</div>
          <div style={{ fontSize: 11, color: c.mute, lineHeight: 1.6 }}>
            メール認証が完了しています。<br/>
            追加認証を行うとプロフィールに「認証済バッジ」が表示されます。
          </div>
        </div>

        <AESection colors={c} label="確認状況">
          {items.map((it, i) => (
            <AERow key={i} colors={c} last={i === items.length - 1}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{
                  width: 32, height: 32, borderRadius: 16,
                  background: it.verified ? c.ok : c.subtle,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: it.verified ? '#fff' : c.mute,
                  flexShrink: 0,
                }}>
                  {it.verified ? (
                    <svg width="14" height="14" viewBox="0 0 14 14"><path d="M3 7l3 3 5-7" stroke="#fff" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
                  ) : (
                    <svg width="14" height="14" viewBox="0 0 14 14"><circle cx="7" cy="7" r="5" stroke={c.mute} strokeWidth="1.5" fill="none"/></svg>
                  )}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 700 }}>{it.label}</div>
                  <div style={{ fontSize: 11, color: c.mute, marginTop: 1 }}>{it.sub}</div>
                  <div style={{ fontSize: 10, color: c.hint, marginTop: 2 }}>{it.time}</div>
                </div>
                {!it.verified && (
                  <button style={{
                    padding: '6px 12px', borderRadius: 10,
                    background: c.lavender, color: '#fff', border: 0,
                    fontFamily: 'inherit', fontSize: 11, fontWeight: 700,
                  }}>追加</button>
                )}
              </div>
            </AERow>
          ))}
        </AESection>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 7. アプリ情報
// ─────────────────────────────────────────────────────────────
function AppInfo({ tweaks }) {
  const c = AE_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      <AEHeader colors={c} title="アプリ情報" />
      <div style={{ padding: '32px 18px 0' }}>
        <div style={{
          textAlign: 'center', marginBottom: 28,
        }}>
          <div style={{
            width: 80, height: 80, borderRadius: 24, margin: '0 auto 14px',
            background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: '#fff', fontSize: 32, fontWeight: 800, letterSpacing: -1,
            boxShadow: `0 8px 24px ${c.lavender}55`,
            fontFamily: '"Inter Tight", system-ui',
          }}>iH</div>
          <div style={{ fontSize: 22, fontWeight: 800, letterSpacing: 0.4 }}>iHub</div>
          <div style={{ fontSize: 12, color: c.mute, marginTop: 4 }}>
            グッズ交換を、現地で、簡単に
          </div>
        </div>

        <AESection colors={c} label="バージョン情報">
          <AERow colors={c}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ fontSize: 13 }}>アプリバージョン</div>
              <div style={{ fontSize: 13, color: c.mute, fontVariantNumeric: 'tabular-nums' }}>1.0.0 (MVP)</div>
            </div>
          </AERow>
          <AERow colors={c}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ fontSize: 13 }}>ビルド番号</div>
              <div style={{ fontSize: 13, color: c.mute, fontVariantNumeric: 'tabular-nums' }}>2026.04.30</div>
            </div>
          </AERow>
          <AERow colors={c} last>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ fontSize: 13 }}>OS / 端末</div>
              <div style={{ fontSize: 13, color: c.mute }}>iOS 17.4 / iPhone 15</div>
            </div>
          </AERow>
        </AESection>

        <AESection colors={c} label="法的情報">
          <AERow colors={c}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ fontSize: 13 }}>利用規約</div>
              <span style={{ color: c.mute }}>›</span>
            </div>
          </AERow>
          <AERow colors={c}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ fontSize: 13 }}>プライバシーポリシー</div>
              <span style={{ color: c.mute }}>›</span>
            </div>
          </AERow>
          <AERow colors={c} last>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ fontSize: 13 }}>特定商取引法に基づく表記</div>
              <span style={{ color: c.mute }}>›</span>
            </div>
          </AERow>
        </AESection>

        <div style={{
          textAlign: 'center', fontSize: 11, color: c.mute, lineHeight: 1.7,
          paddingTop: 20,
        }}>
          © 2026 株式会社iHub<br/>
          All rights reserved.
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 8. アカウント削除完了
// ─────────────────────────────────────────────────────────────
function AccountDeleteComplete({ tweaks }) {
  const c = AE_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: `linear-gradient(180deg, ${c.subtle}, #fff 50%, #fff 100%)`,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, padding: '88px 28px 30px', boxSizing: 'border-box',
      display: 'flex', flexDirection: 'column',
    }}>
      <div style={{
        flex: 1, display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center', textAlign: 'center',
      }}>
        <div style={{
          width: 100, height: 100, borderRadius: 50, marginBottom: 24,
          background: c.subtle,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="44" height="44" viewBox="0 0 44 44" fill="none" stroke={c.mute} strokeWidth="2">
            <circle cx="22" cy="22" r="18"/>
            <path d="M14 22h16" strokeLinecap="round"/>
          </svg>
        </div>
        <div style={{ fontSize: 22, fontWeight: 800, marginBottom: 10 }}>
          削除が完了しました
        </div>
        <div style={{ fontSize: 13, color: c.mute, lineHeight: 1.7, maxWidth: 300, marginBottom: 30 }}>
          ご利用ありがとうございました。<br/>
          アカウントとすべての関連データは削除されました。
        </div>
        <div style={{
          padding: '14px 18px', borderRadius: 12,
          background: '#fff', border: `0.5px solid ${c.divide}`,
          fontSize: 11, color: c.mute, lineHeight: 1.7, maxWidth: 320,
        }}>
          <b style={{ color: c.ink }}>📌 削除されたデータ</b><br/>
          ・プロフィール情報<br/>
          ・登録した在庫・ウィッシュリスト<br/>
          ・取引履歴（証跡含む）<br/>
          ・コレクション・参戦予定 AW<br/>
          <br/>
          <span style={{ color: c.hint }}>※ 法令により7年間保管が必要な取引記録は、当社内部システムで匿名化された状態で保管されます。</span>
        </div>
      </div>
      <div>
        <AEPrimaryBtn colors={c} label="再登録する" />
        <div style={{ height: 8 }} />
        <button style={{
          width: '100%', padding: '12px',
          background: 'transparent', border: 0,
          color: c.mute, fontFamily: 'inherit',
          fontSize: 13, fontWeight: 600, cursor: 'pointer',
        }}>
          アプリを終了する
        </button>
      </div>
    </div>
  );
}

Object.assign(window, {
  ProfileEdit, OshiEdit, BlockList, UserProfile,
  InventoryPrivacy, IdentityVerification, AppInfo, AccountDeleteComplete,
});
