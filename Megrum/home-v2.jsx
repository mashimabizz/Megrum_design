// home-v2.jsx
// Brand-aligned A variation: lavender purple + soft sky blue + pale pink accent
// Softer corners, more breathing room, additional info: oshi-match, rating, "rejected" filter hint

function HomeV2({ tweaks }) {
  const [tab, setTab] = React.useState(0);
  const tabs = ['完全マッチ', '私の譲が欲しい人', '私が欲しい譲を持つ人', '探索'];
  const tabCounts = [3, 12, 8, 64];
  const cards = React.useMemo(() => buildCards(701, 'LUMENA', 'スア'), []);

  // brand palette
  const lavender = tweaks.primary;   // #a695d8
  const sky      = tweaks.secondary; // #a8d4e6
  const pink     = tweaks.accent;    // #f3c5d4
  const ink      = '#3a324a';        // purple-tinted ink
  const mute     = 'rgba(58,50,74,0.55)';
  const subtle   = 'rgba(58,50,74,0.06)';
  const bg       = '#fbf9fc';        // very pale lavender white

  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: ink, fontFeatureSettings: '"palt"',
    }}>
      <div style={{ height: 60 }} />

      {/* sync strip — softer */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 8,
        padding: '7px 18px',
        background: '#fff',
        borderBottom: `0.5px solid ${subtle}`,
        fontSize: 11, color: ink, fontWeight: 400,
      }}>
        <div style={{
          width: 6, height: 6, borderRadius: '50%', background: '#e0a847',
          boxShadow: '0 0 0 3px rgba(224,168,71,0.18)',
        }} />
        <span style={{ fontWeight: 500 }}>オフライン中</span>
        <span style={{ color: 'rgba(58,50,74,0.3)' }}>·</span>
        <span style={{ color: mute, fontVariantNumeric: 'tabular-nums' }}>
          最終同期 3分前
        </span>
        <div style={{ flex: 1 }} />
        <span style={{ color: mute, fontVariantNumeric: 'tabular-nums' }}>
          ローカル保存 マッチ12 / 在庫24
        </span>
      </div>

      {/* Title row */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '16px 18px 6px',
      }}>
        <div>
          <div style={{
            fontSize: 11, color: lavender, fontWeight: 600, letterSpacing: 0.4,
          }}>
            推し：<span style={{ fontFamily: '"Inter Tight", -apple-system, system-ui', letterSpacing: 0.6 }}>LUMENA</span> · スア
          </div>
          <div style={{
            fontSize: 26, fontWeight: 700, lineHeight: 1.15, marginTop: 2,
            letterSpacing: 0.2, color: ink,
          }}>
            マッチング
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button style={{
            width: 38, height: 38, borderRadius: '50%',
            border: `0.5px solid ${subtle}`, background: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 1px 2px rgba(58,50,74,0.04)',
          }}>{Ic.search(16, ink)}</button>
          <button style={{
            width: 38, height: 38, borderRadius: '50%',
            border: `0.5px solid ${subtle}`, background: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 1px 2px rgba(58,50,74,0.04)',
          }}>{Ic.filter(14, ink)}</button>
        </div>
      </div>

      {/* Venue banner — pastel gradient with soft pin */}
      <div style={{
        margin: '10px 18px 0',
        padding: '14px 16px',
        borderRadius: 18,
        background: `linear-gradient(120deg, ${lavender}26, ${sky}30)`,
        border: `0.5px solid ${lavender}55`,
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <div style={{
          width: 40, height: 40, borderRadius: 12,
          background: `linear-gradient(135deg, ${lavender}, ${sky})`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexShrink: 0,
          boxShadow: `0 4px 10px ${lavender}33`,
        }}>
          {Ic.pin(15, '#fff')}
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 14.5, fontWeight: 700, letterSpacing: 0.2 }}>
            横浜アリーナ 周辺 <span style={{ fontSize: 10.5, fontWeight: 600, color: lavender, marginLeft: 4 }}>· AW 有効</span>
          </div>
          <div style={{
            fontSize: 11.5, color: mute, marginTop: 2,
            fontVariantNumeric: 'tabular-nums',
          }}>
            17:30〜18:30 · 半径500m · 時空交差でマッチング
          </div>
        </div>
        <button style={{
          appearance: 'none', border: 0,
          background: '#fff', color: lavender,
          padding: '6px 12px', borderRadius: 999,
          fontSize: 11.5, fontWeight: 600,
          fontFamily: 'inherit',
          boxShadow: '0 1px 3px rgba(58,50,74,0.08)',
        }}>変更</button>
      </div>

      {/* Tab chips */}
      <div style={{
        display: 'flex', gap: 6, padding: '14px 18px 8px',
        overflowX: 'auto', scrollbarWidth: 'none',
      }}>
        {tabs.map((t, i) => (
          <button
            key={t}
            onClick={() => setTab(i)}
            style={{
              appearance: 'none',
              display: 'inline-flex', alignItems: 'center', gap: 6,
              padding: '8px 14px', borderRadius: 999,
              border: tab === i ? `1px solid ${lavender}` : `0.5px solid ${subtle}`,
              background: tab === i ? lavender : '#fff',
              color: tab === i ? '#fff' : ink,
              fontFamily: 'inherit', fontSize: 12.5, fontWeight: 600,
              flexShrink: 0, letterSpacing: 0.2,
              boxShadow: tab === i ? `0 4px 10px ${lavender}3a` : 'none',
              transition: 'all 0.15s',
            }}
          >
            {i === 0 && Ic.matchBadge(8, tab === i ? '#fff' : lavender)}
            {t}
            <span style={{
              fontSize: 11, fontWeight: 600,
              color: tab === i ? 'rgba(255,255,255,0.85)' : mute,
              fontVariantNumeric: 'tabular-nums',
            }}>{tabCounts[i]}</span>
          </button>
        ))}
      </div>

      {/* Content */}
      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 110 }}>
        {tab === 0 && <CompleteList cards={cards.slice(0, 3)} colors={{ lavender, sky, pink, ink, mute }} />}
        {tab === 1 && <OneWayList cards={cards.slice(0, 8)} colors={{ lavender, sky, pink, ink, mute }} dir="theyWantYou" />}
        {tab === 2 && <OneWayList cards={cards.slice(0, 8)} colors={{ lavender, sky, pink, ink, mute }} dir="youWantThem" />}
        {tab === 3 && <ExploreFeedV2 cards={cards} colors={{ lavender, sky, pink, ink, mute }} />}

        {/* Footer hint */}
        {tab === 0 && (
          <div style={{
            margin: '14px 18px 0', padding: '12px 14px',
            borderRadius: 14, background: '#fff',
            border: `0.5px solid ${subtle}`,
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            fontSize: 12,
          }}>
            <div>
              <div style={{ color: ink, fontWeight: 500 }}>
                条件を緩めるとあと<b style={{ color: lavender }}>14件</b>
              </div>
              <div style={{ color: mute, fontSize: 10.5, marginTop: 2 }}>
                断った人2名は自動除外中
              </div>
            </div>
            <span style={{
              color: lavender, fontWeight: 600,
              display: 'flex', alignItems: 'center', gap: 4,
            }}>
              見直す {Ic.arrowR(11, lavender)}
            </span>
          </div>
        )}
      </div>

      <BottomNavV2 colors={{ lavender, sky, pink, ink, mute }} active="home" />
    </div>
  );
}

