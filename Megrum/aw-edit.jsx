// aw-edit.jsx
// Availability Window edit — 2 variations: event-led (A) and location-led (B)
// + shared bottom sheet entry, AW list, archive, multi-AW support

const AW_C = (t) => ({
  lavender: t.primary,
  sky: t.secondary,
  pink: t.accent,
  ink: '#3a324a',
  mute: 'rgba(58,50,74,0.55)',
  faint: 'rgba(58,50,74,0.3)',
  subtle: 'rgba(58,50,74,0.06)',
  bg: '#fbf9fc',
});

// ─────────────────────────────────────────────────────────────
// AW List screen — shows active + scheduled + archived AWs
// ─────────────────────────────────────────────────────────────
function AWListScreen({ tweaks }) {
  const c = AW_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, fontFeatureSettings: '"palt"',
    }}>
      <div style={{ height: 60 }} />
      <div style={{
        padding: '12px 18px 10px', background: '#fff',
        borderBottom: `0.5px solid ${c.subtle}`,
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div>
          <div style={{ fontSize: 19, fontWeight: 800, letterSpacing: 0.3 }}>AW · 合流可能枠</div>
          <div style={{ fontSize: 11, color: c.mute, marginTop: 1 }}>Availability Window — 場所 × 時間 × 半径</div>
        </div>
        <button style={{
          padding: '8px 14px', borderRadius: 999,
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', border: 0, fontFamily: 'inherit',
          fontSize: 12, fontWeight: 700,
          boxShadow: `0 4px 10px ${c.lavender}50`,
          display: 'inline-flex', alignItems: 'center', gap: 5,
        }}>
          <svg width="11" height="11" viewBox="0 0 11 11"><path d="M5.5 1v9M1 5.5h9" stroke="#fff" strokeWidth="1.8" strokeLinecap="round"/></svg>
          AWを追加
        </button>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '14px 16px 30px' }}>
        {/* ACTIVE NOW */}
        <SectionHeading colors={c} pulse>
          ACTIVE NOW
          <span style={{ marginLeft: 6, fontSize: 10, color: c.lavender, fontWeight: 800 }}>· 1</span>
        </SectionHeading>
        <AWCard colors={c} active />

        {/* SCHEDULED */}
        <div style={{ height: 14 }} />
        <SectionHeading colors={c}>
          SCHEDULED
          <span style={{ marginLeft: 6, fontSize: 10, color: c.mute, fontWeight: 800 }}>· 3</span>
        </SectionHeading>
        <AWCard colors={c} scheduled
          venue="東京ドーム" event="STAR DAY 1" date="5/3 (土)" timeLabel="開演 18:00 — 17:30〜18:30" radius="500m" />
        <div style={{ height: 8 }} />
        <AWCard colors={c} scheduled eventless
          venue="渋谷駅周辺" date="明日 4/30 (火)" timeLabel="14:00 〜 16:00" radius="500m"
          note="近場で柔軟に交換できます · 動けます" />
        <div style={{ height: 8 }} />
        <AWCard colors={c} scheduled
          venue="さいたまスーパーアリーナ" event="LUMENA WORLD TOUR" date="5/10 (土)" timeLabel="開演 17:00 — 16:30〜17:30" radius="600m" />

        {/* ARCHIVE */}
        <div style={{ height: 14 }} />
        <SectionHeading colors={c}>
          自動アーカイブ
          <span style={{ marginLeft: 6, fontSize: 10, color: c.mute, fontWeight: 800 }}>· 直近</span>
        </SectionHeading>
        <div style={{
          padding: 12, borderRadius: 14,
          background: '#fff', border: `0.5px solid ${c.subtle}`,
          opacity: 0.75,
        }}>
          {[
            { v: 'マリンメッセ福岡', d: '4/20', n: '取引3件 ★4.9' },
            { v: '神戸ワールド記念ホール', d: '4/13', n: '取引2件 ★5.0' },
          ].map((a, i, arr) => (
            <div key={a.d} style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '8px 0',
              borderBottom: i < arr.length - 1 ? `0.5px solid ${c.subtle}` : 'none',
            }}>
              <div style={{
                width: 30, height: 30, borderRadius: 8,
                background: c.subtle,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 10, color: c.mute, fontWeight: 700,
              }}>済</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12, fontWeight: 600 }}>{a.v}</div>
                <div style={{ fontSize: 10, color: c.mute, marginTop: 1 }}>{a.d} · {a.n}</div>
              </div>
              <button style={{
                fontSize: 10, color: c.lavender, background: 'transparent',
                border: 0, fontFamily: 'inherit', cursor: 'pointer',
              }}>復元</button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function SectionHeading({ children, colors, pulse }) {
  return (
    <div style={{
      fontSize: 11, fontWeight: 800, color: colors.mute, letterSpacing: 0.7,
      padding: '0 4px 8px', display: 'flex', alignItems: 'center', gap: 6,
    }}>
      {pulse && (
        <span style={{
          width: 7, height: 7, borderRadius: '50%', background: '#22c55e',
          boxShadow: '0 0 0 3px rgba(34,197,94,0.25)',
        }} />
      )}
      {children}
    </div>
  );
}

