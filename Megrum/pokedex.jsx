// ─────────────────────────────────────────────────────────────
// Collection Pokedex — F10 達成感最大化
// 3 screens: 一覧 / 詳細 / 探し中 + コンプ演出オーバーレイ
// ─────────────────────────────────────────────────────────────

const PD_C = (tweaks) => ({
  lavender: tweaks.primary,
  sky: tweaks.secondary,
  pink: tweaks.accent,
  ink: '#3a324a',
  mute: 'rgba(58,50,74,0.55)',
  hint: 'rgba(58,50,74,0.4)',
  subtle: 'rgba(58,50,74,0.06)',
  divide: 'rgba(58,50,74,0.08)',
  bg: '#fbf9fc',
  ok: '#7a9a8a',
  gold: '#d4a574',
});

// Member palettes for trading-card colors
const MEMBER_HUE = {
  'スア':   { h1: '#f5d5dc', h2: '#e8a8b4', accent: '#c97086', label: 'ピンク' },
  'ヒナ':   { h1: '#dcd0eb', h2: '#b59ed1', accent: '#8a6dba', label: 'パープル' },
  'シユン': { h1: '#cce0e8', h2: '#9ec8d4', accent: '#5b9aae', label: 'スカイ' },
  'ジウォン': { h1: '#dde8d3', h2: '#a8c294', accent: '#7a9a5e', label: 'グリーン' },
  'ミナ':   { h1: '#fbe5cf', h2: '#f0c595', accent: '#d99654', label: 'オレンジ' },
};

// Series data (tour series + photocard generations)
const SERIES = [
  { id: 'wt2', label: 'WORLD TOUR DAY 2', total: 5, owned: 4, year: '2025', kind: 'トレカ' },
  { id: 'fab', label: '4thミニアルバム FABLE', total: 7, owned: 5, year: '2024', kind: 'トレカ' },
  { id: 'sumr', label: 'SUMMER PACKAGE', total: 5, owned: 2, year: '2024', kind: 'トレカ' },
  { id: 'fc25', label: 'FC継続特典 2025', total: 5, owned: 1, year: '2025', kind: 'トレカ' },
  { id: 'badge', label: 'WT会場限定 缶バッジ', total: 5, owned: 5, year: '2025', kind: '缶バッジ' },
  { id: 'photo', label: 'ランダム生写真 Vol.3', total: 5, owned: 3, year: '2024', kind: '生写真' },
];

const totalOwned = SERIES.reduce((s, x) => s + x.owned, 0);
const totalAll = SERIES.reduce((s, x) => s + x.total, 0);

// Generate item list for a series
function getItems(series, members = ['スア', 'ヒナ', 'シユン', 'ジウォン', 'ミナ']) {
  const ms = members.slice(0, series.total);
  // Pad if total > 5
  while (ms.length < series.total) ms.push(members[ms.length % 5]);
  return ms.map((m, i) => ({
    id: `${series.id}-${i}`,
    member: m,
    no: String(i + 1).padStart(2, '0'),
    owned: i < series.owned, // first N owned
    series: series.label,
    kind: series.kind,
  }));
}

