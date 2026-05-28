// home-variations.jsx
// Three variations of the Megrum home screen (matching 4 tabs)

// ─────────────────────────────────────────────────────────────
// Shared data
// ─────────────────────────────────────────────────────────────

const KPOP_GROUPS = ['LUMENA', 'STARFALL', 'NOVA9', 'PRISMA', 'AURORA', 'EDEN', 'KAIROS'];
const MEMBERS_BY_GROUP = {
  'LUMENA': ['ヒナ', 'ミナ', 'スア', 'ジヨン', 'ユア', 'リア'],
  'STARFALL': ['ハル', 'ノア', 'リン', 'ソル', 'ジン'],
  'NOVA9': ['ジェイ', 'カイ', 'ミン', 'シン', 'テオ', 'リオ', 'アサ', 'ユウ', 'レイ'],
  'PRISMA': ['ナナ', 'ココ', 'ミウ', 'リカ'],
  'AURORA': ['アヤ', 'メイ', 'リサ'],
  'EDEN': ['ヒヨ', 'ノエル', 'シア', 'マリ', 'ルナ'],
  'KAIROS': ['カナ', 'ユイ', 'モモ', 'リコ'],
};
const VENUES = ['横浜アリーナ', '東京ドーム', '京セラドーム', 'さいたまSA', 'Kアリーナ'];
const TC_TYPES = ['トレカ', '生写真', 'ポラ', 'グリッター', 'ホロ', 'スリーブ'];

// Seeded PRNG so artboards don't flicker on re-render
function mulberry32(seed) {
  return function () {
    let t = seed += 0x6D2B79F5;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function makeRand(seed) {
  const r = mulberry32(seed);
  return {
    pick: (arr) => arr[Math.floor(r() * arr.length)],
    int: (a, b) => a + Math.floor(r() * (b - a + 1)),
    float: () => r(),
  };
}

// Stable card data, parameterized by seed
function buildCards(seed, group, oshi) {
  const rng = makeRand(seed);
  const handles = ['__no_oshi__', 'mochiko_724', 'lumi_sua', 'pop.ria', 'iam_jiyoung',
    'starly_sua', 'plum_92', 'haru_no_yoake', 'mint_collect', 'ringoame', 'velvet.lu',
    'sora_diary', 'sweetspot', 'piyo.luv', 'mooncake_05', 'akari.tc'];
  return Array.from({ length: 12 }, (_, i) => {
    const member = rng.pick(MEMBERS_BY_GROUP[group]);
    const giveCount = rng.int(2, 5);
    const wantCount = rng.int(1, 3);
    return {
      id: `card-${seed}-${i}`,
      handle: rng.pick(handles),
      member,
      giveSamples: Array.from({ length: giveCount }, (_, j) => ({
        type: rng.pick(TC_TYPES),
        member: rng.pick(MEMBERS_BY_GROUP[group]),
      })),
      wantSamples: Array.from({ length: wantCount }, (_, j) => ({
        type: rng.pick(TC_TYPES),
        member: oshi || rng.pick(MEMBERS_BY_GROUP[group]),
      })),
      distance: rng.int(15, 480), // meters
      lastActive: rng.int(1, 28), // minutes ago
      trades: rng.int(3, 247),
      newcomer: rng.float() < 0.18,
    };
  });
}

// ─────────────────────────────────────────────────────────────
// Shared icons (no emoji)
// ─────────────────────────────────────────────────────────────
const Ic = {
  // Solid filled circle with check, for "complete match"
  matchBadge: (size = 14, color = '#fff') => (
    <svg width={size} height={size} viewBox="0 0 14 14">
      <circle cx="7" cy="7" r="7" fill={color} />
    </svg>
  ),
  // Two interlocking rings
  ringPair: (size = 14, color = '#000') => (
    <svg width={size} height={size + 4} viewBox="0 0 18 14" fill="none">
      <circle cx="6" cy="7" r="4.5" stroke={color} strokeWidth="1.4" />
      <circle cx="12" cy="7" r="4.5" stroke={color} strokeWidth="1.4" />
    </svg>
  ),
  arrowR: (size = 12, color = '#000') => (
    <svg width={size} height={size} viewBox="0 0 12 12" fill="none">
      <path d="M2 6h8m-3-3l3 3-3 3" stroke={color} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  ),
  arrowL: (size = 12, color = '#000') => (
    <svg width={size} height={size} viewBox="0 0 12 12" fill="none">
      <path d="M10 6H2m3-3L2 6l3 3" stroke={color} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  ),
  pin: (size = 11, color = '#000') => (
    <svg width={size} height={size + 2} viewBox="0 0 11 13" fill="none">
      <path d="M5.5 12s4-3.6 4-7a4 4 0 10-8 0c0 3.4 4 7 4 7z" stroke={color} strokeWidth="1.2" />
      <circle cx="5.5" cy="5" r="1.4" fill={color} />
    </svg>
  ),
  dot: (size = 6, color = '#000') => (
    <svg width={size} height={size} viewBox="0 0 6 6">
      <circle cx="3" cy="3" r="3" fill={color} />
    </svg>
  ),
  search: (size = 16, color = '#000') => (
    <svg width={size} height={size} viewBox="0 0 16 16" fill="none">
      <circle cx="7" cy="7" r="5" stroke={color} strokeWidth="1.5" />
      <path d="M11 11l3 3" stroke={color} strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  ),
  filter: (size = 14, color = '#000') => (
    <svg width={size} height={size} viewBox="0 0 14 14" fill="none">
      <path d="M2 3h10M4 7h6M6 11h2" stroke={color} strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  ),
  cloudDot: (size = 14, color = '#000') => (
    <svg width={size + 4} height={size} viewBox="0 0 18 14" fill="none">
      <path d="M5 11h8a3 3 0 000-6 4 4 0 00-7.7-1A3 3 0 005 11z" stroke={color} strokeWidth="1.2" />
    </svg>
  ),
};

// Stripe placeholder for trading-card thumbnails
function Tcg({ w = 28, h = 40, hue = 12, label, dim = false, accent }) {
  const bg = accent || `hsl(${hue}, 24%, 88%)`;
  const stripe = accent ? `${accent}cc` : `hsl(${hue}, 32%, 78%)`;
  return (
    <div style={{
      width: w, height: h, borderRadius: 4,
      background: `repeating-linear-gradient(135deg, ${bg} 0 4px, ${stripe} 4px 7px)`,
      border: '0.5px solid rgba(0,0,0,0.08)',
      flexShrink: 0, position: 'relative',
      opacity: dim ? 0.55 : 1,
      display: 'flex', alignItems: 'flex-end', justifyContent: 'center',
      paddingBottom: 2,
    }}>
      {label && (
        <span style={{
          fontSize: 7, fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace',
          color: 'rgba(0,0,0,0.65)', fontWeight: 600, letterSpacing: 0.2,
        }}>{label}</span>
      )}
    </div>
  );
}

// Avatar: stripe disc with initial
function Avatar({ name, size = 32, hue = 24 }) {
  const initial = name?.[0]?.toUpperCase() || '?';
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%',
      background: `repeating-linear-gradient(45deg, hsl(${hue}, 18%, 86%) 0 3px, hsl(${hue}, 28%, 78%) 3px 5px)`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      flexShrink: 0, fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace',
      fontSize: size * 0.36, color: 'rgba(0,0,0,0.55)', fontWeight: 600,
      border: '0.5px solid rgba(0,0,0,0.08)',
    }}>{initial}</div>
  );
}

