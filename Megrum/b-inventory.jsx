// b-inventory.jsx
// B-1 Inventory grid + B-2 Capture flow (3 steps) + B-3 X post + B-4 Quick mode
// Uses brand palette tokens passed via tweaks prop. Reuses Avatar, Tcg, Ic from home-variations.jsx

const BCOLORS = (t) => ({
  lavender: t.primary,
  sky: t.secondary,
  pink: t.accent,
  ink: '#3a324a',
  mute: 'rgba(58,50,74,0.55)',
  faint: 'rgba(58,50,74,0.3)',
  subtle: 'rgba(58,50,74,0.06)',
  bg: '#fbf9fc',
  yuzuri: t.primary,         // 紫
  motome: t.secondary,        // 水色
});

// ─────────────────────────────────────────────────────────────
// B-1. Inventory list — 譲るもの専用 × view modes (list/collection)
//   list: 3 sub-views (active / keep / traded)
//   collection: wish-based pokedex (silhouette + progress)
//   ※「求めるもの」は Wishリスト画面に集約
// ─────────────────────────────────────────────────────────────
function InventoryScreen({ tweaks, initialTab = 'yuzuri', initialSub = 'active' }) {
  const c = BCOLORS(tweaks);
  const tab = 'yuzuri';
  const [sub, setSub] = React.useState(initialSub); // active | keep | traded
  const [carrying, setCarrying] = React.useState(true);

  const items = MOCK_ITEMS;
  const yuzuri = items.filter(i => i.kind === 'yuzuri');
  const yActive = yuzuri.filter(i => (i.holdStatus || 'active') === 'active');
  const yKeep   = yuzuri.filter(i => i.holdStatus === 'keep');
  const yTraded = yuzuri.filter(i => i.holdStatus === 'traded');
  const subList = sub === 'active' ? yActive : sub === 'keep' ? yKeep : yTraded;
  const carryCount = yActive.filter(i => i.carrying).length;
  const tabColor = c.yuzuri;

  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, fontFeatureSettings: '"palt"',
    }}>
      <div style={{ height: 60 }} />

      {/* Header */}
      <div style={{
        padding: '10px 18px 6px',
        background: '#fff',
        borderBottom: `0.5px solid ${c.subtle}`,
      }}>
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          marginBottom: 10,
        }}>
          <div style={{ fontSize: 19, fontWeight: 800, letterSpacing: 0.3 }}>マイ在庫</div>
          <div style={{ display: 'flex', gap: 6 }}>
            <IconBtn colors={c}>
              <svg width="14" height="14" viewBox="0 0 14 14"><path d="M2 4h10M3.5 7h7M5 10h4" stroke={c.ink} strokeWidth="1.5" strokeLinecap="round"/></svg>
            </IconBtn>
            <IconBtn colors={c}>
              <svg width="14" height="14" viewBox="0 0 14 14"><circle cx="6" cy="6" r="4" stroke={c.ink} strokeWidth="1.5" fill="none"/><path d="M9.5 9.5L12 12" stroke={c.ink} strokeWidth="1.5" strokeLinecap="round"/></svg>
            </IconBtn>
          </div>
        </div>

        {/* Mobile mode toggle — big */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 10,
          padding: '10px 12px',
          borderRadius: 14,
          background: carrying
            ? `linear-gradient(120deg, ${c.lavender}26, ${c.pink}26)`
            : c.subtle,
          border: `0.5px solid ${carrying ? c.lavender + '55' : c.subtle}`,
          marginBottom: 8,
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: 10,
            background: carrying ? `linear-gradient(135deg, ${c.lavender}, ${c.pink})` : '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: carrying ? `0 4px 10px ${c.lavender}40` : 'none',
            border: carrying ? 0 : `0.5px solid ${c.subtle}`,
          }}>
            <svg width="18" height="18" viewBox="0 0 18 18">
              <rect x="3" y="5" width="12" height="10" rx="2" stroke={carrying ? '#fff' : c.mute} strokeWidth="1.5" fill="none"/>
              <path d="M6 5V3.5C6 2.5 7 2 9 2s3 .5 3 1.5V5" stroke={carrying ? '#fff' : c.mute} strokeWidth="1.5" fill="none"/>
            </svg>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{
              fontSize: 13.5, fontWeight: 700,
              color: carrying ? c.ink : c.mute,
            }}>
              {carrying ? '【携帯中】今日持参中' : '【自宅】保管中'}
            </div>
            <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1, fontVariantNumeric: 'tabular-nums' }}>
              {carrying ? `${carryCount} 点を会場で交換可能` : 'タップで携帯モードに切替'}
            </div>
          </div>
          {/* Switch */}
          <button onClick={() => setCarrying(!carrying)} style={{
            width: 48, height: 28, borderRadius: 14, border: 0,
            background: carrying ? c.lavender : c.faint,
            position: 'relative', cursor: 'pointer', padding: 0,
            transition: 'background 0.2s',
          }}>
            <div style={{
              position: 'absolute', top: 2, left: carrying ? 22 : 2,
              width: 24, height: 24, borderRadius: '50%',
              background: '#fff', boxShadow: '0 2px 4px rgba(0,0,0,0.15)',
              transition: 'left 0.2s',
            }} />
          </button>
        </div>

      </div>

      {/* Body */}
      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 110 }}>
        <YuzuriListView
          colors={c}
          sub={sub} setSub={setSub}
          counts={{ active: yActive.length, keep: yKeep.length, traded: yTraded.length }}
          list={subList}
        />
      </div>

      {/* Sticky CTAs */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '12px 18px 30px',
        background: 'rgba(255,255,255,0.92)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `0.5px solid ${c.lavender}22`,
        display: 'flex', gap: 8,
      }}>
        <button style={{
          height: 48, padding: '0 16px', borderRadius: 14,
          background: '#fff', color: c.ink,
          border: `0.5px solid ${c.subtle}`,
          fontFamily: 'inherit', fontSize: 13, fontWeight: 600,
          display: 'inline-flex', alignItems: 'center', gap: 6,
        }}>
          <svg width="13" height="13" viewBox="0 0 13 13"><path d="M2 5l4-3 4 3v6H2zM5 11V8h2v3" stroke={c.ink} strokeWidth="1.4" fill="none"/></svg>
          セット
        </button>
        <button style={{
          flex: 1, height: 48, borderRadius: 14,
          background: `linear-gradient(135deg, ${tabColor}, ${c.pink})`,
          color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 14.5, fontWeight: 700, letterSpacing: 0.4,
          boxShadow: `0 6px 16px ${tabColor}50`,
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          <svg width="14" height="14" viewBox="0 0 14 14"><path d="M7 1v12M1 7h12" stroke="#fff" strokeWidth="2" strokeLinecap="round"/></svg>
          譲るものを追加
        </button>
      </div>
    </div>
  );
}

function IconBtn({ children, colors }) {
  return (
    <button style={{
      width: 32, height: 32, borderRadius: 10,
      background: '#fff', border: `0.5px solid ${colors.subtle}`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      cursor: 'pointer',
    }}>{children}</button>
  );
}