// ─────────────────────────────────────────────────────────────
// Card visual — owned (full color) vs silhouette (薄く輪郭のみ)
// ─────────────────────────────────────────────────────────────
function PCCard({ item, size = 'md', onClick, colors: c }) {
  const dims = size === 'lg' ? { w: 140, h: 200, mh: 60 } : size === 'sm' ? { w: 64, h: 92, mh: 28 } : { w: 92, h: 130, mh: 40 };
  const hue = MEMBER_HUE[item.member] || MEMBER_HUE['スア'];
  return (
    <button onClick={onClick} style={{
      width: dims.w, height: dims.h,
      padding: 0, border: 0, background: 'transparent',
      cursor: 'pointer', position: 'relative',
      fontFamily: 'inherit',
    }}>
      <div style={{
        width: '100%', height: '100%',
        borderRadius: 8,
        background: item.owned
          ? `linear-gradient(160deg, ${hue.h1}, ${hue.h2})`
          : '#f0ecf4',
        border: item.owned ? `1px solid ${hue.accent}40` : `1px dashed rgba(58,50,74,0.2)`,
        position: 'relative', overflow: 'hidden',
        boxShadow: item.owned ? `0 2px 8px ${hue.accent}25` : 'none',
        opacity: item.owned ? 1 : 1,
      }}>
        {/* Top bar — number + member name */}
        {item.owned ? (
          <div style={{
            position: 'absolute', top: 5, left: 6, right: 6,
            display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
          }}>
            <span style={{
              fontFamily: '"Inter Tight", sans-serif',
              fontSize: size === 'sm' ? 8 : 10, fontWeight: 800,
              color: hue.accent, letterSpacing: 0.5,
            }}>#{item.no}</span>
            <span style={{
              fontSize: size === 'sm' ? 7 : 9, fontWeight: 700,
              color: '#fff', background: `${hue.accent}cc`,
              padding: '1px 5px', borderRadius: 3,
            }}>{item.member}</span>
          </div>
        ) : null}

        {/* Member silhouette (only the shoulder line) */}
        <svg viewBox="0 0 92 130" preserveAspectRatio="xMidYMin meet" style={{
          position: 'absolute', top: dims.mh / 4, left: 0, width: '100%', height: '70%',
        }}>
          {/* Head */}
          <ellipse cx="46" cy="50" rx="22" ry="26" fill={item.owned ? hue.accent : 'rgba(58,50,74,0.18)'} />
          {/* Hair tufts */}
          <path d="M24 40 Q30 18 46 22 Q62 18 68 40 Q60 32 46 30 Q32 32 24 40Z" fill={item.owned ? '#3a324a' : 'rgba(58,50,74,0.22)'} />
          {/* Shoulders */}
          <path d="M14 130 Q18 88 46 88 Q74 88 78 130 Z" fill={item.owned ? hue.accent : 'rgba(58,50,74,0.18)'} />
        </svg>

        {/* Status badge */}
        {!item.owned && (
          <div style={{
            position: 'absolute', bottom: 6, left: '50%',
            transform: 'translateX(-50%)',
            fontSize: size === 'sm' ? 8 : 9.5, color: c.mute,
            fontWeight: 700, letterSpacing: 0.5,
            padding: '1.5px 6px', background: '#fff',
            borderRadius: 999,
          }}>未取得</div>
        )}
        {item.owned && size !== 'sm' && (
          <div style={{
            position: 'absolute', bottom: 4, right: 4,
            width: size === 'lg' ? 18 : 14, height: size === 'lg' ? 18 : 14,
            borderRadius: '50%', background: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: `0 1px 3px ${hue.accent}50`,
          }}>
            <svg width={size === 'lg' ? 11 : 8} height={size === 'lg' ? 8 : 6} viewBox="0 0 11 8">
              <path d="M1 4l3 3 6-6" stroke={hue.accent} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
        )}
      </div>
    </button>
  );
}