// ─────────────────────────────────────────────────────────────
// Shared chrome: sync status + venue banner
// ─────────────────────────────────────────────────────────────

function SyncStrip({ accent, lastSync = 3, online = false, dark = false }) {
  const bg = dark ? '#1a1714' : '#fefcfa';
  const fg = dark ? 'rgba(255,255,255,0.85)' : '#1a1714';
  const muted = dark ? 'rgba(255,255,255,0.55)' : 'rgba(26,23,20,0.55)';
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 8,
      padding: '6px 16px', background: bg,
      borderBottom: dark ? '0.5px solid rgba(255,255,255,0.08)' : '0.5px solid rgba(26,23,20,0.06)',
      fontSize: 11, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: fg, fontFeatureSettings: '"palt"',
    }}>
      <div style={{
        width: 6, height: 6, borderRadius: '50%',
        background: online ? '#22c55e' : '#e8a437',
        boxShadow: online ? '0 0 0 3px rgba(34,197,94,0.18)' : '0 0 0 3px rgba(232,164,55,0.18)',
      }} />
      <span style={{ fontWeight: 500 }}>{online ? 'オンライン' : 'オフライン中'}</span>
      <span style={{ color: muted }}>·</span>
      <span style={{ color: muted, fontVariantNumeric: 'tabular-nums' }}>
        最終同期 {lastSync}分前
      </span>
      <div style={{ flex: 1 }} />
      <span style={{ color: muted, fontVariantNumeric: 'tabular-nums' }}>
        ローカル保存 24件
      </span>
    </div>
  );
}

