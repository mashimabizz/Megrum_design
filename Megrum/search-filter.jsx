// ─────────────────────────────────────────────────────────────
// search-filter.jsx — 検索 / フィルタ / 保存検索リスト（3画面）
// ホーム画面の🔍と⚙️アイコンの先 / 「探索」タブの中身
// ─────────────────────────────────────────────────────────────

const SF_C = (t) => ({
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

// ─── Shared components ───
function SFHeader({ colors: c, title, sub, right }) {
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
        <svg width="10" height="16" viewBox="0 0 10 16" style={{ flex: '0 0 auto' }}>
          <path d="M8 1L2 8l6 7" stroke={c.ink} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 15, fontWeight: 700, color: c.ink }}>{title}</div>
          {sub && <div style={{ fontSize: 11, color: c.mute, marginTop: 1 }}>{sub}</div>}
        </div>
        {right}
      </div>
    </div>
  );
}

function SFChip({ label, active, colors: c, onClick }) {
  return (
    <div onClick={onClick} style={{
      padding: '7px 13px', borderRadius: 999,
      background: active ? c.lavender : '#fff',
      color: active ? '#fff' : c.ink,
      border: active ? 0 : `0.5px solid ${c.divide}`,
      fontFamily: 'inherit', fontSize: 12, fontWeight: active ? 700 : 500,
      flexShrink: 0, whiteSpace: 'nowrap', cursor: 'pointer',
      display: 'inline-flex', alignItems: 'center', gap: 5,
    }}>{label}</div>
  );
}