function AWCard({ colors: c, active, scheduled, eventless, venue = '横浜アリーナ', event = 'LUMENA WORLD TOUR DAY 2', date = '今日 4/27 (日)', timeLabel = '開演 18:00 — 17:30〜18:30', radius = '500m', note, actionsOverride }) {
  return (
    <div style={{
      borderRadius: 16,
      background: active ? `linear-gradient(135deg, ${c.lavender}1c, ${c.sky}24)` : '#fff',
      border: active ? `1.5px solid ${c.lavender}88` : `0.5px solid ${c.subtle}`,
      overflow: 'hidden',
      boxShadow: active ? `0 8px 20px ${c.lavender}25` : '0 2px 8px rgba(58,50,74,0.04)',
    }}>
      {/* header strip */}
      <div style={{
        padding: '11px 14px 8px',
        display: 'flex', alignItems: 'center', gap: 8,
      }}>
        {active ? (
          <span style={{
            padding: '3px 8px', borderRadius: 999,
            background: '#22c55e', color: '#fff',
            fontSize: 9.5, fontWeight: 800, letterSpacing: 0.6,
            display: 'inline-flex', alignItems: 'center', gap: 4,
          }}>
            <span style={{ width: 5, height: 5, background: '#fff', borderRadius: '50%' }} />
            LIVE
          </span>
        ) : (
          <span style={{
            padding: '3px 8px', borderRadius: 999,
            background: c.subtle, color: c.mute,
            fontSize: 9.5, fontWeight: 800, letterSpacing: 0.6,
          }}>{date.split(' ')[0]}</span>
        )}
        <div style={{ flex: 1, fontSize: 11, color: c.mute, fontWeight: 600 }}>{date}</div>
        <button style={{
          width: 26, height: 26, borderRadius: '50%',
          background: 'transparent', border: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer',
        }}>
          <svg width="14" height="14" viewBox="0 0 14 14"><circle cx="3" cy="7" r="1.2" fill={c.mute}/><circle cx="7" cy="7" r="1.2" fill={c.mute}/><circle cx="11" cy="7" r="1.2" fill={c.mute}/></svg>
        </button>
      </div>

      <div style={{ padding: '0 14px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          {eventless && (
            <span style={{
              padding: '2px 7px', borderRadius: 5,
              background: c.subtle, color: c.mute,
              fontSize: 9.5, fontWeight: 800, letterSpacing: 0.5,
            }}>合流可能枠</span>
          )}
          <div style={{ fontSize: 15.5, fontWeight: 800, color: c.ink, letterSpacing: 0.2 }}>{venue}</div>
        </div>
        {!eventless && <div style={{ fontSize: 12, color: c.mute, marginTop: 2 }}>{event}</div>}
        {eventless && note && <div style={{ fontSize: 11.5, color: c.mute, marginTop: 2 }}>{note}</div>}
      </div>

      {/* meta rows */}
      <div style={{ padding: '10px 14px 6px', display: 'flex', flexDirection: 'column', gap: 4 }}>
        <Meta colors={c} icon="time" text={timeLabel} />
        <Meta colors={c} icon="pin" text={`半径 ${radius} 内 · ${eventless ? 'エリア内' : '会場周辺'}`} />
        <Meta colors={c} icon="hand" text={eventless ? '時間内で柔軟に動けます' : '会場近くで手渡し / 動けます'} />
      </div>

      {/* counters / actions for active */}
      {active && (
        <>
          <div style={{
            display: 'flex', borderTop: `0.5px solid ${c.lavender}33`,
            background: 'rgba(255,255,255,0.5)',
          }}>
            <Stat colors={c} v="14" label="完全マッチ" />
            <Divider c={c} />
            <Stat colors={c} v="2" label="打診中" />
            <Divider c={c} />
            <Stat colors={c} v="5分" label="クローズ通知まで" tone={c.pink} />
          </div>
          {actionsOverride || <div style={{
            padding: '10px 14px',
            display: 'flex', gap: 6,
            borderTop: `0.5px solid ${c.lavender}22`,
          }}>
            <button style={{
              flex: 1, padding: '10px 0', borderRadius: 10,
              background: `${c.pink}26`, color: c.ink,
              border: 0, fontFamily: 'inherit',
              fontSize: 12, fontWeight: 700,
            }}>一時無効</button>
            <button style={{
              flex: 1, padding: '10px 0', borderRadius: 10,
              background: `${c.lavender}1f`, color: c.lavender,
              border: 0, fontFamily: 'inherit',
              fontSize: 12, fontWeight: 700,
            }}>編集</button>
            <button style={{
              flex: 1, padding: '10px 0', borderRadius: 10,
              background: '#000', color: '#fff',
              border: 0, fontFamily: 'inherit',
              fontSize: 12, fontWeight: 700,
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 4,
            }}>
              <span style={{ fontFamily: '"Inter Tight", sans-serif', fontSize: 13, fontWeight: 800 }}>X</span>
              告知
            </button>
          </div>}
        </>
      )}
      {scheduled && <div style={{ height: 10 }} />}
    </div>
  );
}

function Meta({ colors: c, icon, text }) {
  const ic = {
    time: <><circle cx="6" cy="6" r="4.5" stroke={c.mute} strokeWidth="1.2" fill="none"/><path d="M6 3v3l2 1" stroke={c.mute} strokeWidth="1.2" strokeLinecap="round"/></>,
    pin: <><path d="M6 1.2c-2.4 0-4 1.7-4 4 0 2.7 4 5.6 4 5.6s4-2.9 4-5.6c0-2.3-1.6-4-4-4z" stroke={c.mute} strokeWidth="1.2" fill="none"/><circle cx="6" cy="5.2" r="1.2" stroke={c.mute} strokeWidth="1.2" fill="none"/></>,
    hand: <><path d="M3 6V4c0-.6.4-1 1-1s1 .4 1 1v2M5 6V3.5c0-.6.4-1 1-1s1 .4 1 1V6M7 6V4c0-.6.4-1 1-1s1 .4 1 1v3.5c0 1.5-1.3 3-3 3-1.7 0-3-1.5-3-3.5V6c0-.6-.4-1-1-1" stroke={c.mute} strokeWidth="1.2" fill="none" strokeLinecap="round"/></>,
  };
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
      <svg width="12" height="12" viewBox="0 0 12 12">{ic[icon]}</svg>
      <span style={{ fontSize: 11.5, color: c.ink }}>{text}</span>
    </div>
  );
}

function Stat({ colors: c, v, label, tone }) {
  return (
    <div style={{ flex: 1, padding: '8px 0', textAlign: 'center' }}>
      <div style={{
        fontSize: 17, fontWeight: 800, color: tone || c.lavender,
        fontVariantNumeric: 'tabular-nums', letterSpacing: 0.2,
      }}>{v}</div>
      <div style={{ fontSize: 10, color: c.mute, marginTop: 0 }}>{label}</div>
    </div>
  );
}
function Divider({ c }) { return <div style={{ width: 0.5, background: c.lavender + '33' }} />; }

