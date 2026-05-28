// ─────────────────────────────────────────────────────────────
// nego-flow.jsx — 受諾前ネゴシエーションフロー
// C-1受信（打診受信画面）/ C-1.5 ネゴチャット / 相手の譲モーダル
// 期限：7日（リマインド3日目・6日目、期限切れ自動クローズ・延長可）
// ─────────────────────────────────────────────────────────────

const NF_C = (t) => ({
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

// 簡易マップ（俯瞰図 + 中央ピン）— 待ち合わせ場所表示用
const NF_MiniMap = ({ c, height = 90, label, accent }) => {
  const pin = accent || c.lavender;
  return (
    <div style={{
      height, borderRadius: 10, overflow: 'hidden', position: 'relative',
      border: `0.5px solid ${c.divide}`, background: '#e8eef0',
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
        <g transform="translate(143, 45)">
          <circle cx="0" cy="0" r="20" fill={pin} fillOpacity="0.16" />
          <circle cx="0" cy="0" r="13" fill={pin} fillOpacity="0.32" />
          <path d="M0 -12 C-6 -12 -10 -8 -10 -2 C-10 5 0 12 0 12 C0 12 10 5 10 -2 C10 -8 6 -12 0 -12 Z"
                fill={pin} stroke="#fff" strokeWidth="1.4" />
          <circle cx="0" cy="-3" r="3" fill="#fff" />
        </g>
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

// ──────────────────────────────
// 1. C-1受信 — 打診を受け取った側の画面
// ──────────────────────────────
function C1ReceiveScreen({ tweaks, daysLeft = 6 }) {
  const c = NF_C(tweaks);
  const sender = { handle: '@hana_lumi', star: 4.9, trades: 89, dist: '169m' };
  const proposalIn = [
    { name: 'ヒナ 5th Mini 生写真', qty: 2, hue: 200 },
  ];
  const proposalOut = [
    { name: 'スア WT01 トレカ', qty: 3, hue: 280 },
  ];
  // 提案された待ち合わせ
  const meetup = {
    type: 'scheduled', // 'now' | 'scheduled'
    date: '5/3 (土)',
    time: '14:00〜18:00',
    place: 'TWICE 名古屋ドーム公演',
    area: 'ナゴヤドーム前矢田駅 周辺',
    fromAW: true, // 相手のAWから選択 + 自分のAWとも一致
    matchAW: true,
  };

  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      {/* Header */}
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
            <div style={{ fontSize: 15, fontWeight: 700, color: c.ink }}>打診が届きました</div>
            <div style={{ fontSize: 11, color: c.mute, marginTop: 1 }}>残り {daysLeft}日 ・ 7日後に自動終了</div>
          </div>
        </div>
      </div>

      <div style={{ padding: '20px 18px 0' }}>
        {/* Sender card */}
        <div style={{
          padding: '14px 16px', borderRadius: 14,
          background: '#fff', border: `0.5px solid ${c.divide}`,
          marginBottom: 14, display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <div style={{
            width: 44, height: 44, borderRadius: 22,
            background: `linear-gradient(135deg, ${c.pink}55, ${c.lavender}55)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 14, fontWeight: 800, color: c.ink,
          }}>H</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14, fontWeight: 800 }}>{sender.handle}</div>
            <div style={{ fontSize: 11, color: c.mute, marginTop: 1 }}>
              ★{sender.star} ・ 取引{sender.trades} ・ {sender.dist}
            </div>
          </div>
          <button style={{
            padding: '6px 12px', borderRadius: 10,
            background: '#fff', color: c.lavender,
            border: `1px solid ${c.lavender}55`,
            fontFamily: 'inherit', fontSize: 11, fontWeight: 700,
          }}>プロフ</button>
        </div>

        {/* Proposal contents */}
        <div style={{
          padding: 16, borderRadius: 14,
          background: `linear-gradient(135deg, ${c.lavender}1a, ${c.sky}1a)`,
          border: `1.5px solid ${c.lavender}40`,
          marginBottom: 14,
        }}>
          <div style={{
            fontSize: 9.5, fontWeight: 800, color: c.lavender,
            letterSpacing: 0.5, marginBottom: 10,
          }}>📩 提案内容</div>

          <div style={{ marginBottom: 12 }}>
            <div style={{ fontSize: 11, color: c.mute, fontWeight: 700, marginBottom: 5 }}>あなたが受け取る</div>
            {proposalOut.map((it, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '4px 0' }}>
                <div style={{
                  width: 28, height: 38, borderRadius: 5,
                  background: `repeating-linear-gradient(135deg, hsl(${it.hue}, 35%, 78%) 0 5px, hsl(${it.hue}, 35%, 70%) 5px 10px)`,
                  flexShrink: 0,
                }} />
                <span style={{ flex: 1, fontSize: 13, fontWeight: 700 }}>{it.name}</span>
                <span style={{ fontSize: 13, fontWeight: 800, color: c.lavender, fontVariantNumeric: 'tabular-nums' }}>×{it.qty}</span>
              </div>
            ))}
          </div>

          <div style={{
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            margin: '4px 0', color: c.lavender,
          }}>
            <svg width="22" height="22" viewBox="0 0 22 22">
              <path d="M5 8h12M14 4l4 4-4 4M17 14H5M8 18l-4-4 4-4" stroke={c.lavender} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>

          <div>
            <div style={{ fontSize: 11, color: c.mute, fontWeight: 700, marginBottom: 5 }}>あなたが出す</div>
            {proposalIn.map((it, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '4px 0' }}>
                <div style={{
                  width: 28, height: 38, borderRadius: 5,
                  background: `repeating-linear-gradient(135deg, hsl(${it.hue}, 35%, 78%) 0 5px, hsl(${it.hue}, 35%, 70%) 5px 10px)`,
                  flexShrink: 0,
                }} />
                <span style={{ flex: 1, fontSize: 13, fontWeight: 700 }}>{it.name}</span>
                <span style={{ fontSize: 13, fontWeight: 800, color: c.lavender, fontVariantNumeric: 'tabular-nums' }}>×{it.qty}</span>
              </div>
            ))}
          </div>

          {/* 待ち合わせ（提案の一部） */}
          <div style={{
            marginTop: 12, padding: 12,
            borderRadius: 10, background: 'rgba(255,255,255,0.7)',
            border: `0.5px solid ${c.lavender}33`,
          }}>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 6, marginBottom: 8,
              flexWrap: 'wrap',
            }}>
              <span style={{
                fontSize: 9.5, fontWeight: 800, color: c.lavender,
                background: '#fff', padding: '2px 7px', borderRadius: 999,
                letterSpacing: 0.4,
              }}>📍 待ち合わせ</span>
              {meetup.matchAW && (
                <span style={{
                  fontSize: 9, fontWeight: 800, color: '#fff',
                  background: `linear-gradient(135deg, ${c.lavender}, ${c.pink})`,
                  padding: '2px 7px', borderRadius: 999, letterSpacing: 0.3,
                }}>★ あなたのAWと一致</span>
              )}
            </div>
            <div style={{
              fontSize: 14, fontWeight: 800, color: c.ink, marginBottom: 2,
              fontVariantNumeric: 'tabular-nums',
            }}>{meetup.date} {meetup.time}</div>
            <div style={{ fontSize: 12, fontWeight: 700, color: c.ink, marginBottom: 2 }}>
              {meetup.place}
            </div>
            <div style={{ fontSize: 10.5, color: c.mute, marginBottom: 8 }}>
              📍 {meetup.area}
            </div>
            <NF_MiniMap c={c} height={86} label={meetup.area.split(' ')[0]} />
          </div>
        </div>

        {/* Message */}
        <div style={{
          padding: '12px 14px', borderRadius: 12,
          background: '#fff', border: `0.5px solid ${c.divide}`,
          marginBottom: 14,
        }}>
          <div style={{ fontSize: 11, color: c.mute, fontWeight: 700, marginBottom: 6 }}>メッセージ</div>
          <div style={{ fontSize: 12.5, color: c.ink, lineHeight: 1.7 }}>
            はじめまして！スアトレカに興味があります。<br/>
            お互いの希望が完全一致してて、AWも被ってるので嬉しいです◎<br/>
            当日よろしくお願いします 🙏
          </div>
        </div>

        {/* Auto-attached info（待ち合わせは提案に含まれるため、それ以外） */}
        <div style={{
          padding: '12px 14px', borderRadius: 12,
          background: '#fff', border: `0.5px solid ${c.divide}`,
          marginBottom: 18,
        }}>
          <div style={{ fontSize: 11, color: c.mute, fontWeight: 700, marginBottom: 8 }}>自動添付情報</div>
          {[
            { l: '相手の服装写真', v: '直前撮影で更新', tag: null },
            { l: '評価サマリ', v: '★4.9 ・ 取引89回', tag: null },
            { l: '直近トラブル', v: 'なし', tag: '@Megrum' },
          ].map((it, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 8,
              fontSize: 11.5, padding: '5px 0',
              borderBottom: i < 2 ? `0.5px solid ${c.divide}` : 'none',
            }}>
              <span style={{ color: c.mute, width: 110, flexShrink: 0 }}>{it.l}</span>
              <span style={{ flex: 1, fontWeight: 700 }}>{it.v}</span>
              {it.tag && (
                <span style={{
                  fontSize: 9, fontWeight: 800, color: c.lavender,
                  background: `${c.lavender}14`, padding: '2px 7px', borderRadius: 999,
                }}>{it.tag}</span>
              )}
            </div>
          ))}
        </div>

        {/* Action buttons */}
        <button style={{
          width: '100%', padding: '15px',
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', border: 0, borderRadius: 14,
          fontFamily: 'inherit', fontSize: 14, fontWeight: 700,
          letterSpacing: 0.3, marginBottom: 8,
          boxShadow: `0 4px 14px ${c.lavender}55`,
        }}>承諾する</button>

        <button style={{
          width: '100%', padding: '14px',
          background: '#fff', color: c.lavender,
          border: `1.5px solid ${c.lavender}`, borderRadius: 14,
          fontFamily: 'inherit', fontSize: 14, fontWeight: 700,
          letterSpacing: 0.3, marginBottom: 8,
        }}>反対提案する</button>

        <button style={{
          width: '100%', padding: '12px',
          background: 'transparent', color: c.mute,
          border: 0, borderRadius: 14,
          fontFamily: 'inherit', fontSize: 13, fontWeight: 600,
        }}>拒否する</button>
      </div>
    </div>
  );
}

// ──────────────────────────────
// 2. C-1.5 ネゴチャット
// ──────────────────────────────
function C15NegoChatScreen({ tweaks, scenario = 'normal' }) {
  const c = NF_C(tweaks);
  const partner = { handle: '@plum_92', star: 4.5, trades: 157 };

  // 現在の提案（変更されると更新される）
  const proposalIn = [
    { name: 'スア WT01 トレカ', qty: 3, hue: 280 },
  ];
  const proposalOut = [
    { name: 'ヒナ 5th Mini 生写真', qty: 1, hue: 200, changed: true }, // 変更箇所
    { name: 'スア STUDIO アクスタ', qty: 1, hue: 285, added: true }, // 追加箇所
  ];
  // 提案された待ち合わせ
  const meetup = {
    type: 'scheduled',
    date: '5/3 (土)',
    time: '14:00〜18:00',
    place: 'TWICE 名古屋ドーム公演',
    area: 'ナゴヤドーム前矢田駅 周辺',
  };

  // シナリオ別表示
  const isReminder3 = scenario === 'reminder3';
  const isReminder6 = scenario === 'reminder6';
  const isExpired = scenario === 'expired';
  const isMineAgreed = scenario === 'mine-agreed';

  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 130,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      {/* Header */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0,
        padding: '54px 18px 12px',
        background: 'rgba(255,255,255,0.94)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: `0.5px solid ${c.divide}`,
        zIndex: 10,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <svg width="10" height="16" viewBox="0 0 10 16" style={{ flex: '0 0 auto' }}>
            <path d="M8 1L2 8l6 7" stroke={c.ink} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          <div style={{
            width: 32, height: 32, borderRadius: 16,
            background: `linear-gradient(135deg, ${c.lavender}55, ${c.pink}55)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 12, fontWeight: 800, color: c.ink,
          }}>P</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14, fontWeight: 700 }}>{partner.handle}</div>
            <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>
              ★{partner.star} ・ 取引{partner.trades} ・ <span style={{
                color: isExpired ? c.warn : isMineAgreed ? c.ok : c.lavender, fontWeight: 700,
              }}>{isExpired ? '期限切れ' : isMineAgreed ? '相手の合意待ち' : 'ネゴ中'}</span>
            </div>
          </div>
        </div>
      </div>

      <div style={{ padding: '14px 18px 0' }}>
        {/* Current proposal summary card (always visible at top) */}
        <div style={{
          padding: 12, borderRadius: 12,
          background: '#fff',
          border: `1.5px solid ${c.lavender}55`,
          marginBottom: 14,
          boxShadow: `0 4px 12px ${c.lavender}1a`,
        }}>
          <div style={{
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            marginBottom: 8, gap: 8,
          }}>
            <div style={{
              fontSize: 9.5, fontWeight: 800, color: c.lavender, letterSpacing: 0.5,
              flex: 1, minWidth: 0,
            }}>📋 現在の提案（最終更新 5分前）</div>
            <button style={{
              padding: '3px 9px', borderRadius: 999,
              background: 'transparent', color: c.lavender,
              border: `1px solid ${c.lavender}55`,
              fontFamily: 'inherit', fontSize: 10, fontWeight: 700,
              cursor: 'pointer', flexShrink: 0,
              display: 'inline-flex', alignItems: 'center', gap: 3,
            }}>
              <svg width="9" height="9" viewBox="0 0 9 9" fill="none" stroke={c.lavender} strokeWidth="1.4">
                <path d="M1 7l1-3 5-5 2 2-5 5-3 1z"/>
              </svg>
              編集
            </button>
            <div style={{
              fontSize: 9, fontWeight: 800,
              color: isMineAgreed ? c.ok : c.warn,
              background: isMineAgreed ? `${c.ok}14` : `${c.warn}14`,
              padding: '2px 7px', borderRadius: 999, letterSpacing: 0.3,
              flexShrink: 0,
            }}>{isMineAgreed ? '✓ あなた合意済' : '未合意'}</div>
          </div>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 9, color: c.mute, fontWeight: 700, marginBottom: 4 }}>あなたが受け取る</div>
              {proposalIn.map((it, i) => (
                <div key={i} style={{ fontSize: 11.5, fontWeight: 700, marginBottom: 2 }}>
                  {it.name} <span style={{ color: c.lavender }}>×{it.qty}</span>
                </div>
              ))}
            </div>
            <svg width="18" height="18" viewBox="0 0 22 22" style={{ flexShrink: 0, marginTop: 16 }}>
              <path d="M5 8h12M14 4l4 4-4 4M17 14H5M8 18l-4-4 4-4" stroke={c.lavender} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            <div style={{ flex: 1, minWidth: 0, textAlign: 'right' }}>
              <div style={{ fontSize: 9, color: c.mute, fontWeight: 700, marginBottom: 4 }}>あなたが出す</div>
              {proposalOut.map((it, i) => (
                <div key={i} style={{
                  fontSize: 11.5, fontWeight: 700, marginBottom: 2,
                  display: 'inline-flex', alignItems: 'center', gap: 4,
                }}>
                  {it.added && <span style={{
                    fontSize: 8, fontWeight: 800, color: '#fff',
                    background: c.ok, padding: '1px 5px', borderRadius: 999,
                  }}>追加</span>}
                  {it.changed && <span style={{
                    fontSize: 8, fontWeight: 800, color: '#fff',
                    background: c.pink, padding: '1px 5px', borderRadius: 999,
                  }}>変更</span>}
                  {it.name} <span style={{ color: c.lavender }}>×{it.qty}</span>
                </div>
              )).reduce((acc, el, i) => {
                if (i > 0) acc.push(<br key={`br${i}`} />);
                acc.push(el);
                return acc;
              }, [])}
            </div>
          </div>

          {/* 待ち合わせ（提案の一部） */}
          <div style={{
            marginTop: 10, paddingTop: 10,
            borderTop: `0.5px dashed ${c.divide}`,
            display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <div style={{
              flex: '0 0 88px', height: 56,
            }}>
              <NF_MiniMap c={c} height={56} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{
                fontSize: 8.5, fontWeight: 800, color: c.lavender,
                letterSpacing: 0.4, marginBottom: 2,
              }}>📍 待ち合わせ</div>
              <div style={{
                fontSize: 12, fontWeight: 800, color: c.ink,
                fontVariantNumeric: 'tabular-nums', marginBottom: 1,
              }}>{meetup.date} {meetup.time}</div>
              <div style={{ fontSize: 10.5, color: c.mute, lineHeight: 1.4 }}>
                {meetup.place}
              </div>
              <div style={{ fontSize: 10, color: c.mute, lineHeight: 1.4 }}>
                📍 {meetup.area}
              </div>
            </div>
          </div>
        </div>

        {/* Reminders / expired notice */}
        {isReminder3 && (
          <div style={{
            padding: '10px 12px', borderRadius: 10,
            background: `${c.lavender}14`, border: `1px solid ${c.lavender}33`,
            fontSize: 11, color: c.ink, marginBottom: 12,
            display: 'flex', alignItems: 'flex-start', gap: 8,
          }}>
            <span style={{ fontSize: 14 }}>⏰</span>
            <div style={{ flex: 1, lineHeight: 1.5 }}>
              <b>提案から3日経過しました</b><br/>
              <span style={{ color: c.mute }}>残り 4日で自動終了。返信またはアクションを選択してください。</span>
            </div>
          </div>
        )}
        {isReminder6 && (
          <div style={{
            padding: '10px 12px', borderRadius: 10,
            background: `${c.warn}14`, border: `1px solid ${c.warn}55`,
            fontSize: 11, color: c.ink, marginBottom: 12,
            display: 'flex', alignItems: 'flex-start', gap: 8,
          }}>
            <span style={{ fontSize: 14 }}>⚠️</span>
            <div style={{ flex: 1, lineHeight: 1.5 }}>
              <b style={{ color: c.warn }}>明日でこの提案は自動終了します</b><br/>
              <span style={{ color: c.mute }}>残り 1日。期限延長することもできます。</span>
            </div>
          </div>
        )}
        {isExpired && (
          <div style={{
            padding: '12px 14px', borderRadius: 10,
            background: c.subtle, border: `1px solid ${c.divide}`,
            fontSize: 11.5, color: c.ink, marginBottom: 12,
            display: 'flex', alignItems: 'flex-start', gap: 8,
          }}>
            <span style={{ fontSize: 14 }}>⏱</span>
            <div style={{ flex: 1, lineHeight: 1.6 }}>
              <b>このネゴは期限切れで終了しました</b><br/>
              <span style={{ color: c.mute }}>引き続き取引したい場合は新しく打診を送ってください。</span>
            </div>
          </div>
        )}

        {/* Chat messages */}
        <div style={{
          fontSize: 10, color: c.mute, textAlign: 'center', padding: '8px 0',
        }}>5/12 火 14:23</div>

        {/* Bot message: 提案を修正しました */}
        <div style={{
          margin: '8px 0', padding: '10px 12px',
          background: '#fff', borderRadius: 12,
          border: `0.5px dashed ${c.lavender}55`,
          fontSize: 11, color: c.ink, lineHeight: 1.6,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6 }}>
            <span style={{
              fontSize: 9, fontWeight: 800, color: c.lavender,
              background: `${c.lavender}14`, padding: '2px 7px', borderRadius: 999, letterSpacing: 0.3,
            }}>システム</span>
            <span style={{ color: c.mute, fontSize: 10 }}>14:25</span>
          </div>
          <b>{partner.handle}</b> が提案を修正しました。<br/>
          ・ヒナ生写真 ×2 → ×1（数量変更）<br/>
          ・スア STUDIO アクスタ ×1 を追加
        </div>

        {/* Their message */}
        <div style={{ margin: '8px 0', display: 'flex', justifyContent: 'flex-start' }}>
          <div style={{
            maxWidth: '78%',
            background: '#fff', borderRadius: '14px 14px 14px 4px',
            padding: '10px 13px',
            fontSize: 12.5, lineHeight: 1.5,
            border: `0.5px solid ${c.divide}`,
          }}>
            ヒナの生写真は×1だけで大丈夫です！<br/>
            代わりにスアのアクスタも欲しいので追加してもらえますか？
          </div>
        </div>

        {/* Your message */}
        <div style={{ margin: '8px 0', display: 'flex', justifyContent: 'flex-end' }}>
          <div style={{
            maxWidth: '78%',
            background: c.lavender, color: '#fff',
            borderRadius: '14px 14px 4px 14px',
            padding: '10px 13px',
            fontSize: 12.5, lineHeight: 1.5,
          }}>
            了解です！それなら大丈夫そうです。<br/>
            少し相手の譲を見せてもらえますか？
          </div>
        </div>

        {/* Bot: 相手の譲一覧を共有 */}
        <div style={{
          margin: '8px 0', padding: '10px 12px',
          background: '#fff', borderRadius: 12,
          border: `0.5px dashed ${c.sky}55`,
          fontSize: 11, color: c.ink, lineHeight: 1.5,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6 }}>
            <span style={{
              fontSize: 9, fontWeight: 800, color: c.sky,
              background: `${c.sky}14`, padding: '2px 7px', borderRadius: 999, letterSpacing: 0.3,
            }}>システム</span>
            <span style={{ color: c.mute, fontSize: 10 }}>15:02</span>
          </div>
          <b>{partner.handle}</b> の譲一覧が共有されました
          <button style={{
            display: 'block', marginTop: 6, padding: '6px 12px',
            borderRadius: 999, background: c.sky, color: '#fff',
            border: 0, fontFamily: 'inherit', fontSize: 11, fontWeight: 700,
          }}>📦 譲一覧を見る</button>
        </div>

        {/* Their reply */}
        <div style={{ margin: '8px 0', display: 'flex', justifyContent: 'flex-start' }}>
          <div style={{
            maxWidth: '78%',
            background: '#fff', borderRadius: '14px 14px 14px 4px',
            padding: '10px 13px',
            fontSize: 12.5, lineHeight: 1.5,
            border: `0.5px solid ${c.divide}`,
          }}>
            どうぞ〜！見てみてください 🙏
          </div>
        </div>

        {/* Mine-agreed system message */}
        {isMineAgreed && (
          <div style={{
            margin: '12px 0', padding: '10px 12px',
            background: `${c.ok}10`, borderRadius: 12,
            border: `1px solid ${c.ok}55`,
            fontSize: 11.5, color: c.ink, lineHeight: 1.6,
            display: 'flex', alignItems: 'flex-start', gap: 8,
          }}>
            <span style={{ fontSize: 14 }}>✓</span>
            <div style={{ flex: 1 }}>
              <b style={{ color: c.ok }}>あなたがこの提案に合意しました</b><br/>
              <span style={{ color: c.mute }}>{partner.handle} の合意があれば取引が成立します。プッシュ通知で連絡が来ます。</span>
            </div>
          </div>
        )}

        {/* Extension button (when reminder6 or near expire) */}
        {(isReminder6 || isReminder3) && (
          <div style={{
            display: 'flex', justifyContent: 'center', margin: '14px 0',
          }}>
            <button style={{
              padding: '8px 16px', borderRadius: 999,
              background: '#fff', color: c.lavender,
              border: `1.5px solid ${c.lavender}55`,
              fontFamily: 'inherit', fontSize: 11.5, fontWeight: 700,
              display: 'inline-flex', alignItems: 'center', gap: 5,
            }}>
              ⏱ 期限を +7日 延長する
            </button>
          </div>
        )}
      </div>

      {/* Bottom: input + agreement CTA */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        background: 'rgba(255,255,255,0.96)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `0.5px solid ${c.divide}`,
        paddingTop: 10, paddingBottom: 28,
      }}>
        {/* Message input */}
        <div style={{
          display: 'flex', gap: 8, padding: '0 18px 8px',
          alignItems: 'center',
        }}>
          <button style={{
            width: 32, height: 32, borderRadius: 16,
            background: c.subtle, border: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: c.mute, fontSize: 16, fontWeight: 700,
          }}>+</button>
          <div style={{
            flex: 1, padding: '9px 14px', borderRadius: 999,
            background: c.subtle, fontSize: 12.5, color: c.hint,
          }}>メッセージ…</div>
          <button style={{
            width: 32, height: 32, borderRadius: 16,
            background: c.lavender, border: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: '#fff',
          }}>
            <svg width="14" height="14" viewBox="0 0 14 14" fill="#fff">
              <path d="M2 12L12 7 2 2v4l7 1-7 1z"/>
            </svg>
          </button>
        </div>

        {/* Agreement CTA */}
        <div style={{ padding: '0 18px', display: 'flex', gap: 8 }}>
          <button style={{
            padding: '12px 16px', borderRadius: 12,
            background: '#fff', color: c.mute,
            border: `0.5px solid ${c.divide}`,
            fontFamily: 'inherit', fontSize: 12, fontWeight: 600,
          }}>拒否</button>
          <button disabled={isExpired || isMineAgreed} style={{
            flex: 1, padding: '12px',
            background: isExpired
              ? c.subtle
              : isMineAgreed
              ? `${c.ok}1a`
              : `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
            color: isExpired ? c.hint : isMineAgreed ? c.ok : '#fff',
            border: isMineAgreed ? `1.5px solid ${c.ok}55` : 0,
            borderRadius: 12,
            fontFamily: 'inherit', fontSize: 13, fontWeight: 700,
            letterSpacing: 0.3,
            boxShadow: (isExpired || isMineAgreed) ? 'none' : `0 4px 12px ${c.lavender}55`,
          }}>
            {isExpired ? '期限切れで終了'
              : isMineAgreed ? '⏳ 相手の合意を待っています'
              : '✓ 合意して受諾'}
          </button>
        </div>
      </div>
    </div>
  );
}

// ──────────────────────────────
// 3. 相手の譲モーダル（参照用）
// ──────────────────────────────
function PartnerInventoryModal({ tweaks }) {
  const c = NF_C(tweaks);
  const partner = { handle: '@plum_92' };
  const items = [
    { id: 'p1', name: 'スア WT01 トレカ', sub: 'WORLD TOUR DAY 2', qty: 3, hue: 280, wishMatch: true, inProposal: true },
    { id: 'p2', name: 'スア WT02 アクスタ', sub: 'WORLD TOUR DAY 2', qty: 1, hue: 285, inProposal: true },
    { id: 'p3', name: 'ヒナ STUDIO トレカ', sub: '5th Mini', qty: 2, hue: 200, wishMatch: true },
    { id: 'p4', name: 'ジウォン JAPAN トレカ', sub: 'JAPAN TOUR', qty: 3, hue: 180 },
    { id: 'p5', name: 'チェ WT01 缶バッジ', sub: 'WORLD TOUR DAY 2', qty: 1, hue: 30 },
    { id: 'p6', name: 'ナナ POPUP アクスタ', sub: '誕生日カフェ', qty: 1, hue: 120 },
  ];

  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: 'rgba(58,50,74,0.45)',
      backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)',
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      display: 'flex', alignItems: 'flex-end',
    }}>
      <div style={{
        width: '100%', maxHeight: '85%',
        background: c.bg,
        borderTopLeftRadius: 22, borderTopRightRadius: 22,
        boxShadow: '0 -10px 40px rgba(0,0,0,0.2)',
        display: 'flex', flexDirection: 'column',
      }}>
        {/* Drag handle */}
        <div style={{
          width: 40, height: 4, background: c.divide, borderRadius: 2,
          margin: '8px auto 0',
        }} />

        {/* Header */}
        <div style={{
          padding: '12px 18px 14px',
          borderBottom: `0.5px solid ${c.divide}`,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 4 }}>
            <div style={{
              width: 30, height: 30, borderRadius: 15,
              background: `linear-gradient(135deg, ${c.lavender}55, ${c.pink}55)`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 11, fontWeight: 800, color: c.ink,
            }}>P</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 800 }}>{partner.handle} の譲一覧</div>
              <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>
                {items.length}件 ・ ★ wish一致 = あなたのwishと一致
              </div>
            </div>
            <button style={{
              width: 28, height: 28, borderRadius: 14,
              background: c.subtle, border: 0,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              color: c.mute, fontSize: 14, lineHeight: 1,
            }}>×</button>
          </div>
          <div style={{
            display: 'flex', gap: 6, marginTop: 6,
            overflowX: 'auto', WebkitOverflowScrolling: 'touch',
          }}>
            {['すべて', 'スア', 'ヒナ', 'トレカ', '生写真', '★ wish一致'].map((f, i) => (
              <button key={f} style={{
                padding: '5px 11px', borderRadius: 999,
                background: i === 0 ? c.lavender : '#fff',
                color: i === 0 ? '#fff' : c.ink,
                border: i === 0 ? 0 : `0.5px solid ${c.divide}`,
                fontFamily: 'inherit', fontSize: 10.5, fontWeight: 600,
                flexShrink: 0, whiteSpace: 'nowrap',
              }}>{f}</button>
            ))}
          </div>
        </div>

        {/* Item list */}
        <div style={{
          flex: 1, overflowY: 'auto', padding: '14px 18px',
        }}>
          <div style={{
            display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10,
          }}>
            {items.map(it => (
              <div key={it.id} style={{
                background: '#fff', borderRadius: 12,
                border: it.inProposal ? `1.5px solid ${c.ok}` : `0.5px solid ${c.divide}`,
                padding: 10, position: 'relative',
              }}>
                <div style={{
                  width: '100%', aspectRatio: '3 / 4', borderRadius: 8,
                  background: `repeating-linear-gradient(135deg, hsl(${it.hue}, 35%, 78%) 0 6px, hsl(${it.hue}, 35%, 70%) 6px 11px)`,
                  marginBottom: 8, boxShadow: `0 2px 6px hsla(${it.hue}, 30%, 30%, 0.15)`,
                }} />
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 3, marginBottom: 4 }}>
                  {it.wishMatch && (
                    <span style={{
                      fontSize: 8, fontWeight: 800, color: '#fff',
                      background: `linear-gradient(135deg, ${c.lavender}, ${c.pink})`,
                      padding: '1px 6px', borderRadius: 999, letterSpacing: 0.3,
                    }}>★ wish</span>
                  )}
                  {it.inProposal && (
                    <span style={{
                      fontSize: 8, fontWeight: 800, color: '#fff',
                      background: c.ok,
                      padding: '1px 6px', borderRadius: 999, letterSpacing: 0.3,
                    }}>提案中</span>
                  )}
                </div>
                <div style={{ fontSize: 11, fontWeight: 700, marginBottom: 2, lineHeight: 1.3 }}>
                  {it.name}
                </div>
                <div style={{
                  fontSize: 9.5, color: c.mute, fontVariantNumeric: 'tabular-nums',
                }}>{it.sub} ・ ×{it.qty}</div>
                <button style={{
                  width: '100%', marginTop: 7, padding: '5px',
                  background: it.inProposal ? c.subtle : `${c.lavender}14`,
                  color: it.inProposal ? c.mute : c.lavender,
                  border: 0, borderRadius: 8,
                  fontFamily: 'inherit', fontSize: 10, fontWeight: 700,
                }}>
                  {it.inProposal ? '提案中' : '+ 希望に追加'}
                </button>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

// ──────────────────────────────
// 4. 合意送信前モーダル
// ──────────────────────────────
function C15AgreementConfirmModal({ tweaks }) {
  const c = NF_C(tweaks);
  const meetup = {
    date: '5/3 (土)',
    time: '14:00〜18:00',
    place: 'TWICE 名古屋ドーム公演',
    area: 'ナゴヤドーム前矢田駅 周辺',
  };
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: 'rgba(58,50,74,0.45)',
      backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)',
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      display: 'flex', alignItems: 'flex-end',
    }}>
      <div style={{
        width: '100%', background: '#fff',
        borderTopLeftRadius: 22, borderTopRightRadius: 22,
        padding: '14px 22px 32px',
        boxShadow: '0 -10px 40px rgba(0,0,0,0.2)',
        maxHeight: '92%', overflowY: 'auto',
      }}>
        {/* Drag handle */}
        <div style={{
          width: 40, height: 4, background: c.divide, borderRadius: 2,
          margin: '0 auto 16px',
        }} />

        <div style={{
          fontSize: 19, fontWeight: 800, marginBottom: 6, textAlign: 'center', color: c.ink,
        }}>この内容で合意しますか？</div>
        <div style={{
          fontSize: 12, color: c.mute, marginBottom: 16,
          lineHeight: 1.7, textAlign: 'center',
        }}>
          双方が合意すると<b style={{ color: c.ink }}>取引が成立</b>します。<br/>
          日時・場所も含めて確定するので、ご確認ください。
        </div>

        {/* Proposal summary */}
        <div style={{
          padding: 14, borderRadius: 14,
          background: `linear-gradient(135deg, ${c.lavender}1a, ${c.sky}1a)`,
          border: `1.5px solid ${c.lavender}40`,
          marginBottom: 12,
        }}>
          <div style={{
            fontSize: 9.5, fontWeight: 800, color: c.lavender,
            letterSpacing: 0.5, marginBottom: 10, textAlign: 'center',
          }}>📋 取引内容</div>
          <div style={{ marginBottom: 10 }}>
            <div style={{ fontSize: 10, color: c.mute, fontWeight: 700, marginBottom: 4 }}>あなたが受け取る</div>
            <div style={{ fontSize: 12.5, fontWeight: 700, color: c.ink }}>
              スア WT01 トレカ <span style={{ color: c.lavender }}>×3</span>
            </div>
          </div>
          <div style={{
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            margin: '4px 0', color: c.lavender,
          }}>
            <svg width="20" height="20" viewBox="0 0 22 22">
              <path d="M5 8h12M14 4l4 4-4 4M17 14H5M8 18l-4-4 4-4" stroke={c.lavender} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
          <div>
            <div style={{ fontSize: 10, color: c.mute, fontWeight: 700, marginBottom: 4 }}>あなたが出す</div>
            <div style={{ fontSize: 12.5, fontWeight: 700, color: c.ink, lineHeight: 1.7 }}>
              ヒナ生写真 <span style={{ color: c.lavender }}>×1</span><br/>
              スア STUDIO アクスタ <span style={{ color: c.lavender }}>×1</span>
            </div>
          </div>
        </div>

        {/* 待ち合わせ */}
        <div style={{
          padding: 12, borderRadius: 14,
          background: `linear-gradient(135deg, ${c.pink}10, ${c.lavender}1a)`,
          border: `1.5px solid ${c.lavender}40`,
          marginBottom: 16,
        }}>
          <div style={{
            fontSize: 9.5, fontWeight: 800, color: c.lavender,
            letterSpacing: 0.5, marginBottom: 8, textAlign: 'center',
          }}>📍 待ち合わせ</div>
          <div style={{
            fontSize: 15, fontWeight: 800, color: c.ink, marginBottom: 2,
            fontVariantNumeric: 'tabular-nums', textAlign: 'center',
          }}>{meetup.date} {meetup.time}</div>
          <div style={{ fontSize: 12, fontWeight: 700, color: c.ink, textAlign: 'center', marginBottom: 2 }}>
            {meetup.place}
          </div>
          <div style={{ fontSize: 10.5, color: c.mute, textAlign: 'center', marginBottom: 8 }}>
            📍 {meetup.area}
          </div>
          <NF_MiniMap c={c} height={80} label={meetup.area.split(' ')[0]} />
        </div>

        <div style={{
          padding: '10px 12px', borderRadius: 10,
          background: `${c.warn}14`, fontSize: 10.5, color: c.ink,
          lineHeight: 1.6, marginBottom: 18,
        }}>
          <b style={{ color: c.warn }}>⚠ 注意</b><br/>
          合意後は提案内容（アイテム・日時・場所）の変更ができません。当日は時間に余裕をもって会場へ向かいましょう。
        </div>

        <button style={{
          width: '100%', padding: '14px',
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', border: 0, borderRadius: 14,
          fontFamily: 'inherit', fontSize: 14, fontWeight: 700,
          letterSpacing: 0.3, marginBottom: 8,
          boxShadow: `0 6px 18px ${c.lavender}55`,
        }}>合意する</button>
        <button style={{
          width: '100%', padding: '12px',
          background: 'transparent', color: c.mute,
          border: 0,
          fontFamily: 'inherit', fontSize: 13, fontWeight: 600,
        }}>編集に戻る</button>
      </div>
    </div>
  );
}

// ──────────────────────────────
// 5. 取引成立画面（双方合意後の演出）
// ──────────────────────────────
function C15AgreementSuccess({ tweaks }) {
  const c = NF_C(tweaks);
  const partner = { handle: '@plum_92', star: 4.5, trades: 157 };
  const meetup = {
    date: '5/3 (土)',
    time: '14:00〜18:00',
    place: 'TWICE 名古屋ドーム公演',
    area: 'ナゴヤドーム前矢田駅 周辺',
  };

  // Confetti dots positions
  const confetti = [
    { x: 8, y: 12, color: c.lavender, size: 6, rot: 15 },
    { x: 88, y: 8, color: c.pink, size: 8, rot: -20 },
    { x: 22, y: 20, color: c.sky, size: 5, rot: 30 },
    { x: 75, y: 18, color: c.lavender, size: 7, rot: -10 },
    { x: 12, y: 32, color: c.pink, size: 6, rot: 45 },
    { x: 92, y: 28, color: c.sky, size: 5, rot: -30 },
    { x: 5, y: 48, color: c.lavender, size: 4, rot: 20 },
    { x: 82, y: 45, color: c.pink, size: 5, rot: -15 },
    { x: 18, y: 65, color: c.sky, size: 6, rot: 35 },
    { x: 90, y: 60, color: c.lavender, size: 5, rot: -25 },
    { x: 15, y: 78, color: c.pink, size: 6, rot: 10 },
    { x: 88, y: 75, color: c.sky, size: 7, rot: -40 },
    { x: 50, y: 6, color: c.pink, size: 8, rot: 0 },
    { x: 35, y: 92, color: c.lavender, size: 6, rot: 25 },
    { x: 65, y: 90, color: c.sky, size: 5, rot: -15 },
  ];

  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: `linear-gradient(180deg, ${c.lavender}33 0%, ${c.sky}22 35%, #fff 80%)`,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, padding: '70px 22px 30px',
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      {/* Confetti */}
      {confetti.map((p, i) => (
        <div key={i} style={{
          position: 'absolute',
          left: `${p.x}%`, top: `${p.y}%`,
          width: p.size, height: p.size * 1.6,
          background: p.color,
          transform: `rotate(${p.rot}deg)`,
          borderRadius: 1,
          boxShadow: `0 1px 3px ${p.color}66`,
          zIndex: 0,
        }} />
      ))}

      <div style={{ position: 'relative', zIndex: 1, textAlign: 'center' }}>
        {/* Sparkle icon */}
        <div style={{
          width: 110, height: 110, borderRadius: 55,
          margin: '20px auto 22px',
          background: `linear-gradient(135deg, ${c.lavender}, ${c.pink})`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 12px 36px ${c.lavender}66`,
          position: 'relative',
        }}>
          <span style={{ fontSize: 56, lineHeight: 1 }}>✨</span>
          {/* Outer glow ring */}
          <div style={{
            position: 'absolute', inset: -8,
            borderRadius: '50%',
            border: `2px solid ${c.lavender}33`,
          }} />
          <div style={{
            position: 'absolute', inset: -16,
            borderRadius: '50%',
            border: `1.5px solid ${c.lavender}1a`,
          }} />
        </div>

        <div style={{
          fontSize: 12, fontWeight: 800, color: c.lavender,
          letterSpacing: 1.2, marginBottom: 6,
        }}>★ AGREEMENT REACHED</div>
        <div style={{
          fontSize: 26, fontWeight: 800, marginBottom: 10,
          letterSpacing: 0.4, color: c.ink,
        }}>取引が成立しました！</div>
        <div style={{
          fontSize: 13, color: c.mute, lineHeight: 1.7, marginBottom: 22,
          maxWidth: 320, margin: '0 auto 22px',
        }}>
          <b style={{ color: c.ink }}>{partner.handle}</b> と合意しました。<br/>
          当日、決まった場所で合流しましょう。
        </div>

        {/* Trade summary card */}
        <div style={{
          padding: 16, borderRadius: 16,
          background: '#fff',
          border: `1.5px solid ${c.lavender}33`,
          boxShadow: `0 8px 24px ${c.lavender}22`,
          marginBottom: 18, textAlign: 'left',
        }}>
          <div style={{
            fontSize: 10, fontWeight: 800, color: c.lavender,
            letterSpacing: 0.5, marginBottom: 10, textAlign: 'center',
          }}>確定した取引内容</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 9.5, color: c.mute, fontWeight: 700, marginBottom: 4 }}>あなたが受け取る</div>
              <div style={{
                width: 36, height: 48, borderRadius: 5,
                background: `repeating-linear-gradient(135deg, hsl(280, 35%, 78%) 0 5px, hsl(280, 35%, 70%) 5px 10px)`,
                marginBottom: 4,
              }} />
              <div style={{ fontSize: 11, fontWeight: 700, lineHeight: 1.4 }}>
                スア WT01 トレカ<br/>
                <span style={{ color: c.lavender }}>×3</span>
              </div>
            </div>
            <svg width="22" height="22" viewBox="0 0 22 22" style={{ flexShrink: 0 }}>
              <path d="M5 8h12M14 4l4 4-4 4M17 14H5M8 18l-4-4 4-4" stroke={c.lavender} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            <div style={{ flex: 1, minWidth: 0, textAlign: 'right' }}>
              <div style={{ fontSize: 9.5, color: c.mute, fontWeight: 700, marginBottom: 4 }}>あなたが出す</div>
              <div style={{
                display: 'flex', gap: 4, justifyContent: 'flex-end', marginBottom: 4,
              }}>
                <div style={{
                  width: 28, height: 38, borderRadius: 4,
                  background: `repeating-linear-gradient(135deg, hsl(200, 35%, 78%) 0 4px, hsl(200, 35%, 70%) 4px 8px)`,
                }} />
                <div style={{
                  width: 28, height: 38, borderRadius: 4,
                  background: `repeating-linear-gradient(135deg, hsl(285, 35%, 78%) 0 4px, hsl(285, 35%, 70%) 4px 8px)`,
                }} />
              </div>
              <div style={{ fontSize: 11, fontWeight: 700, lineHeight: 1.4 }}>
                ヒナ生写真 <span style={{ color: c.lavender }}>×1</span><br/>
                スア STUDIO <span style={{ color: c.lavender }}>×1</span>
              </div>
            </div>
          </div>
        </div>

        {/* 待ち合わせ確定情報（最重要） */}
        <div style={{
          padding: 14, borderRadius: 16,
          background: '#fff',
          border: `1.5px solid ${c.lavender}55`,
          boxShadow: `0 8px 24px ${c.lavender}22`,
          marginBottom: 14, textAlign: 'left',
        }}>
          <div style={{
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            marginBottom: 10,
          }}>
            <div style={{
              fontSize: 10, fontWeight: 800, color: c.lavender,
              letterSpacing: 0.5,
            }}>📍 確定した待ち合わせ</div>
            <span style={{
              fontSize: 9, fontWeight: 800, color: '#fff',
              background: c.ok, padding: '3px 8px', borderRadius: 999, letterSpacing: 0.4,
            }}>確定</span>
          </div>
          <div style={{
            fontSize: 18, fontWeight: 800, color: c.ink, marginBottom: 2,
            fontVariantNumeric: 'tabular-nums',
          }}>{meetup.date} {meetup.time}</div>
          <div style={{ fontSize: 13, fontWeight: 700, color: c.ink, marginBottom: 2 }}>
            {meetup.place}
          </div>
          <div style={{ fontSize: 11, color: c.mute, marginBottom: 10 }}>
            📍 {meetup.area}
          </div>
          <NF_MiniMap c={c} height={100} label={meetup.area.split(' ')[0]} />
          <button style={{
            width: '100%', marginTop: 10, padding: '8px',
            background: c.subtle, color: c.ink,
            border: `0.5px solid ${c.divide}`,
            borderRadius: 8,
            fontFamily: 'inherit', fontSize: 11, fontWeight: 700,
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6,
            cursor: 'pointer',
          }}>
            <svg width="12" height="12" viewBox="0 0 12 12" fill="none" stroke={c.ink} strokeWidth="1.4">
              <rect x="1" y="2" width="10" height="9" rx="1.5"/>
              <path d="M3 0v3M9 0v3M1 5h10"/>
            </svg>
            カレンダーに追加
          </button>
        </div>

        {/* Partner info */}
        <div style={{
          padding: '12px 14px', borderRadius: 12,
          background: 'rgba(255,255,255,0.7)', border: `0.5px solid ${c.divide}`,
          display: 'flex', alignItems: 'center', gap: 10, marginBottom: 18,
          textAlign: 'left',
        }}>
          <div style={{
            width: 38, height: 38, borderRadius: 19,
            background: `linear-gradient(135deg, ${c.pink}55, ${c.lavender}55)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 13, fontWeight: 800, color: c.ink, flexShrink: 0,
          }}>P</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13, fontWeight: 800 }}>{partner.handle}</div>
            <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>
              ★{partner.star} ・ 取引{partner.trades}
            </div>
          </div>
          <div style={{
            fontSize: 9, fontWeight: 800, color: '#fff',
            background: c.ok, padding: '3px 8px', borderRadius: 999, letterSpacing: 0.4,
          }}>合意済</div>
        </div>

        {/* Next steps（待ち合わせがfix済なので簡潔） */}
        <div style={{ textAlign: 'left', marginBottom: 18 }}>
          <div style={{
            fontSize: 11, fontWeight: 800, color: c.mute,
            letterSpacing: 0.5, marginBottom: 8, padding: '0 4px',
          }}>次のステップ</div>
          {[
            { num: '1', label: '当日、決まった場所・時間で合流' },
            { num: '2', label: '取引チャットで最終調整・現地連絡' },
            { num: '3', label: '物理交換 → 証跡撮影 → 評価' },
          ].map((s, i) => (
            <div key={i} style={{
              padding: '10px 12px', borderRadius: 10,
              background: '#fff', border: `0.5px solid ${c.divide}`,
              fontSize: 12, color: c.ink,
              display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6,
            }}>
              <span style={{
                width: 22, height: 22, borderRadius: 11,
                background: `${c.lavender}14`, color: c.lavender,
                fontSize: 11, fontWeight: 800,
                display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
              }}>{s.num}</span>
              <span style={{ flex: 1 }}>{s.label}</span>
            </div>
          ))}
        </div>

        {/* CTA */}
        <button style={{
          width: '100%', padding: '15px',
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', border: 0, borderRadius: 14,
          fontFamily: 'inherit', fontSize: 14.5, fontWeight: 800,
          letterSpacing: 0.4,
          boxShadow: `0 6px 20px ${c.lavender}66`,
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6,
        }}>
          取引チャットへ進む
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M3 7h8M7 3l4 4-4 4"/>
          </svg>
        </button>
      </div>
    </div>
  );
}

Object.assign(window, {
  C1ReceiveScreen, C15NegoChatScreen, PartnerInventoryModal,
  C15AgreementConfirmModal, C15AgreementSuccess,
});