function SFSection({ children, label, colors: c }) {
  return (
    <div style={{ marginBottom: 22 }}>
      <div style={{
        fontSize: 11, fontWeight: 700, color: c.mute,
        letterSpacing: 0.4, padding: '0 4px', marginBottom: 10,
      }}>{label}</div>
      <div style={{
        background: '#fff', borderRadius: 14,
        border: `0.5px solid ${c.divide}`, padding: '14px 14px',
      }}>{children}</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 1. 検索画面
// ─────────────────────────────────────────────────────────────
function SearchScreen({ tweaks }) {
  const c = SF_C(tweaks);
  const popular = [
    'スア トレカ', 'ヒナ 生写真', 'WORLD TOUR', 'POP-UP STORE',
    '横浜アリーナ', '推し誕生日カフェ',
  ];
  const recent = ['スア WT01', 'ヒナ 5th MINI', 'リナ JAPAN'];
  const results = [
    {
      id: 'r1', user: '@plum_92', oshi: 'スア', dist: '169m', star: 4.5, count: 157,
      offer: 'スア WT01 トレカ', want: 'ヒナ 生写真', match: '完全マッチ',
    },
    {
      id: 'r2', user: '@iam_jiyoung', oshi: 'スア', dist: '182m', star: 4.6, count: 109,
      offer: 'スア POPUP 缶バッジ', want: 'スア STUDIO トレカ', match: '完全マッチ',
    },
    {
      id: 'r3', user: '@mochiko_724', oshi: 'スア', dist: '345m', star: 4.7, count: 89,
      offer: 'スア WT02 アクスタ', want: 'ヒナ JAPAN トレカ', match: '片方向',
    },
  ];
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      <SFHeader colors={c} title="検索" />

      {/* Search bar */}
      <div style={{
        position: 'absolute', top: 96, left: 0, right: 0, zIndex: 5,
        padding: '0 18px 12px', background: c.bg,
      }}>
        <div style={{
          background: '#fff', borderRadius: 12,
          border: `0.5px solid ${c.divide}`,
          padding: '11px 14px',
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke={c.mute} strokeWidth="1.6">
            <circle cx="7" cy="7" r="5"/><path d="M11 11l4 4"/>
          </svg>
          <span style={{ flex: 1, fontSize: 14, color: c.ink, fontWeight: 500 }}>スア トレカ</span>
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke={c.mute} strokeWidth="1.4">
            <line x1="3" y1="3" x2="11" y2="11"/><line x1="11" y1="3" x2="3" y2="11"/>
          </svg>
        </div>
        <div style={{ display: 'flex', gap: 8, marginTop: 10, alignItems: 'center' }}>
          <SFChip colors={c} label="🎚️ フィルタ" active />
          <SFChip colors={c} label="完全マッチのみ" />
          <SFChip colors={c} label="500m以内" />
          <SFChip colors={c} label="★4.5+" />
        </div>
      </div>

      <div style={{ paddingTop: 100, padding: '100px 18px 0' }}>
        {/* Results header */}
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          marginBottom: 12, padding: '0 4px',
        }}>
          <div style={{ fontSize: 12, color: c.mute }}>
            <b style={{ color: c.ink, fontSize: 14 }}>{results.length}件</b> ヒット
          </div>
          <div style={{ fontSize: 11, color: c.mute, display: 'flex', alignItems: 'center', gap: 4 }}>
            並び替え:近い順
            <svg width="9" height="9" viewBox="0 0 9 9" fill="none" stroke={c.mute} strokeWidth="1.5"><path d="M2 3.5L4.5 6 7 3.5"/></svg>
          </div>
        </div>

        {/* Results */}
        {results.map(r => (
          <div key={r.id} style={{
            background: '#fff', borderRadius: 14,
            border: `0.5px solid ${c.divide}`,
            padding: '14px', marginBottom: 10,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
              <div style={{
                width: 36, height: 36, borderRadius: 18,
                background: `linear-gradient(135deg, ${c.lavender}55, ${c.sky}55)`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 12, fontWeight: 800, color: c.ink,
              }}>{r.user[1].toUpperCase()}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, fontWeight: 700 }}>{r.user}</div>
                <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>
                  {r.dist}・★{r.star}・取引{r.count} ・<span style={{ color: c.lavender, fontWeight: 700 }}>推し: {r.oshi}</span>
                </div>
              </div>
              <span style={{
                fontSize: 9, fontWeight: 800, color: '#fff',
                background: r.match === '完全マッチ' ? `linear-gradient(135deg, ${c.lavender}, ${c.pink})` : c.ok,
                padding: '3px 8px', borderRadius: 999, letterSpacing: 0.3,
              }}>{r.match}</span>
            </div>
            <div style={{
              padding: '10px 12px', borderRadius: 10,
              background: c.subtle, fontSize: 11.5,
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                <span style={{ color: c.mute }}>譲</span>
                <span style={{ fontWeight: 600 }}>{r.offer}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: c.mute }}>求</span>
                <span style={{ fontWeight: 600 }}>{r.want}</span>
              </div>
            </div>
          </div>
        ))}

        {/* Suggestions */}
        <div style={{
          fontSize: 11, fontWeight: 700, color: c.mute,
          letterSpacing: 0.4, padding: '14px 4px 8px',
        }}>履歴</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 16 }}>
          {recent.map(s => (
            <SFChip key={s} colors={c} label={`🕐 ${s}`} />
          ))}
        </div>

        <div style={{
          fontSize: 11, fontWeight: 700, color: c.mute,
          letterSpacing: 0.4, padding: '4px 4px 8px',
        }}>人気の検索</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
          {popular.map(s => (
            <SFChip key={s} colors={c} label={s} />
          ))}
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 2. フィルタ画面
// ─────────────────────────────────────────────────────────────
function FilterScreen({ tweaks }) {
  const c = SF_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 100,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      <SFHeader colors={c} title="フィルタ" right={
        <button style={{
          padding: '6px 12px', borderRadius: 999,
          background: 'transparent', color: c.warn, border: 0,
          fontFamily: 'inherit', fontSize: 12, fontWeight: 700,
        }}>リセット</button>
      } />
      <div style={{ padding: '20px 18px 0' }}>
        <SFSection colors={c} label="距離・時間">
          <div style={{ marginBottom: 14 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
              <span style={{ fontSize: 12, fontWeight: 600 }}>半径</span>
              <span style={{ fontSize: 12, fontWeight: 700, color: c.lavender }}>500m</span>
            </div>
            <div style={{ position: 'relative', height: 4, background: c.subtle, borderRadius: 2 }}>
              <div style={{
                position: 'absolute', left: 0, top: 0, height: 4, width: '20%',
                background: c.lavender, borderRadius: 2,
              }} />
              <div style={{
                position: 'absolute', left: '20%', top: -7, width: 18, height: 18, borderRadius: 9,
                background: '#fff', border: `2px solid ${c.lavender}`,
                boxShadow: '0 2px 6px rgba(0,0,0,0.15)', transform: 'translateX(-50%)',
              }} />
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 9.5, color: c.mute, marginTop: 6 }}>
              <span>200m</span><span>1km</span><span>5km</span>
            </div>
          </div>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, marginBottom: 8 }}>AW参戦時間</div>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              <SFChip colors={c} label="今日" active />
              <SFChip colors={c} label="今週" />
              <SFChip colors={c} label="月内" />
              <SFChip colors={c} label="すべて" />
            </div>
          </div>
        </SFSection>

        <SFSection colors={c} label="推し（グループ・作品 → メンバー・キャラ）">
          {/* Search bar for any oshi */}
          <div style={{
            background: c.bg, borderRadius: 10,
            padding: '10px 12px', marginBottom: 12,
            display: 'flex', alignItems: 'center', gap: 8,
            border: `0.5px solid ${c.divide}`,
          }}>
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke={c.mute} strokeWidth="1.5">
              <circle cx="6" cy="6" r="4.5"/><path d="M9.5 9.5L13 13"/>
            </svg>
            <span style={{ flex: 1, fontSize: 12.5, color: c.hint }}>
              グループ・作品・キャラ名で検索
            </span>
          </div>

          <div style={{ marginBottom: 12 }}>
            <SFChip colors={c} label="✓ すべての推し" active />
          </div>

          {/* === Your registered oshi === */}
          <div style={{
            display: 'flex', alignItems: 'center', gap: 6,
            marginTop: 14, marginBottom: 8,
          }}>
            <span style={{
              fontSize: 9.5, fontWeight: 800, color: '#fff',
              background: c.pink, padding: '2px 8px', borderRadius: 999,
              letterSpacing: 0.4,
            }}>あなたの推し</span>
            <div style={{ flex: 1, height: 0.5, background: c.divide }} />
          </div>

          <div style={{
            paddingTop: 6,
          }}>
            <div style={{
              fontSize: 11, fontWeight: 700, color: c.lavender,
              marginBottom: 6, display: 'flex', alignItems: 'center', gap: 6,
            }}>
              <span style={{
                fontSize: 9, fontWeight: 800, color: '#fff',
                background: c.lavender, padding: '2px 7px', borderRadius: 999,
              }}>K-POP</span>
              <span style={{ fontFamily: '"Inter Tight"', letterSpacing: 0.3 }}>LUMENA</span>
            </div>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', paddingLeft: 8 }}>
              <SFChip colors={c} label="LUMENA 全体" />
              <SFChip colors={c} label="スア" active />
              <SFChip colors={c} label="ヒナ" />
              <SFChip colors={c} label="リナ" />
              <SFChip colors={c} label="チェ" />
              <SFChip colors={c} label="ナナ" />
              <SFChip colors={c} label="ジュン" />
            </div>
          </div>
          <div style={{ paddingTop: 12, marginTop: 12, borderTop: `0.5px solid ${c.divide}` }}>
            <div style={{
              fontSize: 11, fontWeight: 700, color: c.lavender,
              marginBottom: 6, display: 'flex', alignItems: 'center', gap: 6,
            }}>
              <span style={{
                fontSize: 9, fontWeight: 800, color: '#fff',
                background: c.sky, padding: '2px 7px', borderRadius: 999,
              }}>アニメ</span>
              <span>呪術廻戦</span>
            </div>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', paddingLeft: 8 }}>
              <SFChip colors={c} label="呪術廻戦 全体" />
              <SFChip colors={c} label="五条悟" />
              <SFChip colors={c} label="虎杖悠仁" />
              <SFChip colors={c} label="伏黒恵" />
            </div>
          </div>

          {/* === Other oshi (not registered) === */}
          <div style={{
            display: 'flex', alignItems: 'center', gap: 6,
            marginTop: 18, marginBottom: 8,
          }}>
            <span style={{
              fontSize: 9.5, fontWeight: 800, color: c.mute,
              background: c.subtle, padding: '2px 8px', borderRadius: 999,
              letterSpacing: 0.4,
            }}>他の推しから検索</span>
            <div style={{ flex: 1, height: 0.5, background: c.divide }} />
          </div>
          <div style={{
            fontSize: 10.5, color: c.mute, lineHeight: 1.5, marginBottom: 10,
          }}>
            登録していない推しでも検索できます。タップで一時的にフィルタに追加。
          </div>

          {/* Genre tabs */}
          <div style={{
            display: 'flex', gap: 5, marginBottom: 10,
            overflowX: 'auto', WebkitOverflowScrolling: 'touch',
          }}>
            <SFChip colors={c} label="K-POP" active />
            <SFChip colors={c} label="アニメ" />
            <SFChip colors={c} label="ゲーム" />
            <SFChip colors={c} label="2.5次元" />
            <SFChip colors={c} label="VTuber" />
            <SFChip colors={c} label="邦アイ" />
          </div>

          {/* Popular K-POP groups */}
          <div style={{
            fontSize: 10, fontWeight: 700, color: c.mute,
            letterSpacing: 0.4, marginBottom: 6,
          }}>人気の K-POP グループ</div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            <SFChip colors={c} label="BTS" />
            <SFChip colors={c} label="TWICE" />
            <SFChip colors={c} label="NewJeans" />
            <SFChip colors={c} label="IVE" />
            <SFChip colors={c} label="Stray Kids" />
            <SFChip colors={c} label="aespa" />
            <SFChip colors={c} label="LE SSERAFIM" />
          </div>

          <div style={{
            padding: '10px 12px', borderRadius: 10,
            background: 'transparent', border: `1px dashed ${c.divide}`,
            fontSize: 11, color: c.mute, textAlign: 'center',
            marginTop: 12,
          }}>
            + 見つからない場合は運営に追加リクエスト
          </div>
        </SFSection>

        <SFSection colors={c} label="グッズ種別">
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            <SFChip colors={c} label="トレカ" active />
            <SFChip colors={c} label="生写真" active />
            <SFChip colors={c} label="缶バッジ" />
            <SFChip colors={c} label="アクスタ" />
            <SFChip colors={c} label="スロガン" />
            <SFChip colors={c} label="その他" />
          </div>
        </SFSection>

        <SFSection colors={c} label="状態">
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            <SFChip colors={c} label="✓ こだわらない" active />
            <SFChip colors={c} label="美品" />
            <SFChip colors={c} label="中古" />
            <SFChip colors={c} label="傷あり可" />
          </div>
        </SFSection>

        <SFSection colors={c} label="信頼性（マッチ相手）">
          <div style={{ marginBottom: 12 }}>
            <div style={{ fontSize: 11.5, color: c.mute, marginBottom: 6 }}>★ しきい値</div>
            <div style={{ display: 'flex', gap: 6 }}>
              <SFChip colors={c} label="すべて" />
              <SFChip colors={c} label="★4.0+" active />
              <SFChip colors={c} label="★4.5+" />
              <SFChip colors={c} label="★4.8+" />
            </div>
          </div>
          <div>
            <div style={{ fontSize: 11.5, color: c.mute, marginBottom: 6 }}>取引実績</div>
            <div style={{ display: 'flex', gap: 6 }}>
              <SFChip colors={c} label="すべて" active />
              <SFChip colors={c} label="10回以上" />
              <SFChip colors={c} label="50回以上" />
              <SFChip colors={c} label="100回以上" />
            </div>
          </div>
        </SFSection>

        <SFSection colors={c} label="マッチ強度">
          <div style={{ display: 'flex', gap: 6 }}>
            <SFChip colors={c} label="完全マッチのみ" active />
            <SFChip colors={c} label="片方向もOK" />
          </div>
        </SFSection>

        <SFSection colors={c} label="並び替え">
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            <SFChip colors={c} label="近い順" active />
            <SFChip colors={c} label="新着順" />
            <SFChip colors={c} label="★順" />
            <SFChip colors={c} label="マッチ強度順" />
          </div>
        </SFSection>
      </div>

      {/* Bottom CTAs */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '12px 18px 30px',
        background: 'rgba(255,255,255,0.96)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `0.5px solid ${c.divide}`,
        display: 'flex', gap: 8,
      }}>
        <button style={{
          padding: '14px 18px', borderRadius: 14,
          background: '#fff', color: c.lavender,
          border: `1px solid ${c.lavender}55`,
          fontFamily: 'inherit', fontSize: 13, fontWeight: 700,
          display: 'inline-flex', alignItems: 'center', gap: 6,
        }}>
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke={c.lavender} strokeWidth="1.6">
            <path d="M3 1v12l4-3 4 3V1z"/>
          </svg>
          条件を保存
        </button>
        <button style={{
          flex: 1, padding: '14px', borderRadius: 14,
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 13.5, fontWeight: 700,
          letterSpacing: 0.3, boxShadow: `0 4px 12px ${c.lavender}55`,
        }}>適用する（12件）</button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 3. 保存検索リスト