function VenueBanner({ accent, venue = '横浜アリーナ', minsToShow = 118, dark = false }) {
  const h = Math.floor(minsToShow / 60);
  const m = minsToShow % 60;
  const timeStr = h > 0 ? `${h}時間${m}分` : `${m}分`;
  return (
    <div style={{
      margin: '10px 16px 0', padding: '12px 14px',
      borderRadius: 14,
      background: dark ? `linear-gradient(180deg, ${accent}24, ${accent}12)` : `linear-gradient(180deg, ${accent}1f, ${accent}0a)`,
      border: `0.5px solid ${accent}55`,
      display: 'flex', alignItems: 'center', gap: 10,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: dark ? '#fff' : '#1a1714',
    }}>
      <div style={{
        width: 36, height: 36, borderRadius: 10,
        background: `${accent}33`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        {Ic.pin(15, accent)}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14.5, fontWeight: 600, letterSpacing: 0.2 }}>
          {venue} 周辺
        </div>
        <div style={{
          fontSize: 11.5, color: dark ? 'rgba(255,255,255,0.65)' : 'rgba(26,23,20,0.6)',
          marginTop: 1, fontVariantNumeric: 'tabular-nums',
        }}>
          開演まで {timeStr} · LUMENA WORLD TOUR
        </div>
      </div>
      <button style={{
        appearance: 'none', border: `0.5px solid ${accent}66`,
        background: 'transparent', color: accent,
        padding: '5px 10px', borderRadius: 999, fontSize: 11.5, fontWeight: 600,
        fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      }}>変更</button>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// VARIATION A — Hero stack: Complete-match as horizontal stack on top
// Tabs: top, segmented chip-style. Card: photo-feed on lower tabs.
// ─────────────────────────────────────────────────────────────

function VariationA({ accent }) {
  const [tab, setTab] = React.useState(0);
  const tabs = ['完全マッチ', '求めてる', '求められてる', '探索'];
  const tabCounts = [3, 12, 8, 64];
  const cards = React.useMemo(() => buildCards(101, 'LUMENA', 'スア'), []);

  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: '#faf7f4', fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: '#1a1714', fontFeatureSettings: '"palt"',
    }}>
      {/* Status bar spacer */}
      <div style={{ height: 60 }} />
      <SyncStrip lastSync={3} />

      {/* Title row */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '14px 16px 4px',
      }}>
        <div>
          <div style={{ fontSize: 11, color: 'rgba(26,23,20,0.5)', fontWeight: 500, letterSpacing: 0.6 }}>
            Megrum · LUMENA
          </div>
          <div style={{ fontSize: 26, fontWeight: 700, lineHeight: 1.15, marginTop: 1, letterSpacing: 0.2 }}>
            マッチング
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button style={{
            width: 36, height: 36, borderRadius: '50%', border: '0.5px solid rgba(26,23,20,0.12)',
            background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>{Ic.search(16)}</button>
          <button style={{
            width: 36, height: 36, borderRadius: '50%', border: '0.5px solid rgba(26,23,20,0.12)',
            background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>{Ic.filter(14)}</button>
        </div>
      </div>

      <VenueBanner accent={accent} />

      {/* Segmented tabs (chip-style, scroll) */}
      <div style={{
        display: 'flex', gap: 6, padding: '14px 16px 8px',
        overflowX: 'auto', scrollbarWidth: 'none',
      }}>
        {tabs.map((t, i) => (
          <button
            key={t}
            onClick={() => setTab(i)}
            style={{
              appearance: 'none',
              display: 'inline-flex', alignItems: 'center', gap: 6,
              padding: '7px 12px', borderRadius: 999,
              border: tab === i ? `1px solid ${accent}` : '0.5px solid rgba(26,23,20,0.14)',
              background: tab === i ? accent : '#fff',
              color: tab === i ? '#fff' : '#1a1714',
              fontFamily: 'inherit', fontSize: 12.5, fontWeight: 600,
              flexShrink: 0, letterSpacing: 0.2,
            }}
          >
            {i === 0 && Ic.matchBadge(8, tab === i ? '#fff' : accent)}
            {t}
            <span style={{
              fontSize: 11, fontWeight: 600,
              color: tab === i ? 'rgba(255,255,255,0.85)' : 'rgba(26,23,20,0.5)',
              fontVariantNumeric: 'tabular-nums',
            }}>{tabCounts[i]}</span>
          </button>
        ))}
      </div>

      {/* Content */}
      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 100 }}>
        {tab === 0 && (
          <>
            {/* Hero label */}
            <div style={{ padding: '6px 16px 6px', display: 'flex', alignItems: 'baseline', gap: 6 }}>
              <span style={{ fontSize: 12, fontWeight: 600, color: accent }}>● 完全マッチ</span>
              <span style={{ fontSize: 11, color: 'rgba(26,23,20,0.5)' }}>双方の希望が一致</span>
            </div>
            {/* Stacked tall cards */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10, padding: '0 16px' }}>
              {cards.slice(0, 3).map((c, i) => <CompleteMatchCardA key={c.id} card={c} accent={accent} index={i} />)}
            </div>
            {/* Soft footer link */}
            <div style={{
              margin: '14px 16px 0', padding: '12px 14px',
              borderRadius: 12, background: '#fff',
              border: '0.5px solid rgba(26,23,20,0.06)',
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              fontSize: 12.5,
            }}>
              <span style={{ color: 'rgba(26,23,20,0.7)' }}>条件を緩めるとあと<b style={{ color: '#1a1714' }}>14件</b></span>
              <span style={{ color: accent, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 4 }}>
                条件を見直す {Ic.arrowR(11, accent)}
              </span>
            </div>
          </>
        )}
        {tab === 1 && (
          <OneWayList cards={cards.slice(0, 8)} accent={accent} direction="theyWantYou" />
        )}
        {tab === 2 && (
          <OneWayList cards={cards.slice(0, 8)} accent={accent} direction="youWantThem" />
        )}
        {tab === 3 && (
          <ExploreFeed cards={cards} accent={accent} />
        )}
      </div>

      {/* Bottom nav */}
      <BottomNav accent={accent} active="home" />
    </div>
  );
}

