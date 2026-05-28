// ─────────────────────────────────────────────────────────────
// hub-screens.jsx — Profile Hub + Wishlist (list/empty/edit)
// ─────────────────────────────────────────────────────────────

const HS_C = (t) => ({
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
});

function HSHeader({ colors: c, title, sub, back = true, right }) {
  return (
    <div style={{
      position: 'absolute', top: 0, left: 0, right: 0,
      padding: '54px 18px 12px',
      background: 'rgba(255,255,255,0.92)',
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

function HSBottomNav({ colors: c, active }) {
  const items = [
    { id: 'home', l: 'ホーム' },
    { id: 'inv', l: '在庫' },
    { id: 'trade', l: '取引' },
    { id: 'wish', l: 'ウィッシュ' },
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

function HSSection({ children, label, colors: c, hint }) {
  return (
    <div style={{ marginBottom: 14 }}>
      {label && (
        <div style={{
          fontSize: 10.5, color: c.mute, fontWeight: 700,
          letterSpacing: 0.6, textTransform: 'uppercase',
          padding: '0 4px', marginBottom: 8,
          display: 'flex', justifyContent: 'space-between',
        }}>
          <span>{label}</span>
          {hint && <span style={{ textTransform: 'none', letterSpacing: 0, fontWeight: 500 }}>{hint}</span>}
        </div>
      )}
      <div style={{
        background: '#fff', borderRadius: 14,
        border: `0.5px solid ${c.divide}`, overflow: 'hidden',
      }}>{children}</div>
    </div>
  );
}

function HSRow({ children, last, colors: c, padding = '13px 14px', onClick }) {
  return (
    <div onClick={onClick} style={{
      padding,
      borderBottom: last ? 'none' : `0.5px solid ${c.divide}`,
      cursor: onClick ? 'pointer' : 'default',
    }}>{children}</div>
  );
}

// ─────────────────────────────────────────────────────────────
// 1. Profile Hub — Top
// ─────────────────────────────────────────────────────────────
function ProfileHub({ tweaks }) {
  const c = HS_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 80,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <HSHeader colors={c} title="プロフ" back={false} right={
        <svg width="20" height="20" viewBox="0 0 20 20">
          <circle cx="10" cy="10" r="2" fill="none" stroke={c.ink} strokeWidth="1.5"/>
          <path d="M10 4v2M10 14v2M4 10h2M14 10h2M5.5 5.5l1.4 1.4M13.1 13.1l1.4 1.4M5.5 14.5l1.4-1.4M13.1 6.9l1.4-1.4" stroke={c.ink} strokeWidth="1.5" strokeLinecap="round"/>
        </svg>
      } />

      {/* Identity hero */}
      <div style={{ padding: '14px 18px 0' }}>
        <div style={{
          padding: 18, borderRadius: 18,
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', marginBottom: 18,
          boxShadow: `0 10px 24px ${c.lavender}38`,
          position: 'relative', overflow: 'hidden',
        }}>
          <div style={{
            position: 'absolute', top: -20, right: -20,
            width: 120, height: 120, borderRadius: '50%',
            background: 'rgba(255,255,255,0.12)',
          }} />
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
            <div style={{
              width: 56, height: 56, borderRadius: 16,
              background: 'rgba(255,255,255,0.25)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 22, fontWeight: 800,
              border: '2px solid rgba(255,255,255,0.3)',
            }}>H</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 16, fontWeight: 800, marginBottom: 2 }}>@hana_lumi</div>
              <div style={{ fontSize: 11, opacity: 0.92, lineHeight: 1.5 }}>
                LUMENA推し · スア&ヒナ箱推し<br/>関東 · 取引マナー◎
              </div>
            </div>
          </div>
          <div style={{
            display: 'flex', gap: 0, paddingTop: 12,
            borderTop: '1px solid rgba(255,255,255,0.2)',
          }}>
            {[
              { v: '★4.9', l: '評価' },
              { v: '89', l: '取引' },
              { v: '20/32', l: 'コレク' },
              { v: '5', l: 'AW予定' },
            ].map((s, i) => (
              <div key={i} style={{
                flex: 1, textAlign: 'center',
                borderLeft: i > 0 ? '1px solid rgba(255,255,255,0.2)' : 'none',
              }}>
                <div style={{ fontSize: 14, fontWeight: 800, fontFamily: '"Inter Tight", sans-serif' }}>{s.v}</div>
                <div style={{ fontSize: 9.5, opacity: 0.85, marginTop: 1 }}>{s.l}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Collection summary (small entry, not a featured section) */}
        <HSSection colors={c} label="コレクションサマリ" hint="wish基準 · 20/32">
          <HSRow colors={c} last>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ fontSize: 18, width: 24, textAlign: 'center' }}>📚</span>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>wish進捗 20/32</div>
                <div style={{ fontSize: 10.5, color: c.mute }}>スアコレコンプ · ヒナあと<b style={{ color: c.ink }}>3枚</b></div>
              </div>
              <span style={{ fontSize: 14, color: c.lavender }}>›</span>
            </div>
          </HSRow>
        </HSSection>

        {/* Activity */}
        <HSSection colors={c} label="あなたの活動">
          <HSRow colors={c}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ fontSize: 18, width: 24, textAlign: 'center' }}>📋</span>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>取引履歴</div>
                <div style={{ fontSize: 10.5, color: c.mute }}>89件 · ★4.9 · 直近 4/19</div>
              </div>
              <span style={{ fontSize: 14, color: c.lavender }}>›</span>
            </div>
          </HSRow>
          <HSRow colors={c} last>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ fontSize: 18, width: 24, textAlign: 'center' }}>📅</span>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>自分のAW（合流可能枠）</div>
                <div style={{ fontSize: 10.5, color: c.mute }}>5件 · 次回 4/27 横アリ</div>
              </div>
              <span style={{
                fontSize: 9, fontWeight: 800, color: '#fff',
                background: c.lavender, padding: '2px 6px', borderRadius: 999,
              }}>本日</span>
              <span style={{ fontSize: 14, color: c.lavender }}>›</span>
            </div>
          </HSRow>
        </HSSection>

        {/* Identity */}
        <HSSection colors={c} label="アイデンティティ">
          <HSRow colors={c}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ fontSize: 18, width: 24, textAlign: 'center' }}>👤</span>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>プロフィール編集</div>
                <div style={{ fontSize: 10.5, color: c.mute }}>ハンドル・自己紹介・アイコン</div>
              </div>
              <span style={{ fontSize: 14, color: c.lavender }}>›</span>
            </div>
          </HSRow>
          <HSRow colors={c}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ fontSize: 18, width: 24, textAlign: 'center' }}>💜</span>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>推し設定</div>
                <div style={{ fontSize: 10.5, color: c.mute }}>LUMENA · スア / ヒナ（箱推し）</div>
              </div>
              <span style={{ fontSize: 14, color: c.lavender }}>›</span>
            </div>
          </HSRow>
          <HSRow colors={c}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ fontSize: 18, width: 24, textAlign: 'center' }}>📅</span>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>スケジュール</div>
                <div style={{ fontSize: 10.5, color: c.mute }}>個人予定 · 公開設定 · 取引候補日の整理</div>
              </div>
              <span style={{ fontSize: 14, color: c.lavender }}>›</span>
            </div>
          </HSRow>
          <HSRow colors={c} last>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ fontSize: 18, width: 24, textAlign: 'center' }}>✓</span>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>本人確認</div>
                <div style={{ fontSize: 10.5, color: c.ok, fontWeight: 700 }}>● 完了済</div>
              </div>
              <span style={{ fontSize: 14, color: c.lavender }}>›</span>
            </div>
          </HSRow>
        </HSSection>

        {/* Notification & Support */}
        <HSSection colors={c} label="通知・サポート">
          <HSRow colors={c}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ fontSize: 18, width: 24, textAlign: 'center' }}>🔔</span>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>通知設定</div>
                <div style={{ fontSize: 10.5, color: c.mute }}>夜間モード ON · 当日例外</div>
              </div>
              <span style={{ fontSize: 14, color: c.lavender }}>›</span>
            </div>
          </HSRow>
          <HSRow colors={c} last>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ fontSize: 18, width: 24, textAlign: 'center' }}>?</span>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>ヘルプ・問い合わせ</div>
                <div style={{ fontSize: 10.5, color: c.mute }}>FAQ · 運営に問い合わせ · 通報</div>
              </div>
              <span style={{ fontSize: 14, color: c.lavender }}>›</span>
            </div>
          </HSRow>
        </HSSection>

        {/* Logout row */}
        <HSSection colors={c}>
          <HSRow colors={c} last>
            <div style={{ fontSize: 12.5, fontWeight: 600, color: c.mute, textAlign: 'center' }}>ログアウト</div>
          </HSRow>
        </HSSection>

        <div style={{ textAlign: 'center', fontSize: 10, color: c.hint, padding: '4px 0 12px' }}>
          Megrum 0.9.2 · build 1042
        </div>
      </div>

      <HSBottomNav colors={c} active="me" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 2. Wishlist — List