// ─────────────────────────────────────────────────────────────
// Top progress bar — overall completion
// ─────────────────────────────────────────────────────────────
function ProgressHero({ colors: c, owned, total, oshi = 'LUMENA · スア' }) {
  const pct = Math.round((owned / total) * 100);
  return (
    <div style={{
      margin: '0 18px 16px',
      padding: '16px 16px 14px',
      borderRadius: 16,
      background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
      color: '#fff', position: 'relative', overflow: 'hidden',
      boxShadow: `0 8px 24px ${c.lavender}40`,
    }}>
      <div style={{ position: 'relative', zIndex: 1 }}>
        <div style={{ fontSize: 10.5, fontWeight: 700, opacity: 0.9, letterSpacing: 0.5, marginBottom: 2 }}>{oshi}</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
          <span style={{ fontFamily: '"Inter Tight", sans-serif', fontSize: 38, fontWeight: 800, letterSpacing: -1 }}>{owned}</span>
          <span style={{ fontSize: 16, fontWeight: 600, opacity: 0.7 }}>/ {total}</span>
          <span style={{ fontSize: 12, fontWeight: 700, opacity: 0.85, marginLeft: 'auto' }}>{pct}% 達成</span>
        </div>
        <div style={{
          marginTop: 10, height: 6, borderRadius: 999,
          background: 'rgba(255,255,255,0.25)', overflow: 'hidden',
        }}>
          <div style={{
            height: '100%', width: `${pct}%`,
            background: '#fff', borderRadius: 999,
            boxShadow: '0 0 12px rgba(255,255,255,0.6)',
          }} />
        </div>
        <div style={{ marginTop: 8, fontSize: 10.5, opacity: 0.85 }}>
          あと <b>{total - owned}枚</b> でコンプリート
        </div>
      </div>
      {/* decorative orbs */}
      <div style={{ position: 'absolute', top: -20, right: -20, width: 80, height: 80, borderRadius: '50%', background: 'rgba(255,255,255,0.12)' }} />
      <div style={{ position: 'absolute', bottom: -30, right: 40, width: 60, height: 60, borderRadius: '50%', background: 'rgba(255,255,255,0.08)' }} />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 1. Pokedex List Screen
// ─────────────────────────────────────────────────────────────
function PokedexList({ tweaks }) {
  const c = PD_C(tweaks);
  const [filter, setFilter] = React.useState('all'); // all | owned | missing
  const [member, setMember] = React.useState('all'); // all | each member
  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      overflowY: 'auto',
      paddingTop: 54, paddingBottom: 80,
      boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      {/* Header */}
      <div style={{ padding: '14px 18px 10px' }}>
        <div style={{ fontSize: 11, color: c.mute, fontWeight: 700, letterSpacing: 0.6, marginBottom: 2 }}>COLLECTION</div>
        <div style={{ fontSize: 26, fontWeight: 800, letterSpacing: -0.5 }}>図鑑</div>
      </div>

      <ProgressHero colors={c} owned={totalOwned} total={totalAll} />

      {/* Filter rail */}
      <div style={{
        margin: '0 0 12px',
        display: 'flex', gap: 6, padding: '0 18px',
        overflowX: 'auto', WebkitOverflowScrolling: 'touch',
      }}>
        {[
          { id: 'all', l: 'すべて' },
          { id: 'owned', l: `取得済 ${totalOwned}` },
          { id: 'missing', l: `未取得 ${totalAll - totalOwned}` },
        ].map(f => (
          <button key={f.id} onClick={() => setFilter(f.id)} style={{
            padding: '6px 14px', borderRadius: 999,
            background: filter === f.id ? c.ink : '#fff',
            color: filter === f.id ? '#fff' : c.ink,
            border: filter === f.id ? 'none' : `0.5px solid ${c.divide}`,
            fontFamily: 'inherit', fontSize: 11.5, fontWeight: 700,
            whiteSpace: 'nowrap', flex: '0 0 auto', cursor: 'pointer',
          }}>{f.l}</button>
        ))}
        <div style={{ width: 1, background: c.divide, margin: '4px 4px' }} />
        {['all', 'スア', 'ヒナ', 'シユン', 'ジウォン', 'ミナ'].map(m => (
          <button key={m} onClick={() => setMember(m)} style={{
            padding: '6px 12px', borderRadius: 999,
            background: member === m ? `${c.lavender}1a` : '#fff',
            color: member === m ? c.lavender : c.mute,
            border: member === m ? `1px solid ${c.lavender}` : `0.5px solid ${c.divide}`,
            fontFamily: 'inherit', fontSize: 11.5,
            fontWeight: member === m ? 700 : 500,
            whiteSpace: 'nowrap', flex: '0 0 auto', cursor: 'pointer',
          }}>{m === 'all' ? '全メンバー' : m}</button>
        ))}
      </div>

      {/* Series sections */}
      <div style={{ padding: '0 18px' }}>
        {SERIES.map(series => {
          const items = getItems(series);
          const filtered = items.filter(it =>
            (filter === 'all' || (filter === 'owned' && it.owned) || (filter === 'missing' && !it.owned)) &&
            (member === 'all' || it.member === member)
          );
          if (filtered.length === 0) return null;
          const isComplete = series.owned === series.total;
          return (
            <div key={series.id} style={{ marginBottom: 22 }}>
              <div style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                marginBottom: 10,
              }}>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 1 }}>
                    <span style={{ fontSize: 13, fontWeight: 800, color: c.ink }}>{series.label}</span>
                    {isComplete && (
                      <span style={{
                        fontSize: 9.5, padding: '1px 6px', borderRadius: 4,
                        background: c.gold, color: '#fff', fontWeight: 800, letterSpacing: 0.5,
                      }}>COMP</span>
                    )}
                  </div>
                  <div style={{ fontSize: 10.5, color: c.mute }}>
                    {series.year} · {series.kind} · {series.owned}/{series.total}
                  </div>
                </div>
                <div style={{
                  width: 60, height: 4, background: c.subtle, borderRadius: 999, overflow: 'hidden',
                }}>
                  <div style={{
                    width: `${(series.owned / series.total) * 100}%`, height: '100%',
                    background: isComplete ? c.gold : c.lavender, borderRadius: 999,
                  }} />
                </div>
              </div>
              <div style={{
                display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(92px, 1fr))', gap: 10,
              }}>
                {filtered.map(it => <PCCard key={it.id} item={it} colors={c} />)}
              </div>
            </div>
          );
        })}
      </div>

      {/* Bottom share band */}
      <div style={{
        margin: '0 18px',
        padding: 14, borderRadius: 14,
        background: '#fff', border: `0.5px solid ${c.divide}`,
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 12.5, fontWeight: 700, marginBottom: 1 }}>図鑑をシェア</div>
          <div style={{ fontSize: 10.5, color: c.mute }}>X · スクリーンショット · 画像保存</div>
        </div>
        <button style={{
          padding: '8px 14px', borderRadius: 10,
          background: c.ink, color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 11.5, fontWeight: 700,
        }}>X で共有</button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 2. Pokedex Detail — owned item (取引履歴・取得日・相手)