function AddCard({ colors: c, tabColor, kind }) {
  return (
    <button style={{
      aspectRatio: '3 / 4', borderRadius: 12,
      background: '#fff',
      border: `1.5px dashed ${tabColor}88`,
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      gap: 6, cursor: 'pointer', padding: 0,
    }}>
      <div style={{
        width: 32, height: 32, borderRadius: '50%',
        background: `${tabColor}26`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <svg width="14" height="14" viewBox="0 0 14 14"><path d="M7 1v12M1 7h12" stroke={tabColor} strokeWidth="2" strokeLinecap="round"/></svg>
      </div>
      <div style={{ fontSize: 10.5, color: tabColor, fontWeight: 700 }}>追加</div>
      <div style={{ fontSize: 9, color: c.mute }}>{kind === 'yuzuri' ? '撮影で登録' : '推しから選ぶ'}</div>
    </button>
  );
}

// ── YuzuriListView: 3 sub-views (active / keep / traded) + filter chips + grid ──
function YuzuriListView({ colors: c, sub, setSub, counts, list }) {
  const subTabs = [
    { id: 'active', label: '譲る候補', sub: 'マッチ対象', n: counts.active, color: c.yuzuri },
    { id: 'keep',   label: '自分用キープ', sub: 'マッチ対象外', n: counts.keep, color: c.pink },
    { id: 'traded', label: '過去に譲った', sub: '履歴', n: counts.traded, color: c.faint },
  ];
  const cur = subTabs.find(s => s.id === sub);
  return (
    <>
      {/* Sub-view tabs (3) */}
      <div style={{
        display: 'flex', gap: 4, padding: '12px 16px 6px',
      }}>
        {subTabs.map(s => (
          <button key={s.id} onClick={() => setSub(s.id)} style={{
            flex: 1, padding: '10px 4px', borderRadius: 12,
            background: sub === s.id ? '#fff' : c.subtle,
            border: sub === s.id ? `1.5px solid ${s.color}` : `0.5px solid ${c.subtle}`,
            cursor: 'pointer', fontFamily: 'inherit',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
            position: 'relative',
          }}>
            <div style={{
              fontSize: 12, fontWeight: sub === s.id ? 800 : 600,
              color: sub === s.id ? c.ink : c.mute,
            }}>{s.label}
              <span style={{
                marginLeft: 5, fontSize: 10, color: sub === s.id ? s.color : c.mute,
                fontVariantNumeric: 'tabular-nums', fontWeight: 700,
              }}>{s.n}</span>
            </div>
            <div style={{ fontSize: 9, color: c.mute }}>{s.sub}</div>
          </button>
        ))}
      </div>

      {/* Filter chips — separated into 推し and グッズ種別 */}
      <div style={{ padding: '6px 16px 4px' }}>
        <div style={{
          display: 'flex', gap: 6, alignItems: 'center',
          overflowX: 'auto', WebkitOverflowScrolling: 'touch',
          marginBottom: 6,
        }}>
          <span style={{
            fontSize: 9.5, fontWeight: 700, color: c.mute,
            letterSpacing: 0.4, flexShrink: 0,
            paddingRight: 6, width: 30,
          }}>推し</span>
          {['すべて', 'LUMENA', 'スア', 'ヒナ', '呪術廻戦', '+ 他'].map((f, i) => (
            <button key={f} style={{
              padding: '5px 11px', borderRadius: 999,
              background: i === 0 ? c.yuzuri : '#fff',
              color: i === 0 ? '#fff' : c.ink,
              border: i === 0 ? 0 : `0.5px solid ${c.subtle}`,
              fontFamily: 'inherit', fontSize: 11, fontWeight: 600,
              flexShrink: 0, whiteSpace: 'nowrap',
            }}>{f}</button>
          ))}
        </div>
        <div style={{
          display: 'flex', gap: 6, alignItems: 'center',
          overflowX: 'auto', WebkitOverflowScrolling: 'touch',
          paddingBottom: 4,
        }}>
          <span style={{
            fontSize: 9.5, fontWeight: 700, color: c.mute,
            letterSpacing: 0.4, flexShrink: 0,
            paddingRight: 6, width: 30,
          }}>種別</span>
          {['すべて', 'トレカ', '生写真', '缶バッジ', 'アクスタ', 'スロガン'].map((f, i) => (
            <button key={f} style={{
              padding: '5px 11px', borderRadius: 999,
              background: i === 0 ? c.yuzuri : '#fff',
              color: i === 0 ? '#fff' : c.ink,
              border: i === 0 ? 0 : `0.5px solid ${c.subtle}`,
              fontFamily: 'inherit', fontSize: 11, fontWeight: 600,
              flexShrink: 0, whiteSpace: 'nowrap',
            }}>{f}</button>
          ))}
        </div>
      </div>

      {/* Sub-view explanation banner */}
      {sub === 'keep' && (
        <div style={{
          margin: '4px 16px 8px', padding: '10px 12px',
          borderRadius: 12, background: `${c.pink}1a`,
          border: `0.5px solid ${c.pink}55`,
          fontSize: 11.5, color: c.ink, lineHeight: 1.5,
          display: 'flex', gap: 8, alignItems: 'flex-start',
        }}>
          <div style={{
            width: 16, height: 16, borderRadius: '50%',
            background: c.pink, color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 10, fontWeight: 800, flexShrink: 0, marginTop: 1,
          }}>🔒</div>
          <div>
            <b>自分用キープ</b>
            <span style={{ color: c.mute }}> — マッチング・打診の対象外。コレクションには反映されます</span>
          </div>
        </div>
      )}
      {sub === 'traded' && (
        <div style={{
          margin: '4px 16px 8px', padding: '10px 12px',
          borderRadius: 12, background: c.subtle,
          fontSize: 11.5, color: c.mute, lineHeight: 1.5,
          display: 'flex', gap: 8, alignItems: 'flex-start',
        }}>
          <span style={{ flexShrink: 0 }}>📦</span>
          <div>過去に譲ったアイテムの履歴。タップ時は詳細のみ表示し、更新・削除はできません</div>
        </div>
      )}

      {/* Grid */}
      <div style={{
        padding: '4px 16px 0',
        display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10,
      }}>
        {sub === 'active' && <AddCard colors={c} tabColor={c.yuzuri} kind="yuzuri" />}
        {list.map(item => (
          <ItemCard key={item.id} item={item} colors={c} kind="yuzuri" />
        ))}
      </div>

      {/* Duplicate detection note (only on active) */}
      {sub === 'active' && list.length > 0 && (
        <div style={{
          margin: '12px 16px 0',
          padding: '10px 12px', borderRadius: 12,
          background: `${c.pink}1f`,
          border: `0.5px solid ${c.pink}66`,
          fontSize: 11.5, color: c.ink, lineHeight: 1.5,
          display: 'flex', gap: 8, alignItems: 'flex-start',
        }}>
          <div style={{
            width: 16, height: 16, borderRadius: '50%',
            background: c.pink, color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 10, fontWeight: 800, flexShrink: 0, marginTop: 1,
          }}>!</div>
          <div>
            <b>似たトレカが2件あります</b>
            <span style={{ color: c.mute }}> — まとめるか個別に管理するか確認してください</span>
          </div>
        </div>
      )}
    </>
  );
}

// ── MotomeListView: simple grid ──
function MotomeListView({ colors: c, list, tabColor }) {
  return (
    <>
      <div style={{ padding: '12px 16px 4px' }}>
        <div style={{
          display: 'flex', gap: 6, alignItems: 'center',
          overflowX: 'auto', WebkitOverflowScrolling: 'touch',
          marginBottom: 6,
        }}>
          <span style={{
            fontSize: 9.5, fontWeight: 700, color: c.mute,
            letterSpacing: 0.4, flexShrink: 0,
            paddingRight: 6, width: 30,
          }}>推し</span>
          {['すべて', 'LUMENA', 'スア', 'ヒナ', 'リナ', '+ 他'].map((f, i) => (
            <button key={f} style={{
              padding: '5px 11px', borderRadius: 999,
              background: i === 0 ? tabColor : '#fff',
              color: i === 0 ? '#fff' : c.ink,
              border: i === 0 ? 0 : `0.5px solid ${c.subtle}`,
              fontFamily: 'inherit', fontSize: 11, fontWeight: 600,
              flexShrink: 0, whiteSpace: 'nowrap',
            }}>{f}</button>
          ))}
        </div>
        <div style={{
          display: 'flex', gap: 6, alignItems: 'center',
          overflowX: 'auto', WebkitOverflowScrolling: 'touch',
          paddingBottom: 4,
        }}>
          <span style={{
            fontSize: 9.5, fontWeight: 700, color: c.mute,
            letterSpacing: 0.4, flexShrink: 0,
            paddingRight: 6, width: 30,
          }}>種別</span>
          {['すべて', 'トレカ', '生写真', '缶バッジ', 'アクスタ', 'スロガン'].map((f, i) => (
            <button key={f} style={{
              padding: '5px 11px', borderRadius: 999,
              background: i === 0 ? tabColor : '#fff',
              color: i === 0 ? '#fff' : c.ink,
              border: i === 0 ? 0 : `0.5px solid ${c.subtle}`,
              fontFamily: 'inherit', fontSize: 11, fontWeight: 600,
              flexShrink: 0, whiteSpace: 'nowrap',
            }}>{f}</button>
          ))}
        </div>
      </div>
      <div style={{
        padding: '8px 16px',
        display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10,
      }}>
        <AddCard colors={c} tabColor={tabColor} kind="motome" />
        {list.map(item => (
          <ItemCard key={item.id} item={item} colors={c} kind="motome" />
        ))}
      </div>
      <div style={{
        margin: '14px 16px 0', padding: '12px 14px',
        borderRadius: 12, background: `${c.sky}14`,
        border: `0.5px solid ${c.sky}44`,
        fontSize: 11.5, color: c.ink, lineHeight: 1.5,
      }}>
        <b>💡 ウィッシュタブと同期</b>
        <span style={{ color: c.mute }}> — 「求めるもの」はウィッシュリストとして共通管理</span>
      </div>
    </>
  );
}

function ItemCard({ item, colors: c, kind }) {
  const tone = kind === 'yuzuri' ? c.yuzuri : c.motome;
  return (
    <div style={{
      position: 'relative', aspectRatio: '3 / 4',
      borderRadius: 12, overflow: 'hidden',
      background: `repeating-linear-gradient(135deg, hsl(${item.hue}, 28%, 88%) 0 6px, hsl(${item.hue}, 28%, 82%) 6px 11px)`,
      boxShadow: '0 2px 6px rgba(58,50,74,0.08)',
      border: `0.5px solid ${c.subtle}`,
    }}>
      {/* Member name plate */}
      <div style={{
        position: 'absolute', top: 6, left: 6, right: 6,
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{
          padding: '2px 6px', borderRadius: 5,
          background: 'rgba(255,255,255,0.85)',
          fontSize: 9, fontWeight: 700, color: `hsl(${item.hue}, 35%, 28%)`,
        }}>{item.member}</div>
        {item.carrying && (
          <div style={{
            width: 18, height: 18, borderRadius: '50%',
            background: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 1px 3px rgba(0,0,0,0.12)',
          }}>
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: c.pink }} />
          </div>
        )}
      </div>
      {/* Initial */}
      <div style={{
        position: 'absolute', top: '50%', left: '50%',
        transform: 'translate(-50%, -50%)',
        fontSize: 28, fontWeight: 800, color: 'rgba(255,255,255,0.9)',
        fontFamily: '"Noto Sans JP", sans-serif',
        textShadow: `0 2px 6px hsla(${item.hue}, 30%, 30%, 0.4)`,
      }}>{item.member[0]}</div>

      {/* Bottom strip */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '6px 7px',
        background: 'linear-gradient(180deg, transparent, rgba(255,255,255,0.95))',
        display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between',
      }}>
        <div>
          <div style={{ fontSize: 10, fontWeight: 700, color: c.ink, lineHeight: 1.2 }}>
            {item.type}
          </div>
          <div style={{ fontSize: 8.5, color: c.mute, lineHeight: 1.2, marginTop: 1 }}>
            {item.series}
          </div>
        </div>
        {item.qty > 1 && (
          <div style={{
            padding: '2px 6px', borderRadius: 6,
            background: tone, color: '#fff',
            fontSize: 10, fontWeight: 800, fontVariantNumeric: 'tabular-nums',
          }}>×{item.qty}</div>
        )}
      </div>

      {/* Status corner: draft */}
      {item.status === 'draft' && (
        <div style={{
          position: 'absolute', top: 0, right: 0,
          padding: '2px 7px',
          background: c.faint, color: '#fff',
          fontSize: 8, fontWeight: 800, letterSpacing: 0.4,
          borderBottomLeftRadius: 8,
        }}>登録中</div>
      )}
    </div>
  );
}