// ─────────────────────────────────────────────────────────────
const WISHES = [
  {
    id: 'w1', name: 'スア 生写真 Vol.4', sub: 'WORLD TOUR会場限定',
    priority: 'top', flex: 'exact',
    matches: 3, awNear: 2, days: 7, hot: true,
    note: '4/27 横アリで取引できる人優先',
  },
  {
    id: 'w2', name: 'ヒナ ペンライト3.0', sub: 'COMEBACK SHOW会場限定',
    priority: 'top', flex: 'exact',
    matches: 1, awNear: 0, days: 14,
    note: '',
  },
  {
    id: 'w3', name: 'ジウォン トレカ', sub: 'シリーズ問わず（character_any）',
    priority: 'second', flex: 'character_any',
    matches: 8, awNear: 4, days: 21,
    note: '',
  },
  {
    id: 'w4', name: 'LUMENA 何でも', sub: 'スア優先（series_any）',
    priority: 'compromise', flex: 'series_any',
    matches: 24, awNear: 9, days: 30,
    note: '推しの誰かに会えたら満足',
  },
];

const PRIO_LABEL = {
  top: { l: '最優先', c: '#d9826b' },
  second: { l: '2番手', c: '#a695d8' },
  compromise: { l: '妥協OK', c: '#7a9a8a' },
};
const FLEX_LABEL = {
  exact: '完全一致',
  character_any: 'キャラ問わず',
  series_any: 'シリーズ問わず',
};