// ─────────────────────────────────────────────────────────────
function PokedexDetailOwned({ tweaks }) {
  const c = PD_C(tweaks);
  const item = { id: 'wt2-1', member: 'スア', no: '02', series: 'WORLD TOUR DAY 2', kind: 'トレカ' };
  const hue = MEMBER_HUE[item.member];

  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      overflowY: 'auto',
      paddingTop: 0, paddingBottom: 100,
      boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      {/* Hero — full-bleed gradient with card centered */}
      <div style={{
        background: `linear-gradient(180deg, ${hue.h1}, ${hue.h2}aa)`,
        padding: '54px 18px 22px',
        position: 'relative',
      }}>
        {/* back chevron */}
        <svg width="10" height="16" viewBox="0 0 10 16" style={{ position: 'absolute', top: 60, left: 18 }}>
          <path d="M8 1L2 8l6 7" stroke="#fff" strokeWidth="1.8" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
        <div style={{ display: 'flex', justifyContent: 'center', marginTop: 10, marginBottom: 12 }}>
          <PCCard item={{ ...item, owned: true }} size="lg" colors={c} />
        </div>
        <div style={{ textAlign: 'center', color: '#fff', textShadow: '0 1px 4px rgba(0,0,0,0.15)' }}>
          <div style={{
            display: 'inline-block', fontSize: 10, fontWeight: 800,
            padding: '2px 8px', borderRadius: 4,
            background: 'rgba(255,255,255,0.3)', letterSpacing: 0.6, marginBottom: 4,
          }}>#{item.no} · {item.series}</div>
          <div style={{ fontSize: 22, fontWeight: 800, letterSpacing: -0.3 }}>{item.member}</div>
          <div style={{ fontSize: 11, fontWeight: 600, opacity: 0.9 }}>WORLD TOUR DAY 2 トレカ</div>
        </div>
      </div>

      {/* Acquisition history */}
      <div style={{ padding: '16px 18px 0' }}>
        <div style={{ fontSize: 10.5, color: c.mute, fontWeight: 700, letterSpacing: 0.5, marginBottom: 8 }}>
          取得記録
        </div>
        <div style={{
          background: '#fff', borderRadius: 14,
          border: `0.5px solid ${c.divide}`, overflow: 'hidden',
          marginBottom: 16,
        }}>
          <div style={{ padding: '14px', display: 'flex', gap: 12, alignItems: 'center' }}>
            <div style={{
              width: 44, height: 44, borderRadius: 12,
              background: `linear-gradient(135deg, ${c.lavender}33, ${c.sky}33)`,
              color: c.lavender, fontSize: 14, fontWeight: 800,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flex: '0 0 auto',
            }}>M</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 12.5, fontWeight: 700, marginBottom: 1 }}>@mochiko_724</div>
              <div style={{ fontSize: 10.5, color: c.mute }}>
                2025/02/14 · 横浜アリーナ DAY1 · 取引完了
              </div>
            </div>
            <button style={{
              padding: '6px 10px', borderRadius: 8,
              background: c.subtle, color: c.ink, border: 0,
              fontFamily: 'inherit', fontSize: 10.5, fontWeight: 700,
            }}>プロフ</button>
          </div>
          <div style={{ height: 0.5, background: c.divide }} />
          {/* trade evidence photo placeholder */}
          <div style={{ padding: '10px 14px 14px' }}>
            <div style={{ fontSize: 10, color: c.mute, marginBottom: 6 }}>取引完了時の証跡写真</div>
            <div style={{
              aspectRatio: '16/9', borderRadius: 8,
              background: `linear-gradient(135deg, ${hue.h1}88, ${c.sky}44)`,
              border: `0.5px solid ${c.divide}`,
              position: 'relative',
            }}>
              <div style={{
                position: 'absolute', bottom: 6, left: 8,
                fontSize: 9, color: c.mute, fontWeight: 600,
              }}>2025/02/14 18:43</div>
            </div>
          </div>
        </div>

        {/* Card metadata */}
        <div style={{ fontSize: 10.5, color: c.mute, fontWeight: 700, letterSpacing: 0.5, marginBottom: 8 }}>
          詳細
        </div>
        <div style={{
          background: '#fff', borderRadius: 14,
          border: `0.5px solid ${c.divide}`, overflow: 'hidden',
          marginBottom: 16,
        }}>
          {[
            { k: 'シリーズ', v: 'WORLD TOUR DAY 2 (2025)' },
            { k: 'メンバー', v: `${item.member} · ${hue.label}` },
            { k: 'タイプ', v: 'ランダムトレカ（封入）' },
            { k: 'レアリティ', v: '通常版' },
            { k: 'メモ', v: '初の生身参戦記念' },
          ].map((row, i, arr) => (
            <div key={row.k} style={{
              padding: '11px 14px',
              display: 'flex', justifyContent: 'space-between',
              borderBottom: i < arr.length - 1 ? `0.5px solid ${c.divide}` : 'none',
            }}>
              <span style={{ fontSize: 11.5, color: c.mute }}>{row.k}</span>
              <span style={{ fontSize: 12, fontWeight: 600, color: c.ink, textAlign: 'right', maxWidth: '60%' }}>{row.v}</span>
            </div>
          ))}
        </div>

        {/* Series mini-progress */}
        <div style={{
          background: '#fff', borderRadius: 14,
          border: `0.5px solid ${c.divide}`,
          padding: 14, marginBottom: 12,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 8 }}>
            <span style={{ fontSize: 12, fontWeight: 700 }}>シリーズ進捗</span>
            <span style={{ fontSize: 11, color: c.mute, fontWeight: 600 }}>4/5 · あと1枚</span>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            {getItems(SERIES[0]).map(it => (
              <PCCard key={it.id} item={it} size="sm" colors={c} />
            ))}
          </div>
        </div>
      </div>

      {/* Sticky CTA */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '12px 18px 30px',
        background: 'rgba(255,255,255,0.94)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `0.5px solid ${c.divide}`,
        display: 'flex', gap: 8,
      }}>
        <button style={{
          width: 48, height: 48, borderRadius: 14,
          background: '#fff', border: `0.5px solid ${c.divide}`,
          fontFamily: 'inherit', fontSize: 13, fontWeight: 700, color: c.ink,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
            <path d="M9 2v8M5 6l4 4 4-4M3 12v3a1 1 0 001 1h10a1 1 0 001-1v-3" stroke={c.ink} strokeWidth="1.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </button>
        <button style={{
          flex: 1, height: 48, borderRadius: 14,
          background: '#fff', border: `0.5px solid ${c.divide}`,
          fontFamily: 'inherit', fontSize: 13.5, fontWeight: 600, color: c.ink,
        }}>譲るとして登録</button>
        <button style={{
          flex: 1, height: 48, borderRadius: 14,
          background: c.ink, color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 13.5, fontWeight: 700,
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6,
        }}>
          <svg width="13" height="13" viewBox="0 0 13 13"><path d="M11 2L6 7l-3-3M2 11h9" stroke="#fff" strokeWidth="1.4" fill="none" strokeLinecap="round"/></svg>
          シェア
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 3. Pokedex Detail — missing item (探し中ステータス + wish連携)
// ─────────────────────────────────────────────────────────────
function PokedexDetailMissing({ tweaks }) {
  const c = PD_C(tweaks);
  const item = { id: 'wt2-4', member: 'ミナ', no: '05', series: 'WORLD TOUR DAY 2', kind: 'トレカ' };
  const hue = MEMBER_HUE[item.member];
  const [wished, setWished] = React.useState(true);

  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      overflowY: 'auto',
      paddingBottom: 100,
      boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      {/* Hero — muted */}
      <div style={{
        background: '#ebe5f0',
        padding: '54px 18px 22px',
        position: 'relative',
      }}>
        <svg width="10" height="16" viewBox="0 0 10 16" style={{ position: 'absolute', top: 60, left: 18 }}>
          <path d="M8 1L2 8l6 7" stroke={c.ink} strokeWidth="1.8" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
        <div style={{ display: 'flex', justifyContent: 'center', marginTop: 10, marginBottom: 12 }}>
          <PCCard item={{ ...item, owned: false }} size="lg" colors={c} />
        </div>
        <div style={{ textAlign: 'center', color: c.ink }}>
          <div style={{
            display: 'inline-block', fontSize: 10, fontWeight: 800,
            padding: '2px 8px', borderRadius: 4,
            background: '#fff', letterSpacing: 0.6, marginBottom: 4, color: c.mute,
          }}>#{item.no} · {item.series}</div>
          <div style={{ fontSize: 22, fontWeight: 800, letterSpacing: -0.3 }}>{item.member}</div>
          <div style={{ fontSize: 11, fontWeight: 600, color: c.mute }}>未取得 · まだ手元にありません</div>
        </div>
      </div>

      {/* Searching status banner */}
      <div style={{ padding: '16px 18px 0' }}>
        {wished && (
          <div style={{
            padding: 14, borderRadius: 14,
            background: `linear-gradient(135deg, ${c.lavender}1a, ${c.sky}1a)`,
            border: `1px solid ${c.lavender}40`,
            marginBottom: 16,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
              <div style={{
                width: 8, height: 8, borderRadius: '50%',
                background: c.lavender, animation: 'pulse 1.5s ease-in-out infinite',
              }} />
              <span style={{ fontSize: 12, fontWeight: 800, color: c.lavender, letterSpacing: 0.4 }}>探し中</span>
              <span style={{ fontSize: 10.5, color: c.mute, marginLeft: 'auto' }}>3日前から</span>
            </div>
            <div style={{ fontSize: 12, color: c.ink, lineHeight: 1.5, marginBottom: 10 }}>
              wishに登録済み。マッチが見つかると通知します。
            </div>
            <div style={{
              display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8,
            }}>
              <div style={{ background: '#fff', borderRadius: 10, padding: '8px 10px', border: `0.5px solid ${c.divide}` }}>
                <div style={{ fontSize: 9, color: c.mute, fontWeight: 700, letterSpacing: 0.3, marginBottom: 2 }}>所持ユーザー</div>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 3 }}>
                  <span style={{ fontFamily: '"Inter Tight", sans-serif', fontSize: 20, fontWeight: 800, color: c.ink, lineHeight: 1 }}>3</span>
                  <span style={{ fontSize: 10, color: c.mute, fontWeight: 600 }}>人</span>
                </div>
              </div>
              <div style={{ background: '#fff', borderRadius: 10, padding: '8px 10px', border: `0.5px solid ${c.divide}` }}>
                <div style={{ fontSize: 9, color: c.mute, fontWeight: 700, letterSpacing: 0.3, marginBottom: 2 }}>AW近隣</div>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 3 }}>
                  <span style={{ fontFamily: '"Inter Tight", sans-serif', fontSize: 20, fontWeight: 800, color: c.ink, lineHeight: 1 }}>1</span>
                  <span style={{ fontSize: 10, color: c.mute, fontWeight: 600 }}>人</span>
                </div>
              </div>
              <div style={{ background: '#fff', borderRadius: 10, padding: '8px 10px', border: `0.5px solid ${c.divide}` }}>
                <div style={{ fontSize: 9, color: c.mute, fontWeight: 700, letterSpacing: 0.3, marginBottom: 2 }}>次の参戦予定</div>
                <div style={{ fontFamily: '"Inter Tight", sans-serif', fontSize: 16, fontWeight: 800, color: c.ink, lineHeight: 1 }}>4/27</div>
              </div>
            </div>
          </div>
        )}

        {/* Available holders preview */}
        <div style={{ fontSize: 10.5, color: c.mute, fontWeight: 700, letterSpacing: 0.5, marginBottom: 8 }}>
          このカードを持っているユーザー
        </div>
        <div style={{
          background: '#fff', borderRadius: 14,
          border: `0.5px solid ${c.divide}`, overflow: 'hidden',
          marginBottom: 16,
        }}>
          {[
            { h: '@pop_ria', meta: '横浜アリーナ参戦予定 4/27 · ★4.9 · あなたの欲しい譲所持', match: 'comp', dist: '約12km' },
            { h: '@iam_jiyoung', meta: 'AW未設定 · ★4.5', match: 'one-way', dist: '約45km' },
            { h: '@mochiko_724', meta: '東京ドーム 5/4予定 · ★4.7', match: 'one-way', dist: '約8km' },
          ].map((u, i, arr) => (
            <div key={u.h} style={{
              padding: '12px 14px',
              borderBottom: i < arr.length - 1 ? `0.5px solid ${c.divide}` : 'none',
              display: 'flex', alignItems: 'center', gap: 10,
            }}>
              <div style={{
                width: 32, height: 32, borderRadius: 10,
                background: `linear-gradient(135deg, ${c.lavender}33, ${c.sky}33)`,
                color: c.lavender, fontSize: 11, fontWeight: 800,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                flex: '0 0 auto',
              }}>{u.h[1].toUpperCase()}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <span style={{ fontSize: 12, fontWeight: 700 }}>{u.h}</span>
                  {u.match === 'comp' && (
                    <span style={{
                      fontSize: 9, padding: '1px 5px', borderRadius: 3,
                      background: c.lavender, color: '#fff', fontWeight: 800,
                    }}>完全マッチ</span>
                  )}
                </div>
                <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {u.meta}
                </div>
              </div>
              <div style={{ fontSize: 10.5, color: c.mute, flex: '0 0 auto', textAlign: 'right' }}>{u.dist}</div>
            </div>
          ))}
        </div>

        {/* Card metadata */}
        <div style={{
          background: '#fff', borderRadius: 14,
          border: `0.5px solid ${c.divide}`, overflow: 'hidden',
          marginBottom: 16,
        }}>
          {[
            { k: 'シリーズ', v: 'WORLD TOUR DAY 2 (2025)' },
            { k: 'メンバー', v: `${item.member} · ${hue.label}` },
            { k: 'タイプ', v: 'ランダムトレカ（封入）' },
            { k: 'wish登録日', v: '2025/02/11（3日前）' },
          ].map((row, i, arr) => (
            <div key={row.k} style={{
              padding: '11px 14px',
              display: 'flex', justifyContent: 'space-between',
              borderBottom: i < arr.length - 1 ? `0.5px solid ${c.divide}` : 'none',
            }}>
              <span style={{ fontSize: 11.5, color: c.mute }}>{row.k}</span>
              <span style={{ fontSize: 12, fontWeight: 600, color: c.ink }}>{row.v}</span>
            </div>
          ))}
        </div>

        {/* Series mini-progress */}
        <div style={{
          background: '#fff', borderRadius: 14,
          border: `0.5px solid ${c.divide}`,
          padding: 14, marginBottom: 12,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 8 }}>
            <span style={{ fontSize: 12, fontWeight: 700 }}>シリーズ進捗 · あと1枚でコンプ</span>
            <span style={{ fontSize: 11, color: c.lavender, fontWeight: 700 }}>4/5</span>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            {getItems(SERIES[0]).map(it => (
              <PCCard key={it.id} item={it} size="sm" colors={c} />
            ))}
          </div>
        </div>
      </div>

      {/* Sticky CTA */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '12px 18px 30px',
        background: 'rgba(255,255,255,0.94)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `0.5px solid ${c.divide}`,
        display: 'flex', gap: 8,
      }}>
        <button onClick={() => setWished(!wished)} style={{
          flex: 1, height: 48, borderRadius: 14,
          background: '#fff', border: `0.5px solid ${c.divide}`,
          fontFamily: 'inherit', fontSize: 12.5, fontWeight: 600,
          color: wished ? c.lavender : c.ink,
        }}>{wished ? '✓ wishに登録済' : 'wishに追加'}</button>
        <button style={{
          flex: 2, height: 48, borderRadius: 14,
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', border: 0, fontFamily: 'inherit',
          fontSize: 14, fontWeight: 700,
          boxShadow: `0 6px 16px ${c.lavender}50`,
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6,
        }}>
          <svg width="14" height="14" viewBox="0 0 14 14"><circle cx="6" cy="6" r="4.5" stroke="#fff" strokeWidth="1.5" fill="none"/><path d="M9.5 9.5L13 13" stroke="#fff" strokeWidth="1.5" strokeLinecap="round"/></svg>
          このカードを探す
        </button>
      </div>
      <style>{`@keyframes pulse { 0%,100% { opacity: 1; } 50% { opacity: 0.3; } }`}</style>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 4. Complete Achievement Overlay (コンプ達成演出)
