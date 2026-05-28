// c-flow.jsx
// C-flow: Propose → Chat → Complete (with evidence photo + dual approve)
// Uses brand palette tokens passed via tweaks prop

const COLORS = (t) => ({
  lavender: t.primary,
  sky: t.secondary,
  pink: t.accent,
  ink: '#3a324a',
  mute: 'rgba(58,50,74,0.55)',
  subtle: 'rgba(58,50,74,0.06)',
  bg: '#fbf9fc',
});

// ─────────────────────────────────────────────────────────────
// C-1. Propose flow — auto-generated template + edit + send
// ─────────────────────────────────────────────────────────────
function ProposeScreen({ tweaks }) {
  const c = COLORS(tweaks);
  const [tab, setTab] = React.useState(0);
  const [text, setText] = React.useState(
    'はじめまして！スア @lumi_sua\n横アリ周辺で交換可能でしょうか？\nお互いの希望が完全一致しています◎\n会場周辺で30分以内に合流可能です。'
  );

  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, fontFeatureSettings: '"palt"',
    }}>
      <div style={{ height: 60 }} />
      {/* Header */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '8px 14px',
        borderBottom: `0.5px solid ${c.subtle}`,
        background: '#fff',
      }}>
        <button style={{
          width: 36, height: 36, borderRadius: '50%',
          background: '#fff', border: `0.5px solid ${c.subtle}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="10" height="16" viewBox="0 0 10 16">
            <path d="M8 2L2 8l6 6" stroke={c.ink} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </button>
        <div style={{ fontSize: 14.5, fontWeight: 700, letterSpacing: 0.3 }}>打診を送る</div>
        <div style={{ width: 36 }} />
      </div>

      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 110 }}>
        {/* Recipient summary */}
        <div style={{ padding: '14px 18px 10px' }}>
          <div style={{
            background: '#fff', borderRadius: 16, padding: 12,
            border: `0.5px solid ${c.lavender}22`,
            display: 'flex', alignItems: 'center', gap: 10,
            boxShadow: '0 2px 8px rgba(58,50,74,0.04)',
          }}>
            <Avatar name="lumi_sua" size={40} hue={280} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                <span style={{ fontSize: 13.5, fontWeight: 700 }}>@lumi_sua</span>
                <span style={{
                  fontSize: 9.5, padding: '1px 7px', borderRadius: 999,
                  background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
                  color: '#fff', fontWeight: 700, letterSpacing: 0.4,
                }}>COMPLETE</span>
              </div>
              <div style={{ fontSize: 10.5, color: c.mute, marginTop: 2, fontVariantNumeric: 'tabular-nums' }}>
                約169m · 3分前 · ★4.8 · 取引127回
              </div>
            </div>
          </div>
        </div>

        {/* Trade preview */}
        <div style={{ padding: '0 18px' }}>
          <SectionLabel colors={c}>交換内容</SectionLabel>
          <div style={{
            display: 'grid', gridTemplateColumns: '1fr auto 1fr', gap: 10,
            padding: 14, background: '#fff', borderRadius: 16,
            border: `0.5px solid ${c.subtle}`,
          }}>
            <div>
              <div style={{ fontSize: 9.5, color: c.mute, fontWeight: 700, letterSpacing: 0.5, marginBottom: 6 }}>相手の譲</div>
              <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
                <Tcg label="ス" hue={280} />
                <Tcg label="ス" hue={300} />
                <Tcg label="ス" hue={320} />
              </div>
              <div style={{ fontSize: 10.5, color: c.ink, marginTop: 6 }}>
                スア トレカ ×3
              </div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', flexDirection: 'column', gap: 4, justifyContent: 'center' }}>
              <div style={{
                width: 24, height: 24, borderRadius: '50%', background: c.lavender,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>{Ic.arrowR(12, '#fff')}</div>
              <div style={{
                width: 24, height: 24, borderRadius: '50%', background: c.sky,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>{Ic.arrowL(12, '#fff')}</div>
            </div>
            <div>
              <div style={{ fontSize: 9.5, color: c.mute, fontWeight: 700, letterSpacing: 0.5, marginBottom: 6, textAlign: 'right' }}>あなたの譲</div>
              <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap', justifyContent: 'flex-end' }}>
                <Tcg label="ヒ" hue={200} accent={`${c.pink}cc`} />
                <Tcg label="ヒ" hue={210} accent={`${c.pink}cc`} />
              </div>
              <div style={{ fontSize: 10.5, color: c.ink, marginTop: 6, textAlign: 'right' }}>
                ヒナ 生写真 ×2
              </div>
            </div>
          </div>
        </div>

        {/* Template tabs */}
        <div style={{ padding: '0 18px' }}>
          <SectionLabel colors={c}>メッセージ</SectionLabel>
          <div style={{
            display: 'flex', gap: 4, padding: 3,
            background: c.subtle, borderRadius: 10,
            marginBottom: 8,
          }}>
            {['標準', 'カジュアル', '丁寧'].map((t, i) => (
              <button key={t} onClick={() => setTab(i)} style={{
                flex: 1, height: 28, borderRadius: 8,
                background: tab === i ? '#fff' : 'transparent',
                color: tab === i ? c.lavender : c.mute,
                border: 0, fontFamily: 'inherit', fontSize: 12,
                fontWeight: tab === i ? 700 : 500,
                boxShadow: tab === i ? '0 1px 3px rgba(58,50,74,0.1)' : 'none',
              }}>{t}</button>
            ))}
          </div>
          <div style={{
            background: '#fff', borderRadius: 14, padding: 12,
            border: `0.5px solid ${c.subtle}`,
            minHeight: 120, fontSize: 13, lineHeight: 1.6,
            color: c.ink, whiteSpace: 'pre-wrap',
          }}>
            {text}
            <div style={{ display: 'inline-block', width: 1, height: 14, background: c.lavender, marginLeft: 1, verticalAlign: 'middle', animation: 'blink 1s infinite' }} />
          </div>
          <div style={{
            fontSize: 10.5, color: c.mute, marginTop: 6, padding: '0 4px',
            display: 'flex', justifyContent: 'space-between',
          }}>
            <span>テンプレを編集できます</span>
            <span style={{ fontVariantNumeric: 'tabular-nums' }}>{text.length} / 200</span>
          </div>
        </div>

        {/* Auto-included info */}
        <div style={{ padding: '14px 18px 0' }}>
          <SectionLabel colors={c}>自動で添付される情報</SectionLabel>
          <div style={{
            background: '#fff', borderRadius: 14,
            border: `0.5px solid ${c.subtle}`,
            overflow: 'hidden',
          }}>
            {[
              { k: '推奨合流ポイント', v: '横浜アリーナ 西ゲート', src: '@Megrum推奨' },
              { k: 'あなたの服装写真', v: '直前撮影で更新', src: '撮影 ›' },
              { k: '評価サマリ', v: '★4.7 · 取引89回' },
            ].map((row, i, arr) => (
              <div key={row.k} style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                padding: '11px 14px',
                borderBottom: i < arr.length - 1 ? `0.5px solid ${c.subtle}` : 'none',
              }}>
                <span style={{ fontSize: 12, color: c.mute }}>{row.k}</span>
                <span style={{ fontSize: 12, fontWeight: 600, color: c.ink, display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                  {row.v}
                  {row.src && (
                    <span style={{
                      fontSize: 9.5, padding: '1px 6px', borderRadius: 4,
                      background: row.src.includes('Megrum') ? `${c.lavender}1f` : c.subtle,
                      color: row.src.includes('Megrum') ? c.lavender : c.mute,
                      fontWeight: 700, letterSpacing: 0.3,
                    }}>{row.src}</span>
                  )}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Sticky CTA */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '12px 18px 30px',
        background: 'rgba(255,255,255,0.92)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `0.5px solid ${c.lavender}22`,
        display: 'flex', gap: 8,
      }}>
        <button style={{
          flex: 1, height: 48, borderRadius: 14,
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', border: 0, fontFamily: 'inherit',
          fontSize: 15, fontWeight: 700, letterSpacing: 0.4,
          boxShadow: `0 6px 16px ${c.lavender}50`,
        }}>打診を送る</button>
      </div>
    </div>
  );
}

function SectionLabel({ children, colors }) {
  return (
    <div style={{
      fontSize: 10.5, fontWeight: 700, letterSpacing: 0.6,
      color: colors.mute, textTransform: 'uppercase',
      padding: '14px 4px 8px',
    }}>{children}</div>
  );
}

// ─────────────────────────────────────────────────────────────
// C-2. Trade chat — 当日のライブ運用（場所・時間は合意前にfix済）
//   - 取引内容＋確定済の待ち合わせ（mini map）固定表示
//   - 服装写真をシェアCTAを目立たせる
//   - 現在地共有（mini mapでメッセージとして送信）
//   - 到着ステータス（ヘッダーに表示）
//   - QR本人確認・証跡撮影への入口は維持
// ─────────────────────────────────────────────────────────────

// 簡易マップ（俯瞰図 + 中央ピン）
const CF_MiniMap = ({ c, height = 90, label, accent, you, partner }) => {
  const pin = accent || c.lavender;
  return (
    <div style={{
      height, borderRadius: 10, overflow: 'hidden', position: 'relative',
      border: `0.5px solid ${c.subtle}`, background: '#e8eef0',
    }}>
      <svg width="100%" height="100%" viewBox="0 0 300 90" preserveAspectRatio="none">
        <rect width="300" height="90" fill="#e8eef0" />
        <rect x="0" y="38" width="300" height="14" fill="#fafbfc" />
        <line x1="0" y1="45" x2="300" y2="45" stroke="#dde0e2" strokeWidth="0.5" strokeDasharray="4 3" />
        <rect x="138" y="0" width="11" height="90" fill="#fafbfc" />
        <rect x="14" y="6" width="48" height="26" fill="#d4d8d6" rx="2" />
        <rect x="68" y="6" width="62" height="28" fill="#cfd2d0" rx="2" />
        <rect x="156" y="4" width="56" height="30" fill="#d4d8d6" rx="2" />
        <rect x="220" y="6" width="68" height="28" fill="#d0d4d2" rx="2" />
        <rect x="14" y="56" width="50" height="28" fill="#d2d6d4" rx="2" />
        <rect x="70" y="58" width="60" height="26" fill="#d8dcda" rx="2" />
        <rect x="156" y="56" width="56" height="30" fill="#cfd3d1" rx="2" />
        <rect x="220" y="58" width="68" height="26" fill="#d6dad8" rx="2" />
        <rect x="225" y="36" width="60" height="14" fill="#cad8c6" rx="2" />
        <circle cx="240" cy="43" r="2.5" fill="#b9ccb3" />
        <circle cx="252" cy="44" r="2" fill="#b9ccb3" />
        <circle cx="267" cy="42" r="2.3" fill="#b9ccb3" />
        {/* 中央: 待ち合わせポイント */}
        <g transform="translate(143, 45)">
          <circle cx="0" cy="0" r="20" fill={pin} fillOpacity="0.16" />
          <circle cx="0" cy="0" r="13" fill={pin} fillOpacity="0.32" />
          <path d="M0 -12 C-6 -12 -10 -8 -10 -2 C-10 5 0 12 0 12 C0 12 10 5 10 -2 C10 -8 6 -12 0 -12 Z"
                fill={pin} stroke="#fff" strokeWidth="1.4" />
          <circle cx="0" cy="-3" r="3" fill="#fff" />
        </g>
        {/* You / partner positions（あれば） */}
        {you && (
          <g transform={`translate(${you.x}, ${you.y})`}>
            <circle cx="0" cy="0" r="8" fill={c.lavender} fillOpacity="0.25" />
            <circle cx="0" cy="0" r="4.5" fill={c.lavender} stroke="#fff" strokeWidth="1.4" />
          </g>
        )}
        {partner && (
          <g transform={`translate(${partner.x}, ${partner.y})`}>
            <circle cx="0" cy="0" r="8" fill={c.pink} fillOpacity="0.25" />
            <circle cx="0" cy="0" r="4.5" fill={c.pink} stroke="#fff" strokeWidth="1.4" />
          </g>
        )}
      </svg>
      {label && (
        <div style={{
          position: 'absolute', left: 8, bottom: 6,
          background: 'rgba(255,255,255,0.94)', padding: '3px 7px',
          borderRadius: 6, fontSize: 9.5, fontWeight: 700, color: c.ink,
          boxShadow: '0 2px 6px rgba(0,0,0,0.08)',
        }}>{label}</div>
      )}
    </div>
  );
};

function ChatScreen({ tweaks }) {
  const c = COLORS(tweaks);

  // 確定した取引内容＋待ち合わせ（合意前にfix済）
  const meetup = {
    date: '5/3 (土)',
    time: '14:00〜18:00',
    place: 'TWICE 名古屋ドーム公演',
    area: 'ナゴヤドーム前矢田駅 周辺',
  };

  // 到着ステータス
  const myArrived = false;
  const partnerArrived = true;

  // 服装写真の共有状況
  const myOutfitShared = false;
  const partnerOutfitShared = true;

  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, fontFeatureSettings: '"palt"',
    }}>
      <div style={{ height: 60 }} />
      {/* Chat header（到着状態を表示） */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        padding: '8px 14px',
        borderBottom: `0.5px solid ${c.subtle}`,
        background: '#fff',
      }}>
        <button style={{
          width: 32, height: 32, borderRadius: '50%',
          background: '#fff', border: `0.5px solid ${c.subtle}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="9" height="14" viewBox="0 0 9 14">
            <path d="M7 1L2 7l5 6" stroke={c.ink} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </button>
        <Avatar name="lumi_sua" size={32} hue={280} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 13.5, fontWeight: 700 }}>@lumi_sua</div>
          <div style={{ fontSize: 10, color: c.mute, fontVariantNumeric: 'tabular-nums', display: 'flex', alignItems: 'center', gap: 4 }}>
            <span style={{
              display: 'inline-block', width: 5, height: 5, borderRadius: '50%',
              background: partnerArrived ? '#22c55e' : '#e0a847',
            }} />
            <span style={{ fontWeight: 700, color: partnerArrived ? '#22c55e' : '#e0a847' }}>
              {partnerArrived ? '会場到着済' : '移動中'}
            </span>
            <span>· 169m</span>
          </div>
        </div>
        <button style={{
          padding: '6px 11px', borderRadius: 999,
          background: `${c.lavender}1a`, color: c.lavender,
          border: 0, fontFamily: 'inherit', fontSize: 11.5, fontWeight: 700,
          display: 'inline-flex', alignItems: 'center', gap: 4,
        }}>
          <svg width="10" height="10" viewBox="0 0 10 10">
            <rect x="1" y="1" width="8" height="8" rx="1.5" fill="none" stroke={c.lavender} strokeWidth="1.2"/>
          </svg>
          QR
        </button>
      </div>

      {/* Pinned: 取引内容＋確定済の待ち合わせ */}
      <div style={{
        padding: '12px 16px 4px', background: c.bg,
        borderBottom: `0.5px solid ${c.subtle}`,
      }}>
        <div style={{
          background: '#fff', borderRadius: 14,
          border: `0.5px solid ${c.lavender}33`,
          padding: 12,
          boxShadow: `0 2px 8px ${c.lavender}14`,
        }}>
          <div style={{
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            marginBottom: 8,
          }}>
            <div style={{
              fontSize: 9.5, fontWeight: 800, color: c.lavender,
              letterSpacing: 0.5,
            }}>📋 取引内容＋待ち合わせ（確定済）</div>
            <span style={{
              fontSize: 9, fontWeight: 800, color: '#fff',
              background: '#22c55e', padding: '2px 7px', borderRadius: 999,
              letterSpacing: 0.4,
            }}>合意済</span>
          </div>

          {/* Trade items */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 9, color: c.mute, fontWeight: 700, marginBottom: 2 }}>受け取る</div>
              <div style={{ fontSize: 11.5, fontWeight: 700, color: c.ink, lineHeight: 1.4 }}>
                スア WT01 トレカ <span style={{ color: c.lavender }}>×3</span>
              </div>
            </div>
            <svg width="16" height="16" viewBox="0 0 22 22" style={{ flexShrink: 0 }}>
              <path d="M5 8h12M14 4l4 4-4 4M17 14H5M8 18l-4-4 4-4" stroke={c.lavender} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            <div style={{ flex: 1, minWidth: 0, textAlign: 'right' }}>
              <div style={{ fontSize: 9, color: c.mute, fontWeight: 700, marginBottom: 2 }}>出す</div>
              <div style={{ fontSize: 11.5, fontWeight: 700, color: c.ink, lineHeight: 1.4 }}>
                ヒナ生写真 <span style={{ color: c.lavender }}>×1</span><br/>
                スア STUDIO <span style={{ color: c.lavender }}>×1</span>
              </div>
            </div>
          </div>

          {/* Meetup with mini map */}
          <div style={{
            display: 'flex', gap: 10, alignItems: 'center',
            paddingTop: 8, borderTop: `0.5px dashed ${c.subtle}`,
          }}>
            <div style={{ flex: '0 0 92px', height: 60 }}>
              <CF_MiniMap c={c} height={60} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 8.5, fontWeight: 800, color: c.lavender, letterSpacing: 0.4, marginBottom: 2 }}>📍 待ち合わせ</div>
              <div style={{ fontSize: 12, fontWeight: 800, color: c.ink, fontVariantNumeric: 'tabular-nums', marginBottom: 1 }}>
                {meetup.date} {meetup.time}
              </div>
              <div style={{ fontSize: 10.5, color: c.mute, lineHeight: 1.4 }}>
                {meetup.place}<br/>
                📍 {meetup.area}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* PROMINENT: 服装写真をシェア CTA */}
      {!myOutfitShared && (
        <div style={{
          margin: '10px 16px 6px',
          padding: 14, borderRadius: 14,
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', position: 'relative', overflow: 'hidden',
          boxShadow: `0 6px 18px ${c.lavender}44`,
        }}>
          {/* decorative sparkles */}
          <div style={{
            position: 'absolute', right: -16, top: -16, width: 80, height: 80,
            borderRadius: '50%', background: 'rgba(255,255,255,0.12)',
          }} />
          <div style={{
            position: 'absolute', right: 14, bottom: -8, width: 30, height: 30,
            borderRadius: '50%', background: 'rgba(255,255,255,0.1)',
          }} />

          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8, position: 'relative' }}>
            <div style={{
              width: 40, height: 40, borderRadius: 12,
              background: 'rgba(255,255,255,0.22)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
              fontSize: 20,
            }}>👕</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 800, marginBottom: 2 }}>
                服装写真をシェア
              </div>
              <div style={{ fontSize: 10.5, opacity: 0.92, lineHeight: 1.4 }}>
                合流時にお互いを見つけやすく
              </div>
            </div>
          </div>

          {/* status row */}
          <div style={{
            display: 'flex', gap: 6, marginBottom: 10,
            position: 'relative',
          }}>
            <div style={{
              flex: 1, padding: '6px 10px', borderRadius: 8,
              background: 'rgba(255,255,255,0.18)',
              fontSize: 10, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            }}>
              <span>あなた</span>
              <span style={{ opacity: 0.9 }}>未シェア</span>
            </div>
            <div style={{
              flex: 1, padding: '6px 10px', borderRadius: 8,
              background: 'rgba(255,255,255,0.32)',
              fontSize: 10, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            }}>
              <span>{partnerOutfitShared ? '@lumi_sua' : '相手'}</span>
              <span>{partnerOutfitShared ? '✓ 共有済' : '未シェア'}</span>
            </div>
          </div>

          <button style={{
            width: '100%', padding: '11px',
            background: '#fff', color: c.lavender,
            border: 0, borderRadius: 12,
            fontFamily: 'inherit', fontSize: 13.5, fontWeight: 800,
            letterSpacing: 0.3, position: 'relative',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6,
            boxShadow: '0 2px 6px rgba(0,0,0,0.08)',
            cursor: 'pointer',
          }}>
            <svg width="14" height="14" viewBox="0 0 14 14">
              <rect x="1.5" y="3.5" width="11" height="8" rx="1.5" stroke={c.lavender} strokeWidth="1.5" fill="none"/>
              <circle cx="7" cy="7.5" r="2.2" stroke={c.lavender} strokeWidth="1.5" fill="none"/>
            </svg>
            服装写真を撮影してシェア
          </button>
        </div>
      )}

      {/* Messages */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '8px 16px 100px', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {/* Day separator */}
        <div style={{
          alignSelf: 'center', fontSize: 10, color: c.mute,
          background: c.subtle, padding: '3px 10px', borderRadius: 999,
        }}>5/3 (土) · 13:08</div>

        <Bubble side="them" colors={c}>合意ありがとうございます！当日よろしくお願いします 🙏</Bubble>
        <Bubble side="me" colors={c}>こちらこそ！会場では西4ゲート前あたりが分かりやすそうです</Bubble>
        <Bubble side="them" colors={c}>了解です◎ 13:30くらいに会場入りしますね</Bubble>

        {/* 服装写真メッセージ（相手から） */}
        <div style={{
          alignSelf: 'flex-start', maxWidth: '78%',
          background: '#fff', borderRadius: '14px 14px 14px 4px',
          padding: 4, border: `0.5px solid ${c.subtle}`,
          boxShadow: '0 1px 3px rgba(58,50,74,0.06)',
        }}>
          <div style={{
            width: 180, height: 200, borderRadius: 12, overflow: 'hidden',
            position: 'relative',
            background: `linear-gradient(160deg, ${c.pink}55, ${c.lavender}55, ${c.sky}33)`,
          }}>
            {/* fake outfit silhouette */}
            <svg width="100%" height="100%" viewBox="0 0 180 200" preserveAspectRatio="xMidYMid meet">
              <rect width="180" height="200" fill={`hsl(280, 30%, 75%)`} fillOpacity="0.3"/>
              {/* head */}
              <circle cx="90" cy="55" r="22" fill="rgba(58,50,74,0.5)" />
              {/* body — purple long T */}
              <path d="M55 90 L60 75 L80 70 L100 70 L120 75 L125 90 L128 180 L52 180 Z" fill={`${c.lavender}cc`} />
              {/* tote bag */}
              <rect x="115" y="100" width="30" height="40" rx="3" fill="rgba(255,255,255,0.7)" stroke="rgba(58,50,74,0.3)" strokeWidth="1"/>
              <path d="M120 100 L120 92 Q120 88 124 88 L136 88 Q140 88 140 92 L140 100" stroke="rgba(58,50,74,0.4)" strokeWidth="1.5" fill="none" />
            </svg>
            <div style={{
              position: 'absolute', left: 8, bottom: 8,
              background: 'rgba(0,0,0,0.55)', color: '#fff',
              fontSize: 9.5, fontWeight: 700, padding: '3px 8px', borderRadius: 6,
              backdropFilter: 'blur(8px)',
            }}>👕 服装写真</div>
          </div>
          <div style={{ padding: '6px 8px 4px', fontSize: 10.5, color: c.mute }}>
            紫ロンT＋トートバッグ
          </div>
        </div>

        <Bubble side="them" colors={c}>こんな感じです！紫のロンTです 🎀</Bubble>

        {/* 現在地共有メッセージ（自分から） */}
        <div style={{
          alignSelf: 'flex-end', maxWidth: '78%',
          background: '#fff', borderRadius: '14px 14px 4px 14px',
          padding: 4, border: `0.5px solid ${c.lavender}40`,
          boxShadow: `0 2px 6px ${c.lavender}22`,
          overflow: 'hidden',
        }}>
          <div style={{ position: 'relative' }}>
            <CF_MiniMap c={c}
              height={120}
              you={{ x: 60, y: 30 }}
              partner={{ x: 200, y: 60 }}
              label="あなた → 待ち合わせまで 約450m" />
          </div>
          <div style={{ padding: '8px 10px 4px' }}>
            <div style={{ fontSize: 11, fontWeight: 700, color: c.ink, marginBottom: 2 }}>
              📍 現在地を共有
            </div>
            <div style={{ fontSize: 9.5, color: c.mute, fontVariantNumeric: 'tabular-nums' }}>
              ナゴヤドーム前矢田駅 1番出口付近<br/>
              13:42 時点
            </div>
          </div>
        </div>

        <Bubble side="me" colors={c}>もう駅着きました！あと5分くらいで合流地点に着きそうです</Bubble>

        {/* 相手の到着システムメッセージ */}
        <div style={{
          alignSelf: 'center', display: 'flex', alignItems: 'center', gap: 6,
          padding: '6px 12px', borderRadius: 999,
          background: '#22c55e22', color: '#15803d',
          fontSize: 10.5, fontWeight: 700,
        }}>
          <span style={{ width: 6, height: 6, borderRadius: '50%', background: '#22c55e' }} />
          @lumi_sua が会場に到着しました · 13:45
        </div>

        <Bubble side="them" colors={c}>着きました！西4ゲート前で待ってます！</Bubble>

        {/* Pending evidence chip — 合流したら証跡撮影 */}
        <div style={{
          alignSelf: 'center', width: '100%',
          background: '#fff', borderRadius: 14, padding: '10px 12px',
          border: `1px dashed ${c.lavender}66`,
          display: 'flex', alignItems: 'center', gap: 10, marginTop: 4,
        }}>
          <div style={{
            width: 32, height: 32, borderRadius: 10,
            background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="14" height="14" viewBox="0 0 14 14">
              <rect x="1.5" y="3.5" width="11" height="8" rx="1.5" stroke="#fff" strokeWidth="1.4" fill="none"/>
              <circle cx="7" cy="7.5" r="2" stroke="#fff" strokeWidth="1.4" fill="none"/>
            </svg>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12, fontWeight: 700, color: c.ink }}>合流したら証跡を撮影</div>
            <div style={{ fontSize: 10, color: c.mute, marginTop: 1 }}>両者の交換物を1枚に収めます</div>
          </div>
          <button style={{
            padding: '7px 12px', borderRadius: 10,
            background: c.lavender, color: '#fff', border: 0,
            fontFamily: 'inherit', fontSize: 11.5, fontWeight: 700,
          }}>撮影へ</button>
        </div>
      </div>

      {/* Composer + quick actions */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        background: 'rgba(255,255,255,0.96)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `0.5px solid ${c.lavender}22`,
        paddingBottom: 30,
      }}>
        {/* Quick actions row（現在地・服装を即送信できるように） */}
        <div style={{
          display: 'flex', gap: 6, padding: '8px 12px 6px',
          alignItems: 'center', overflowX: 'auto', WebkitOverflowScrolling: 'touch',
        }}>
          <button style={{
            display: 'inline-flex', alignItems: 'center', gap: 5,
            padding: '6px 11px', borderRadius: 999,
            background: `${c.lavender}14`, color: c.lavender,
            border: `0.5px solid ${c.lavender}44`,
            fontFamily: 'inherit', fontSize: 11.5, fontWeight: 700,
            cursor: 'pointer', flexShrink: 0,
          }}>
            <svg width="11" height="11" viewBox="0 0 12 12">
              <path d="M6 1C3.5 1 1.5 3 1.5 5.5c0 3 4.5 6 4.5 6s4.5-3 4.5-6C10.5 3 8.5 1 6 1z" stroke={c.lavender} strokeWidth="1.3" fill="none"/>
              <circle cx="6" cy="5.5" r="1.6" fill={c.lavender}/>
            </svg>
            現在地を送る
          </button>
          <button style={{
            display: 'inline-flex', alignItems: 'center', gap: 5,
            padding: '6px 11px', borderRadius: 999,
            background: `${c.pink}1a`, color: c.ink,
            border: `0.5px solid ${c.pink}55`,
            fontFamily: 'inherit', fontSize: 11.5, fontWeight: 700,
            cursor: 'pointer', flexShrink: 0,
          }}>
            <span style={{ fontSize: 12 }}>👕</span>
            服装写真
          </button>
          <button style={{
            display: 'inline-flex', alignItems: 'center', gap: 5,
            padding: '6px 11px', borderRadius: 999,
            background: c.subtle, color: c.ink,
            border: `0.5px solid ${c.subtle}`,
            fontFamily: 'inherit', fontSize: 11.5, fontWeight: 700,
            cursor: 'pointer', flexShrink: 0,
          }}>
            <svg width="11" height="11" viewBox="0 0 12 12">
              <rect x="1.5" y="2.5" width="9" height="7" rx="1" stroke={c.ink} strokeWidth="1.2" fill="none"/>
              <circle cx="6" cy="6" r="2" stroke={c.ink} strokeWidth="1.2" fill="none"/>
            </svg>
            写真添付
          </button>
        </div>

        {/* Composer row */}
        <div style={{
          padding: '0 12px 4px',
          display: 'flex', alignItems: 'center', gap: 8,
        }}>
          <button style={{
            width: 36, height: 36, borderRadius: '50%',
            background: c.subtle, border: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="14" height="14" viewBox="0 0 14 14"><path d="M7 1v12M1 7h12" stroke={c.ink} strokeWidth="1.6" strokeLinecap="round"/></svg>
          </button>
          <div style={{
            flex: 1, height: 36, borderRadius: 18,
            background: '#fff', border: `0.5px solid ${c.subtle}`,
            padding: '0 14px', display: 'flex', alignItems: 'center',
            fontSize: 13, color: c.mute,
          }}>メッセージ…</div>
          <button style={{
            width: 36, height: 36, borderRadius: '50%',
            background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
            border: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="14" height="14" viewBox="0 0 14 14"><path d="M2 12L13 7 2 2v4l7 1-7 1z" fill="#fff"/></svg>
          </button>
        </div>
      </div>
    </div>
  );
}

function Bubble({ side, children, colors }) {
  const isMe = side === 'me';
  return (
    <div style={{
      alignSelf: isMe ? 'flex-end' : 'flex-start',
      maxWidth: '78%',
      background: isMe ? `linear-gradient(135deg, ${colors.lavender}, ${colors.sky})` : '#fff',
      color: isMe ? '#fff' : colors.ink,
      padding: '9px 13px', borderRadius: 16,
      borderTopRightRadius: isMe ? 4 : 16,
      borderTopLeftRadius: isMe ? 16 : 4,
      fontSize: 13, lineHeight: 1.5,
      boxShadow: isMe ? `0 3px 8px ${colors.lavender}30` : '0 1px 3px rgba(58,50,74,0.06)',
      border: isMe ? 0 : `0.5px solid ${colors.subtle}`,
    }}>{children}</div>
  );
}

// ─────────────────────────────────────────────────────────────
// C-3. Complete flow — evidence photo + dual approve + rating
// ─────────────────────────────────────────────────────────────
function CompleteScreen({ tweaks, step = 'capture' }) {
  const c = COLORS(tweaks);

  if (step === 'capture') return <CaptureStep colors={c} />;
  if (step === 'approve') return <ApproveStep colors={c} />;
  if (step === 'rate' || step === 'done') return <RateStep colors={c} />;
  return null;
}

function CaptureStep({ colors: c }) {
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: '#0a0810', overflow: 'hidden',
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: '#fff', fontFeatureSettings: '"palt"',
    }}>
      {/* viewfinder bg */}
      <div style={{
        position: 'absolute', inset: 0,
        background: `radial-gradient(circle at 50% 55%, ${c.lavender}20, transparent 60%), repeating-linear-gradient(135deg, #1a1525 0 6px, #221a30 6px 12px)`,
      }} />

      {/* status header */}
      <div style={{
        position: 'absolute', top: 50, left: 0, right: 0, padding: '0 18px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        zIndex: 5,
      }}>
        <button style={{
          width: 36, height: 36, borderRadius: '50%',
          background: 'rgba(255,255,255,0.12)', border: 0,
          backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
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
          <span style={{
            width: 6, height: 6, borderRadius: '50%', background: '#e0a847',
          }} />
          オフライン保存
        </div>
        <div style={{ width: 36 }} />
      </div>

      {/* Title */}
      <div style={{
        position: 'absolute', top: 100, left: 0, right: 0,
        textAlign: 'center', zIndex: 5,
      }}>
        <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: 0.4 }}>取引証跡を撮影</div>
        <div style={{ fontSize: 11.5, color: 'rgba(255,255,255,0.7)', marginTop: 4 }}>
          両者の交換物を1枚に収めてください
        </div>
      </div>

      {/* Viewfinder split frame */}
      <div style={{
        position: 'absolute', top: 170, left: 30, right: 30, bottom: 220,
        borderRadius: 18,
        border: `2px solid ${c.lavender}`,
        boxShadow: `0 0 0 1px ${c.lavender}55, 0 0 60px ${c.lavender}40`,
        display: 'flex', overflow: 'hidden',
      }}>
        {/* left: their items */}
        <div style={{
          flex: 1, position: 'relative',
          background: `linear-gradient(160deg, ${c.lavender}25, ${c.lavender}10)`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexDirection: 'column', gap: 8,
        }}>
          <div style={{ display: 'flex', gap: 6 }}>
            {[0, 1, 2].map((i) => (
              <div key={i} style={{
                width: 38, height: 54, borderRadius: 5,
                background: 'rgba(255,255,255,0.85)',
                transform: `rotate(${(i - 1) * 4}deg)`,
                boxShadow: '0 4px 12px rgba(0,0,0,0.4)',
                display: 'flex', alignItems: 'flex-end', justifyContent: 'center',
                paddingBottom: 4,
                fontSize: 9, fontFamily: 'ui-monospace, monospace', color: 'rgba(0,0,0,0.55)',
                fontWeight: 700,
              }}>ス</div>
            ))}
          </div>
          <div style={{
            padding: '3px 8px', borderRadius: 999,
            background: 'rgba(0,0,0,0.5)',
            fontSize: 9.5, fontWeight: 700, letterSpacing: 0.4,
          }}>相手の3点</div>
        </div>
        {/* divider */}
        <div style={{
          width: 0, position: 'relative',
          borderLeft: `1px dashed rgba(255,255,255,0.4)`,
        }}>
          <div style={{
            position: 'absolute', top: '50%', left: '50%',
            transform: 'translate(-50%, -50%)',
            width: 28, height: 28, borderRadius: '50%',
            background: '#fff', color: c.lavender,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 12, fontWeight: 800,
            boxShadow: `0 0 0 4px ${c.lavender}55`,
          }}>↔</div>
        </div>
        {/* right: my items */}
        <div style={{
          flex: 1, position: 'relative',
          background: `linear-gradient(200deg, ${c.pink}28, ${c.sky}20)`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexDirection: 'column', gap: 8,
        }}>
          <div style={{ display: 'flex', gap: 6 }}>
            {[0, 1].map((i) => (
              <div key={i} style={{
                width: 38, height: 54, borderRadius: 5,
                background: 'rgba(255,255,255,0.85)',
                transform: `rotate(${(i - 0.5) * 5}deg)`,
                boxShadow: '0 4px 12px rgba(0,0,0,0.4)',
                display: 'flex', alignItems: 'flex-end', justifyContent: 'center',
                paddingBottom: 4,
                fontSize: 9, fontFamily: 'ui-monospace, monospace', color: 'rgba(0,0,0,0.55)',
                fontWeight: 700,
              }}>ヒ</div>
            ))}
          </div>
          <div style={{
            padding: '3px 8px', borderRadius: 999,
            background: 'rgba(0,0,0,0.5)',
            fontSize: 9.5, fontWeight: 700, letterSpacing: 0.4,
          }}>あなたの2点</div>
        </div>

        {/* corner marks */}
        {[
          { top: -2, left: -2, br: '4px 0 0 0' },
          { top: -2, right: -2, br: '0 4px 0 0' },
          { bottom: -2, left: -2, br: '0 0 0 4px' },
          { bottom: -2, right: -2, br: '0 0 4px 0' },
        ].map((p, i) => (
          <div key={i} style={{
            position: 'absolute', ...p, width: 18, height: 18,
            borderColor: '#fff',
            borderStyle: 'solid',
            borderWidth: i === 0 ? '3px 0 0 3px' : i === 1 ? '3px 3px 0 0' : i === 2 ? '0 0 3px 3px' : '0 3px 3px 0',
            borderRadius: p.br,
          }} />
        ))}
      </div>

      {/* Hint chip */}
      <div style={{
        position: 'absolute', bottom: 200, left: 0, right: 0,
        textAlign: 'center', zIndex: 5,
      }}>
        <div style={{
          display: 'inline-flex', gap: 8, alignItems: 'center',
          padding: '7px 14px', borderRadius: 999,
          background: 'rgba(0,0,0,0.5)',
          backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)',
          fontSize: 11, fontWeight: 500,
        }}>
          <svg width="13" height="13" viewBox="0 0 13 13"><circle cx="6.5" cy="6.5" r="5" stroke="#fff" strokeWidth="1.2" fill="none"/><path d="M6.5 4v3M6.5 8.5v.5" stroke="#fff" strokeWidth="1.4" strokeLinecap="round"/></svg>
          自動メタ: 18:43 · 横浜アリーナ
        </div>
      </div>

      {/* Capture button */}
      <div style={{
        position: 'absolute', bottom: 60, left: 0, right: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'space-around',
        padding: '0 32px',
      }}>
        <button style={{
          width: 44, height: 44, borderRadius: '50%',
          background: 'rgba(255,255,255,0.14)', border: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="18" height="18" viewBox="0 0 18 18"><circle cx="9" cy="9" r="7" stroke="#fff" strokeWidth="1.5" fill="none"/><path d="M9 5v4l3 2" stroke="#fff" strokeWidth="1.5" strokeLinecap="round"/></svg>
        </button>
        <button style={{
          width: 76, height: 76, borderRadius: '50%',
          background: '#fff', border: `4px solid rgba(255,255,255,0.45)`,
          boxShadow: '0 8px 24px rgba(0,0,0,0.4)',
        }} />
        <button style={{
          width: 44, height: 44, borderRadius: '50%',
          background: 'rgba(255,255,255,0.14)', border: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="18" height="18" viewBox="0 0 18 18"><path d="M3 6h12M3 12h12" stroke="#fff" strokeWidth="1.5" strokeLinecap="round"/></svg>
        </button>
      </div>
    </div>
  );
}

function ApproveStep({ colors: c }) {
  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, fontFeatureSettings: '"palt"',
    }}>
      <div style={{ height: 60 }} />

      <div style={{
        padding: '8px 14px',
        borderBottom: `0.5px solid ${c.subtle}`,
        background: '#fff',
        textAlign: 'center', position: 'relative',
      }}>
        <div style={{ fontSize: 14.5, fontWeight: 700 }}>取引完了の確認</div>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '18px 18px 110px' }}>
        {/* Captured photo */}
        <div style={{
          borderRadius: 18, overflow: 'hidden', position: 'relative',
          aspectRatio: '4 / 3',
          background: `repeating-linear-gradient(135deg, ${c.lavender}28 0 8px, ${c.sky}28 8px 14px)`,
          boxShadow: `0 8px 24px rgba(58,50,74,0.15)`,
        }}>
          {/* split items mock */}
          <div style={{
            position: 'absolute', top: '50%', left: '25%', transform: 'translate(-50%, -50%)',
            display: 'flex', gap: 4,
          }}>
            {[0, 1, 2].map((i) => (
              <div key={i} style={{
                width: 32, height: 46, borderRadius: 4,
                background: '#fff', transform: `rotate(${(i - 1) * 5}deg)`,
                boxShadow: '0 4px 8px rgba(0,0,0,0.2)',
              }} />
            ))}
          </div>
          <div style={{
            position: 'absolute', top: '50%', left: '75%', transform: 'translate(-50%, -50%)',
            display: 'flex', gap: 4,
          }}>
            {[0, 1].map((i) => (
              <div key={i} style={{
                width: 32, height: 46, borderRadius: 4,
                background: '#fff', transform: `rotate(${(i - 0.5) * 6}deg)`,
                boxShadow: '0 4px 8px rgba(0,0,0,0.2)',
              }} />
            ))}
          </div>
          {/* meta strip */}
          <div style={{
            position: 'absolute', bottom: 8, left: 8, right: 8,
            background: 'rgba(0,0,0,0.55)', color: '#fff',
            backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)',
            padding: '7px 12px', borderRadius: 10,
            display: 'flex', justifyContent: 'space-between',
            fontSize: 10.5, fontVariantNumeric: 'tabular-nums',
          }}>
            <span>2026-04-27 18:43</span>
            <span>横浜アリーナ · 西ゲート</span>
          </div>
        </div>

        {/* Items */}
        <div style={{
          marginTop: 14,
          background: '#fff', borderRadius: 16,
          border: `0.5px solid ${c.subtle}`,
          overflow: 'hidden',
        }}>
          <Row colors={c} side="them" handle="lumi_sua" desc="スア トレカ ×3" tcg={['ス', 'ス', 'ス']} />
          <div style={{ height: 0.5, background: c.subtle }} />
          <Row colors={c} side="me" handle="あなた" desc="ヒナ 生写真 ×2" tcg={['ヒ', 'ヒ']} />
        </div>

        {/* Approval status */}
        <div style={{
          marginTop: 14,
          background: '#fff', borderRadius: 16, padding: 14,
          border: `0.5px solid ${c.subtle}`,
        }}>
          <div style={{
            fontSize: 11, color: c.mute, fontWeight: 700, letterSpacing: 0.5,
            marginBottom: 10, textTransform: 'uppercase',
          }}>両者の確認</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
            <div style={{
              width: 28, height: 28, borderRadius: '50%',
              background: '#22c55e',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <svg width="14" height="14" viewBox="0 0 14 14"><path d="M3 7l3 3 5-6" stroke="#fff" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 12.5, fontWeight: 600 }}>@lumi_sua が承認</div>
              <div style={{ fontSize: 10.5, color: c.mute }}>18:44</div>
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{
              width: 28, height: 28, borderRadius: '50%',
              background: c.subtle, border: `1.5px dashed ${c.lavender}88`,
            }} />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 12.5, fontWeight: 600 }}>あなたの承認待ち</div>
              <div style={{ fontSize: 10.5, color: c.mute }}>内容を確認してください</div>
            </div>
          </div>
        </div>

        {/* Trouble note */}
        <div style={{
          marginTop: 12, padding: '10px 12px',
          fontSize: 11, color: c.mute,
          background: c.subtle, borderRadius: 10,
          lineHeight: 1.5,
        }}>
          内容に問題がある場合は「相違あり」を選び、後でサポートに通報できます。
        </div>
      </div>

      {/* Sticky CTA */}
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
        }}>相違あり</button>
        <button style={{
          flex: 1, height: 48, borderRadius: 14,
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 15, fontWeight: 700, letterSpacing: 0.4,
          boxShadow: `0 6px 16px ${c.lavender}50`,
        }}>承認して完了</button>
      </div>
    </div>
  );
}