function CompleteList({ cards, colors }) {
  return (
    <div style={{ padding: '4px 0 0' }}>
      <div style={{ padding: '6px 18px 8px', display: 'flex', alignItems: 'baseline', gap: 8 }}>
        <span style={{
          display: 'inline-flex', alignItems: 'center', gap: 5,
          fontSize: 12, fontWeight: 700, color: colors.lavender,
        }}>
          <span style={{
            width: 8, height: 8, borderRadius: '50%', background: colors.lavender,
            boxShadow: `0 0 0 4px ${colors.lavender}25`,
          }} />
          完全マッチ
        </span>
        <span style={{ fontSize: 11, color: colors.mute }}>時空交差 · 双方の希望が一致</span>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12, padding: '0 18px' }}>
        {cards.map((c, i) => <CompleteCardV2 key={c.id} card={c} colors={colors} index={i} />)}
      </div>
    </div>
  );
}

function CompleteCardV2({ card, colors, index }) {
  // generated stats
  const rating = (4.5 + (index * 0.13) % 0.5).toFixed(1);
  const trades = card.trades;
  const cancels = (index === 1) ? 1 : 0;
  const isComplete = true;

  return (
    <div style={{
      background: '#fff', borderRadius: 20,
      border: `1px solid ${colors.lavender}30`,
      boxShadow: `0 1px 0 rgba(255,255,255,0.8) inset, 0 8px 24px ${colors.lavender}1a`,
      padding: 14, display: 'flex', flexDirection: 'column', gap: 12,
      position: 'relative', overflow: 'hidden',
    }}>
      {/* soft top tint */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 80,
        background: `linear-gradient(180deg, ${colors.lavender}10, transparent)`,
        pointerEvents: 'none',
      }} />

      {/* badge — pill instead of ribbon */}
      <div style={{
        position: 'absolute', top: 12, right: 12, zIndex: 2,
        display: 'inline-flex', alignItems: 'center', gap: 4,
        background: `linear-gradient(135deg, ${colors.lavender}, ${colors.sky})`,
        color: '#fff',
        padding: '4px 10px',
        fontSize: 9.5, fontWeight: 700, letterSpacing: 0.6,
        borderRadius: 999,
        boxShadow: `0 3px 8px ${colors.lavender}40`,
      }}>
        <svg width="9" height="9" viewBox="0 0 9 9">
          <path d="M4.5 1.5l1 2 2.2.3-1.6 1.5.4 2.2-2-1.1-2 1.1.4-2.2L1.3 3.8 3.5 3.5z" fill="#fff" />
        </svg>
        COMPLETE
      </div>

      {/* Header row */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, position: 'relative', paddingRight: 80 }}>
        <Avatar name={card.handle} size={40} hue={(index * 67 + 240) % 360} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontSize: 13.5, fontWeight: 700, color: colors.ink }}>
              @{card.handle}
            </span>
            {index !== 2 && (
              <span style={{
                display: 'inline-flex', alignItems: 'center', gap: 3,
                fontSize: 9.5, fontWeight: 700, letterSpacing: 0.3,
                color: colors.sky,
                background: `${colors.sky}26`,
                padding: '2px 7px', borderRadius: 999,
              }}>
                <span style={{ width: 5, height: 5, borderRadius: '50%', background: colors.sky }} />
                同イベント
              </span>
            )}
          </div>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 6, marginTop: 3,
            fontSize: 10.5, color: colors.mute,
            fontVariantNumeric: 'tabular-nums',
          }}>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3 }}>
              {Ic.pin(9, colors.mute)}
              約{card.distance}m
            </span>
            <span>·</span>
            <span>{card.lastActive}分前</span>
            <span>·</span>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3 }}>
              <svg width="9" height="9" viewBox="0 0 9 9"><path d="M4.5 0.5l1.2 2.4 2.7.4-2 1.9.5 2.6-2.4-1.2-2.4 1.2.5-2.6-2-1.9 2.7-.4z" fill={colors.mute}/></svg>
              {rating}
            </span>
            <span>·</span>
            <span>取引{trades}</span>
            {cancels > 0 && (
              <>
                <span>·</span>
                <span style={{ color: '#d97259' }}>キャンセル{cancels}</span>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Trade preview */}
      <div style={{
        display: 'grid', gridTemplateColumns: '1fr auto 1fr', gap: 10,
        padding: '12px 6px', background: colors.sky + '14',
        borderRadius: 14,
      }}>
        <div>
          <div style={{
            fontSize: 9.5, color: colors.mute, fontWeight: 700,
            letterSpacing: 0.6, marginBottom: 6, paddingLeft: 4,
          }}>
            相手の譲（{card.giveSamples.length}）
          </div>
          <div style={{ display: 'flex', gap: 4, paddingLeft: 4, flexWrap: 'wrap' }}>
            {card.giveSamples.slice(0, 4).map((s, i) => (
              <Tcg key={i} hue={(i * 60 + 260) % 360} label={s.member.slice(0, 1)} />
            ))}
          </div>
        </div>
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexDirection: 'column', gap: 4,
        }}>
          <div style={{
            width: 24, height: 24, borderRadius: '50%',
            background: colors.lavender,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: `0 2px 6px ${colors.lavender}55`,
          }}>{Ic.arrowR(12, '#fff')}</div>
          <div style={{
            width: 24, height: 24, borderRadius: '50%',
            background: colors.sky,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: `0 2px 6px ${colors.sky}55`,
          }}>{Ic.arrowL(12, '#fff')}</div>
        </div>
        <div>
          <div style={{
            fontSize: 9.5, color: colors.mute, fontWeight: 700,
            letterSpacing: 0.6, marginBottom: 6, textAlign: 'right', paddingRight: 4,
          }}>
            あなたの譲（{card.wantSamples.length}）
          </div>
          <div style={{
            display: 'flex', gap: 4, paddingRight: 4,
            flexWrap: 'wrap', justifyContent: 'flex-end',
          }}>
            {card.wantSamples.slice(0, 4).map((s, i) => (
              <Tcg key={i} hue={(i * 60 + 200) % 360} label={s.member.slice(0, 1)}
                   accent={`${colors.pink}cc`} />
            ))}
          </div>
        </div>
      </div>

      {/* CTA */}
      <div style={{ display: 'flex', gap: 8 }}>
        <button style={{
          flex: 1, height: 42, borderRadius: 14,
          background: `linear-gradient(135deg, ${colors.lavender}, ${colors.sky})`,
          color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 14, fontWeight: 700, letterSpacing: 0.4,
          boxShadow: `0 4px 12px ${colors.lavender}40`,
        }}>打診する</button>
        <button style={{
          height: 42, padding: '0 16px', borderRadius: 14,
          background: '#fff', color: colors.ink,
          border: `0.5px solid ${colors.lavender}55`,
          fontFamily: 'inherit', fontSize: 13, fontWeight: 600,
          display: 'inline-flex', alignItems: 'center', gap: 4,
        }}>相手プロフ {Ic.arrowR(11, colors.ink)}</button>
      </div>
    </div>
  );
}