// ─────────────────────────────────────────────────────────────
// Variation A — Event-led
// Pick event → location/radius derives → time presets
// ─────────────────────────────────────────────────────────────
function AWEditEventLed({ tweaks }) {
  const c = AW_C(tweaks);
  const [radius, setRadius] = React.useState(500);
  const [meeting, setMeeting] = React.useState(['near', 'mobile']);
  const [express, setExpress] = React.useState(true);
  const [closeBefore, setCloseBefore] = React.useState(15);
  const [time, setTime] = React.useState('preset'); // preset | manual

  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, fontFeatureSettings: '"palt"',
    }}>
      <div style={{ height: 60 }} />
      <SheetHeader colors={c} title="AW（合流可能枠）を作成" sub="🎤 イベントから埋める — 時間・場所をワンタップ補完（ショートカット）" />

      <div style={{ flex: 1, overflowY: 'auto', padding: '14px 16px 110px' }}>
        {/* Event picker — selected */}
        <FLabel colors={c}>イベント <span style={{ color: c.lavender }}>*</span></FLabel>
        <div style={{
          padding: 14, borderRadius: 16,
          background: `linear-gradient(120deg, ${c.lavender}22, ${c.sky}22)`,
          border: `0.5px solid ${c.lavender}55`,
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <div style={{
            width: 44, height: 44, borderRadius: 11,
            background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: '#fff', fontWeight: 800, fontSize: 12,
            flexShrink: 0, letterSpacing: 0.5,
            boxShadow: `0 4px 10px ${c.lavender}40`,
          }}>4/27</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 14, fontWeight: 800 }}>LUMENA WORLD TOUR DAY 2</div>
            <div style={{ fontSize: 11, color: c.mute, marginTop: 2 }}>
              横浜アリーナ · 開演 18:00 · あと1時間58分
            </div>
            <div style={{
              display: 'inline-flex', alignItems: 'center', gap: 4,
              marginTop: 6, padding: '2px 7px', borderRadius: 999,
              background: '#fff', fontSize: 9.5, fontWeight: 700, color: c.lavender,
            }}>
              <span style={{ width: 4, height: 4, borderRadius: '50%', background: c.lavender }} />
              マスタ登録済
            </div>
          </div>
          <button style={{
            fontSize: 11, color: c.lavender, background: 'transparent',
            border: 0, fontFamily: 'inherit', fontWeight: 700, cursor: 'pointer',
          }}>変更</button>
        </div>
        <div style={{
          marginTop: 6, padding: '0 4px',
          fontSize: 10.5, color: c.mute, display: 'flex', justifyContent: 'space-between',
        }}>
          <span>近日のイベントから選択</span>
          <span style={{ color: c.lavender, fontWeight: 700 }}>+ イベントを追加</span>
        </div>

        {/* Location auto-derived */}
        <FLabel colors={c} top={18}>位置と範囲</FLabel>
        <div style={{
          borderRadius: 16, overflow: 'hidden',
          background: '#fff', border: `0.5px solid ${c.subtle}`,
        }}>
          {/* mini map */}
          <MiniMap colors={c} radius={radius} />
          <div style={{ padding: '10px 12px', display: 'flex', alignItems: 'center', gap: 8 }}>
            <button style={{
              padding: '6px 10px', borderRadius: 999,
              background: c.subtle, color: c.ink,
              border: 0, fontFamily: 'inherit', fontSize: 11, fontWeight: 600,
              display: 'inline-flex', alignItems: 'center', gap: 4,
            }}>
              <svg width="11" height="11" viewBox="0 0 11 11"><circle cx="5.5" cy="5.5" r="1.4" fill={c.lavender}/><circle cx="5.5" cy="5.5" r="4.5" stroke={c.lavender} strokeWidth="0.8" fill="none"/></svg>
              現在地を使う
            </button>
            <button style={{
              padding: '6px 10px', borderRadius: 999,
              background: c.subtle, color: c.ink,
              border: 0, fontFamily: 'inherit', fontSize: 11, fontWeight: 600,
            }}>📍 ピン調整</button>
            <div style={{ flex: 1 }} />
            <span style={{ fontSize: 10, color: c.mute }}>キャッシュ済</span>
          </div>
          <div style={{ padding: '4px 14px 14px' }}>
            <div style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
              fontSize: 11, color: c.mute, fontWeight: 600, marginBottom: 6,
            }}>
              <span>半径</span>
              <span style={{
                color: c.lavender, fontWeight: 800, fontSize: 14,
                fontVariantNumeric: 'tabular-nums',
              }}>{radius >= 1000 ? `${(radius / 1000).toFixed(1)}km` : `${radius}m`}</span>
            </div>
            <input type="range" min="200" max="2000" step="100" value={radius}
              onChange={e => setRadius(+e.target.value)}
              style={{
                width: '100%', accentColor: c.lavender, height: 4,
              }} />
            <div style={{
              display: 'flex', justifyContent: 'space-between',
              fontSize: 9.5, color: c.faint, marginTop: 4,
              fontVariantNumeric: 'tabular-nums',
            }}>
              <span>200m</span><span>500m</span><span>1km</span><span>2km</span>
            </div>
          </div>
        </div>

        {/* Time */}
        <FLabel colors={c} top={18}>時間ウィンドウ</FLabel>
        <div style={{
          display: 'flex', gap: 4, padding: 3,
          background: c.subtle, borderRadius: 10, marginBottom: 10,
        }}>
          {[
            { id: 'preset', l: 'プリセット' },
            { id: 'manual', l: '手動調整' },
            { id: 'now', l: 'いま' },
          ].map(o => (
            <button key={o.id} onClick={() => setTime(o.id)} style={{
              flex: 1, height: 30, borderRadius: 8,
              background: time === o.id ? '#fff' : 'transparent',
              color: time === o.id ? c.lavender : c.mute,
              border: 0, fontFamily: 'inherit', fontSize: 11.5,
              fontWeight: time === o.id ? 700 : 500,
              boxShadow: time === o.id ? '0 1px 3px rgba(58,50,74,0.1)' : 'none',
            }}>{o.l}</button>
          ))}
        </div>
        {time === 'preset' && (
          <div style={{
            padding: 12, borderRadius: 14,
            background: '#fff', border: `0.5px solid ${c.subtle}`,
            display: 'flex', flexDirection: 'column', gap: 6,
          }}>
            {[
              { l: '開演前後30分', s: '17:30 〜 18:30', sel: true, sub: '推奨' },
              { l: '開演前30分のみ', s: '17:30 〜 18:00' },
              { l: '開演前後60分', s: '17:00 〜 19:00', sub: 'ロング' },
              { l: '終演後のみ', s: '20:30 〜 21:30' },
            ].map(p => (
              <button key={p.l} style={{
                padding: '10px 12px', borderRadius: 11,
                background: p.sel ? `${c.lavender}1c` : 'transparent',
                border: p.sel ? `1.5px solid ${c.lavender}` : `0.5px solid ${c.subtle}`,
                cursor: 'pointer', display: 'flex', alignItems: 'center',
                fontFamily: 'inherit', textAlign: 'left',
              }}>
                <div style={{ flex: 1 }}>
                  <div style={{
                    fontSize: 12.5, fontWeight: 700,
                    color: p.sel ? c.lavender : c.ink,
                    display: 'flex', alignItems: 'center', gap: 6,
                  }}>
                    {p.l}
                    {p.sub && (
                      <span style={{
                        fontSize: 9, padding: '1px 6px', borderRadius: 4,
                        background: p.sel ? c.lavender : c.subtle,
                        color: p.sel ? '#fff' : c.mute, fontWeight: 700,
                      }}>{p.sub}</span>
                    )}
                  </div>
                  <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1, fontVariantNumeric: 'tabular-nums' }}>{p.s}</div>
                </div>
                <div style={{
                  width: 18, height: 18, borderRadius: '50%',
                  border: `1.5px solid ${p.sel ? c.lavender : c.faint}`,
                  background: p.sel ? c.lavender : 'transparent',
                  color: '#fff', fontSize: 10, display: 'flex',
                  alignItems: 'center', justifyContent: 'center',
                }}>{p.sel ? '✓' : ''}</div>
              </button>
            ))}
          </div>
        )}

        {/* Now-chips for current usage */}
        <div style={{ marginTop: 8, display: 'flex', gap: 5, flexWrap: 'wrap' }}>
          {['いま', '15分後', '30分後', '19:00', '19:30'].map((t, i) => (
            <button key={t} style={{
              padding: '6px 11px', borderRadius: 999,
              background: '#fff', border: `0.5px solid ${c.subtle}`,
              color: c.ink, fontFamily: 'inherit', fontSize: 11, fontWeight: 600,
            }}>{t}</button>
          ))}
        </div>

        {/* Meeting prefs */}
        <FLabel colors={c} top={18}>現地交換の希望</FLabel>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {[
            { id: 'near', l: '会場近くで手渡し希望' },
            { id: 'mobile', l: '動けます（相手の場所もOK）' },
            { id: 'landmark', l: 'ランドマーク指定でやりとり', sub: 'トイレ前 / ドリンクコーナー / 関係者口' },
            { id: 'onsite', l: '現地オンリー（郵送交換不可）' },
          ].map(o => {
            const sel = meeting.includes(o.id);
            return (
              <button key={o.id} onClick={() => setMeeting(sel ? meeting.filter(x => x !== o.id) : [...meeting, o.id])} style={{
                padding: '10px 12px', borderRadius: 12,
                background: sel ? `${c.lavender}14` : '#fff',
                border: sel ? `1.5px solid ${c.lavender}` : `0.5px solid ${c.subtle}`,
                cursor: 'pointer', display: 'flex', alignItems: 'flex-start',
                gap: 10, fontFamily: 'inherit', textAlign: 'left',
              }}>
                <div style={{
                  width: 18, height: 18, borderRadius: 4, marginTop: 2,
                  border: `1.5px solid ${sel ? c.lavender : c.faint}`,
                  background: sel ? c.lavender : 'transparent',
                  color: '#fff', fontSize: 10, display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0,
                }}>{sel ? '✓' : ''}</div>
                <div>
                  <div style={{ fontSize: 12.5, fontWeight: 600, color: c.ink }}>{o.l}</div>
                  {o.sub && <div style={{ fontSize: 10, color: c.mute, marginTop: 2 }}>{o.sub}</div>}
                </div>
              </button>
            );
          })}
        </div>

        {/* Express + close */}
        <FLabel colors={c} top={18}>運用オプション</FLabel>
        <div style={{
          padding: 12, borderRadius: 14,
          background: '#fff', border: `0.5px solid ${c.subtle}`,
        }}>
          <ToggleRow colors={c} title="「今すぐ交換」エクスプレス" sub="5分以内に合流可能 — 完全マッチに即時通知" v={express} onChange={setExpress} accent={c.pink} />
          <div style={{ height: 0.5, background: c.subtle, margin: '8px 0' }} />
          <div style={{ marginBottom: 6 }}>
            <div style={{ fontSize: 12.5, fontWeight: 700, color: c.ink }}>クローズ時間（自動促進送信）</div>
            <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>AW終了 {closeBefore}分前に進行中の取引へ「もうすぐ終了」自動送信</div>
          </div>
          <div style={{ display: 'flex', gap: 5 }}>
            {[10, 15, 20, 30].map(m => (
              <button key={m} onClick={() => setCloseBefore(m)} style={{
                flex: 1, padding: '7px 0', borderRadius: 8,
                background: closeBefore === m ? c.lavender : c.subtle,
                color: closeBefore === m ? '#fff' : c.ink,
                border: 0, fontFamily: 'inherit', fontSize: 11.5, fontWeight: 700,
                fontVariantNumeric: 'tabular-nums',
              }}>{m}分前</button>
            ))}
          </div>
        </div>

        {/* Visibility note */}
        <div style={{
          marginTop: 14, padding: '10px 12px',
          fontSize: 11, color: c.mute,
          background: c.subtle, borderRadius: 10,
          lineHeight: 1.5, display: 'flex', gap: 8, alignItems: 'flex-start',
        }}>
          <svg width="13" height="13" viewBox="0 0 13 13" style={{ flexShrink: 0, marginTop: 1 }}><circle cx="6.5" cy="6.5" r="5" stroke={c.mute} strokeWidth="1" fill="none"/><path d="M6.5 4v3M6.5 8.5v.5" stroke={c.mute} strokeWidth="1.2" strokeLinecap="round"/></svg>
          <div>
            このAWは<b style={{ color: c.ink }}>すべてのユーザーに公開</b>されます。<br />
            保存と同時に <b style={{ color: c.ink }}>マッチを再計算</b> し、ホームに即反映。
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
          background: '#fff', color: c.ink, border: `0.5px solid ${c.subtle}`,
          fontFamily: 'inherit', fontSize: 13, fontWeight: 600,
          display: 'inline-flex', alignItems: 'center', gap: 5,
        }}>
          <span style={{ fontFamily: '"Inter Tight", sans-serif', fontWeight: 800 }}>X</span>
          告知も
        </button>
        <button style={{
          flex: 1, height: 48, borderRadius: 14,
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 14.5, fontWeight: 700, letterSpacing: 0.4,
          boxShadow: `0 6px 16px ${c.lavender}50`,
        }}>保存して有効化</button>
      </div>
    </div>
  );
}