function CompleteMatchCardA({ card, accent, index }) {
  return (
    <div style={{
      background: '#fff', borderRadius: 16,
      border: `1px solid ${accent}33`,
      boxShadow: `0 1px 0 rgba(0,0,0,0.02), 0 6px 18px ${accent}14`,
      padding: 12, display: 'flex', flexDirection: 'column', gap: 10,
      position: 'relative', overflow: 'hidden',
    }}>
      {/* corner ribbon */}
      <div style={{
        position: 'absolute', top: 0, right: 0,
        background: accent, color: '#fff',
        padding: '3px 10px 3px 14px',
        fontSize: 9.5, fontWeight: 700, letterSpacing: 0.6,
        borderBottomLeftRadius: 10,
      }}>COMPLETE</div>

      {/* Header row */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <Avatar name={card.handle} size={36} hue={(index * 47) % 360} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontSize: 13, fontWeight: 600 }}>@{card.handle}</span>
            {card.newcomer && <span style={{
              fontSize: 9, color: '#3a8cd9', fontWeight: 700, letterSpacing: 0.5,
              border: '0.5px solid #3a8cd944', borderRadius: 4, padding: '0 4px',
            }}>NEW</span>}
          </div>
          <div style={{ fontSize: 11, color: 'rgba(26,23,20,0.55)', marginTop: 1, fontVariantNumeric: 'tabular-nums' }}>
            {card.distance}m先 · {card.lastActive}分前 · 取引{card.trades}回
          </div>
        </div>
      </div>

      {/* Trade preview: theirs ↔ yours */}
      <div style={{
        display: 'grid', gridTemplateColumns: '1fr auto 1fr', gap: 8,
        padding: '10px 4px', background: '#faf7f4', borderRadius: 10,
      }}>
        <div>
          <div style={{ fontSize: 9.5, color: 'rgba(26,23,20,0.5)', fontWeight: 600, letterSpacing: 0.5, marginBottom: 5, paddingLeft: 4 }}>
            相手の譲（{card.giveSamples.length}）
          </div>
          <div style={{ display: 'flex', gap: 4, paddingLeft: 4, flexWrap: 'wrap' }}>
            {card.giveSamples.slice(0, 4).map((s, i) => (
              <Tcg key={i} hue={(i * 60 + 12) % 360} label={s.member.slice(0, 1)} />
            ))}
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 4 }}>
          <div style={{
            width: 22, height: 22, borderRadius: '50%', background: accent,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>{Ic.arrowR(11, '#fff')}</div>
          <div style={{
            width: 22, height: 22, borderRadius: '50%', background: '#1a1714',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>{Ic.arrowL(11, '#fff')}</div>
        </div>
        <div>
          <div style={{ fontSize: 9.5, color: 'rgba(26,23,20,0.5)', fontWeight: 600, letterSpacing: 0.5, marginBottom: 5, textAlign: 'right', paddingRight: 4 }}>
            あなたの譲（{card.wantSamples.length}）
          </div>
          <div style={{ display: 'flex', gap: 4, paddingRight: 4, flexWrap: 'wrap', justifyContent: 'flex-end' }}>
            {card.wantSamples.slice(0, 4).map((s, i) => (
              <Tcg key={i} hue={(i * 60 + 200) % 360} label={s.member.slice(0, 1)} accent={`${accent}66`} />
            ))}
          </div>
        </div>
      </div>

      {/* CTA row */}
      <div style={{ display: 'flex', gap: 8 }}>
        <button style={{
          flex: 1, height: 38, borderRadius: 10,
          background: accent, color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 13.5, fontWeight: 700,
        }}>打診する</button>
        <button style={{
          height: 38, padding: '0 14px', borderRadius: 10,
          background: '#fff', color: '#1a1714',
          border: '0.5px solid rgba(26,23,20,0.14)',
          fontFamily: 'inherit', fontSize: 13, fontWeight: 600,
        }}>詳細</button>
      </div>
    </div>
  );
}

function OneWayList({ cards, accent, direction }) {
  const isTheyWant = direction === 'theyWantYou';
  return (
    <div style={{ padding: '6px 16px 0' }}>
      <div style={{
        fontSize: 11.5, color: 'rgba(26,23,20,0.6)',
        padding: '4px 0 8px',
      }}>
        {isTheyWant
          ? '相手はあなたの在庫を求めています。あなたの希望と一致する譲を持っているかは未確認。'
          : 'あなたが求める在庫を持っています。相手の希望を確認して打診してください。'}
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {cards.map((c, i) => (
          <div key={c.id} style={{
            display: 'flex', alignItems: 'center', gap: 10,
            background: '#fff', padding: '10px 12px', borderRadius: 12,
            border: '0.5px solid rgba(26,23,20,0.06)',
          }}>
            <Avatar name={c.handle} size={36} hue={(i * 53) % 360} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                <span style={{ fontSize: 12.5, fontWeight: 600 }}>@{c.handle}</span>
                <span style={{
                  fontSize: 9.5, padding: '1px 6px', borderRadius: 4,
                  background: isTheyWant ? `${accent}1a` : 'rgba(26,23,20,0.06)',
                  color: isTheyWant ? accent : 'rgba(26,23,20,0.65)',
                  fontWeight: 700, letterSpacing: 0.4,
                }}>
                  {isTheyWant ? 'あなたを求めてる' : 'あなたが求める'}
                </span>
              </div>
              <div style={{ fontSize: 10.5, color: 'rgba(26,23,20,0.5)', fontVariantNumeric: 'tabular-nums', marginTop: 2 }}>
                {c.distance}m · {c.lastActive}分前
              </div>
              <div style={{ display: 'flex', gap: 3, marginTop: 6 }}>
                {(isTheyWant ? c.giveSamples : c.wantSamples).slice(0, 4).map((s, j) => (
                  <Tcg key={j} w={20} h={28} hue={(j * 60 + 30) % 360} />
                ))}
                <span style={{ fontSize: 10.5, color: 'rgba(26,23,20,0.5)', alignSelf: 'flex-end', marginLeft: 2 }}>
                  +{(isTheyWant ? c.giveSamples : c.wantSamples).length - Math.min(4, (isTheyWant ? c.giveSamples : c.wantSamples).length)}
                </span>
              </div>
            </div>
            <button style={{
              padding: '7px 12px', borderRadius: 8, border: `0.5px solid ${accent}`,
              background: 'transparent', color: accent, fontWeight: 600, fontSize: 12,
              fontFamily: 'inherit', flexShrink: 0,
            }}>打診</button>
          </div>
        ))}
      </div>
    </div>
  );
}

function ExploreFeed({ cards, accent }) {
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8,
      padding: '6px 16px 0',
    }}>
      {cards.slice(0, 8).map((c, i) => (
        <div key={c.id} style={{
          background: '#fff', borderRadius: 12, padding: 8,
          border: '0.5px solid rgba(26,23,20,0.06)',
        }}>
          <div style={{ display: 'flex', gap: 4, marginBottom: 8 }}>
            {c.giveSamples.slice(0, 2).map((s, j) => (
              <Tcg key={j} w={'100%'} h={70} hue={(j * 60 + i * 30) % 360} />
            ))}
          </div>
          <div style={{ fontSize: 11, fontWeight: 600 }}>@{c.handle}</div>
          <div style={{ fontSize: 9.5, color: 'rgba(26,23,20,0.5)', marginTop: 1 }}>
            {c.distance}m · {c.lastActive}分前
          </div>
        </div>
      ))}
    </div>
  );
}