function OneWayList({ cards, colors, dir }) {
  const isTheyWant = dir === 'theyWantYou';
  const tagBg = isTheyWant ? `${colors.lavender}1a` : `${colors.sky}26`;
  const tagFg = isTheyWant ? colors.lavender : '#5d96b3';

  return (
    <div style={{ padding: '6px 18px 0' }}>
      <div style={{
        fontSize: 11.5, color: colors.mute,
        padding: '4px 0 10px', lineHeight: 1.5,
      }}>
        {isTheyWant
          ? '相手はあなたの在庫を求めています。プロフを開いて相手の譲も確認できます。'
          : 'あなたが求める在庫を持っています。相手の希望に合う譲があれば打診できます。'}
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {cards.map((c, i) => {
          const rating = (4.3 + (i * 0.17) % 0.7).toFixed(1);
          return (
            <div key={c.id} style={{
              display: 'flex', alignItems: 'center', gap: 11,
              background: '#fff', padding: '12px 14px', borderRadius: 16,
              border: `0.5px solid ${colors.lavender}1a`,
              boxShadow: `0 2px 8px rgba(58,50,74,0.04)`,
            }}>
              <Avatar name={c.handle} size={38} hue={(i * 53 + 250) % 360} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 5, flexWrap: 'wrap' }}>
                  <span style={{ fontSize: 13, fontWeight: 700, color: colors.ink }}>
                    @{c.handle}
                  </span>
                  <span style={{
                    fontSize: 9.5, padding: '1px 7px', borderRadius: 999,
                    background: tagBg, color: tagFg,
                    fontWeight: 700, letterSpacing: 0.3,
                  }}>
                    {isTheyWant ? '求めてる' : '求める'}
                  </span>
                </div>
                <div style={{
                  fontSize: 10.5, color: colors.mute,
                  fontVariantNumeric: 'tabular-nums', marginTop: 2,
                }}>
                  約{c.distance}m · {c.lastActive}分前 · ★{rating}
                </div>
                <div style={{ display: 'flex', gap: 3, marginTop: 6, alignItems: 'center' }}>
                  {(isTheyWant ? c.giveSamples : c.wantSamples).slice(0, 4).map((s, j) => (
                    <Tcg key={j} w={20} h={28} hue={(j * 60 + 260) % 360}
                         accent={isTheyWant ? undefined : `${colors.pink}aa`} />
                  ))}
                  {(isTheyWant ? c.giveSamples : c.wantSamples).length > 4 && (
                    <span style={{ fontSize: 10, color: colors.mute, marginLeft: 2 }}>
                      +{(isTheyWant ? c.giveSamples : c.wantSamples).length - 4}
                    </span>
                  )}
                </div>
              </div>
              <button style={{
                padding: '8px 14px', borderRadius: 12,
                border: `0.5px solid ${colors.lavender}`,
                background: 'transparent', color: colors.lavender,
                fontWeight: 700, fontSize: 12, fontFamily: 'inherit', flexShrink: 0,
              }}>打診</button>
            </div>
          );
        })}
      </div>

      {/* Empty-state-like nudge to complete tab */}
      <div style={{
        marginTop: 14, padding: '12px 14px',
        borderRadius: 14,
        background: `linear-gradient(120deg, ${colors.pink}30, ${colors.sky}24)`,
        border: `0.5px solid ${colors.pink}55`,
        fontSize: 11.5, color: colors.ink,
      }}>
        <b style={{ fontSize: 12.5 }}>昇格のヒント</b>
        <div style={{ marginTop: 4, color: 'rgba(58,50,74,0.7)', lineHeight: 1.5 }}>
          相手プロフから他の在庫を見ると、完全マッチに昇格するかも。
        </div>
      </div>
    </div>
  );
}