function Row({ colors: c, side, handle, desc, tcg }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 11, padding: '12px 14px',
    }}>
      <div style={{
        width: 30, height: 30, borderRadius: '50%',
        background: side === 'me' ? `${c.pink}55` : `${c.sky}55`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 11, fontWeight: 700,
      }}>{side === 'me' ? '私' : '相'}</div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 12, fontWeight: 600 }}>@{handle}</div>
        <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>{desc}</div>
      </div>
      <div style={{ display: 'flex', gap: 3 }}>
        {tcg.map((label, i) => (
          <Tcg key={i} w={18} h={26} hue={(i * 60 + 260) % 360} label={label}
               accent={side === 'me' ? `${c.pink}cc` : undefined} />
        ))}
      </div>
    </div>
  );
}

function RateStep({ colors: c }) {
  const [stars, setStars] = React.useState(5);
  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, fontFeatureSettings: '"palt"',
    }}>
      <div style={{ height: 60 }} />

      {/* celebrate header */}
      <div style={{
        padding: '20px 18px 16px', textAlign: 'center',
        background: `linear-gradient(180deg, ${c.lavender}22, transparent)`,
      }}>
        <div style={{
          width: 64, height: 64, borderRadius: '50%',
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          margin: '0 auto 12px',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 8px 20px ${c.lavender}50`,
        }}>
          <svg width="28" height="28" viewBox="0 0 28 28"><path d="M6 14l5 5 11-12" stroke="#fff" strokeWidth="3" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </div>
        <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: 0.4 }}>取引完了！</div>
        <div style={{ fontSize: 12, color: c.mute, marginTop: 4 }}>
          @lumi_sua との交換が記録されました
        </div>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '0 18px 110px' }}>
        {/* Rating */}
        <div style={{
          background: '#fff', borderRadius: 16, padding: 16,
          border: `0.5px solid ${c.subtle}`,
        }}>
          <div style={{
            fontSize: 13, fontWeight: 700, marginBottom: 12, textAlign: 'center',
          }}>取引相手を評価</div>
          <div style={{ display: 'flex', justifyContent: 'center', gap: 6, marginBottom: 12 }}>
            {[1, 2, 3, 4, 5].map((n) => (
              <button key={n} onClick={() => setStars(n)} style={{
                width: 36, height: 36, background: 'transparent', border: 0,
                cursor: 'pointer', padding: 0,
              }}>
                <svg width="32" height="32" viewBox="0 0 32 32">
                  <path d="M16 3l4 8.4 9.2 1.4-6.6 6.4 1.6 9-8.2-4.4-8.2 4.4 1.6-9L2.8 12.8 12 11.4z"
                        fill={n <= stars ? c.lavender : c.subtle} />
                </svg>
              </button>
            ))}
          </div>
          <textarea placeholder="コメント（任意）— 親切でした、合流もスムーズでした、など" style={{
            width: '100%', boxSizing: 'border-box',
            minHeight: 70, padding: 12, borderRadius: 12,
            border: `0.5px solid ${c.subtle}`, background: c.bg,
            fontSize: 12.5, color: c.ink, resize: 'none',
            fontFamily: 'inherit', lineHeight: 1.5, outline: 'none',
          }} />
        </div>

        {/* Collection update */}
        <div style={{
          marginTop: 14, padding: 14,
          background: `linear-gradient(120deg, ${c.pink}26, ${c.sky}26)`,
          border: `0.5px solid ${c.pink}55`,
          borderRadius: 16,
        }}>
          <div style={{
            fontSize: 11, fontWeight: 700, color: c.lavender,
            letterSpacing: 0.5, marginBottom: 8,
          }}>◆ あなたのコレクション更新（wish基準）</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ display: 'flex', gap: -3 }}>
              {[0, 1, 2].map((i) => (
                <Tcg key={i} w={26} h={36} hue={280 + i * 10} label="ス" />
              ))}
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 700 }}>スアの wish 進捗</div>
              <div style={{ fontSize: 11, color: c.mute, marginTop: 2 }}>
                3 / 4 取得 — あと <b style={{ color: c.lavender }}>1枚</b> で
                <b style={{ color: c.lavender }}>スアコレ コンプ</b>
              </div>
              {/* progress bar */}
              <div style={{
                height: 4, borderRadius: 2, marginTop: 6,
                background: c.subtle, overflow: 'hidden',
              }}>
                <div style={{
                  width: '75%', height: '100%',
                  background: `linear-gradient(90deg, ${c.lavender}, ${c.sky})`,
                  borderRadius: 2,
                }} />
              </div>
            </div>
          </div>
        </div>

        {/* X share */}
        <div style={{
          marginTop: 12, padding: 14,
          background: '#fff', borderRadius: 16,
          border: `0.5px solid ${c.subtle}`,
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: 10,
            background: '#000',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: '#fff', fontWeight: 800, fontFamily: '"Inter Tight", sans-serif',
          }}>X</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12.5, fontWeight: 700 }}>Xで報告ポストを作成</div>
            <div style={{ fontSize: 10.5, color: c.mute, marginTop: 2 }}>
              交換完了の御礼テキスト＋画像を自動生成
            </div>
          </div>
          <button style={{
            padding: '7px 12px', borderRadius: 10,
            background: c.subtle, color: c.ink, border: 0,
            fontFamily: 'inherit', fontSize: 11.5, fontWeight: 700,
          }}>作成</button>
        </div>
      </div>

      {/* Sticky CTA */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '12px 18px 30px',
        background: 'rgba(255,255,255,0.92)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `0.5px solid ${c.lavender}22`,
      }}>
        <button style={{
          width: '100%', height: 48, borderRadius: 14,
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 15, fontWeight: 700, letterSpacing: 0.4,
          boxShadow: `0 6px 16px ${c.lavender}50`,
        }}>評価を送信</button>
      </div>
    </div>
  );
}

Object.assign(window, { ProposeScreen, ChatScreen, CompleteScreen });

// __MVP_EXPORTS__
Object.assign(window, { ProposeScreen, ChatScreen, CompleteScreen });