function ToggleRow({ colors: c, title, sub, v, onChange, accent }) {
  const tone = accent || c.lavender;
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 12.5, fontWeight: 700, color: c.ink }}>{title}</div>
        {sub && <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>{sub}</div>}
      </div>
      <button onClick={() => onChange(!v)} style={{
        width: 44, height: 26, borderRadius: 13, border: 0,
        background: v ? tone : c.faint,
        position: 'relative', cursor: 'pointer', padding: 0,
        flexShrink: 0,
      }}>
        <div style={{
          position: 'absolute', top: 2, left: v ? 20 : 2,
          width: 22, height: 22, borderRadius: '50%',
          background: '#fff', boxShadow: '0 2px 4px rgba(0,0,0,0.15)',
          transition: 'left 0.2s',
        }} />
      </button>
    </div>
  );
}

function SheetHeader({ colors: c, title, sub }) {
  return (
    <div style={{
      padding: '10px 14px',
      borderBottom: `0.5px solid ${c.subtle}`,
      background: '#fff',
    }}>
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        marginBottom: 6,
      }}>
        <button style={{
          width: 32, height: 32, borderRadius: '50%',
          background: '#fff', border: `0.5px solid ${c.subtle}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="14" height="14" viewBox="0 0 14 14"><path d="M2 2l10 10M12 2L2 12" stroke={c.ink} strokeWidth="1.5" strokeLinecap="round"/></svg>
        </button>
        <div style={{ fontSize: 11, color: c.mute, fontWeight: 600 }}>登録中</div>
        <button style={{
          fontSize: 12, color: c.mute, background: 'transparent', border: 0,
          fontFamily: 'inherit', cursor: 'pointer',
        }}>クリア</button>
      </div>
      <div style={{ fontSize: 17, fontWeight: 800, letterSpacing: 0.3 }}>{title}</div>
      <div style={{ fontSize: 11, color: c.mute, marginTop: 2 }}>{sub}</div>
    </div>
  );
}

function FLabel({ children, colors, top = 14 }) {
  return (
    <div style={{
      fontSize: 11, fontWeight: 800, color: colors.mute,
      letterSpacing: 0.6, padding: '0 2px',
      marginTop: top, marginBottom: 6,
    }}>{children}</div>
  );
}

function MiniMap({ colors: c, radius = 500 }) {
  const r = Math.min(60, 12 + radius / 30);
  return (
    <div style={{
      height: 150, position: 'relative',
      background: `repeating-linear-gradient(45deg, ${c.sky}1a 0 8px, ${c.sky}28 8px 14px)`,
      overflow: 'hidden',
    }}>
      <svg width="100%" height="100%" viewBox="0 0 240 150" preserveAspectRatio="none" style={{ position: 'absolute', inset: 0 }}>
        <path d="M0 90 Q60 75 120 95 T240 80" stroke="#fff" strokeWidth="7" fill="none" opacity="0.8"/>
        <path d="M70 0 L110 150" stroke="#fff" strokeWidth="5" fill="none" opacity="0.55"/>
        <path d="M180 0 L150 150" stroke="#fff" strokeWidth="3" fill="none" opacity="0.4"/>
      </svg>
      {/* venue label */}
      <div style={{
        position: 'absolute', top: 36, left: 70,
        padding: '3px 8px', borderRadius: 6,
        background: 'rgba(255,255,255,0.92)', fontSize: 9.5, fontWeight: 700,
      }}>横浜アリーナ</div>
      {/* radius circle */}
      <div style={{
        position: 'absolute', top: '50%', left: '50%',
        transform: 'translate(-50%, -50%)',
        width: r * 2.2, height: r * 2.2, borderRadius: '50%',
        background: `${c.lavender}26`,
        border: `2px solid ${c.lavender}`,
        boxShadow: `0 0 0 1px ${c.lavender}66`,
      }} />
      {/* pin */}
      <div style={{
        position: 'absolute', top: '50%', left: '50%',
        transform: 'translate(-50%, -50%)',
        width: 22, height: 22, borderRadius: '50%',
        background: c.lavender,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: `0 0 0 4px #fff, 0 4px 10px ${c.lavender}55`,
      }}>
        <div style={{ width: 6, height: 6, background: '#fff', borderRadius: '50%' }} />
      </div>
      {/* radius label */}
      <div style={{
        position: 'absolute', bottom: 10, right: 10,
        padding: '4px 9px', borderRadius: 8,
        background: 'rgba(0,0,0,0.6)', color: '#fff',
        fontSize: 10, fontWeight: 700, fontVariantNumeric: 'tabular-nums',
        backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)',
      }}>半径 {radius >= 1000 ? `${(radius / 1000).toFixed(1)}km` : `${radius}m`}</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Variation B — Location-led