function WishlistList({ tweaks }) {
  const c = HS_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 80,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <HSHeader colors={c} title="ウィッシュ" sub="探したいグッズを管理 · 4件登録" back={false} right={
        <button style={{
          padding: '6px 12px', borderRadius: 999,
          background: c.lavender, color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 11, fontWeight: 700,
        }}>+ 追加</button>
      } />

      <div style={{ padding: '14px 18px 0' }}>
        {/* Summary stat */}
        <div style={{
          padding: '12px 14px', borderRadius: 14,
          background: `linear-gradient(135deg, ${c.lavender}1a, ${c.sky}1a)`,
          border: `0.5px solid ${c.lavender}30`,
          marginBottom: 14, display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <div style={{
            width: 38, height: 38, borderRadius: 10,
            background: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flex: '0 0 auto',
          }}>
            <svg width="20" height="20" viewBox="0 0 20 20">
              <path d="M10 17l-1-1c-3.5-3-6-5-6-8a3.5 3.5 0 016-2.5A3.5 3.5 0 0117 8c0 3-2.5 5-6 8l-1 1z" stroke={c.lavender} strokeWidth="1.6" fill="none" strokeLinejoin="round"/>
            </svg>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12.5, fontWeight: 800 }}>マッチ <span style={{ color: c.lavender }}>36件</span> 検出中</div>
            <div style={{ fontSize: 10.5, color: c.mute }}>うちAW近隣で取引可能 15件</div>
          </div>
          <button style={{
            padding: '7px 12px', borderRadius: 10,
            background: c.lavender, color: '#fff', border: 0,
            fontFamily: 'inherit', fontSize: 11, fontWeight: 700,
          }}>ホームで見る</button>
        </div>

        {/* Filter chips */}
        <div style={{ display: 'flex', gap: 6, marginBottom: 12, overflowX: 'auto' }}>
          {['すべて 4', '最優先 2', '2番手 1', '妥協OK 1', '探し中(AW近)'].map((l, i) => (
            <button key={i} style={{
              padding: '6px 12px', borderRadius: 999,
              background: i === 0 ? c.ink : '#fff',
              color: i === 0 ? '#fff' : c.ink,
              border: i === 0 ? 'none' : `0.5px solid ${c.divide}`,
              fontFamily: 'inherit', fontSize: 11, fontWeight: 700,
              whiteSpace: 'nowrap', flex: '0 0 auto',
            }}>{l}</button>
          ))}
        </div>

        {/* Wish cards */}
        {WISHES.map(w => {
          const prio = PRIO_LABEL[w.priority];
          return (
            <div key={w.id} style={{
              background: '#fff', borderRadius: 14,
              border: `0.5px solid ${c.divide}`, marginBottom: 10,
              overflow: 'hidden',
              boxShadow: w.hot ? `0 6px 16px ${c.lavender}25` : 'none',
            }}>
              <div style={{ padding: 14, display: 'flex', gap: 12 }}>
                {/* Thumb */}
                <div style={{
                  width: 56, height: 56, borderRadius: 10,
                  background: `linear-gradient(135deg, ${c.lavender}33, ${c.sky}33)`,
                  border: `0.5px solid ${c.divide}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flex: '0 0 auto', position: 'relative',
                }}>
                  <span style={{ fontSize: 11, color: c.lavender, fontWeight: 800 }}>IMG</span>
                  {w.hot && (
                    <span style={{
                      position: 'absolute', top: -4, right: -4,
                      fontSize: 9, fontWeight: 800, color: '#fff',
                      background: c.warn, padding: '2px 5px', borderRadius: 999,
                    }}>HOT</span>
                  )}
                </div>

                <div style={{ flex: 1, minWidth: 0 }}>
                  {/* Title row */}
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: 6, marginBottom: 4 }}>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 800, marginBottom: 1 }}>{w.name}</div>
                      <div style={{ fontSize: 10.5, color: c.mute }}>{w.sub}</div>
                    </div>
                  </div>

                  {/* Badges */}
                  <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 8 }}>
                    <span style={{
                      fontSize: 10, fontWeight: 800, color: '#fff',
                      background: prio.c, padding: '2px 8px', borderRadius: 999,
                    }}>{prio.l}</span>
                    <span style={{
                      fontSize: 10, fontWeight: 700, color: c.ink,
                      background: c.subtle, padding: '2px 8px', borderRadius: 999,
                      border: `0.5px solid ${c.divide}`,
                    }}>{FLEX_LABEL[w.flex]}</span>
                  </div>

                  {/* Searching status */}
                  <div style={{
                    padding: '8px 10px', borderRadius: 8,
                    background: w.matches > 0 ? `${c.lavender}10` : c.subtle,
                    fontSize: 10.5, lineHeight: 1.5,
                  }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginBottom: 2 }}>
                      <span style={{
                        width: 6, height: 6, borderRadius: '50%',
                        background: w.matches > 0 ? c.lavender : c.hint,
                        animation: w.matches > 0 ? 'wishpulse 1.6s ease-in-out infinite' : 'none',
                      }} />
                      <span style={{ fontWeight: 800, color: w.matches > 0 ? c.lavender : c.mute }}>
                        {w.matches > 0 ? `探し中 · ${w.days}日前から` : '探し中 · まだマッチなし'}
                      </span>
                    </div>
                    {w.matches > 0 && (
                      <div style={{ color: c.ink, paddingLeft: 10 }}>
                        マッチ <b>{w.matches}件</b>
                        {w.awNear > 0 && <> · AW近隣 <b>{w.awNear}人</b></>}
                      </div>
                    )}
                  </div>

                  {w.note && (
                    <div style={{
                      marginTop: 6, fontSize: 10.5, color: c.mute,
                      fontStyle: 'italic', lineHeight: 1.5,
                    }}>” {w.note} ”</div>
                  )}
                </div>
              </div>
            </div>
          );
        })}

        <div style={{ height: 12 }} />
      </div>

      <style>{`
        @keyframes wishpulse {
          0%, 100% { opacity: 0.5; transform: scale(1); }
          50% { opacity: 1; transform: scale(1.4); }
        }
      `}</style>

      <HSBottomNav colors={c} active="wish" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 3. Wishlist — Empty state
// ─────────────────────────────────────────────────────────────
function WishlistEmpty({ tweaks }) {
  const c = HS_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 80,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <HSHeader colors={c} title="ウィッシュ" sub="探したいグッズを登録しよう" back={false} />

      <div style={{ padding: '40px 28px 0', textAlign: 'center' }}>
        {/* Big visual */}
        <div style={{
          width: 110, height: 110, margin: '0 auto 20px',
          borderRadius: 28,
          background: `linear-gradient(135deg, ${c.lavender}1a, ${c.sky}1a, ${c.pink}1a)`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          position: 'relative',
        }}>
          <svg width="56" height="56" viewBox="0 0 56 56">
            <path d="M28 48l-3-3c-9-7-16-13-16-22a9 9 0 0116-6 9 9 0 0116 6c0 9-7 15-16 22l-3 3z"
              stroke={c.lavender} strokeWidth="2.4" fill="none" strokeLinejoin="round"/>
          </svg>
          <div style={{
            position: 'absolute', bottom: -6, right: -6,
            width: 30, height: 30, borderRadius: '50%',
            background: c.lavender, color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 18, fontWeight: 800,
            boxShadow: `0 4px 10px ${c.lavender}50`,
          }}>+</div>
        </div>

        <div style={{ fontSize: 18, fontWeight: 800, marginBottom: 8 }}>
          欲しいものを登録しよう
        </div>
        <div style={{ fontSize: 12, color: c.mute, lineHeight: 1.7, marginBottom: 28 }}>
          ウィッシュリストに追加すると、<br/>
          持っている人が見つかり次第<br/>
          ホームに通知されます。
        </div>

        {/* 3 hints */}
        <div style={{ textAlign: 'left', marginBottom: 28 }}>
          {[
            { n: '1', l: '欲しいグッズを追加', sub: '生写真 · トレカ · ペンライトなど' },
            { n: '2', l: '優先度・許容範囲を設定', sub: '完全一致／キャラ問わず／シリーズ問わず' },
            { n: '3', l: 'マッチを待つ', sub: '見つかればホームで通知' },
          ].map(h => (
            <div key={h.n} style={{
              display: 'flex', gap: 12, alignItems: 'flex-start',
              padding: 12, marginBottom: 8,
              background: '#fff', borderRadius: 12,
              border: `0.5px solid ${c.divide}`,
            }}>
              <div style={{
                width: 26, height: 26, borderRadius: '50%',
                background: `${c.lavender}1a`, color: c.lavender,
                fontSize: 12, fontWeight: 800,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                flex: '0 0 auto', fontFamily: '"Inter Tight", sans-serif',
              }}>{h.n}</div>
              <div>
                <div style={{ fontSize: 12.5, fontWeight: 700, marginBottom: 2 }}>{h.l}</div>
                <div style={{ fontSize: 10.5, color: c.mute }}>{h.sub}</div>
              </div>
            </div>
          ))}
        </div>

        <button style={{
          width: '100%', height: 52, borderRadius: 16,
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 14, fontWeight: 800,
          boxShadow: `0 8px 20px ${c.lavender}40`,
          marginBottom: 10,
        }}>+ 最初のウィッシュを追加</button>
        <button style={{
          width: '100%', height: 44, borderRadius: 12,
          background: 'transparent', color: c.lavender,
          border: 0, fontFamily: 'inherit', fontSize: 12, fontWeight: 700,
        }}>サンプルから追加（人気の生写真など）</button>
      </div>

      <HSBottomNav colors={c} active="wish" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 4. Wishlist — Edit individual wish
// ─────────────────────────────────────────────────────────────
function WishlistEdit({ tweaks }) {
  const c = HS_C(tweaks);
  const [prio, setPrio] = React.useState('top');
  const [flex, setFlex] = React.useState('exact');
  const [notif, setNotif] = React.useState(true);
  const [name] = React.useState('スア 生写真 Vol.4');
  const [note, setNote] = React.useState('4/27 横アリで取引できる人優先');

  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 100,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <HSHeader colors={c} title="ウィッシュを編集" sub="探したいグッズの条件を設定" right={
        <button style={{
          padding: 0, background: 'transparent', border: 0,
          fontFamily: 'inherit', fontSize: 12, fontWeight: 700,
          color: c.warn,
        }}>削除</button>
      } />

      <div style={{ padding: '14px 18px 0' }}>
        {/* Item display */}
        <HSSection colors={c} label="グッズ">
          <HSRow colors={c} last padding="14px">
            <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
              <div style={{
                width: 56, height: 56, borderRadius: 10,
                background: `linear-gradient(135deg, ${c.lavender}33, ${c.sky}33)`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                flex: '0 0 auto',
              }}>
                <span style={{ fontSize: 11, color: c.lavender, fontWeight: 800 }}>IMG</span>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, fontWeight: 800, marginBottom: 2 }}>{name}</div>
                <div style={{ fontSize: 10.5, color: c.mute }}>LUMENA · WORLD TOUR会場限定</div>
              </div>
              <span style={{ fontSize: 14, color: c.lavender }}>›</span>
            </div>
          </HSRow>
        </HSSection>

        {/* Priority */}
        <HSSection colors={c} label="優先度" hint="マッチ提案の並び順に影響">
          <HSRow colors={c} last padding="12px">
            <div style={{ display: 'flex', gap: 6 }}>
              {[
                { id: 'top', l: '最優先', sub: '最高ウェイト', color: '#d9826b' },
                { id: 'second', l: '2番手', sub: '通常', color: c.lavender },
                { id: 'compromise', l: '妥協OK', sub: '低ウェイト', color: c.ok },
              ].map(p => (
                <button key={p.id} onClick={() => setPrio(p.id)} style={{
                  flex: 1, padding: '10px 4px', borderRadius: 10,
                  background: prio === p.id ? p.color : '#fff',
                  color: prio === p.id ? '#fff' : c.ink,
                  border: prio === p.id ? 'none' : `1px solid ${c.divide}`,
                  fontFamily: 'inherit', cursor: 'pointer',
                }}>
                  <div style={{ fontSize: 12, fontWeight: 800 }}>{p.l}</div>
                  <div style={{ fontSize: 9.5, opacity: prio === p.id ? 0.85 : 0.5, marginTop: 2 }}>{p.sub}</div>
                </button>
              ))}
            </div>
          </HSRow>
        </HSSection>

        {/* Flexibility — MVP differentiator */}
        <HSSection colors={c} label="許容範囲（マッチング条件）" hint="広いほどマッチ多数">
          {[
            { id: 'exact', l: '完全一致のみ', sub: 'このグッズと完全に同じものだけ', exNum: 3 },
            { id: 'character_any', l: 'キャラ問わず', sub: '同じシリーズなら推し以外でもOK', exNum: 8 },
            { id: 'series_any', l: 'シリーズ問わず', sub: 'スア関連なら何でも嬉しい', exNum: 24 },
          ].map((g, i, arr) => (
            <HSRow key={g.id} colors={c} last={i === arr.length - 1} padding="0">
              <button onClick={() => setFlex(g.id)} style={{
                width: '100%', padding: '13px 14px',
                background: flex === g.id ? `${c.lavender}10` : 'transparent',
                border: 0, fontFamily: 'inherit',
                display: 'flex', alignItems: 'flex-start', gap: 12,
                textAlign: 'left', cursor: 'pointer',
              }}>
                <div style={{
                  width: 18, height: 18, borderRadius: '50%',
                  border: `1.5px solid ${flex === g.id ? c.lavender : 'rgba(58,50,74,0.25)'}`,
                  background: flex === g.id ? c.lavender : 'transparent',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flex: '0 0 auto', marginTop: 1.5,
                }}>
                  {flex === g.id && <div style={{ width: 7, height: 7, borderRadius: '50%', background: '#fff' }} />}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 2 }}>
                    <span style={{ fontSize: 12.5, fontWeight: 700 }}>{g.l}</span>
                    <span style={{
                      fontSize: 9.5, fontWeight: 800, color: c.lavender,
                      background: `${c.lavender}1a`, padding: '1px 6px', borderRadius: 999,
                    }}>マッチ予測 {g.exNum}件</span>
                  </div>
                  <div style={{ fontSize: 10.5, color: c.mute, lineHeight: 1.5 }}>{g.sub}</div>
                </div>
              </button>
            </HSRow>
          ))}
        </HSSection>

        {/* Notification toggle */}
        <HSSection colors={c} label="通知">
          <HSRow colors={c} last padding="14px">
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10 }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>このウィッシュのマッチ通知</div>
                <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>
                  該当する譲が見つかった時にホームに通知
                </div>
              </div>
              <div onClick={() => setNotif(!notif)} style={{
                width: 38, height: 22, borderRadius: 999,
                background: notif ? c.lavender : c.divide,
                position: 'relative', flex: '0 0 auto', cursor: 'pointer',
                transition: 'background 0.2s',
              }}>
                <div style={{
                  position: 'absolute', top: 2, left: notif ? 18 : 2,
                  width: 18, height: 18, borderRadius: '50%',
                  background: '#fff', boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
                  transition: 'left 0.2s',
                }} />
              </div>
            </div>
          </HSRow>
        </HSSection>

        {/* Note */}
        <HSSection colors={c} label="メモ（任意）" hint={`${note.length}/200`}>
          <HSRow colors={c} last padding="12px">
            <textarea
              value={note}
              onChange={e => setNote(e.target.value)}
              placeholder="例：4/27 横アリで取引できる人優先"
              style={{
                width: '100%', minHeight: 70, resize: 'vertical',
                border: 0, outline: 'none',
                fontFamily: 'inherit', fontSize: 12.5,
                color: c.ink, lineHeight: 1.6, background: 'transparent',
                boxSizing: 'border-box', padding: 0,
              }}
            />
          </HSRow>
        </HSSection>

        {/* Live status preview */}
        <div style={{
          padding: 12, borderRadius: 12,
          background: `linear-gradient(135deg, ${c.lavender}1a, ${c.sky}1a)`,
          border: `0.5px solid ${c.lavender}30`,
          marginBottom: 14,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
            <span style={{
              width: 6, height: 6, borderRadius: '50%', background: c.lavender,
              animation: 'wishpulse 1.6s ease-in-out infinite',
            }} />
            <span style={{ fontSize: 11, fontWeight: 800, color: c.lavender }}>現在の探し中ステータス</span>
          </div>
          <div style={{ fontSize: 11.5, color: c.ink, lineHeight: 1.6, paddingLeft: 12 }}>
            この設定でマッチ <b>3件</b> · AW近隣 <b>2人</b><br/>
            <span style={{ color: c.mute }}>許容範囲を広げるとマッチ数が増えます</span>
          </div>
        </div>
      </div>

      <style>{`
        @keyframes wishpulse {
          0%, 100% { opacity: 0.5; transform: scale(1); }
          50% { opacity: 1; transform: scale(1.4); }
        }
      `}</style>

      {/* Save bar */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '12px 18px 30px',
        background: 'rgba(255,255,255,0.94)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `0.5px solid ${c.divide}`,
        display: 'flex', gap: 8,
      }}>
        <button style={{
          flex: 1, height: 48, borderRadius: 14,
          background: '#fff', color: c.ink, border: `0.5px solid ${c.divide}`,
          fontFamily: 'inherit', fontSize: 13, fontWeight: 600,
        }}>キャンセル</button>
        <button style={{
          flex: 2, height: 48, borderRadius: 14,
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 14, fontWeight: 700,
          boxShadow: `0 6px 16px ${c.lavender}40`,
        }}>保存</button>
      </div>
    </div>
  );
}


// __EXPORTS__
Object.assign(window, {
  ProfileHub, WishlistList, WishlistEmpty, WishlistEdit,
});