const MOCK_ITEMS = [
  { id: 1, kind: 'yuzuri', member: 'スア', type: 'トレカ', series: 'WORLD TOUR', qty: 2, hue: 280, carrying: true, status: 'public', holdStatus: 'active' },
  { id: 2, kind: 'yuzuri', member: 'ヒナ', type: '生写真', series: '5th Mini', qty: 3, hue: 200, carrying: true, status: 'public', holdStatus: 'active' },
  { id: 3, kind: 'yuzuri', member: 'スア', type: 'トレカ', series: 'WORLD TOUR', qty: 1, hue: 285, carrying: true, status: 'public', holdStatus: 'keep' },
  { id: 4, kind: 'yuzuri', member: 'リナ', type: 'スロガン', series: '公式', qty: 1, hue: 350, carrying: false, status: 'public', holdStatus: 'active' },
  { id: 5, kind: 'yuzuri', member: 'ヒナ', type: 'トレカ', series: 'POP-UP', qty: 1, hue: 195, carrying: true, status: 'draft', holdStatus: 'active' },
  { id: 6, kind: 'yuzuri', member: 'スア', type: '生写真', series: 'STUDIO', qty: 4, hue: 290, carrying: false, status: 'public', holdStatus: 'keep' },
  { id: 7, kind: 'yuzuri', member: 'チェ', type: 'トレカ', series: 'JAPAN', qty: 1, hue: 30, carrying: true, status: 'public', holdStatus: 'active' },
  { id: 8, kind: 'yuzuri', member: 'リナ', type: 'トレカ', series: 'WORLD TOUR', qty: 2, hue: 355, carrying: false, status: 'limited', holdStatus: 'traded' },
  { id: 13, kind: 'yuzuri', member: 'ヒナ', type: 'トレカ', series: 'JAPAN', qty: 1, hue: 200, carrying: false, status: 'public', holdStatus: 'traded' },
  // motome
  { id: 9, kind: 'motome', member: 'ヒナ', type: 'トレカ', series: 'WORLD TOUR', qty: 3, hue: 200 },
  { id: 10, kind: 'motome', member: 'ヒナ', type: '生写真', series: 'STUDIO', qty: 1, hue: 205 },
  { id: 11, kind: 'motome', member: 'スア', type: 'トレカ', series: 'JAPAN', qty: 2, hue: 280 },
  { id: 12, kind: 'motome', member: 'チェ', type: 'スロガン', series: '公式', qty: 1, hue: 30 },
];