function BottomNav({ accent, active }) {
  const items = [
    { id: 'home', label: 'ホーム' },
    { id: 'inv', label: '在庫' },
    { id: 'trade', label: '取引' },
    { id: 'wish', label: 'ウィッシュ' },
    { id: 'me', label: 'プロフ' },
  ];
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 0,
      paddingBottom: 28, paddingTop: 8,
      background: 'rgba(255,255,255,0.92)',
      backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
      borderTop: '0.5px solid rgba(26,23,20,0.08)',
      display: 'flex', justifyContent: 'space-around',
    }}>
      {items.map((it) => (
        <div key={it.id} style={{
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
        }}>
          <div style={{
            width: 22, height: 22, borderRadius: 6,
            background: active === it.id ? accent : 'transparent',
            border: active === it.id ? 'none' : '1.5px solid rgba(26,23,20,0.4)',
          }} />
          <span style={{
            fontSize: 9.5, fontWeight: 600,
            color: active === it.id ? accent : 'rgba(26,23,20,0.55)',
          }}>{it.label}</span>
        </div>
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// VARIATION B — Photo-feed first, complete-match as a banner
// Tabs: bottom-pinned tabbed bar above nav (swipe-style indicator)
// ─────────────────────────────────────────────────────────────

function VariationB({ accent }) {
  const [tab, setTab] = React.useState(0);
  const tabs = [
    { label: '完全', sub: 'マッチ', count: 3 },
    { label: '求めてる', sub: '相手→あなた', count: 12 },
    { label: '求める', sub: 'あなた→相手', count: 8 },
    { label: '探索', sub: 'すべて', count: 64 },
  ];
  const cards = React.useMemo(() => buildCards(202, 'LUMENA', 'スア'), []);

  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: '#1a1714', fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: '#fff', fontFeatureSettings: '"palt"',
    }}>
      <div style={{ height: 60 }} />
      <SyncStrip lastSync={3} dark />

      {/* Compact title row */}
      <div style={{ padding: '12px 16px 8px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{
            width: 26, height: 26, borderRadius: 7,
            background: `repeating-linear-gradient(45deg, ${accent}, ${accent} 4px, ${accent}cc 4px 7px)`,
          }} />
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, letterSpacing: 0.4 }}>横浜アリーナ</div>
            <div style={{ fontSize: 10.5, color: 'rgba(255,255,255,0.55)', fontVariantNumeric: 'tabular-nums' }}>
              開演まで <b style={{ color: accent, fontWeight: 700 }}>1時間58分</b> · 半径500m
            </div>
          </div>
        </div>
        <button style={{
          width: 34, height: 34, borderRadius: '50%',
          background: 'rgba(255,255,255,0.08)', border: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>{Ic.filter(13, '#fff')}</button>
      </div>

      {/* Hero: complete-match carousel banner */}
      <div style={{ padding: '4px 16px 0' }}>
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '0 2px 6px',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <div style={{
              width: 14, height: 14, borderRadius: '50%', background: accent,
              boxShadow: `0 0 0 4px ${accent}33`,
            }} />
            <span style={{ fontSize: 13, fontWeight: 700, letterSpacing: 0.4 }}>完全マッチ</span>
            <span style={{
              fontSize: 10.5, color: 'rgba(255,255,255,0.55)', fontVariantNumeric: 'tabular-nums',
              padding: '1px 6px', background: 'rgba(255,255,255,0.06)', borderRadius: 999,
            }}>3件</span>
          </div>
          <span style={{ fontSize: 11, color: accent, fontWeight: 600 }}>すべて見る ›</span>
        </div>

        {/* Horizontal carousel */}
        <div style={{
          display: 'flex', gap: 10, overflowX: 'auto',
          margin: '0 -16px', padding: '4px 16px 14px',
          scrollbarWidth: 'none',
        }}>
          {cards.slice(0, 4).map((c, i) => (
            <div key={c.id} style={{
              flex: '0 0 240px',
              borderRadius: 14, padding: 10,
              background: `linear-gradient(180deg, ${accent}40, ${accent}18)`,
              border: `0.5px solid ${accent}66`,
              display: 'flex', flexDirection: 'column', gap: 8,
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <Avatar name={c.handle} size={28} hue={(i * 47) % 360} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 12, fontWeight: 600 }}>@{c.handle}</div>
                  <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.6)', fontVariantNumeric: 'tabular-nums' }}>
                    {c.distance}m · {c.lastActive}分前
                  </div>
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <div style={{ display: 'flex', gap: 3, flex: 1 }}>
                  {c.giveSamples.slice(0, 3).map((s, j) => (
                    <Tcg key={j} w={28} h={40} hue={(j * 60 + 20) % 360} />
                  ))}
                </div>
                <div style={{ color: accent, fontSize: 14 }}>↔</div>
                <div style={{ display: 'flex', gap: 3, flex: 1, justifyContent: 'flex-end' }}>
                  {c.wantSamples.slice(0, 3).map((s, j) => (
                    <Tcg key={j} w={28} h={40} hue={(j * 60 + 200) % 360} accent={`${accent}aa`} />
                  ))}
                </div>
              </div>
              <button style={{
                height: 32, borderRadius: 8, border: 0,
                background: accent, color: '#fff', fontFamily: 'inherit',
                fontSize: 12.5, fontWeight: 700,
              }}>打診</button>
            </div>
          ))}
        </div>
      </div>

      {/* Section divider */}
      <div style={{
        height: 0.5, background: 'rgba(255,255,255,0.08)', margin: '0 16px',
      }} />

      {/* Tabs (bottom-pinned) + photo-feed */}
      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 130 }}>
        <div style={{ padding: '14px 16px 4px' }}>
          <div style={{ fontSize: 13, fontWeight: 700, letterSpacing: 0.3, marginBottom: 8 }}>
            周辺のヲタク {64}人
          </div>
          {tab === 0 && <PhotoFeed cards={cards.slice(2, 10)} accent={accent} dark badge="完全" />}
          {tab === 1 && <PhotoFeed cards={cards.slice(0, 8)} accent={accent} dark badge="求めてる" />}
          {tab === 2 && <PhotoFeed cards={cards.slice(2, 10)} accent={accent} dark badge="求める" />}
          {tab === 3 && <PhotoFeed cards={cards.slice(0, 12)} accent={accent} dark badge="" />}
        </div>
      </div>

      {/* Bottom-pinned tab bar */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 76,
        background: 'rgba(26,23,20,0.78)',
        backdropFilter: 'blur(24px) saturate(180%)',
        WebkitBackdropFilter: 'blur(24px) saturate(180%)',
        borderTop: '0.5px solid rgba(255,255,255,0.08)',
        display: 'flex', padding: '8px 8px',
      }}>
        {tabs.map((t, i) => (
          <button
            key={t.label}
            onClick={() => setTab(i)}
            style={{
              flex: 1, padding: '6px 4px', appearance: 'none', background: 'transparent',
              border: 0, color: tab === i ? '#fff' : 'rgba(255,255,255,0.5)',
              fontFamily: 'inherit', display: 'flex', flexDirection: 'column', alignItems: 'center',
              gap: 2, position: 'relative',
            }}
          >
            <span style={{ fontSize: 12, fontWeight: 700, letterSpacing: 0.2 }}>
              {t.label} <span style={{ fontWeight: 500, fontVariantNumeric: 'tabular-nums', color: 'rgba(255,255,255,0.55)' }}>{t.count}</span>
            </span>
            <span style={{ fontSize: 9, color: 'rgba(255,255,255,0.4)' }}>{t.sub}</span>
            {tab === i && <div style={{
              position: 'absolute', bottom: -8, left: '20%', right: '20%', height: 2,
              borderRadius: 2, background: accent,
            }} />}
          </button>
        ))}
      </div>

      <BottomNavDark accent={accent} active="home" />
    </div>
  );
}