// Map first, big radius dial → events nearby → time
// ─────────────────────────────────────────────────────────────
function AWEditLocationLed({ tweaks }) {
  const c = AW_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, overflow: 'hidden', fontFeatureSettings: '"palt"',
    }}>
      <div style={{ height: 60 }} />

      {/* Map fills top half */}
      <div style={{ position: 'relative', height: 360, overflow: 'hidden' }}>
        <div style={{ position: 'absolute', inset: 0 }}>
          <svg width="100%" height="100%" viewBox="0 0 420 360" preserveAspectRatio="xMidYMid slice">
            <defs>
              <pattern id="hatch" x="0" y="0" width="14" height="14" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
                <rect width="14" height="14" fill={c.sky + '22'} />
                <rect width="6" height="14" fill={c.sky + '33'} />
              </pattern>
            </defs>
            <rect width="420" height="360" fill="url(#hatch)"/>
            <path d="M0 220 Q120 180 220 230 T420 200" stroke="#fff" strokeWidth="14" fill="none" opacity="0.9"/>
            <path d="M0 220 Q120 180 220 230 T420 200" stroke={c.sky + '66'} strokeWidth="2" fill="none" opacity="0.7"/>
            <path d="M120 0 L160 360" stroke="#fff" strokeWidth="9" fill="none" opacity="0.7"/>
            <path d="M310 0 L290 360" stroke="#fff" strokeWidth="6" fill="none" opacity="0.55"/>
            {/* blocks */}
            <rect x="160" y="40" width="60" height="36" fill="#fff" opacity="0.6" rx="3"/>
            <rect x="240" y="60" width="50" height="50" fill="#fff" opacity="0.6" rx="3"/>
            <rect x="40" y="240" width="80" height="60" fill="#fff" opacity="0.55" rx="3"/>
          </svg>
        </div>

        {/* Top sheet header */}
        <div style={{
          position: 'absolute', top: 0, left: 0, right: 0, padding: '10px 14px',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          background: 'linear-gradient(180deg, rgba(255,255,255,0.95), rgba(255,255,255,0))',
        }}>
          <button style={{
            width: 36, height: 36, borderRadius: '50%',
            background: '#fff', border: `0.5px solid ${c.subtle}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 2px 6px rgba(58,50,74,0.1)',
          }}>
            <svg width="14" height="14" viewBox="0 0 14 14"><path d="M2 2l10 10M12 2L2 12" stroke={c.ink} strokeWidth="1.5" strokeLinecap="round"/></svg>
          </button>
          <div style={{
            padding: '7px 12px', borderRadius: 999,
            background: '#fff', border: `0.5px solid ${c.subtle}`,
            fontSize: 12, fontWeight: 700,
            display: 'inline-flex', alignItems: 'center', gap: 6,
            boxShadow: '0 2px 6px rgba(58,50,74,0.1)',
          }}>
            <svg width="11" height="11" viewBox="0 0 11 11"><circle cx="5" cy="5" r="3.5" stroke={c.ink} strokeWidth="1.4" fill="none"/><path d="M8 8l2.5 2.5" stroke={c.ink} strokeWidth="1.4" strokeLinecap="round"/></svg>
            会場・場所を検索
          </div>
          <button style={{
            width: 36, height: 36, borderRadius: '50%',
            background: '#fff', border: `0.5px solid ${c.subtle}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 2px 6px rgba(58,50,74,0.1)',
          }}>
            <svg width="14" height="14" viewBox="0 0 14 14"><circle cx="7" cy="7" r="2" fill={c.lavender}/><circle cx="7" cy="7" r="5.5" stroke={c.lavender} strokeWidth="1" fill="none"/></svg>
          </button>
        </div>

        {/* radius circle on map */}
        <div style={{
          position: 'absolute', top: '50%', left: '50%',
          transform: 'translate(-50%, -50%)',
          width: 200, height: 200, borderRadius: '50%',
          background: `${c.lavender}1a`,
          border: `2px solid ${c.lavender}`,
          boxShadow: `0 0 0 1px ${c.lavender}66, 0 8px 28px ${c.lavender}40`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <div style={{
            width: 32, height: 32, borderRadius: '50%',
            background: c.lavender,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 0 0 5px #fff, 0 6px 14px rgba(0,0,0,0.2)',
          }}>
            <div style={{ width: 9, height: 9, background: '#fff', borderRadius: '50%' }} />
          </div>
        </div>

        {/* radius bubble */}
        <div style={{
          position: 'absolute', top: 100, right: 18,
          padding: '5px 10px', borderRadius: 999,
          background: c.lavender, color: '#fff',
          fontSize: 11, fontWeight: 800, letterSpacing: 0.5,
          fontVariantNumeric: 'tabular-nums',
          boxShadow: `0 4px 10px ${c.lavender}55`,
        }}>500m</div>

        {/* venue label */}
        <div style={{
          position: 'absolute', top: '55%', left: '50%',
          transform: 'translate(-50%, 0)',
          padding: '4px 10px', borderRadius: 8,
          background: '#fff', fontSize: 10.5, fontWeight: 700, color: c.ink,
          boxShadow: '0 2px 6px rgba(58,50,74,0.15)',
          marginTop: 70,
        }}>横浜アリーナ</div>

        {/* offline badge */}
        <div style={{
          position: 'absolute', top: 60, left: 14,
          padding: '4px 9px', borderRadius: 999,
          background: 'rgba(0,0,0,0.6)', color: '#fff',
          backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)',
          fontSize: 10, fontWeight: 600,
          display: 'inline-flex', alignItems: 'center', gap: 5,
        }}>
          <span style={{ width: 5, height: 5, borderRadius: '50%', background: '#e0a847' }} />
          地図キャッシュ
        </div>
      </div>

      {/* Bottom sheet */}
      <div style={{
        position: 'absolute', left: 0, right: 0, top: 360 + 60, bottom: 0,
        background: '#fff',
        borderTopLeftRadius: 22, borderTopRightRadius: 22,
        boxShadow: '0 -10px 30px rgba(58,50,74,0.12)',
        padding: '10px 16px 110px',
        overflowY: 'auto',
      }}>
        {/* drag handle */}
        <div style={{
          width: 36, height: 4, background: c.faint, borderRadius: 2,
          margin: '0 auto 12px',
        }} />

        {/* Radius slider — prominent */}
        <div style={{
          padding: 14, borderRadius: 14,
          background: `linear-gradient(120deg, ${c.lavender}10, ${c.sky}14)`,
          border: `0.5px solid ${c.lavender}33`,
        }}>
          <div style={{
            display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
            marginBottom: 6,
          }}>
            <div style={{ fontSize: 12, fontWeight: 700, color: c.mute }}>マッチ範囲</div>
            <div style={{
              fontSize: 22, fontWeight: 800, color: c.lavender,
              fontVariantNumeric: 'tabular-nums', letterSpacing: 0.3,
            }}>500m</div>
          </div>
          <input type="range" min="200" max="2000" step="100" defaultValue="500"
            style={{ width: '100%', accentColor: c.lavender, height: 4 }} />
          <div style={{
            display: 'flex', justifyContent: 'space-between',
            fontSize: 9.5, color: c.mute, marginTop: 4,
            fontVariantNumeric: 'tabular-nums',
          }}>
            <span>200m</span><span>2km</span>
          </div>
        </div>

        {/* Events nearby */}
        <FLabel colors={c} top={16}>このエリアの近日イベント <span style={{ color: c.faint, fontWeight: 600 }}>(任意・加点要素)</span></FLabel>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {/* No-event option — explicit */}
          <button style={{
            padding: '11px 12px', borderRadius: 12,
            background: '#fff',
            border: `1.5px solid ${c.lavender}`,
            cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 10,
            fontFamily: 'inherit', textAlign: 'left',
          }}>
            <div style={{
              width: 38, height: 38, borderRadius: 10,
              background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
              color: '#fff',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
            }}>
              <svg width="18" height="18" viewBox="0 0 18 18"><circle cx="9" cy="9" r="6" stroke="#fff" strokeWidth="1.4" fill="none"/><path d="M9 5v4l3 2" stroke="#fff" strokeWidth="1.6" fill="none" strokeLinecap="round"/></svg>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 12.5, fontWeight: 700, color: c.ink }}>イベントなしで設定</div>
              <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>
                「明日渋谷で1時間」「陸上てら30分」など · 場所×時間だけでマッチング
              </div>
            </div>
            <div style={{
              width: 18, height: 18, borderRadius: '50%',
              border: `1.5px solid ${c.lavender}`,
              background: c.lavender,
              color: '#fff', fontSize: 10, display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
            }}>✓</div>
          </button>

          {[
            { d: '今日', date: '4/27', name: 'LUMENA WORLD TOUR DAY 2', t: '開演 18:00', k: '横浜アリーナ' },
            { d: '今日', date: '4/27', name: 'STAR Fan Meeting', t: '開演 19:00', k: '横浜BUNTAI' },
            { d: '明日', date: '4/28', name: 'AURORA POP-UP STORE', t: '11:00 - 20:00', k: '横浜駅西口' },
          ].map((e, i) => (
            <button key={i} style={{
              padding: '11px 12px', borderRadius: 12,
              background: e.sel ? `${c.lavender}14` : '#fff',
              border: e.sel ? `1.5px solid ${c.lavender}` : `0.5px solid ${c.subtle}`,
              cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 10,
              fontFamily: 'inherit', textAlign: 'left',
            }}>
              <div style={{
                width: 38, height: 38, borderRadius: 10,
                background: e.sel ? `linear-gradient(135deg, ${c.lavender}, ${c.sky})` : c.subtle,
                color: e.sel ? '#fff' : c.mute,
                display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                fontSize: 9, fontWeight: 700, lineHeight: 1.1,
                flexShrink: 0,
              }}>
                <span>{e.d}</span>
                <span style={{ fontSize: 10 }}>{e.date}</span>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 12.5, fontWeight: 700, color: c.ink }}>{e.name}</div>
                <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1, fontVariantNumeric: 'tabular-nums' }}>
                  {e.k} · {e.t}
                </div>
              </div>
              <div style={{
                width: 18, height: 18, borderRadius: '50%',
                border: `1.5px solid ${e.sel ? c.lavender : c.faint}`,
                background: e.sel ? c.lavender : 'transparent',
                color: '#fff', fontSize: 10, display: 'flex', alignItems: 'center', justifyContent: 'center',
                flexShrink: 0,
              }}>{e.sel ? '✓' : ''}</div>
            </button>
          ))}
          <button style={{
            padding: '8px 12px', borderRadius: 10,
            background: '#fff', border: `1px dashed ${c.lavender}88`,
            color: c.lavender, fontFamily: 'inherit',
            fontSize: 11.5, fontWeight: 700, cursor: 'pointer',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6,
          }}>
            <svg width="11" height="11" viewBox="0 0 11 11"><path d="M5.5 1v9M1 5.5h9" stroke={c.lavender} strokeWidth="1.6" strokeLinecap="round"/></svg>
            イベントを追加（リストにない）
          </button>
        </div>

        {/* Now/X-min/Time chips */}
        <FLabel colors={c} top={14}>有効時間</FLabel>
        <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap', marginBottom: 6 }}>
          {[
            { l: 'いま', sel: true },
            { l: '15分後' },
            { l: '30分後' },
            { l: '19:00' },
            { l: '19:30' },
          ].map(t => (
            <button key={t.l} style={{
              padding: '7px 13px', borderRadius: 999,
              background: t.sel ? c.lavender : '#fff',
              color: t.sel ? '#fff' : c.ink,
              border: t.sel ? 0 : `0.5px solid ${c.subtle}`,
              fontFamily: 'inherit', fontSize: 11.5, fontWeight: 600,
            }}>{t.l}</button>
          ))}
        </div>
        <div style={{
          padding: '10px 12px', borderRadius: 12,
          background: c.subtle, fontSize: 11, color: c.mute,
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        }}>
          <span>〜</span>
          <span style={{ fontVariantNumeric: 'tabular-nums', color: c.ink, fontWeight: 700 }}>21:30</span>
          <span>(終演 +30分)</span>
        </div>

        {/* Quick toggles */}
        <div style={{
          marginTop: 12, padding: 12, borderRadius: 14,
          background: '#fff', border: `0.5px solid ${c.subtle}`,
        }}>
          <ToggleRow colors={c} title="今すぐ交換 (5分以内)" sub="完全マッチ相手に即通知" v={true} onChange={() => {}} accent={c.pink} />
          <div style={{ height: 0.5, background: c.subtle, margin: '8px 0' }} />
          <ToggleRow colors={c} title="動けます" sub="相手の場所近くもOK" v={true} onChange={() => {}} />
        </div>
      </div>

      {/* CTA */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '12px 18px 30px',
        background: 'rgba(255,255,255,0.96)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `0.5px solid ${c.lavender}22`,
        display: 'flex', gap: 8,
      }}>
        <button style={{
          flex: 1, height: 48, borderRadius: 14,
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 14.5, fontWeight: 700, letterSpacing: 0.4,
          boxShadow: `0 6px 16px ${c.lavender}50`,
        }}>有効化 — 時空交差 14件</button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Other-user AW preview card (for profile)