// ─────────────────────────────────────────────────────────────
// B-2. Capture flow — 3 steps: shoot → crop → meta
// ─────────────────────────────────────────────────────────────
function CaptureFlowScreen({ tweaks, step = 'shoot' }) {
  const c = BCOLORS(tweaks);
  if (step === 'shoot') return <ShootStep colors={c} />;
  if (step === 'crop') return <CropStep colors={c} />;
  if (step === 'meta') return <MetaStep colors={c} />;
  if (step === 'xpost') return <XPostStep colors={c} />;
  return null;
}

function StepHeader({ colors: c, step, total = 3, title, sub }) {
  return (
    <div style={{
      padding: '10px 14px',
      borderBottom: `0.5px solid ${c.subtle}`,
      background: '#fff',
    }}>
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        marginBottom: 8,
      }}>
        <button style={{
          width: 32, height: 32, borderRadius: '50%',
          background: '#fff', border: `0.5px solid ${c.subtle}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="9" height="14" viewBox="0 0 9 14"><path d="M7 1L2 7l5 6" stroke={c.ink} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </button>
        <div style={{
          fontSize: 11, color: c.mute, fontWeight: 600,
          fontVariantNumeric: 'tabular-nums',
        }}>STEP {step} / {total}</div>
        <button style={{
          fontSize: 12, color: c.mute, background: 'transparent', border: 0,
          fontFamily: 'inherit', cursor: 'pointer',
        }}>キャンセル</button>
      </div>
      {/* progress */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 10 }}>
        {Array.from({ length: total }).map((_, i) => (
          <div key={i} style={{
            flex: 1, height: 3, borderRadius: 2,
            background: i < step ? c.lavender : c.subtle,
          }} />
        ))}
      </div>
      <div style={{ fontSize: 17, fontWeight: 800, letterSpacing: 0.3 }}>{title}</div>
      <div style={{ fontSize: 11.5, color: c.mute, marginTop: 2 }}>{sub}</div>
    </div>
  );
}

function ShootStep({ colors: c }) {
  return (
    <div style={{
      width: '100%', height: '100%',
      background: '#0a0810',
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: '#fff', position: 'relative', overflow: 'hidden',
    }}>
      <div style={{ height: 60 }} />
      {/* dark camera viewfinder */}
      <div style={{
        position: 'absolute', inset: 0,
        background: `radial-gradient(circle at 50% 45%, #1a1525, #0a0810)`,
      }}>
        {/* simulate paper backdrop with cards on it */}
        <div style={{
          position: 'absolute', top: '32%', left: '50%',
          transform: 'translate(-50%, 0)',
          width: '70%', aspectRatio: '4 / 3',
          background: 'rgba(255,255,255,0.07)',
          borderRadius: 8,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          gap: 10,
        }}>
          {[280, 285, 290].map((hue, i) => (
            <div key={i} style={{
              width: 50, height: 70, borderRadius: 5,
              background: `repeating-linear-gradient(135deg, hsla(${hue}, 30%, 75%, 0.6) 0 5px, hsla(${hue}, 30%, 65%, 0.6) 5px 10px)`,
              boxShadow: '0 4px 12px rgba(0,0,0,0.4)',
              transform: `rotate(${(i - 1) * 3}deg)`,
              display: 'flex', alignItems: 'flex-end', justifyContent: 'center',
              paddingBottom: 6, fontSize: 9, fontWeight: 700,
              color: 'rgba(255,255,255,0.7)',
            }}>ス</div>
          ))}
        </div>
      </div>

      {/* top bar */}
      <div style={{
        position: 'absolute', top: 50, left: 0, right: 0, padding: '0 14px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <button style={{
          width: 36, height: 36, borderRadius: '50%',
          background: 'rgba(255,255,255,0.12)', border: 0,
          backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)',
          color: '#fff',
        }}>
          <svg width="14" height="14" viewBox="0 0 14 14"><path d="M2 2l10 10M12 2L2 12" stroke="#fff" strokeWidth="2" strokeLinecap="round"/></svg>
        </button>
        <div style={{
          padding: '6px 12px', borderRadius: 999,
          background: 'rgba(0,0,0,0.45)',
          backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)',
          fontSize: 11.5, fontWeight: 600,
          display: 'inline-flex', alignItems: 'center', gap: 6,
        }}>
          <span style={{ width: 6, height: 6, borderRadius: '50%', background: '#e0a847' }} />
          オフライン保存
        </div>
        <div style={{ width: 36 }} />
      </div>

      {/* mode chips */}
      <div style={{
        position: 'absolute', top: 100, left: 0, right: 0, textAlign: 'center',
      }}>
        <div style={{
          display: 'inline-flex', gap: 4, padding: 3, borderRadius: 999,
          background: 'rgba(0,0,0,0.45)',
          backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)',
        }}>
          {['通常', 'クイック', '連続'].map((m, i) => (
            <button key={m} style={{
              padding: '5px 14px', borderRadius: 999,
              background: i === 0 ? '#fff' : 'transparent',
              color: i === 0 ? c.ink : '#fff',
              border: 0, fontFamily: 'inherit', fontSize: 11.5,
              fontWeight: i === 0 ? 700 : 500,
            }}>{m}</button>
          ))}
        </div>
      </div>

      {/* shutter strip */}
      <div style={{
        position: 'absolute', bottom: 60, left: 0, right: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'space-around',
        padding: '0 32px',
      }}>
        <button style={{
          width: 52, height: 52, borderRadius: 12,
          background: 'rgba(255,255,255,0.14)', border: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          {/* gallery */}
          <div style={{
            width: 26, height: 26, borderRadius: 4,
            background: `repeating-linear-gradient(135deg, ${c.lavender}88 0 4px, ${c.sky}88 4px 7px)`,
          }} />
        </button>
        <button style={{
          width: 76, height: 76, borderRadius: '50%',
          background: '#fff', border: '4px solid rgba(255,255,255,0.45)',
          boxShadow: '0 8px 24px rgba(0,0,0,0.4)',
        }} />
        <button style={{
          width: 52, height: 52, borderRadius: '50%',
          background: 'rgba(255,255,255,0.14)', border: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="20" height="20" viewBox="0 0 20 20">
            <path d="M3 7V4h3M17 7V4h-3M3 13v3h3M17 13v3h-3" stroke="#fff" strokeWidth="1.5" fill="none" strokeLinecap="round"/>
          </svg>
        </button>
      </div>

      {/* hint */}
      <div style={{
        position: 'absolute', bottom: 160, left: 0, right: 0, textAlign: 'center',
      }}>
        <div style={{
          display: 'inline-block',
          padding: '6px 12px', borderRadius: 999,
          background: 'rgba(0,0,0,0.5)',
          backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)',
          fontSize: 11, fontWeight: 500, color: '#fff',
        }}>白背景に置いて撮影 · 複数枚OK</div>
      </div>
    </div>
  );
}

function CropStep({ colors: c }) {
  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, fontFeatureSettings: '"palt"',
    }}>
      <div style={{ height: 60 }} />
      <StepHeader colors={c} step={2} title="切り抜き" sub="ドラッグで矩形を調整 · 必要なら回転" />

      <div style={{ flex: 1, padding: '14px 16px 110px', overflowY: 'auto' }}>
        {/* Crop canvas */}
        <div style={{
          position: 'relative', aspectRatio: '4 / 3',
          background: `repeating-linear-gradient(135deg, ${c.subtle} 0 8px, rgba(58,50,74,0.1) 8px 14px)`,
          borderRadius: 14, overflow: 'hidden',
          boxShadow: '0 4px 12px rgba(58,50,74,0.1)',
        }}>
          {/* simulated photo of cards */}
          {[0, 1, 2].map(i => (
            <div key={i} style={{
              position: 'absolute',
              top: `${22 + i * 4}%`, left: `${20 + i * 22}%`,
              width: '18%', aspectRatio: '3 / 4',
              background: `repeating-linear-gradient(135deg, hsl(${280 + i * 5}, 35%, 75%) 0 5px, hsl(${280 + i * 5}, 35%, 65%) 5px 10px)`,
              borderRadius: 4, transform: `rotate(${(i - 1) * 4}deg)`,
              boxShadow: '0 4px 8px rgba(0,0,0,0.15)',
            }} />
          ))}

          {/* dimmed overlay outside crop */}
          <div style={{
            position: 'absolute', inset: 0, pointerEvents: 'none',
            background: `
              linear-gradient(to bottom, rgba(0,0,0,0.55) 0 18%, transparent 18% 82%, rgba(0,0,0,0.55) 82% 100%),
              linear-gradient(to right, rgba(0,0,0,0.55) 0 14%, transparent 14% 86%, rgba(0,0,0,0.55) 86% 100%)
            `,
            mixBlendMode: 'multiply',
          }} />

          {/* crop rect */}
          <div style={{
            position: 'absolute', top: '18%', left: '14%', right: '14%', bottom: '18%',
            border: '1.5px solid #fff',
            boxShadow: `0 0 0 1px ${c.lavender}, 0 0 24px ${c.lavender}66`,
          }}>
            {/* grid */}
            <div style={{
              position: 'absolute', inset: 0,
              backgroundImage: `
                linear-gradient(to right, rgba(255,255,255,0.4) 1px, transparent 1px),
                linear-gradient(to bottom, rgba(255,255,255,0.4) 1px, transparent 1px)
              `,
              backgroundSize: '33.33% 33.33%',
              opacity: 0.6,
            }} />
            {/* corner handles */}
            {['nw', 'ne', 'sw', 'se'].map(p => {
              const s = {
                width: 14, height: 14, position: 'absolute',
                background: '#fff', borderRadius: 3,
                boxShadow: `0 0 0 2px ${c.lavender}`,
              };
              if (p.includes('n')) s.top = -7; else s.bottom = -7;
              if (p.includes('w')) s.left = -7; else s.right = -7;
              return <div key={p} style={s} />;
            })}
            {/* edge handles */}
            {[
              { top: -5, left: '50%', transform: 'translateX(-50%)' },
              { bottom: -5, left: '50%', transform: 'translateX(-50%)' },
              { left: -5, top: '50%', transform: 'translateY(-50%)' },
              { right: -5, top: '50%', transform: 'translateY(-50%)' },
            ].map((p, i) => (
              <div key={i} style={{
                ...p, position: 'absolute', width: 10, height: 10,
                background: '#fff', borderRadius: 2,
                boxShadow: `0 0 0 2px ${c.lavender}`,
              }} />
            ))}
          </div>
        </div>

        {/* Multi-photo strip */}
        <div style={{
          marginTop: 12,
          display: 'flex', alignItems: 'center', gap: 8,
          padding: '10px 12px', borderRadius: 14,
          background: '#fff', border: `0.5px solid ${c.subtle}`,
        }}>
          <div style={{ fontSize: 11, color: c.mute, fontWeight: 600 }}>
            <span style={{ color: c.lavender, fontWeight: 800 }}>1</span> / 3 枚
          </div>
          <div style={{ flex: 1, display: 'flex', gap: 6, justifyContent: 'flex-end' }}>
            {[0, 1, 2].map(i => (
              <div key={i} style={{
                width: 32, height: 44, borderRadius: 4,
                background: `repeating-linear-gradient(135deg, hsl(${280 + i * 5}, 30%, 80%) 0 4px, hsl(${280 + i * 5}, 30%, 70%) 4px 7px)`,
                border: i === 0 ? `2px solid ${c.lavender}` : `0.5px solid ${c.subtle}`,
                boxShadow: i === 0 ? `0 0 0 1px ${c.lavender}` : 'none',
              }} />
            ))}
          </div>
        </div>

        {/* Tools */}
        <div style={{
          marginTop: 12, padding: '8px 4px',
          display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 4,
        }}>
          {[
            { label: '回転', icon: <path d="M3 7a4 4 0 117 2.5L8 11" stroke={c.ink} strokeWidth="1.4" fill="none" strokeLinecap="round"/> },
            { label: '反転', icon: <><path d="M2 7h10M7 3v8" stroke={c.ink} strokeWidth="1.4" strokeLinecap="round"/><path d="M4 5l-2 2 2 2M10 5l2 2-2 2" stroke={c.ink} strokeWidth="1.4" fill="none" strokeLinecap="round"/></> },
            { label: '比率', icon: <rect x="2" y="3" width="10" height="8" stroke={c.ink} strokeWidth="1.4" fill="none" rx="1"/> },
            { label: '補正', icon: <path d="M4 7h6M7 4l3 3-3 3" stroke={c.ink} strokeWidth="1.4" fill="none" strokeLinecap="round" strokeLinejoin="round"/> },
          ].map(tool => (
            <button key={tool.label} style={{
              padding: '10px 0', borderRadius: 10,
              background: '#fff', border: `0.5px solid ${c.subtle}`,
              fontFamily: 'inherit', fontSize: 11, color: c.ink,
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
              cursor: 'pointer',
            }}>
              <svg width="14" height="14" viewBox="0 0 14 14">{tool.icon}</svg>
              {tool.label}
            </button>
          ))}
        </div>
      </div>

      {/* CTA */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '12px 18px 30px',
        background: 'rgba(255,255,255,0.92)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `0.5px solid ${c.lavender}22`,
        display: 'flex', gap: 8,
      }}>
        <button style={{
          height: 48, padding: '0 16px', borderRadius: 14,
          background: '#fff', color: c.ink,
          border: `0.5px solid ${c.subtle}`,
          fontFamily: 'inherit', fontSize: 13, fontWeight: 600,
        }}>戻る</button>
        <button style={{
          flex: 1, height: 48, borderRadius: 14,
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 14.5, fontWeight: 700, letterSpacing: 0.4,
          boxShadow: `0 6px 16px ${c.lavender}50`,
        }}>次へ — メタ入力</button>
      </div>
    </div>
  );
}