function ExploreFeedV2({ cards, colors }) {
  return (
    <div style={{ padding: '4px 18px 0' }}>
      <div style={{
        fontSize: 11.5, color: colors.mute, marginBottom: 8,
      }}>
        半径500m · 64人がアクティブ
      </div>
      <div style={{
        display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10,
      }}>
        {cards.slice(0, 8).map((c, i) => (
          <div key={c.id} style={{
            background: '#fff', borderRadius: 16, padding: 8,
            border: `0.5px solid ${colors.lavender}1a`,
            boxShadow: '0 2px 8px rgba(58,50,74,0.04)',
          }}>
            <div style={{ display: 'flex', gap: 4, marginBottom: 8 }}>
              {c.giveSamples.slice(0, 2).map((s, j) => (
                <div key={j} style={{ flex: 1 }}>
                  <Tcg w="100%" h={76} hue={(j * 60 + i * 30 + 240) % 360} />
                </div>
              ))}
            </div>
            <div style={{ fontSize: 11.5, fontWeight: 700, color: colors.ink, padding: '0 2px' }}>
              @{c.handle}
            </div>
            <div style={{
              fontSize: 10, color: colors.mute, marginTop: 2, padding: '0 2px',
              fontVariantNumeric: 'tabular-nums',
            }}>
              {c.distance}m · {c.lastActive}分前
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function BottomNavV2({ colors, active }) {
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
      paddingBottom: 28, paddingTop: 10,
      background: 'rgba(255,255,255,0.92)',
      backdropFilter: 'blur(20px) saturate(180%)',
      WebkitBackdropFilter: 'blur(20px) saturate(180%)',
      borderTop: `0.5px solid ${colors.lavender}22`,
      display: 'flex', justifyContent: 'space-around',
    }}>
      {items.map((it) => {
        const isActive = active === it.id;
        return (
          <div key={it.id} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
          }}>
            <div style={{
              width: 24, height: 24, borderRadius: 8,
              background: isActive ? `linear-gradient(135deg, ${colors.lavender}, ${colors.sky})` : 'transparent',
              border: isActive ? 'none' : `1.5px solid ${colors.mute}`,
              boxShadow: isActive ? `0 3px 8px ${colors.lavender}40` : 'none',
            }} />
            <span style={{
              fontSize: 9.5, fontWeight: 600,
              color: isActive ? colors.lavender : colors.mute,
            }}>{it.label}</span>
          </div>
        );
      })}
    </div>
  );
}

Object.assign(window, { HomeV2 });

// __MVP_EXPORTS__
Object.assign(window, { HomeV2 });