function PhotoFeed({ cards, accent, dark, badge }) {
  const fg = dark ? '#fff' : '#1a1714';
  const cardBg = dark ? 'rgba(255,255,255,0.04)' : '#fff';
  const muted = dark ? 'rgba(255,255,255,0.55)' : 'rgba(26,23,20,0.55)';
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8,
    }}>
      {cards.map((c, i) => (
        <div key={c.id} style={{
          background: cardBg, borderRadius: 12, overflow: 'hidden',
          border: dark ? '0.5px solid rgba(255,255,255,0.06)' : '0.5px solid rgba(26,23,20,0.06)',
          position: 'relative',
        }}>
          {/* hero photo */}
          <div style={{ position: 'relative' }}>
            <Tcg w="100%" h={130} hue={(i * 47 + 20) % 360} />
            {badge && (
              <div style={{
                position: 'absolute', top: 6, left: 6,
                fontSize: 9, fontWeight: 700, letterSpacing: 0.5,
                color: '#fff', background: accent, padding: '2px 6px', borderRadius: 4,
              }}>{badge}</div>
            )}
            {/* count chip */}
            <div style={{
              position: 'absolute', bottom: 6, right: 6,
              fontSize: 9, fontWeight: 600,
              color: '#fff', background: 'rgba(0,0,0,0.55)',
              padding: '2px 6px', borderRadius: 999,
              fontVariantNumeric: 'tabular-nums',
            }}>+{c.giveSamples.length - 1}</div>
          </div>
          <div style={{ padding: '8px 10px' }}>
            <div style={{ fontSize: 11.5, fontWeight: 600, color: fg }}>@{c.handle}</div>
            <div style={{ fontSize: 10, color: muted, marginTop: 1, fontVariantNumeric: 'tabular-nums' }}>
              {c.distance}m · {c.lastActive}分前
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

function BottomNavDark({ accent, active }) {
  const items = [
    { id: 'home', label: 'ホーム' },
    { id: 'inv', label: '在庫' },
    { id: 'trade', label: '取引' },
    { id: 'wish', label: 'ウィッシュ' },
    { id: 'me', label: 'プロフ' },
  ];
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 0,
      paddingBottom: 28, paddingTop: 8,
      background: 'rgba(10,9,8,0.95)',
      backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
      borderTop: '0.5px solid rgba(255,255,255,0.06)',
      display: 'flex', justifyContent: 'space-around',
    }}>
      {items.map((it) => (
        <div key={it.id} style={{
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
        }}>
          <div style={{
            width: 22, height: 22, borderRadius: 6,
            background: active === it.id ? accent : 'transparent',
            border: active === it.id ? 'none' : '1.5px solid rgba(255,255,255,0.4)',
          }} />
          <span style={{
            fontSize: 9.5, fontWeight: 600,
            color: active === it.id ? accent : 'rgba(255,255,255,0.55)',
          }}>{it.label}</span>
        </div>
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// VARIATION C — Dense list, monotone, top tabs underline-style
// Optimized for scanning many matches under time pressure
// ─────────────────────────────────────────────────────────────

function VariationC({ accent }) {
  const [tab, setTab] = React.useState(0);
  const tabs = ['完全マッチ', '求めてる', '求める', '探索'];
  const counts = [3, 12, 8, 64];
  const cards = React.useMemo(() => buildCards(303, 'LUMENA', 'スア'), []);

  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: '#fefcfa', fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: '#1a1714', fontFeatureSettings: '"palt"',
    }}>
      <div style={{ height: 60 }} />

      {/* Combined: sync + venue compact strip */}
      <div style={{
        padding: '8px 16px',
        background: '#1a1714', color: '#fff',
        display: 'flex', alignItems: 'center', gap: 10,
        fontSize: 11.5,
      }}>
        <div style={{
          width: 6, height: 6, borderRadius: '50%', background: '#e8a437',
          boxShadow: '0 0 0 3px rgba(232,164,55,0.18)',
        }} />
        <span style={{ fontWeight: 500 }}>オフライン中</span>
        <span style={{ color: 'rgba(255,255,255,0.4)' }}>|</span>
        <span style={{ fontWeight: 600 }}>横浜アリーナ</span>
        <span style={{ color: 'rgba(255,255,255,0.6)', fontVariantNumeric: 'tabular-nums' }}>
          開演 1:58
        </span>
        <div style={{ flex: 1 }} />
        <span style={{ color: 'rgba(255,255,255,0.55)', fontVariantNumeric: 'tabular-nums' }}>
          同期 3分前
        </span>
      </div>

      {/* Title */}
      <div style={{
        padding: '14px 16px 0',
        display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
      }}>
        <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: 0.2 }}>マッチング</div>
        <div style={{ display: 'flex', gap: 14, fontSize: 12, color: 'rgba(26,23,20,0.55)' }}>
          <span>並替</span>
          <span>絞込</span>
        </div>
      </div>

      {/* Underline tabs */}
      <div style={{
        display: 'flex', gap: 0, padding: '12px 16px 0',
        borderBottom: '0.5px solid rgba(26,23,20,0.1)',
      }}>
        {tabs.map((t, i) => (
          <button
            key={t}
            onClick={() => setTab(i)}
            style={{
              flex: 1, appearance: 'none', background: 'transparent',
              border: 0, padding: '10px 0',
              fontFamily: 'inherit', cursor: 'pointer',
              borderBottom: tab === i ? `2px solid ${accent}` : '2px solid transparent',
              marginBottom: -0.5, position: 'relative',
            }}
          >
            <div style={{
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1,
            }}>
              <span style={{
                fontSize: 12.5, fontWeight: tab === i ? 700 : 500,
                color: tab === i ? '#1a1714' : 'rgba(26,23,20,0.55)',
                display: 'flex', alignItems: 'center', gap: 4,
              }}>
                {i === 0 && <div style={{
                  width: 6, height: 6, borderRadius: '50%', background: accent,
                }} />}
                {t}
              </span>
              <span style={{
                fontSize: 10.5, fontWeight: 700,
                fontVariantNumeric: 'tabular-nums',
                color: tab === i ? accent : 'rgba(26,23,20,0.4)',
              }}>{counts[i]}</span>
            </div>
          </button>
        ))}
      </div>

      {/* Dense list */}
      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 100 }}>
        {tab === 0 && <DenseCompleteList cards={cards.slice(0, 6)} accent={accent} />}
        {tab === 1 && <DenseOneWayList cards={cards.slice(0, 12)} accent={accent} dir="theyWantYou" />}
        {tab === 2 && <DenseOneWayList cards={cards.slice(0, 8)} accent={accent} dir="youWantThem" />}
        {tab === 3 && (
          <div style={{ padding: '8px 16px' }}>
            <div style={{ fontSize: 11, color: 'rgba(26,23,20,0.5)', marginBottom: 6 }}>
              半径500m · 64人がアクティブ
            </div>
            <DenseOneWayList cards={cards} accent={accent} dir="explore" />
          </div>
        )}
      </div>

      <BottomNav accent={accent} active="home" />
    </div>
  );
}