function MetaStep({ colors: c }) {
  const [member, setMember] = React.useState('スア');
  const [type, setType] = React.useState('トレカ');
  const [qty, setQty] = React.useState(2);
  const [condition, setCondition] = React.useState(0);
  const [status, setStatus] = React.useState('public');
  const [tone, setTone] = React.useState('standard');

  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, fontFeatureSettings: '"palt"',
    }}>
      <div style={{ height: 60 }} />
      <StepHeader colors={c} step={3} title="メタ入力" sub="3枚分まとめて適用 · あとから個別に編集できます" />

      <div style={{ flex: 1, overflowY: 'auto', padding: '14px 16px 110px' }}>
        {/* Cropped previews */}
        <div style={{
          display: 'flex', gap: 6, marginBottom: 14,
          padding: 10, borderRadius: 12,
          background: '#fff', border: `0.5px solid ${c.subtle}`,
          alignItems: 'center',
        }}>
          {[0, 1, 2].map(i => (
            <div key={i} style={{
              width: 44, height: 60, borderRadius: 4,
              background: `repeating-linear-gradient(135deg, hsl(${280 + i * 5}, 35%, 78%) 0 5px, hsl(${280 + i * 5}, 35%, 70%) 5px 9px)`,
              boxShadow: '0 2px 4px rgba(0,0,0,0.08)',
            }} />
          ))}
          <div style={{ flex: 1, paddingLeft: 6 }}>
            <div style={{ fontSize: 12.5, fontWeight: 700 }}>3枚に共通設定</div>
            <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>1枚だけ違う場合は次の画面で個別編集</div>
          </div>
        </div>

        {/* キャラ (member) */}
        <FieldLabel colors={c}>キャラ <span style={{ color: c.lavender }}>*</span></FieldLabel>
        <div style={{
          display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 14,
        }}>
          {['スア', 'ヒナ', 'リナ', 'チェ', 'ナナ', '+ 他'].map(m => (
            <button key={m} onClick={() => m !== '+ 他' && setMember(m)} style={{
              padding: '8px 14px', borderRadius: 999,
              background: member === m ? c.lavender : '#fff',
              color: member === m ? '#fff' : c.ink,
              border: member === m ? 0 : `0.5px solid ${c.subtle}`,
              fontFamily: 'inherit', fontSize: 12.5, fontWeight: member === m ? 700 : 500,
              cursor: 'pointer',
            }}>{m}</button>
          ))}
        </div>

        {/* グッズ種別 (type) */}
        <FieldLabel colors={c}>グッズ種別 <span style={{ color: c.lavender }}>*</span></FieldLabel>
        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 6,
          marginBottom: 14,
        }}>
          {[
            { label: 'トレカ', short: 'カード' },
            { label: '生写真', short: '写真' },
            { label: 'スロガン', short: 'バナー' },
            { label: 'オケ', short: 'オケ' },
          ].map(t => (
            <button key={t.label} onClick={() => setType(t.label)} style={{
              padding: '12px 0', borderRadius: 12,
              background: type === t.label ? `${c.lavender}1f` : '#fff',
              color: type === t.label ? c.lavender : c.ink,
              border: type === t.label ? `1.5px solid ${c.lavender}` : `0.5px solid ${c.subtle}`,
              fontFamily: 'inherit', fontSize: 12.5,
              fontWeight: type === t.label ? 700 : 500,
              cursor: 'pointer',
            }}>{t.label}</button>
          ))}
        </div>

        {/* シリーズ (series) */}
        <FieldLabel colors={c}>シリーズ</FieldLabel>
        <button style={{
          width: '100%', boxSizing: 'border-box',
          padding: '12px 14px', borderRadius: 12,
          background: '#fff', border: `0.5px solid ${c.subtle}`,
          fontFamily: 'inherit', fontSize: 13, color: c.ink,
          textAlign: 'left', display: 'flex', justifyContent: 'space-between',
          alignItems: 'center', marginBottom: 14, cursor: 'pointer',
        }}>
          <span>WORLD TOUR Ver.</span>
          <span style={{ color: c.mute, fontSize: 11 }}>変更 ›</span>
        </button>

        {/* 数量 (qty) — stepper */}
        <FieldLabel colors={c}>数量</FieldLabel>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 12,
          padding: '8px 12px', borderRadius: 12,
          background: '#fff', border: `0.5px solid ${c.subtle}`,
          marginBottom: 14,
        }}>
          <button onClick={() => setQty(Math.max(1, qty - 1))} style={{
            width: 36, height: 36, borderRadius: 10,
            background: c.subtle, border: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer',
          }}>
            <svg width="14" height="14" viewBox="0 0 14 14"><path d="M2 7h10" stroke={c.ink} strokeWidth="2" strokeLinecap="round"/></svg>
          </button>
          <div style={{
            flex: 1, textAlign: 'center', fontSize: 22, fontWeight: 800,
            fontVariantNumeric: 'tabular-nums', color: c.ink,
          }}>{qty}<span style={{ fontSize: 13, color: c.mute, fontWeight: 500, marginLeft: 4 }}>枚</span></div>
          <button onClick={() => setQty(qty + 1)} style={{
            width: 36, height: 36, borderRadius: 10,
            background: `${c.lavender}26`, border: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer',
          }}>
            <svg width="14" height="14" viewBox="0 0 14 14"><path d="M7 2v10M2 7h10" stroke={c.lavender} strokeWidth="2" strokeLinecap="round"/></svg>
          </button>
        </div>

        {/* 状態 (condition) — segmented */}
        <FieldLabel colors={c}>状態</FieldLabel>
        <div style={{
          display: 'flex', gap: 4, padding: 3,
          background: c.subtle, borderRadius: 10, marginBottom: 14,
        }}>
          {['美品', '中古', '傷あり'].map((s, i) => (
            <button key={s} onClick={() => setCondition(i)} style={{
              flex: 1, height: 32, borderRadius: 8,
              background: condition === i ? '#fff' : 'transparent',
              color: condition === i ? c.ink : c.mute,
              border: 0, fontFamily: 'inherit', fontSize: 12,
              fontWeight: condition === i ? 700 : 500,
              boxShadow: condition === i ? '0 1px 3px rgba(58,50,74,0.1)' : 'none',
            }}>{s}</button>
          ))}
        </div>

        {/* メモ (memo) */}
        <FieldLabel colors={c}>メモ <span style={{ color: c.mute, fontWeight: 400 }}>(任意)</span></FieldLabel>
        <div style={{
          padding: '10px 12px', borderRadius: 12,
          background: '#fff', border: `0.5px solid ${c.subtle}`,
          fontSize: 12.5, color: c.faint, minHeight: 50, marginBottom: 14,
        }}>例: 開封済み・スリーブ付き</div>

        {/* 掲載ステータス */}
        <FieldLabel colors={c}>掲載ステータス</FieldLabel>
        <div style={{
          display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 14,
        }}>
          {[
            { id: 'public', label: '公開', sub: '探索タブ・マッチング対象', icon: '◯' },
            { id: 'limited', label: '閲覧限定', sub: '相互フォローのみ', icon: '◐' },
            { id: 'draft', label: '登録中', sub: 'マッチング対象外', icon: '–' },
          ].map(s => (
            <button key={s.id} onClick={() => setStatus(s.id)} style={{
              padding: '10px 12px', borderRadius: 12,
              background: '#fff',
              border: status === s.id ? `1.5px solid ${c.lavender}` : `0.5px solid ${c.subtle}`,
              fontFamily: 'inherit', cursor: 'pointer',
              display: 'flex', alignItems: 'center', gap: 10, textAlign: 'left',
            }}>
              <div style={{
                width: 22, height: 22, borderRadius: '50%',
                border: `1.5px solid ${status === s.id ? c.lavender : c.faint}`,
                background: status === s.id ? c.lavender : 'transparent',
                color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 11, flexShrink: 0,
              }}>{status === s.id ? '✓' : ''}</div>
              <div>
                <div style={{ fontSize: 12.5, fontWeight: 700, color: c.ink }}>{s.label}</div>
                <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>{s.sub}</div>
              </div>
            </button>
          ))}
        </div>

        {/* デフォルトトーン */}
        <FieldLabel colors={c}>打診時のデフォルトトーン</FieldLabel>
        <div style={{
          display: 'flex', gap: 4, padding: 3,
          background: c.subtle, borderRadius: 10, marginBottom: 14,
        }}>
          {[
            { id: 'standard', label: '標準' },
            { id: 'casual', label: 'カジュアル' },
            { id: 'polite', label: '丁寧' },
          ].map(t => (
            <button key={t.id} onClick={() => setTone(t.id)} style={{
              flex: 1, height: 32, borderRadius: 8,
              background: tone === t.id ? '#fff' : 'transparent',
              color: tone === t.id ? c.lavender : c.mute,
              border: 0, fontFamily: 'inherit', fontSize: 12,
              fontWeight: tone === t.id ? 700 : 500,
              boxShadow: tone === t.id ? '0 1px 3px rgba(58,50,74,0.1)' : 'none',
            }}>{t.label}</button>
          ))}
        </div>

        {/* 譲る / 自分用キープ トグル */}
        <FieldLabel colors={c}>用途</FieldLabel>
        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 6,
          marginBottom: 14,
        }}>
          {[
            { id: 'active', label: '譲る候補', sub: 'マッチング対象', icon: '🤝', color: c.lavender },
            { id: 'keep', label: '自分用キープ', sub: 'マッチ対象外', icon: '🔒', color: c.pink },
          ].map((h, i) => {
            const sel = i === 0; // default: active
            return (
              <button key={h.id} style={{
                padding: '12px 10px', borderRadius: 12,
                background: sel ? `${h.color}1f` : '#fff',
                border: sel ? `1.5px solid ${h.color}` : `0.5px solid ${c.subtle}`,
                fontFamily: 'inherit', cursor: 'pointer', textAlign: 'left',
              }}>
                <div style={{
                  display: 'flex', alignItems: 'center', gap: 6, marginBottom: 2,
                }}>
                  <span style={{ fontSize: 14 }}>{h.icon}</span>
                  <span style={{
                    fontSize: 12.5, fontWeight: 700,
                    color: sel ? h.color : c.ink,
                  }}>{h.label}</span>
                </div>
                <div style={{ fontSize: 10, color: c.mute }}>{h.sub}</div>
              </button>
            );
          })}
        </div>

        {/* 携帯中 toggle */}
        <div style={{
          padding: '12px 14px', borderRadius: 12,
          background: `linear-gradient(120deg, ${c.lavender}1c, ${c.pink}1c)`,
          border: `0.5px solid ${c.lavender}55`,
          display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8,
        }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12.5, fontWeight: 700, color: c.ink }}>今すぐ【携帯中】にする</div>
            <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>会場で交換可能リストに即追加</div>
          </div>
          <button style={{
            width: 44, height: 26, borderRadius: 13, border: 0,
            background: c.lavender, position: 'relative',
            cursor: 'pointer', padding: 0,
          }}>
            <div style={{
              position: 'absolute', top: 2, left: 20,
              width: 22, height: 22, borderRadius: '50%',
              background: '#fff', boxShadow: '0 2px 4px rgba(0,0,0,0.15)',
            }} />
          </button>
        </div>
      </div>

      {/* CTA */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '12px 18px 30px',
        background: 'rgba(255,255,255,0.92)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `0.5px solid ${c.lavender}22`,
        display: 'flex', gap: 8,
      }}>
        <button style={{
          height: 48, padding: '0 14px', borderRadius: 14,
          background: '#fff', color: c.ink,
          border: `0.5px solid ${c.subtle}`,
          fontFamily: 'inherit', fontSize: 12.5, fontWeight: 600,
        }}>個別編集</button>
        <button style={{
          flex: 1, height: 48, borderRadius: 14,
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 14.5, fontWeight: 700, letterSpacing: 0.4,
          boxShadow: `0 6px 16px ${c.lavender}50`,
        }}>3枚を登録</button>
      </div>
    </div>
  );
}