// ─────────────────────────────────────────────────────────────
function SavedSearches({ tweaks }) {
  const c = SF_C(tweaks);
  const saved = [
    {
      id: 's1', name: 'スアコレ完成セット',
      conds: ['スア', 'トレカ', '★4.5+', '横アリ周辺'],
      hits: 12, lastUsed: '今日',
      pinned: true,
    },
    {
      id: 's2', name: '生写真探し中',
      conds: ['生写真', '美品', '500m以内', '今日参戦'],
      hits: 5, lastUsed: '昨日',
    },
    {
      id: 's3', name: 'ヒナ箱推し向け',
      conds: ['ヒナ', '★4.0+', 'すべて'],
      hits: 28, lastUsed: '3日前',
    },
    {
      id: 's4', name: '5/4 東京ドーム参戦',
      conds: ['5/4 東京ドーム', '会場周辺', 'すべての推し'],
      hits: 0, lastUsed: '1週間前', empty: true,
    },
  ];
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      <SFHeader colors={c} title="保存した検索" sub={`${saved.length}件保存中`} right={
        <button style={{
          padding: '6px 12px', borderRadius: 999,
          background: c.lavender, color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 12, fontWeight: 700,
        }}>+ 新規</button>
      } />
      <div style={{ padding: '20px 18px 0' }}>
        <div style={{
          padding: '14px 16px', borderRadius: 12,
          background: `${c.lavender}10`, border: `1px solid ${c.lavender}30`,
          fontSize: 12, color: c.ink, lineHeight: 1.7,
          marginBottom: 18,
        }}>
          よく使う検索条件を保存。タップでワンタップ適用、新しいマッチがあれば件数バッジで通知します。
        </div>

        {saved.map(s => (
          <div key={s.id} style={{
            background: '#fff', borderRadius: 14,
            border: s.pinned ? `1.5px solid ${c.lavender}` : `0.5px solid ${c.divide}`,
            padding: '14px 16px', marginBottom: 10,
            boxShadow: s.pinned ? `0 4px 12px ${c.lavender}22` : 'none',
            position: 'relative',
          }}>
            {s.pinned && (
              <span style={{
                position: 'absolute', top: -8, left: 12,
                fontSize: 9, fontWeight: 800, color: '#fff',
                background: `linear-gradient(135deg, ${c.lavender}, ${c.pink})`,
                padding: '2px 8px', borderRadius: 999, letterSpacing: 0.4,
              }}>📌 ピン留め</span>
            )}
            <div style={{
              display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between',
              marginBottom: 10, gap: 10,
            }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontWeight: 800, marginBottom: 4 }}>{s.name}</div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                  {s.conds.map((cd, i) => (
                    <span key={i} style={{
                      fontSize: 10, color: c.mute, fontWeight: 600,
                      background: c.subtle, padding: '2px 7px', borderRadius: 999,
                    }}>{cd}</span>
                  ))}
                </div>
              </div>
              <svg width="20" height="20" viewBox="0 0 20 20" fill={c.mute}>
                <circle cx="4" cy="10" r="1.5"/><circle cx="10" cy="10" r="1.5"/><circle cx="16" cy="10" r="1.5"/>
              </svg>
            </div>
            <div style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              padding: '10px 12px', borderRadius: 10,
              background: s.empty ? c.subtle : `${c.lavender}10`,
              fontSize: 11,
            }}>
              <div style={{ color: s.empty ? c.mute : c.ink }}>
                {s.empty ? '現在マッチなし' : <>マッチ <b style={{ color: c.lavender }}>{s.hits}件</b></>}
                <span style={{ color: c.mute, marginLeft: 8 }}>・最終使用 {s.lastUsed}</span>
              </div>
              <button style={{
                padding: '5px 12px', borderRadius: 999,
                background: s.empty ? '#fff' : c.lavender,
                color: s.empty ? c.mute : '#fff',
                border: s.empty ? `0.5px solid ${c.divide}` : 0,
                fontFamily: 'inherit', fontSize: 11, fontWeight: 700,
              }}>適用</button>
            </div>
          </div>
        ))}

        <button style={{
          width: '100%', padding: '14px',
          background: 'transparent', border: `1.5px dashed ${c.lavender}55`,
          color: c.lavender, borderRadius: 14,
          fontFamily: 'inherit', fontSize: 13, fontWeight: 700,
          cursor: 'pointer', marginBottom: 12,
        }}>＋ 現在のフィルタを保存</button>
      </div>
    </div>
  );
}

Object.assign(window, { SearchScreen, FilterScreen, SavedSearches });