function DenseCompleteList({ cards, accent }) {
  return (
    <div style={{ padding: '4px 0 0' }}>
      {/* Sticky summary */}
      <div style={{
        margin: '8px 16px 12px', padding: '10px 12px',
        borderRadius: 10, background: '#1a1714', color: '#fff',
        display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <div style={{
          width: 28, height: 28, borderRadius: '50%', background: accent,
          display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
        }}>{Ic.matchBadge(10, '#fff')}</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 13, fontWeight: 700 }}>3件の完全マッチ</div>
          <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.6)', fontVariantNumeric: 'tabular-nums' }}>
            最近接 23m · 双方の希望が一致
          </div>
        </div>
        <button style={{
          padding: '6px 12px', borderRadius: 999,
          background: accent, color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 12, fontWeight: 700,
        }}>一括打診</button>
      </div>

      {cards.slice(0, 3).map((c, i) => (
        <DenseRow key={c.id} card={c} accent={accent} variant="complete" />
      ))}

      <div style={{
        padding: '14px 16px 8px',
        fontSize: 11, color: 'rgba(26,23,20,0.45)', fontWeight: 600, letterSpacing: 0.6,
        textTransform: 'uppercase',
      }}>準完全マッチ · 推し違い</div>
      {cards.slice(3, 6).map((c) => (
        <DenseRow key={c.id} card={c} accent={accent} variant="near" />
      ))}
    </div>
  );
}