// ─────────────────────────────────────────────────────────────
function OtherAWPreviewScreen({ tweaks }) {
  const c = AW_C(tweaks);
  // Override: in other-user view, hide self CTAs and show DM/Follow instead
  const otherActions = (
    <div style={{
      padding: '10px 14px',
      display: 'flex', gap: 6,
      borderTop: `0.5px solid ${c.lavender}22`,
    }}>
      <button style={{
        flex: 1, padding: '10px 0', borderRadius: 10,
        background: '#fff', color: c.ink,
        border: `0.5px solid ${c.subtle}`,
        fontFamily: 'inherit', fontSize: 12, fontWeight: 700,
      }}>フォロー</button>
      <button style={{
        flex: 2, padding: '10px 0', borderRadius: 10,
        background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
        color: '#fff', border: 0, fontFamily: 'inherit',
        fontSize: 12, fontWeight: 700,
        boxShadow: `0 4px 10px ${c.lavender}40`,
      }}>DMで打診する</button>
    </div>
  );
  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, fontFeatureSettings: '"palt"',
    }}>
      <div style={{ height: 60 }} />
      <div style={{
        padding: '10px 14px',
        borderBottom: `0.5px solid ${c.subtle}`, background: '#fff',
        display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <button style={{
          width: 32, height: 32, borderRadius: '50%',
          background: '#fff', border: `0.5px solid ${c.subtle}`,
        }}>
          <svg width="9" height="14" viewBox="0 0 9 14"><path d="M7 1L2 7l5 6" stroke={c.ink} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </button>
        <div style={{ fontSize: 14, fontWeight: 700 }}>@lumi_sua の予定</div>
      </div>
      <div style={{ flex: 1, overflowY: 'auto', padding: '14px 16px 30px' }}>
        <SectionHeading colors={c} pulse>
          ACTIVE NOW
        </SectionHeading>
        <AWCard colors={c} active actionsOverride={otherActions} />
        <div style={{ height: 14 }} />
        <SectionHeading colors={c}>
          NEXT
        </SectionHeading>
        <AWCard colors={c} scheduled
          venue="さいたまスーパーアリーナ" event="LUMENA WORLD TOUR" date="5/10 (土)" timeLabel="開演 17:00 — 16:30〜17:30" radius="600m" />
        <div style={{ height: 14 }} />
        <div style={{
          padding: '12px 14px', borderRadius: 14,
          background: `linear-gradient(120deg, ${c.lavender}1a, ${c.sky}22)`,
          border: `0.5px solid ${c.lavender}44`,
          fontSize: 12, lineHeight: 1.5, color: c.ink,
        }}>
          あなたと <b style={{ color: c.lavender }}>2件のAW</b> が時空交差中 — 同じ場所・近い時間に居る可能性大
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { AWListScreen, AWEditEventLed, AWEditLocationLed, OtherAWPreviewScreen });

// ─────────────────────────────────────────────────────────────
// AW Add Entry — 2-choice bottom sheet (location-led default / event-led shortcut)
// ─────────────────────────────────────────────────────────────
function AWAddEntry({ tweaks }) {
  const c = AW_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, overflow: 'hidden', fontFeatureSettings: '"palt"',
    }}>
      <div style={{ height: 60 }} />

      {/* Dimmed backdrop hint — implies bottom sheet */}
      <div style={{
        position: 'absolute', top: 60, left: 0, right: 0, bottom: 0,
        background: `linear-gradient(180deg, rgba(58,50,74,0.18), rgba(58,50,74,0.32))`,
      }} />

      {/* Bottom sheet */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        background: '#fff',
        borderTopLeftRadius: 22, borderTopRightRadius: 22,
        boxShadow: '0 -10px 40px rgba(58,50,74,0.18)',
        padding: '10px 18px 30px',
      }}>
        {/* drag handle */}
        <div style={{
          width: 36, height: 4, background: c.faint, borderRadius: 2,
          margin: '0 auto 14px',
        }} />

        <div style={{ marginBottom: 4, padding: '0 2px' }}>
          <div style={{ fontSize: 18, fontWeight: 800, letterSpacing: 0.3 }}>AW を追加</div>
          <div style={{ fontSize: 11.5, color: c.mute, marginTop: 3, lineHeight: 1.5 }}>
            合流可能枠 = <b style={{ color: c.ink }}>場所 × 時間 × 半径</b>。
            イベントは任意のタグ。
          </div>
        </div>

        {/* Primary: Location-led — default */}
        <div style={{ marginTop: 14 }}>
          <button style={{
            width: '100%', padding: '16px 16px 14px',
            borderRadius: 16,
            background: `linear-gradient(120deg, ${c.lavender}1c, ${c.sky}24)`,
            border: `1.5px solid ${c.lavender}`,
            cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
            display: 'flex', alignItems: 'flex-start', gap: 12,
            position: 'relative',
          }}>
            <span style={{
              position: 'absolute', top: 10, right: 10,
              padding: '2px 7px', borderRadius: 999,
              background: c.lavender, color: '#fff',
              fontSize: 9, fontWeight: 800, letterSpacing: 0.5,
            }}>おすすめ</span>
            <div style={{
              width: 44, height: 44, borderRadius: 12,
              background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
              boxShadow: `0 6px 14px ${c.lavender}55`,
            }}>
              <svg width="22" height="22" viewBox="0 0 22 22">
                <path d="M11 2.5c-3.6 0-6 2.5-6 6 0 4 6 11 6 11s6-7 6-11c0-3.5-2.4-6-6-6z" stroke="#fff" strokeWidth="1.6" fill="none"/>
                <circle cx="11" cy="9" r="2.2" stroke="#fff" strokeWidth="1.6" fill="none"/>
              </svg>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 14.5, fontWeight: 800, color: c.ink, letterSpacing: 0.2 }}>
                📍 場所から作る
              </div>
              <div style={{
                fontSize: 11.5, color: c.mute, marginTop: 3, lineHeight: 1.5,
              }}>
                地図でピン → 半径ダイヤル → 時間。<br />
                <span style={{ color: c.ink, fontWeight: 600 }}>「明日 渋谷で1時間」「会場周辺」</span>
                どちらでも対応。イベント紐付けは任意。
              </div>
              {/* example chips */}
              <div style={{ display: 'flex', gap: 4, marginTop: 8, flexWrap: 'wrap' }}>
                {['イベントなしOK', 'フレキシブル', '半径200m〜2km'].map(l => (
                  <span key={l} style={{
                    fontSize: 9.5, padding: '2px 8px', borderRadius: 999,
                    background: '#fff', color: c.ink, fontWeight: 600,
                    border: `0.5px solid ${c.lavender}33`,
                  }}>{l}</span>
                ))}
              </div>
            </div>
          </button>
        </div>

        {/* Secondary: Event-led — shortcut */}
        <div style={{ marginTop: 8 }}>
          <button style={{
            width: '100%', padding: '14px 16px',
            borderRadius: 16,
            background: '#fff',
            border: `0.5px solid ${c.subtle}`,
            cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
            display: 'flex', alignItems: 'flex-start', gap: 12,
            position: 'relative',
          }}>
            <span style={{
              position: 'absolute', top: 10, right: 10,
              padding: '2px 7px', borderRadius: 999,
              background: c.subtle, color: c.mute,
              fontSize: 9, fontWeight: 800, letterSpacing: 0.5,
            }}>ショートカット</span>
            <div style={{
              width: 44, height: 44, borderRadius: 12,
              background: c.subtle,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
            }}>
              <svg width="22" height="22" viewBox="0 0 22 22">
                <rect x="4" y="6" width="14" height="13" rx="2" stroke={c.ink} strokeWidth="1.4" fill="none"/>
                <path d="M4 10h14M8 3v4M14 3v4" stroke={c.ink} strokeWidth="1.4" strokeLinecap="round"/>
              </svg>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 14.5, fontWeight: 800, color: c.ink, letterSpacing: 0.2 }}>
                🎤 イベントから埋める
              </div>
              <div style={{
                fontSize: 11.5, color: c.mute, marginTop: 3, lineHeight: 1.5,
              }}>
                ライブ・ファンミ・ポップアップ等を選ぶと
                <span style={{ color: c.ink, fontWeight: 600 }}> 会場座標と開演±30分が自動入力</span>。
                1タップで保存できる。
              </div>
              {/* upcoming preview */}
              <div style={{
                marginTop: 8, padding: '7px 10px',
                background: c.bg, borderRadius: 10,
                fontSize: 10.5, color: c.ink,
                display: 'flex', alignItems: 'center', gap: 6,
                fontVariantNumeric: 'tabular-nums',
              }}>
                <span style={{
                  width: 6, height: 6, borderRadius: '50%', background: c.pink,
                }} />
                <b>4/27 今夜</b>
                <span style={{ color: c.mute }}>LUMENA WORLD TOUR DAY 2 — 横浜アリーナ</span>
              </div>
            </div>
          </button>
        </div>

        {/* Cancel */}
        <button style={{
          width: '100%', marginTop: 12, padding: '12px 0',
          borderRadius: 12, background: 'transparent',
          border: 0, color: c.mute,
          fontFamily: 'inherit', fontSize: 13, fontWeight: 600,
        }}>キャンセル</button>
      </div>
    </div>
  );
}

Object.assign(window, { AWAddEntry });