// ─────────────────────────────────────────────────────────────
function CompleteCelebration({ tweaks }) {
  const c = PD_C(tweaks);
  const items = getItems(SERIES[4]); // badge series — owned 5/5

  return (
    <div style={{
      width: '100%', height: '100%',
      background: `radial-gradient(circle at 50% 30%, ${c.lavender}, ${c.ink})`,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: '#fff', position: 'relative',
      overflow: 'hidden',
      paddingTop: 54, paddingBottom: 30,
      boxSizing: 'border-box',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* Confetti SVG */}
      <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', pointerEvents: 'none' }}>
        {[...Array(40)].map((_, i) => {
          const x = (i * 53) % 100;
          const y = ((i * 31) % 90) + 5;
          const r = 3 + (i % 4);
          const colors = [c.gold, c.pink, c.sky, '#fff'];
          return <circle key={i} cx={`${x}%`} cy={`${y}%`} r={r} fill={colors[i % 4]} opacity={0.7 + (i % 3) * 0.1} />;
        })}
      </svg>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 32px', position: 'relative', zIndex: 1, textAlign: 'center' }}>
        {/* Trophy/star */}
        <div style={{
          width: 88, height: 88, borderRadius: '50%',
          background: c.gold,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          marginBottom: 20,
          boxShadow: `0 0 40px ${c.gold}80, 0 8px 24px rgba(0,0,0,0.3)`,
        }}>
          <svg width="46" height="46" viewBox="0 0 46 46">
            <path d="M23 4l5.4 11 12.1 1.8-8.7 8.5 2 12.1L23 32l-10.8 5.4 2-12.1-8.7-8.5L17.6 15z" fill="#fff" />
          </svg>
        </div>

        <div style={{ fontSize: 11.5, fontWeight: 800, letterSpacing: 2, opacity: 0.85, marginBottom: 6 }}>COMPLETE</div>
        <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: -0.5, marginBottom: 6, lineHeight: 1.2 }}>
          コンプリート<br />達成！
        </div>
        <div style={{ fontSize: 13, fontWeight: 600, opacity: 0.9, marginBottom: 26 }}>
          WT会場限定 缶バッジ · 5/5
        </div>

        {/* Card row */}
        <div style={{
          display: 'flex', gap: 8, marginBottom: 24,
          padding: 12, borderRadius: 16,
          background: 'rgba(255,255,255,0.1)',
          backdropFilter: 'blur(10px)', WebkitBackdropFilter: 'blur(10px)',
        }}>
          {items.map(it => (
            <PCCard key={it.id} item={it} size="sm" colors={c} />
          ))}
        </div>

        {/* Stats */}
        <div style={{
          padding: '10px 18px', borderRadius: 999,
          background: 'rgba(255,255,255,0.15)',
          fontSize: 12, fontWeight: 600, marginBottom: 28,
          backdropFilter: 'blur(10px)', WebkitBackdropFilter: 'blur(10px)',
        }}>
          初回コンプ · 取引3回 · 12日間
        </div>
      </div>

      {/* CTAs */}
      <div style={{ padding: '0 18px', display: 'flex', flexDirection: 'column', gap: 8, position: 'relative', zIndex: 1 }}>
        <button style={{
          width: '100%', height: 50, borderRadius: 14,
          background: '#fff', color: c.ink, border: 0,
          fontFamily: 'inherit', fontSize: 14, fontWeight: 800,
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          <svg width="15" height="15" viewBox="0 0 15 15"><path d="M11 2H4a2 2 0 00-2 2v9l3-2h6a2 2 0 002-2V4a2 2 0 00-2-2z" stroke={c.ink} strokeWidth="1.4" fill="none"/></svg>
          Xでシェア（テンプレ生成済）
        </button>
        <button style={{
          width: '100%', height: 46, borderRadius: 14,
          background: 'transparent', color: '#fff',
          border: '0.5px solid rgba(255,255,255,0.4)',
          fontFamily: 'inherit', fontSize: 13, fontWeight: 600,
        }}>図鑑に戻る</button>
      </div>
    </div>
  );
}

// __MVP_EXPORTS__
Object.assign(window, { PokedexList, PokedexDetailOwned, PokedexDetailMissing, CompleteCelebration });