function DenseOneWayList({ cards, accent, dir }) {
  return (
    <div style={{ padding: '4px 0 0' }}>
      {cards.map((c) => (
        <DenseRow key={c.id} card={c} accent={accent} variant={dir} />
      ))}
    </div>
  );
}

function DenseRow({ card, accent, variant }) {
  const isComplete = variant === 'complete';
  const showGive = variant !== 'youWantThem';
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '10px 16px',
      borderBottom: '0.5px solid rgba(26,23,20,0.06)',
      background: isComplete ? `${accent}06` : 'transparent',
      position: 'relative',
    }}>
      {isComplete && (
        <div style={{
          position: 'absolute', left: 0, top: 0, bottom: 0, width: 3, background: accent,
        }} />
      )}
      <Avatar name={card.handle} size={38} hue={(card.handle.length * 23) % 360} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          {isComplete && Ic.matchBadge(8, accent)}
          <span style={{ fontSize: 13, fontWeight: 600 }}>@{card.handle}</span>
          {card.newcomer && (
            <span style={{
              fontSize: 9, color: '#3a8cd9', fontWeight: 700, letterSpacing: 0.5,
              border: '0.5px solid #3a8cd944', borderRadius: 3, padding: '0 4px',
            }}>NEW</span>
          )}
        </div>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 6, marginTop: 1,
          fontSize: 10.5, color: 'rgba(26,23,20,0.55)',
          fontVariantNumeric: 'tabular-nums',
        }}>
          <span>{card.distance}m</span>
          <span>·</span>
          <span>{card.lastActive}分前</span>
          <span>·</span>
          <span>{card.trades}取引</span>
        </div>
        <div style={{ display: 'flex', gap: 3, marginTop: 5, alignItems: 'center' }}>
          {showGive && (
            <>
              {card.giveSamples.slice(0, 3).map((s, j) => (
                <Tcg key={j} w={18} h={26} hue={(j * 60 + 30) % 360} />
              ))}
              {card.giveSamples.length > 3 && (
                <span style={{ fontSize: 10, color: 'rgba(26,23,20,0.5)', marginLeft: 2 }}>
                  +{card.giveSamples.length - 3}
                </span>
              )}
            </>
          )}
          {variant === 'youWantThem' && (
            <>
              {card.giveSamples.slice(0, 3).map((s, j) => (
                <Tcg key={j} w={18} h={26} hue={(j * 60 + 30) % 360} />
              ))}
              <span style={{ fontSize: 9.5, color: 'rgba(26,23,20,0.5)', margin: '0 2px' }}>← 譲</span>
            </>
          )}
        </div>
      </div>
      <button style={{
        padding: '7px 14px', borderRadius: 8,
        background: isComplete ? accent : 'transparent',
        color: isComplete ? '#fff' : accent,
        border: isComplete ? 0 : `0.5px solid ${accent}`,
        fontFamily: 'inherit', fontSize: 12, fontWeight: 700, flexShrink: 0,
      }}>打診</button>
    </div>
  );
}

Object.assign(window, { VariationA, VariationB, VariationC, Avatar, Tcg, Ic });
