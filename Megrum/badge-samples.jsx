// ─────────────────────────────────────────────────────────────
// badge-samples.jsx — マッチカードの「推し一致」バッジ 4パターン比較
// 案A 現状 / 案B 簡潔（推し名別行） / 案C 詳細（インライン）/ 案D 絵文字コンパクト
// ─────────────────────────────────────────────────────────────

const BS_C = (t) => ({
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
});

function BSCard({ tweaks, variant }) {
  const c = BS_C(tweaks);
  // Variant config: A 現状 / B 簡潔別行 / C 詳細インライン / D 絵文字コンパクト
  return (
    <div style={{
      width: '100%', height: '100%',
      background: c.bg, padding: '40px 16px',
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, boxSizing: 'border-box', overflowY: 'auto',
      fontFeatureSettings: '"palt"',
    }}>
      <div style={{
        fontSize: 11, fontWeight: 800, color: c.mute,
        letterSpacing: 0.5, marginBottom: 4, padding: '0 4px',
      }}>{variant.label}</div>
      <div style={{
        fontSize: 13, color: c.ink, lineHeight: 1.5, marginBottom: 16, padding: '0 4px',
      }}>{variant.desc}</div>

      {/* === Card 1: 完全マッチ・グループ＋メンバー一致 === */}
      <div style={{
        background: '#fff', borderRadius: 16,
        border: `1.5px solid ${c.lavender}33`,
        padding: '14px', marginBottom: 12,
        boxShadow: `0 4px 14px ${c.lavender}1a`,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
          <div style={{
            width: 40, height: 40, borderRadius: 20,
            background: `linear-gradient(135deg, ${c.lavender}55, ${c.pink}55)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 12, fontWeight: 800, color: c.ink,
          }}>P</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, flexWrap: 'wrap' }}>
              <span style={{ fontSize: 13, fontWeight: 700 }}>@plum_92</span>
              {variant.id === 'A' && <BadgeA c={c} />}
              {variant.id === 'B' && <BadgeB c={c} target="member" />}
              {variant.id === 'C' && <BadgeC c={c} target="member" name="スア" />}
              {variant.id === 'D' && <BadgeD c={c} name="スア" />}
              <span style={{
                display: 'inline-flex', alignItems: 'center', gap: 3,
                fontSize: 9.5, fontWeight: 700, color: c.sky,
                background: `${c.sky}26`,
                padding: '2px 7px', borderRadius: 999,
              }}>
                <span style={{ width: 5, height: 5, borderRadius: '50%', background: c.sky }} />
                同イベント
              </span>
            </div>
            {variant.id === 'B' && (
              <div style={{
                fontSize: 10, color: c.lavender, fontWeight: 600,
                marginTop: 2, paddingLeft: 0,
              }}>推し: LUMENA・スア</div>
            )}
            <div style={{
              fontSize: 10.5, color: c.mute, marginTop: variant.id === 'B' ? 2 : 3,
              fontVariantNumeric: 'tabular-nums',
            }}>169m ・ 24分前 ・ ★4.5 ・ 取引157</div>
          </div>
          <span style={{
            position: 'absolute', right: 14, top: 14,
            fontSize: 9, fontWeight: 800, color: '#fff',
            background: `linear-gradient(135deg, ${c.lavender}, ${c.pink})`,
            padding: '3px 9px', borderRadius: 999,
            letterSpacing: 0.4,
          }}>★ COMPLETE</span>
        </div>
        <div style={{
          padding: '10px 12px', borderRadius: 10,
          background: c.subtle, fontSize: 11.5,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
            <span style={{ color: c.mute, fontSize: 10 }}>譲</span>
            <span style={{ fontWeight: 600 }}>スア WT01 トレカ</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ color: c.mute, fontSize: 10 }}>求</span>
            <span style={{ fontWeight: 600 }}>ヒナ 5th 生写真</span>
          </div>
        </div>
      </div>

      {/* === Card 2: グループ一致だけ === */}
      <div style={{
        background: '#fff', borderRadius: 16,
        border: `0.5px solid ${c.divide}`,
        padding: '14px', marginBottom: 12,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
          <div style={{
            width: 40, height: 40, borderRadius: 20,
            background: `linear-gradient(135deg, ${c.sky}55, ${c.lavender}55)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 12, fontWeight: 800, color: c.ink,
          }}>I</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, flexWrap: 'wrap' }}>
              <span style={{ fontSize: 13, fontWeight: 700 }}>@iam_jiyoung</span>
              {variant.id === 'A' && <BadgeA c={c} />}
              {variant.id === 'B' && <BadgeB c={c} target="group" />}
              {variant.id === 'C' && <BadgeC c={c} target="group" name="LUMENA" />}
              {variant.id === 'D' && <BadgeD c={c} name="LUMENA" group />}
            </div>
            {variant.id === 'B' && (
              <div style={{
                fontSize: 10, color: c.lavender, fontWeight: 600,
                marginTop: 2, paddingLeft: 0,
              }}>推し: LUMENA（グループ）</div>
            )}
            <div style={{
              fontSize: 10.5, color: c.mute, marginTop: variant.id === 'B' ? 2 : 3,
              fontVariantNumeric: 'tabular-nums',
            }}>182m ・ 20分前 ・ ★4.6 ・ 取引109</div>
          </div>
        </div>
        <div style={{
          padding: '10px 12px', borderRadius: 10,
          background: c.subtle, fontSize: 11.5,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
            <span style={{ color: c.mute, fontSize: 10 }}>譲</span>
            <span style={{ fontWeight: 600 }}>ヒナ POPUP 缶バッジ</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ color: c.mute, fontSize: 10 }}>求</span>
            <span style={{ fontWeight: 600 }}>スア STUDIO トレカ</span>
          </div>
        </div>
      </div>

      {/* === Card 3: 箱推し一致 === */}
      <div style={{
        background: '#fff', borderRadius: 16,
        border: `0.5px solid ${c.divide}`,
        padding: '14px', marginBottom: 12,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
          <div style={{
            width: 40, height: 40, borderRadius: 20,
            background: `linear-gradient(135deg, ${c.pink}55, ${c.sky}55)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 12, fontWeight: 800, color: c.ink,
          }}>M</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, flexWrap: 'wrap' }}>
              <span style={{ fontSize: 13, fontWeight: 700 }}>@mochiko_724</span>
              {variant.id === 'A' && <BadgeA c={c} />}
              {variant.id === 'B' && <BadgeB c={c} target="box" />}
              {variant.id === 'C' && <BadgeC c={c} target="box" name="LUMENA" />}
              {variant.id === 'D' && <BadgeD c={c} name="箱推し" box />}
            </div>
            {variant.id === 'B' && (
              <div style={{
                fontSize: 10, color: c.lavender, fontWeight: 600,
                marginTop: 2, paddingLeft: 0,
              }}>推し: LUMENA 箱推し</div>
            )}
            <div style={{
              fontSize: 10.5, color: c.mute, marginTop: variant.id === 'B' ? 2 : 3,
              fontVariantNumeric: 'tabular-nums',
            }}>345m ・ 1時間前 ・ ★4.7 ・ 取引89</div>
          </div>
        </div>
        <div style={{
          padding: '10px 12px', borderRadius: 10,
          background: c.subtle, fontSize: 11.5,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
            <span style={{ color: c.mute, fontSize: 10 }}>譲</span>
            <span style={{ fontWeight: 600 }}>リナ JAPAN トレカ</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ color: c.mute, fontSize: 10 }}>求</span>
            <span style={{ fontWeight: 600 }}>スア WT02 アクスタ</span>
          </div>
        </div>
      </div>

      {/* === Comparison summary === */}
      <div style={{
        padding: '12px 14px', borderRadius: 12,
        background: `${c.lavender}10`, border: `1px solid ${c.lavender}30`,
        fontSize: 11, color: c.ink, lineHeight: 1.7,
        marginTop: 10,
      }}>
        <b style={{ color: c.lavender }}>{variant.id} の評価</b><br/>
        <span style={{ color: c.mute }}>{variant.eval}</span>
      </div>
    </div>
  );
}

// ─── Badge variants ───

// 案A：現状 ─ 「推し一致」のみ（曖昧）
function BadgeA({ c }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 3,
      fontSize: 9.5, fontWeight: 700, letterSpacing: 0.3,
      color: c.lavender,
      background: `${c.lavender}1a`,
      padding: '2px 7px', borderRadius: 999,
    }}>
      <svg width="7" height="7" viewBox="0 0 7 7"><path d="M3.5 6.5C1.5 5 0 3.5 0 2A2 2 0 013.5 1 2 2 0 017 2c0 1.5-1.5 3-3.5 4.5z" fill={c.lavender}/></svg>
      推し一致
    </span>
  );
}

// 案B：簡潔・別行で詳細表示
function BadgeB({ c, target }) {
  const label = target === 'box' ? '推し ●' : target === 'group' ? '推し ●' : '推し ●';
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 3,
      fontSize: 9.5, fontWeight: 700, letterSpacing: 0.3,
      color: c.lavender,
      background: `${c.lavender}1a`,
      padding: '2px 7px', borderRadius: 999,
    }}>
      <svg width="7" height="7" viewBox="0 0 7 7"><path d="M3.5 6.5C1.5 5 0 3.5 0 2A2 2 0 013.5 1 2 2 0 017 2c0 1.5-1.5 3-3.5 4.5z" fill={c.lavender}/></svg>
      {label}
    </span>
  );
}

// 案C：詳細インライン「推し: スア 一致」
function BadgeC({ c, target, name }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      fontSize: 9.5, fontWeight: 700, letterSpacing: 0.2,
      color: c.lavender,
      background: `${c.lavender}1a`,
      padding: '2px 8px', borderRadius: 999,
    }}>
      <svg width="7" height="7" viewBox="0 0 7 7"><path d="M3.5 6.5C1.5 5 0 3.5 0 2A2 2 0 013.5 1 2 2 0 017 2c0 1.5-1.5 3-3.5 4.5z" fill={c.lavender}/></svg>
      {target === 'box' ? `${name} 箱推し一致` : `${name} 一致`}
    </span>
  );
}

// 案D：絵文字でコンパクト
function BadgeD({ c, name, group, box }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 3,
      fontSize: 10, fontWeight: 700, letterSpacing: 0.2,
      color: c.lavender,
      background: `${c.lavender}1a`,
      padding: '2px 8px', borderRadius: 999,
    }}>
      🎯 {name}
    </span>
  );
}

Object.assign(window, { BSCard });
