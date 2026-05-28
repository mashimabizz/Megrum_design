// ─────────────────────────────────────────────────────────────
// propose-select.jsx — C-0 提示物選択画面
// 完全マッチ・片方向マッチ全パターンで「両側のアイテム」を選択
// 自分が出すもの / 受け取るもの / 待ち合わせ をそれぞれ tab で切替
// 数量ステッパー＋待ち合わせ（即時/日時指定・AW連携・マップ表示）
// ─────────────────────────────────────────────────────────────

const PS_C = (t) => ({
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

// 簡易マップ表示（駅・道・建物の俯瞰図 + 中央にピン）
const PS_MiniMap = ({ c, height = 110, label }) => (
  <div style={{
    height, borderRadius: 10, overflow: 'hidden', position: 'relative',
    border: `0.5px solid ${c.divide}`, background: '#e8eef0',
  }}>
    <svg width="100%" height="100%" viewBox="0 0 300 110" preserveAspectRatio="none">
      {/* 背景 */}
      <rect width="300" height="110" fill="#e8eef0" />
      {/* 大通り 横 */}
      <rect x="0" y="48" width="300" height="14" fill="#fafbfc" />
      <line x1="0" y1="55" x2="300" y2="55" stroke="#dde0e2" strokeWidth="0.5" strokeDasharray="4 3" />
      {/* 道 縦 */}
      <rect x="138" y="0" width="11" height="110" fill="#fafbfc" />
      {/* 建物ブロック */}
      <rect x="14" y="10" width="48" height="28" fill="#d4d8d6" rx="2" />
      <rect x="68" y="10" width="62" height="32" fill="#cfd2d0" rx="2" />
      <rect x="156" y="6" width="56" height="36" fill="#d4d8d6" rx="2" />
      <rect x="220" y="10" width="68" height="30" fill="#d0d4d2" rx="2" />
      <rect x="14" y="68" width="50" height="32" fill="#d2d6d4" rx="2" />
      <rect x="70" y="72" width="60" height="30" fill="#d8dcda" rx="2" />
      <rect x="156" y="68" width="56" height="34" fill="#cfd3d1" rx="2" />
      <rect x="220" y="70" width="68" height="30" fill="#d6dad8" rx="2" />
      {/* 公園・緑地 */}
      <rect x="225" y="46" width="60" height="18" fill="#cad8c6" rx="2" />
      <circle cx="240" cy="55" r="3" fill="#b9ccb3" />
      <circle cx="252" cy="56" r="2.5" fill="#b9ccb3" />
      <circle cx="267" cy="54" r="2.8" fill="#b9ccb3" />
      {/* 中央のピン（脈動付き） */}
      <g transform="translate(143, 55)">
        <circle cx="0" cy="0" r="22" fill={c.lavender} fillOpacity="0.16" />
        <circle cx="0" cy="0" r="14" fill={c.lavender} fillOpacity="0.32" />
        <path d="M0 -14 C-7 -14 -11 -9 -11 -3 C-11 5 0 14 0 14 C0 14 11 5 11 -3 C11 -9 7 -14 0 -14 Z"
              fill={c.lavender} stroke="#fff" strokeWidth="1.5" />
        <circle cx="0" cy="-3" r="3.5" fill="#fff" />
      </g>
    </svg>
    {label && (
      <div style={{
        position: 'absolute', left: 8, bottom: 8,
        background: 'rgba(255,255,255,0.94)', padding: '4px 8px',
        borderRadius: 6, fontSize: 10, fontWeight: 700, color: c.ink,
        boxShadow: '0 2px 6px rgba(0,0,0,0.08)',
      }}>{label}</div>
    )}
  </div>
);

function ProposeSelectScreen({ tweaks, scenario = 'full', initialTab = 'mine', initialMeetupType = 'scheduled' }) {
  const c = PS_C(tweaks);
  const [tab, setTab] = React.useState(initialTab);

  const partner = { handle: '@plum_92', star: 4.5, trades: 157, dist: '169m' };

  const scenarioLabel = {
    full: '完全マッチからの打診',
    forward: '私が欲しい譲を持つ人 から打診',
    backward: '私の譲が欲しい人 から打診',
  }[scenario];

  // 私の譲一覧（自分の在庫）
  const baseMyItems = [
    { id: 'm1', name: 'ヒナ 5th Mini 生写真', sub: '5th Mini Album', qty: 2, hue: 200, wishMatch: true },
    { id: 'm2', name: 'スア POPUP 缶バッジ', sub: '誕生日カフェ', qty: 1, hue: 280 },
    { id: 'm3', name: 'ヒナ JAPAN トレカ', sub: 'JAPAN TOUR', qty: 3, hue: 200, wishMatch: true },
    { id: 'm4', name: 'スア STUDIO アクスタ', sub: 'STUDIO Ver.', qty: 1, hue: 285 },
    { id: 'm5', name: 'ジュン WT02 トレカ', sub: 'WORLD TOUR DAY 2', qty: 1, hue: 240 },
  ];

  // 相手の譲一覧
  const baseTheirItems = [
    { id: 'p1', name: 'スア WT01 トレカ', sub: 'WORLD TOUR DAY 2', qty: 3, hue: 280, wishMatch: true },
    { id: 'p2', name: 'スア WT02 アクスタ', sub: 'WORLD TOUR DAY 2', qty: 1, hue: 285 },
    { id: 'p3', name: 'ヒナ STUDIO トレカ', sub: '5th Mini', qty: 2, hue: 200, wishMatch: true },
    { id: 'p4', name: 'ジウォン JAPAN トレカ', sub: 'JAPAN TOUR', qty: 3, hue: 180 },
    { id: 'p5', name: 'チェ WT01 缶バッジ', sub: 'WORLD TOUR DAY 2', qty: 1, hue: 30 },
  ];

  // pre-check ＋ selectedQty 初期化
  const initWith = (items, isPreChecked) => items.map(i => {
    const checked = isPreChecked(i);
    return {
      ...i,
      selected: checked,
      selectedQty: checked ? i.qty : 1,
    };
  });

  const myInitial = initWith(baseMyItems, i =>
    scenario === 'full' ? i.id === 'm1'
    : scenario === 'forward' ? false
    : i.id === 'm1'
  );

  const theirInitial = initWith(baseTheirItems, i =>
    scenario === 'full' ? i.id === 'p1'
    : scenario === 'forward' ? i.id === 'p1'
    : false
  );

  const [myItems, setMyItems] = React.useState(myInitial);
  const [theirItems, setTheirItems] = React.useState(theirInitial);

  // ── 待ち合わせ state ──
  const [meetupType, setMeetupType] = React.useState(initialMeetupType); // 'now' | 'scheduled'
  const [meetupMinutes, setMeetupMinutes] = React.useState(15);
  const [selectedAW, setSelectedAW] = React.useState('aw1');
  const [customDate, setCustomDate] = React.useState('');
  const [customTime, setCustomTime] = React.useState('');
  const [customLocation, setCustomLocation] = React.useState('');
  const [registerAsAW, setRegisterAsAW] = React.useState(true);

  // 登録済みAW（aw-edit.jsx と連動するイメージ）
  const awList = [
    { id: 'aw1', date: '5/3 (土)', time: '14:00〜18:00', place: 'TWICE 名古屋ドーム公演', area: 'ナゴヤドーム前矢田駅', match: true },
    { id: 'aw2', date: '5/4 (日)', time: '15:30〜19:30', place: 'NewJeans 大阪城ホール', area: 'JR大阪城公園駅' },
    { id: 'aw3', date: '5/10 (土)', time: '12:00〜17:00', place: 'IVE 横浜アリーナ', area: '新横浜駅' },
  ];

  const myCount = myItems.filter(i => i.selected).reduce((sum, i) => sum + i.selectedQty, 0);
  const theirCount = theirItems.filter(i => i.selected).reduce((sum, i) => sum + i.selectedQty, 0);

  // 待ち合わせの設定済み判定
  const meetupSet = meetupType === 'now'
    ? true
    : selectedAW === 'custom'
      ? !!(customDate && customTime && customLocation)
      : true;

  const meetupSummary = (() => {
    if (meetupType === 'now') return `今すぐ・${meetupMinutes}分以内`;
    if (selectedAW === 'custom') {
      return (customDate && customTime) ? `${customDate} ${customTime}` : '未設定';
    }
    const aw = awList.find(a => a.id === selectedAW);
    return aw ? `${aw.date} ${aw.time.split('〜')[0]}〜` : '';
  })();

  const canProceed = myCount > 0 && theirCount > 0 && meetupSet;

  const toggleItem = (side, id) => {
    const update = (items) => items.map(i => {
      if (i.id !== id) return i;
      const newSelected = !i.selected;
      return {
        ...i,
        selected: newSelected,
        selectedQty: newSelected ? i.qty : 1,
      };
    });
    if (side === 'mine') setMyItems(update(myItems));
    else setTheirItems(update(theirItems));
  };

  const updateQty = (side, id, delta) => {
    const update = (items) => items.map(i => {
      if (i.id !== id) return i;
      const newQty = Math.max(1, Math.min(i.qty, (i.selectedQty || 1) + delta));
      return { ...i, selectedQty: newQty };
    });
    if (side === 'mine') setMyItems(update(myItems));
    else setTheirItems(update(theirItems));
  };

  const items = tab === 'mine' ? myItems : tab === 'theirs' ? theirItems : [];
  const sectionLabel = tab === 'mine'
    ? 'あなたの在庫（譲る候補・自分用キープから選択可）'
    : tab === 'theirs'
      ? `${partner.handle} の譲一覧`
      : '';

  const summaryText = (list) => list
    .filter(i => i.selected)
    .map(i => `${i.name.split(' ').slice(-1)} ×${i.selectedQty}`)
    .join(' / ');

  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 154, paddingBottom: 158,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      {/* Header */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0,
        padding: '54px 18px 0',
        background: 'rgba(255,255,255,0.94)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: `0.5px solid ${c.divide}`,
        zIndex: 10,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
          <svg width="10" height="16" viewBox="0 0 10 16" style={{ flex: '0 0 auto' }}>
            <path d="M8 1L2 8l6 7" stroke={c.ink} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 700, color: c.ink }}>提示物の選択</div>
            <div style={{ fontSize: 11, color: c.mute, marginTop: 1 }}>
              {partner.handle} ・ ★{partner.star}・取引{partner.trades}・{partner.dist}
            </div>
          </div>
          <div style={{
            fontSize: 10.5, color: c.lavender, fontWeight: 800,
            background: `${c.lavender}14`, padding: '4px 9px', borderRadius: 999,
            letterSpacing: 0.3,
          }}>STEP 1/3</div>
        </div>

        {/* Tabs（3つ） */}
        <div style={{
          display: 'flex', gap: 0, borderBottom: `0.5px solid ${c.divide}`,
          marginLeft: -18, marginRight: -18, padding: '0 12px',
        }}>
          {[
            { id: 'mine', label: '私が出す', count: myCount, kind: 'count' },
            { id: 'theirs', label: '受け取る', count: theirCount, kind: 'count' },
            { id: 'meetup', label: '待ち合わせ', count: meetupSet ? '✓' : '!', kind: 'state' },
          ].map(tt => {
            const active = tab === tt.id;
            const isMeetup = tt.kind === 'state';
            return (
              <button key={tt.id} onClick={() => setTab(tt.id)} style={{
                flex: 1, padding: '11px 4px',
                background: 'transparent', border: 0,
                borderBottom: active ? `2.5px solid ${c.lavender}` : '2.5px solid transparent',
                color: active ? c.lavender : c.mute,
                fontFamily: 'inherit', fontSize: 12.5, fontWeight: active ? 800 : 600,
                cursor: 'pointer',
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5,
              }}>
                {tt.label}
                {isMeetup ? (
                  <span style={{
                    fontSize: 10, fontWeight: 800,
                    background: meetupSet ? c.ok : `${c.warn}33`,
                    color: meetupSet ? '#fff' : c.warn,
                    padding: '2px 6px', borderRadius: 999,
                    minWidth: 18, textAlign: 'center',
                  }}>{tt.count}</span>
                ) : (
                  <span style={{
                    fontSize: 10, fontWeight: 800,
                    background: active ? c.lavender : c.subtle,
                    color: active ? '#fff' : c.mute,
                    padding: '2px 7px', borderRadius: 999,
                    fontVariantNumeric: 'tabular-nums',
                    minWidth: 18, textAlign: 'center',
                  }}>{tt.count}</span>
                )}
              </button>
            );
          })}
        </div>
      </div>

      <div style={{ padding: '14px 18px 0' }}>
        {tab === 'meetup' ? (
          // ─────── 待ち合わせタブ ───────
          <>
            {/* Hint */}
            <div style={{
              padding: '10px 12px', borderRadius: 10,
              background: `${c.lavender}10`, fontSize: 11.5,
              color: c.ink, lineHeight: 1.6, marginBottom: 12,
            }}>
              <span style={{
                fontSize: 9.5, fontWeight: 800, color: c.lavender,
                background: '#fff', padding: '2px 7px', borderRadius: 999,
                letterSpacing: 0.4, marginRight: 6,
              }}>📍 待ち合わせ</span>
              日時と場所を決めます。<b>その場で会う</b>なら「いますぐ」、<b>事前に約束</b>するなら「日時指定」を選んでください。
            </div>

            {/* Type toggle（即時 / 日時指定） */}
            <div style={{
              display: 'flex', gap: 6, marginBottom: 14,
              background: c.subtle, borderRadius: 12, padding: 4,
            }}>
              {[
                { id: 'now', label: '🚀 いますぐ', sub: '5〜30分以内に合流' },
                { id: 'scheduled', label: '📅 日時指定', sub: '事前に時間を決める' },
              ].map(opt => {
                const active = meetupType === opt.id;
                return (
                  <button key={opt.id} onClick={() => setMeetupType(opt.id)} style={{
                    flex: 1, padding: '10px 6px',
                    background: active ? '#fff' : 'transparent',
                    border: 0, borderRadius: 9,
                    color: active ? c.lavender : c.mute,
                    fontFamily: 'inherit',
                    cursor: 'pointer',
                    boxShadow: active ? '0 2px 6px rgba(0,0,0,0.06)' : 'none',
                    textAlign: 'center', lineHeight: 1.3,
                  }}>
                    <div style={{ fontSize: 12.5, fontWeight: active ? 800 : 700 }}>{opt.label}</div>
                    <div style={{ fontSize: 9.5, fontWeight: 600, marginTop: 2, color: active ? c.mute : c.hint }}>{opt.sub}</div>
                  </button>
                );
              })}
            </div>

            {meetupType === 'now' ? (
              // ─── 即時モード ───
              <>
                <div style={{
                  fontSize: 11, fontWeight: 700, color: c.mute,
                  letterSpacing: 0.4, padding: '0 4px', marginBottom: 8,
                }}>合流可能時間</div>
                <div style={{
                  display: 'flex', gap: 6, marginBottom: 16, flexWrap: 'wrap',
                }}>
                  {[5, 10, 15, 30].map(m => {
                    const active = meetupMinutes === m;
                    return (
                      <button key={m} onClick={() => setMeetupMinutes(m)} style={{
                        padding: '8px 14px', borderRadius: 999,
                        background: active ? c.lavender : '#fff',
                        color: active ? '#fff' : c.ink,
                        border: active ? 0 : `0.5px solid ${c.divide}`,
                        fontFamily: 'inherit', fontSize: 12, fontWeight: active ? 800 : 600,
                        cursor: 'pointer',
                        boxShadow: active ? `0 2px 6px ${c.lavender}33` : 'none',
                      }}>{m}分以内</button>
                    );
                  })}
                </div>

                <div style={{
                  fontSize: 11, fontWeight: 700, color: c.mute,
                  letterSpacing: 0.4, padding: '0 4px', marginBottom: 8,
                }}>合流場所</div>
                <div style={{
                  background: '#fff', borderRadius: 12,
                  border: `0.5px solid ${c.divide}`,
                  padding: 12, marginBottom: 8,
                }}>
                  <div style={{
                    display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10,
                  }}>
                    <div style={{
                      width: 32, height: 32, borderRadius: '50%',
                      background: `${c.lavender}18`,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      flexShrink: 0,
                    }}>
                      <svg width="16" height="16" viewBox="0 0 16 16">
                        <path d="M8 1.5C5 1.5 2.5 4 2.5 7c0 4 5.5 7.5 5.5 7.5s5.5-3.5 5.5-7.5c0-3-2.5-5.5-5.5-5.5z" stroke={c.lavender} strokeWidth="1.5" fill="none"/>
                        <circle cx="8" cy="7" r="2" fill={c.lavender}/>
                      </svg>
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 700 }}>東京駅 銀の鈴前</div>
                      <div style={{ fontSize: 10.5, color: c.mute }}>八重洲口 中央改札外</div>
                    </div>
                    <button style={{
                      padding: '6px 10px', borderRadius: 8,
                      background: c.subtle, border: 0,
                      color: c.ink, fontSize: 10.5, fontWeight: 700,
                      fontFamily: 'inherit', cursor: 'pointer',
                    }}>変更</button>
                  </div>
                  <PS_MiniMap c={c} height={120} label="現在地から徒歩3分" />
                </div>

                <div style={{
                  padding: '10px 12px', borderRadius: 10,
                  background: `${c.sky}14`, fontSize: 10.5,
                  color: c.ink, lineHeight: 1.6, marginTop: 4,
                }}>
                  💡 「いますぐ」を選んだ場合、相手が承諾した直後に合流できる距離にいることが前提です。会場周辺など、すぐ動ける状況で使いましょう。
                </div>
              </>
            ) : (
              // ─── 日時指定モード ───
              <>
                <div style={{
                  fontSize: 11, fontWeight: 700, color: c.mute,
                  letterSpacing: 0.4, padding: '0 4px', marginBottom: 8,
                  display: 'flex', alignItems: 'center', gap: 6,
                }}>
                  登録済みのAW（活動予定）から選ぶ
                </div>

                {awList.map(aw => {
                  const active = selectedAW === aw.id;
                  return (
                    <div key={aw.id} onClick={() => setSelectedAW(aw.id)} style={{
                      background: '#fff', borderRadius: 12,
                      border: active ? `1.5px solid ${c.lavender}` : `0.5px solid ${c.divide}`,
                      padding: '12px 14px', marginBottom: 8,
                      display: 'flex', alignItems: 'center', gap: 12,
                      boxShadow: active ? `0 4px 12px ${c.lavender}22` : 'none',
                      cursor: 'pointer',
                    }}>
                      <div style={{
                        width: 20, height: 20, borderRadius: '50%', flexShrink: 0,
                        border: `1.8px solid ${active ? c.lavender : c.divide}`,
                        background: '#fff',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                      }}>
                        {active && <div style={{ width: 11, height: 11, borderRadius: '50%', background: c.lavender }} />}
                      </div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{
                          display: 'flex', alignItems: 'center', gap: 6, marginBottom: 2, flexWrap: 'wrap',
                        }}>
                          <span style={{
                            fontSize: 12.5, fontWeight: 800, color: c.lavender,
                            fontVariantNumeric: 'tabular-nums',
                          }}>{aw.date} {aw.time}</span>
                          {aw.match && (
                            <span style={{
                              fontSize: 9, fontWeight: 800, color: '#fff',
                              background: `linear-gradient(135deg, ${c.lavender}, ${c.pink})`,
                              padding: '2px 6px', borderRadius: 999, letterSpacing: 0.3,
                            }}>★ 相手と一致</span>
                          )}
                        </div>
                        <div style={{ fontSize: 12, fontWeight: 700, marginBottom: 1 }}>{aw.place}</div>
                        <div style={{ fontSize: 10.5, color: c.mute }}>📍 {aw.area}</div>
                      </div>
                    </div>
                  );
                })}

                {/* 選択中AWの map preview */}
                {selectedAW !== 'custom' && (() => {
                  const aw = awList.find(a => a.id === selectedAW);
                  return aw ? (
                    <div style={{
                      background: '#fff', borderRadius: 12,
                      border: `0.5px solid ${c.divide}`,
                      padding: 10, marginBottom: 8,
                    }}>
                      <div style={{
                        fontSize: 10, fontWeight: 700, color: c.mute,
                        padding: '0 4px 8px', letterSpacing: 0.4,
                      }}>📍 {aw.area} 周辺</div>
                      <PS_MiniMap c={c} height={100} label={aw.area} />
                    </div>
                  ) : null;
                })()}

                {/* OR 区切り */}
                <div style={{
                  display: 'flex', alignItems: 'center', gap: 12,
                  margin: '16px 0 12px',
                }}>
                  <div style={{ flex: 1, height: 0.5, background: c.divide }} />
                  <span style={{ fontSize: 10, fontWeight: 700, color: c.mute, letterSpacing: 0.5 }}>OR</span>
                  <div style={{ flex: 1, height: 0.5, background: c.divide }} />
                </div>

                {/* 新しい日時を指定 */}
                <div style={{
                  fontSize: 11, fontWeight: 700, color: c.mute,
                  letterSpacing: 0.4, padding: '0 4px', marginBottom: 8,
                }}>新しい日時を指定する</div>

                <div onClick={() => setSelectedAW('custom')} style={{
                  background: '#fff', borderRadius: 12,
                  border: selectedAW === 'custom' ? `1.5px solid ${c.lavender}` : `0.5px solid ${c.divide}`,
                  padding: '12px 14px', marginBottom: 8,
                  boxShadow: selectedAW === 'custom' ? `0 4px 12px ${c.lavender}22` : 'none',
                  cursor: 'pointer',
                }}>
                  <div style={{
                    display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12,
                  }}>
                    <div style={{
                      width: 20, height: 20, borderRadius: '50%', flexShrink: 0,
                      border: `1.8px solid ${selectedAW === 'custom' ? c.lavender : c.divide}`,
                      background: '#fff',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                      {selectedAW === 'custom' && <div style={{ width: 11, height: 11, borderRadius: '50%', background: c.lavender }} />}
                    </div>
                    <div style={{ fontSize: 12.5, fontWeight: 700 }}>カスタム日時で約束する</div>
                  </div>

                  <div style={{ display: 'flex', gap: 8, marginBottom: 8 }}>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 9.5, fontWeight: 700, color: c.mute, marginBottom: 4, letterSpacing: 0.4 }}>日付</div>
                      <div style={{
                        padding: '10px 12px', borderRadius: 8,
                        background: c.subtle, fontSize: 12, fontWeight: 600,
                        color: customDate ? c.ink : c.hint,
                        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                      }}>
                        <span>{customDate || '5/3 (土)'}</span>
                        <span style={{ fontSize: 10, color: c.lavender, fontWeight: 700 }}>▼</span>
                      </div>
                    </div>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 9.5, fontWeight: 700, color: c.mute, marginBottom: 4, letterSpacing: 0.4 }}>時刻</div>
                      <div style={{
                        padding: '10px 12px', borderRadius: 8,
                        background: c.subtle, fontSize: 12, fontWeight: 600,
                        color: customTime ? c.ink : c.hint,
                        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                      }}>
                        <span>{customTime || '14:00'}</span>
                        <span style={{ fontSize: 10, color: c.lavender, fontWeight: 700 }}>▼</span>
                      </div>
                    </div>
                  </div>

                  <div style={{ marginBottom: 10 }}>
                    <div style={{ fontSize: 9.5, fontWeight: 700, color: c.mute, marginBottom: 4, letterSpacing: 0.4 }}>場所（駅・施設名など）</div>
                    <div style={{
                      padding: '10px 12px', borderRadius: 8,
                      background: c.subtle, fontSize: 12, fontWeight: 600,
                      color: customLocation ? c.ink : c.hint,
                    }}>{customLocation || '東京駅 銀の鈴前'}</div>
                  </div>

                  {/* 自動登録 checkbox */}
                  <div
                    onClick={(e) => { e.stopPropagation(); setRegisterAsAW(!registerAsAW); }}
                    style={{
                      display: 'flex', alignItems: 'flex-start', gap: 8,
                      padding: '10px 10px',
                      borderRadius: 8,
                      background: registerAsAW ? `${c.lavender}10` : c.subtle,
                      cursor: 'pointer',
                      border: registerAsAW ? `1px solid ${c.lavender}33` : `1px solid transparent`,
                    }}>
                    <div style={{
                      width: 18, height: 18, borderRadius: 4, flexShrink: 0,
                      background: registerAsAW ? c.lavender : '#fff',
                      border: `1.5px solid ${registerAsAW ? c.lavender : c.divide}`,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      marginTop: 1,
                    }}>
                      {registerAsAW && (
                        <svg width="10" height="10" viewBox="0 0 11 11">
                          <path d="M2 5.5L4.5 8L9 3" stroke="#fff" strokeWidth="1.8" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
                        </svg>
                      )}
                    </div>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 12, fontWeight: 700 }}>この日時をAW（活動予定）に自動登録</div>
                      <div style={{ fontSize: 10, color: c.mute, marginTop: 2, lineHeight: 1.4 }}>
                        他の人とのマッチング・打診にも自動で利用されます。後から編集・削除も可能です。
                      </div>
                    </div>
                  </div>
                </div>

                {/* customの場合のmap preview */}
                {selectedAW === 'custom' && (
                  <div style={{
                    background: '#fff', borderRadius: 12,
                    border: `0.5px solid ${c.divide}`,
                    padding: 10, marginTop: 4, marginBottom: 8,
                  }}>
                    <div style={{
                      fontSize: 10, fontWeight: 700, color: c.mute,
                      padding: '0 4px 8px', letterSpacing: 0.4,
                    }}>📍 {customLocation || '東京駅 銀の鈴前'}</div>
                    <PS_MiniMap c={c} height={100} label={customLocation || '東京駅 銀の鈴前'} />
                  </div>
                )}
              </>
            )}
          </>
        ) : (
          // ─────── 提示物タブ（mine / theirs） ───────
          <>
            {/* Scenario hint */}
            <div style={{
              padding: '10px 12px', borderRadius: 10,
              background: `${c.lavender}10`, fontSize: 11.5,
              color: c.ink, lineHeight: 1.6, marginBottom: 12,
            }}>
              <span style={{
                fontSize: 9.5, fontWeight: 800, color: c.lavender,
                background: '#fff', padding: '2px 7px', borderRadius: 999,
                letterSpacing: 0.4, marginRight: 6,
              }}>{scenarioLabel}</span>
              {tab === 'mine'
                ? <>あなたの在庫から、<b>相手に提示するもの</b>を選びます。同じグッズを複数提示する時は ＋／− で個数を調整してください。</>
                : <>{partner.handle} の譲から、<b>あなたが受け取るもの</b>を選びます。<b style={{ color: c.lavender }}>★ wish 一致</b> はあなたのwishにある目印。</>
              }
            </div>

            {/* Filter chips */}
            <div style={{
              display: 'flex', gap: 6, marginBottom: 12, alignItems: 'center',
              overflowX: 'auto', WebkitOverflowScrolling: 'touch',
            }}>
              <span style={{
                fontSize: 9.5, fontWeight: 700, color: c.mute,
                letterSpacing: 0.4, flexShrink: 0,
                paddingRight: 4,
              }}>絞込</span>
              {['すべて', 'スア', 'ヒナ', 'トレカ', '生写真', '★ wish一致のみ'].map((f, i) => (
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

            {/* Section label */}
            <div style={{
              fontSize: 11, fontWeight: 700, color: c.mute,
              letterSpacing: 0.4, padding: '0 4px', marginBottom: 8,
            }}>{sectionLabel} ({items.length}件)</div>

            {/* Item list */}
            {items.map(it => {
              const stepperVisible = it.selected && it.qty > 1;
              return (
                <div key={it.id}
                  onClick={() => toggleItem(tab, it.id)}
                  style={{
                    background: '#fff', borderRadius: 12,
                    border: it.selected ? `1.5px solid ${c.lavender}` : `0.5px solid ${c.divide}`,
                    padding: '12px 14px', marginBottom: 8,
                    display: 'flex', alignItems: 'center', gap: 12,
                    boxShadow: it.selected ? `0 4px 12px ${c.lavender}22` : 'none',
                    cursor: 'pointer',
                  }}>
                  <div style={{
                    width: 20, height: 20, borderRadius: 5, flexShrink: 0,
                    background: it.selected ? c.lavender : '#fff',
                    border: `1.8px solid ${it.selected ? c.lavender : c.divide}`,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    {it.selected && (
                      <svg width="11" height="11" viewBox="0 0 11 11">
                        <path d="M2 5.5L4.5 8L9 3" stroke="#fff" strokeWidth="1.8" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
                      </svg>
                    )}
                  </div>
                  <div style={{
                    width: 36, height: 48, borderRadius: 6,
                    background: `repeating-linear-gradient(135deg, hsl(${it.hue}, 35%, 78%) 0 5px, hsl(${it.hue}, 35%, 70%) 5px 10px)`,
                    flexShrink: 0,
                  }} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginBottom: 2, flexWrap: 'wrap' }}>
                      <span style={{ fontSize: 13, fontWeight: 700 }}>{it.name}</span>
                      {it.wishMatch && (
                        <span style={{
                          fontSize: 9, fontWeight: 800, color: '#fff',
                          background: `linear-gradient(135deg, ${c.lavender}, ${c.pink})`,
                          padding: '2px 6px', borderRadius: 999, letterSpacing: 0.3,
                        }}>★ wish 一致</span>
                      )}
                    </div>
                    <div style={{
                      fontSize: 10.5, color: c.mute,
                      fontVariantNumeric: 'tabular-nums',
                    }}>
                      {it.sub} ・ 在庫 ×{it.qty}
                      {it.qty === 1 && it.selected && (
                        <span style={{ color: c.lavender, fontWeight: 700, marginLeft: 6 }}>選択中 ×1</span>
                      )}
                    </div>
                  </div>

                  {/* Quantity stepper */}
                  {stepperVisible && (
                    <div
                      onClick={(e) => e.stopPropagation()}
                      style={{
                        display: 'flex', alignItems: 'center', gap: 0,
                        background: c.subtle, borderRadius: 999,
                        padding: 3, flexShrink: 0,
                      }}>
                      <button
                        onClick={() => updateQty(tab, it.id, -1)}
                        disabled={it.selectedQty <= 1}
                        style={{
                          width: 24, height: 24, borderRadius: '50%',
                          border: 0,
                          background: it.selectedQty <= 1 ? '#fff' : c.lavender,
                          color: it.selectedQty <= 1 ? c.hint : '#fff',
                          fontSize: 16, fontWeight: 700, lineHeight: 1,
                          fontFamily: 'inherit',
                          cursor: it.selectedQty <= 1 ? 'not-allowed' : 'pointer',
                          display: 'flex', alignItems: 'center', justifyContent: 'center',
                        }}>−</button>
                      <span style={{
                        fontSize: 12.5, fontWeight: 800, minWidth: 28, textAlign: 'center',
                        color: c.ink, fontVariantNumeric: 'tabular-nums',
                        padding: '0 4px',
                      }}>{it.selectedQty} <span style={{ fontSize: 9, color: c.mute, fontWeight: 600 }}>/{it.qty}</span></span>
                      <button
                        onClick={() => updateQty(tab, it.id, +1)}
                        disabled={it.selectedQty >= it.qty}
                        style={{
                          width: 24, height: 24, borderRadius: '50%',
                          border: 0,
                          background: it.selectedQty >= it.qty ? '#fff' : c.lavender,
                          color: it.selectedQty >= it.qty ? c.hint : '#fff',
                          fontSize: 16, fontWeight: 700, lineHeight: 1,
                          fontFamily: 'inherit',
                          cursor: it.selectedQty >= it.qty ? 'not-allowed' : 'pointer',
                          display: 'flex', alignItems: 'center', justifyContent: 'center',
                        }}>＋</button>
                    </div>
                  )}
                </div>
              );
            })}

            {items.length === 0 && (
              <div style={{
                padding: '40px 20px', textAlign: 'center',
                background: '#fff', borderRadius: 14,
                border: `0.5px solid ${c.divide}`,
                color: c.mute, fontSize: 12, lineHeight: 1.6,
              }}>
                該当アイテムがありません
              </div>
            )}
          </>
        )}
      </div>

      {/* Bottom: 3行 summary + CTA */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '10px 18px 28px',
        background: 'rgba(255,255,255,0.96)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `0.5px solid ${c.divide}`,
      }}>
        {/* 提示物 summary */}
        <div style={{
          display: 'flex', alignItems: 'center',
          padding: '8px 12px', borderRadius: 10,
          background: (myCount > 0 && theirCount > 0) ? `${c.lavender}10` : c.subtle,
          fontSize: 11, marginBottom: 6, gap: 8,
        }}>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{
              fontSize: 9.5, fontWeight: 700, color: c.mute,
              letterSpacing: 0.4, marginBottom: 1,
            }}>あなたが出す ({myCount}枚)</div>
            <div style={{
              fontSize: 11, fontWeight: 700,
              whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
            }}>
              {myCount > 0
                ? summaryText(myItems)
                : <span style={{ color: c.hint, fontWeight: 500 }}>未選択</span>
              }
            </div>
          </div>
          <svg width="22" height="22" viewBox="0 0 22 22" style={{ flexShrink: 0 }}>
            <path d="M5 8h12M14 4l4 4-4 4M17 14H5M8 18l-4-4 4-4" stroke={c.lavender} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          <div style={{ flex: 1, minWidth: 0, textAlign: 'right' }}>
            <div style={{
              fontSize: 9.5, fontWeight: 700, color: c.mute,
              letterSpacing: 0.4, marginBottom: 1,
            }}>あなたが受け取る ({theirCount}枚)</div>
            <div style={{
              fontSize: 11, fontWeight: 700,
              whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
            }}>
              {theirCount > 0
                ? summaryText(theirItems)
                : <span style={{ color: c.hint, fontWeight: 500 }}>未選択</span>
              }
            </div>
          </div>
        </div>

        {/* 待ち合わせ summary */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8,
          padding: '8px 12px', borderRadius: 10,
          background: meetupSet ? `${c.lavender}10` : c.subtle,
          fontSize: 11, marginBottom: 8,
        }}>
          <span style={{ fontSize: 13 }}>📍</span>
          <div style={{
            fontSize: 9.5, fontWeight: 700, color: c.mute,
            letterSpacing: 0.4, flexShrink: 0,
          }}>待ち合わせ</div>
          <div style={{
            flex: 1, fontSize: 11, fontWeight: 700,
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
            textAlign: 'right',
          }}>
            {meetupSet
              ? meetupSummary
              : <span style={{ color: c.hint, fontWeight: 500 }}>未設定</span>
            }
          </div>
        </div>

        <button style={{
          width: '100%', padding: '14px',
          background: canProceed
            ? `linear-gradient(135deg, ${c.lavender}, ${c.sky})`
            : `${c.lavender}55`,
          color: '#fff', border: 0, borderRadius: 14,
          fontFamily: 'inherit', fontSize: 14, fontWeight: 700,
          letterSpacing: 0.3,
          boxShadow: canProceed ? `0 4px 14px ${c.lavender}55` : 'none',
          cursor: canProceed ? 'pointer' : 'not-allowed',
        }}>
          {canProceed
            ? '次へ：メッセージ作成 →'
            : (myCount === 0 || theirCount === 0)
              ? '提示物を両方から選んでください'
              : '待ち合わせを設定してください'
          }
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { ProposeSelectScreen, PS_MiniMap });