function FieldLabel({ children, colors }) {
  return (
    <div style={{
      fontSize: 11, fontWeight: 700, color: colors.mute,
      letterSpacing: 0.4, marginBottom: 6, padding: '0 2px',
    }}>{children}</div>
  );
}

// ─────────────────────────────────────────────────────────────
// B-3. X post — auto-generated post text + image
// ─────────────────────────────────────────────────────────────
function XPostStep({ colors: c }) {
  const [tone, setTone] = React.useState(0);
  const samples = [
    `🌸 譲↔求 🌸\n譲：スア トレカ WORLD TOUR Ver. ×2\n求：ヒナ トレカ WORLD TOUR Ver.\n4/27 横浜アリ参戦 / 当日現地優先\n#LUMENA交換 #スア譲 #ヒナ求`,
    `スア トレカ WT2枚お譲りします〜！\nヒナのWTと交換できる方いますか？？\n横アリ4/27参戦予定です ◎\n#LUMENA交換 #スア譲 #ヒナ求`,
    `【譲】スア トレカ WORLD TOUR Ver. ×2枚\n【求】ヒナ トレカ WORLD TOUR Ver. ×1枚\n4月27日 横浜アリーナ公演にて手交換希望致します。\n#LUMENA交換`,
  ];

  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, fontFeatureSettings: '"palt"',
    }}>
      <div style={{ height: 60 }} />
      <StepHeader colors={c} step={4} total={4} title="X投稿テキストを生成" sub="Megrumで選んだ在庫から下書き作成 · 編集して投稿" />

      <div style={{ flex: 1, overflowY: 'auto', padding: '14px 16px 110px' }}>
        {/* Generated image preview */}
        <FieldLabel colors={c}>添付画像（補正済）</FieldLabel>
        <div style={{
          aspectRatio: '16 / 10', borderRadius: 14, overflow: 'hidden',
          background: `linear-gradient(135deg, ${c.lavender}33, ${c.sky}33, ${c.pink}33)`,
          position: 'relative',
          border: `0.5px solid ${c.subtle}`, marginBottom: 16,
        }}>
          {/* yuzuri side */}
          <div style={{
            position: 'absolute', top: 18, left: 18,
            padding: '3px 9px', borderRadius: 999,
            background: c.lavender, color: '#fff',
            fontSize: 10, fontWeight: 800, letterSpacing: 0.5,
          }}>譲</div>
          <div style={{
            position: 'absolute', top: 50, left: '13%',
            display: 'flex', gap: 5,
          }}>
            {[0, 1].map(i => (
              <div key={i} style={{
                width: 50, height: 70, borderRadius: 5,
                background: `repeating-linear-gradient(135deg, hsl(${280 + i * 5}, 38%, 78%) 0 5px, hsl(${280 + i * 5}, 38%, 68%) 5px 10px)`,
                transform: `rotate(${(i - 0.5) * 5}deg)`,
                boxShadow: '0 4px 10px rgba(0,0,0,0.12)',
              }} />
            ))}
          </div>

          {/* arrow */}
          <div style={{
            position: 'absolute', top: '50%', left: '50%',
            transform: 'translate(-50%, -50%)',
            width: 40, height: 40, borderRadius: '50%',
            background: '#fff', boxShadow: `0 4px 12px rgba(58,50,74,0.18)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 16, color: c.lavender, fontWeight: 800,
          }}>↔</div>

          {/* motome side */}
          <div style={{
            position: 'absolute', top: 18, right: 18,
            padding: '3px 9px', borderRadius: 999,
            background: c.sky, color: '#fff',
            fontSize: 10, fontWeight: 800, letterSpacing: 0.5,
          }}>求</div>
          <div style={{
            position: 'absolute', top: 50, right: '13%',
          }}>
            <div style={{
              width: 50, height: 70, borderRadius: 5,
              background: `repeating-linear-gradient(135deg, hsl(200, 38%, 78%) 0 5px, hsl(200, 38%, 68%) 5px 10px)`,
              boxShadow: '0 4px 10px rgba(0,0,0,0.12)',
            }} />
          </div>

          {/* footer */}
          <div style={{
            position: 'absolute', bottom: 14, left: 0, right: 0, textAlign: 'center',
          }}>
            <div style={{
              fontSize: 9, color: c.mute, letterSpacing: 1, fontWeight: 700,
            }}>Megrum · 4/27 横浜アリーナ</div>
          </div>
        </div>

        {/* Tone tabs */}
        <FieldLabel colors={c}>文面のトーン</FieldLabel>
        <div style={{
          display: 'flex', gap: 4, padding: 3,
          background: c.subtle, borderRadius: 10, marginBottom: 10,
        }}>
          {['標準', 'カジュアル', '丁寧'].map((t, i) => (
            <button key={t} onClick={() => setTone(i)} style={{
              flex: 1, height: 32, borderRadius: 8,
              background: tone === i ? '#fff' : 'transparent',
              color: tone === i ? c.lavender : c.mute,
              border: 0, fontFamily: 'inherit', fontSize: 12,
              fontWeight: tone === i ? 700 : 500,
              boxShadow: tone === i ? '0 1px 3px rgba(58,50,74,0.1)' : 'none',
            }}>{t}</button>
          ))}
        </div>

        {/* Editable text */}
        <div style={{
          padding: 14, borderRadius: 14,
          background: '#fff', border: `0.5px solid ${c.subtle}`,
          fontSize: 13, lineHeight: 1.65, color: c.ink,
          whiteSpace: 'pre-wrap', minHeight: 130, marginBottom: 6,
        }}>{samples[tone]}</div>
        <div style={{
          fontSize: 10.5, color: c.mute,
          display: 'flex', justifyContent: 'space-between',
          padding: '0 4px',
        }}>
          <span>編集できます · ハッシュタグも変更可</span>
          <span style={{ fontVariantNumeric: 'tabular-nums' }}>{samples[tone].length} / 280</span>
        </div>

        {/* Tags strip */}
        <div style={{
          marginTop: 14,
          padding: 12, borderRadius: 14,
          background: '#fff', border: `0.5px solid ${c.subtle}`,
        }}>
          <div style={{
            display: 'flex', justifyContent: 'space-between',
            fontSize: 11, fontWeight: 700, color: c.mute,
            letterSpacing: 0.4, marginBottom: 8,
          }}>
            <span>ハッシュタグ候補</span>
            <span>タップで追加</span>
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 5 }}>
            {['#LUMENA交換', '#スア譲', '#ヒナ求', '#横アリ', '#当日交換', '#現地交換'].map((t, i) => (
              <button key={t} style={{
                padding: '5px 10px', borderRadius: 999,
                background: i < 3 ? `${c.lavender}1f` : '#fff',
                color: i < 3 ? c.lavender : c.ink,
                border: i < 3 ? 0 : `0.5px solid ${c.subtle}`,
                fontFamily: 'inherit', fontSize: 11, fontWeight: 600,
                cursor: 'pointer',
              }}>{t}</button>
            ))}
          </div>
        </div>
      </div>

      {/* CTA */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '12px 18px 30px',
        background: 'rgba(255,255,255,0.92)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `0.5px solid ${c.lavender}22`,
        display: 'flex', gap: 8,
      }}>
        <button style={{
          height: 48, padding: '0 14px', borderRadius: 14,
          background: '#fff', color: c.ink,
          border: `0.5px solid ${c.subtle}`,
          fontFamily: 'inherit', fontSize: 12, fontWeight: 600,
          display: 'inline-flex', alignItems: 'center', gap: 5,
        }}>
          <svg width="13" height="13" viewBox="0 0 13 13"><rect x="2" y="3" width="9" height="7" rx="1" stroke={c.ink} strokeWidth="1.4" fill="none"/></svg>
          コピー
        </button>
        <button style={{
          flex: 1, height: 48, borderRadius: 14,
          background: '#000', color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 14.5, fontWeight: 700, letterSpacing: 0.4,
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          boxShadow: '0 6px 16px rgba(0,0,0,0.25)',
        }}>
          <span style={{ fontFamily: '"Inter Tight", sans-serif', fontSize: 16, fontWeight: 800 }}>X</span>
          で投稿する
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { InventoryScreen, CaptureFlowScreen });

// __MVP_EXPORTS__
Object.assign(window, { InventoryScreen, CaptureFlowScreen });
