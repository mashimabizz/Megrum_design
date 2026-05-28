// ─────────────────────────────────────────────────────────────
// account-support.jsx — D Trade tab / E Report / F Help / G Settings
// ─────────────────────────────────────────────────────────────

const AS_C = (t) => ({
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
  warnBg: '#fdf3ed',
  ok: '#7a9a8a',
  okBg: '#eef4f0',
});

// Shared chrome helpers
function ASHeader({ colors: c, title, sub, back = true, right }) {
  return (
    <div style={{
      position: 'absolute', top: 0, left: 0, right: 0,
      padding: '54px 18px 12px',
      background: 'rgba(255,255,255,0.92)',
      backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
      borderBottom: `0.5px solid ${c.divide}`,
      zIndex: 10,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        {back && (
          <svg width="10" height="16" viewBox="0 0 10 16" style={{ flex: '0 0 auto' }}>
            <path d="M8 1L2 8l6 7" stroke={c.ink} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        )}
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 15, fontWeight: 700, color: c.ink }}>{title}</div>
          {sub && <div style={{ fontSize: 11, color: c.mute, marginTop: 1 }}>{sub}</div>}
        </div>
        {right}
      </div>
    </div>
  );
}

function ASSection({ children, label, colors: c, hint }) {
  return (
    <div style={{ marginBottom: 14 }}>
      {label && (
        <div style={{
          fontSize: 10.5, color: c.mute, fontWeight: 700,
          letterSpacing: 0.6, textTransform: 'uppercase',
          padding: '0 4px', marginBottom: 8,
          display: 'flex', justifyContent: 'space-between',
        }}>
          <span>{label}</span>
          {hint && <span style={{ textTransform: 'none', letterSpacing: 0, fontWeight: 500 }}>{hint}</span>}
        </div>
      )}
      <div style={{
        background: '#fff', borderRadius: 14,
        border: `0.5px solid ${c.divide}`, overflow: 'hidden',
      }}>{children}</div>
    </div>
  );
}

function ASRow({ children, last, colors: c, padding = '12px 14px', onClick }) {
  return (
    <div onClick={onClick} style={{
      padding,
      borderBottom: last ? 'none' : `0.5px solid ${c.divide}`,
      cursor: onClick ? 'pointer' : 'default',
    }}>{children}</div>
  );
}

function ASBottomNav({ colors: c, active = 'trade' }) {
  const items = [
    { id: 'home', l: 'ホーム' },
    { id: 'inv', l: '在庫' },
    { id: 'trade', l: '取引' },
    { id: 'wish', l: 'ウィッシュ' },
    { id: 'me', l: 'プロフ' },
  ];
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 0,
      paddingBottom: 22, paddingTop: 6,
      background: 'rgba(255,255,255,0.96)',
      backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
      borderTop: `0.5px solid ${c.divide}`,
      display: 'flex', justifyContent: 'space-around',
    }}>
      {items.map(it => (
        <div key={it.id} style={{
          padding: '6px 10px', textAlign: 'center',
          color: active === it.id ? c.lavender : c.mute,
          fontSize: 10, fontWeight: active === it.id ? 700 : 500,
        }}>
          <div style={{
            width: 22, height: 22, margin: '0 auto 3px',
            borderRadius: 6, background: active === it.id ? `${c.lavender}22` : 'transparent',
          }} />
          {it.l}
        </div>
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// D. Trade tab — 3 subtabs + 保留中 badge + 空状態
// ─────────────────────────────────────────────────────────────
function TradeTab({ tweaks, sub = 'active', empty = false }) {
  const c = AS_C(tweaks);
  const [tab, setTab] = React.useState(sub); // pending | active | past
  const [pastFilter, setPastFilter] = React.useState('all');

  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 80,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <ASHeader colors={c} title="取引" back={false} />

      {/* Tabs */}
      <div style={{
        position: 'absolute', top: 92, left: 0, right: 0,
        display: 'flex', padding: '0 18px',
        background: 'rgba(255,255,255,0.92)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: `0.5px solid ${c.divide}`,
        zIndex: 9,
      }}>
        {[
          { id: 'pending', l: '打診中', n: 4 },
          { id: 'active', l: '進行中', n: 2 },
          { id: 'past', l: '過去取引', n: 89 },
        ].map(t => (
          <button key={t.id} onClick={() => setTab(t.id)} style={{
            flex: 1, padding: '14px 0',
            background: 'transparent', border: 0, fontFamily: 'inherit',
            fontSize: 12.5, fontWeight: tab === t.id ? 700 : 500,
            color: tab === t.id ? c.ink : c.mute,
            position: 'relative', cursor: 'pointer',
          }}>
            {t.l} <span style={{ fontSize: 10.5, color: c.mute, fontWeight: 600 }}>{t.n}</span>
            {tab === t.id && (
              <div style={{
                position: 'absolute', bottom: -0.5, left: '20%', right: '20%', height: 2,
                background: c.lavender, borderRadius: 999,
              }} />
            )}
          </button>
        ))}
      </div>

      <div style={{ height: 50 }} />

      {/* Empty state */}
      {empty && (
        <div style={{ padding: '60px 32px', textAlign: 'center' }}>
          <div style={{
            width: 72, height: 72, margin: '0 auto 16px',
            borderRadius: 18, background: `${c.lavender}15`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="32" height="32" viewBox="0 0 32 32">
              <circle cx="13" cy="13" r="9" stroke={c.lavender} strokeWidth="2" fill="none" opacity="0.5"/>
              <path d="M20 20l6 6" stroke={c.lavender} strokeWidth="2" strokeLinecap="round"/>
            </svg>
          </div>
          <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 6 }}>
            {tab === 'pending' ? 'まだ打診はありません' : tab === 'active' ? '進行中の取引はありません' : 'まだ取引履歴はありません'}
          </div>
          <div style={{ fontSize: 11.5, color: c.mute, lineHeight: 1.6, marginBottom: 18 }}>
            {tab === 'pending' ? 'ホームのマッチからカードを選んで\n打診を送ってみよう'
              : tab === 'active' ? '打診中タブで現在の状況を確認するか\n新しいマッチを探してみよう'
              : '初めての取引を始めて、コレクションを埋めよう'}
          </div>
          <button style={{
            padding: '12px 28px', borderRadius: 14,
            background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
            color: '#fff', border: 0, fontFamily: 'inherit',
            fontSize: 13, fontWeight: 700,
            boxShadow: `0 6px 16px ${c.lavender}40`,
          }}>{tab === 'past' ? '取引を始める' : 'マッチを探す'}</button>
        </div>
      )}

      {/* Pending */}
      {!empty && tab === 'pending' && (
        <div style={{ padding: '14px 18px 0' }}>
          <ASSection colors={c} label="打診中" hint="新着順">
            {[
              { dir: 'sent', h: '@iam_jiyoung', txt: 'スア×1 ⇄ ヒナ×1', meta: '横浜アリーナ 4/27 · 18時待ち合わせ提案', t: '2時間前', status: '相手の返信待ち' },
              { dir: 'recv', h: '@pop_ria', txt: 'シユン×2 ⇄ スア×2', meta: '東京ドーム 5/4 · 開場前ロビー希望', t: '昨日', status: '返信が必要', alert: true },
              { dir: 'sent', h: '@mochiko_724', txt: 'ミナ×1 ⇄ ジウォン×1', meta: '京セラドーム 5/18 · 開場後合流', t: '2日前', status: '相手の返信待ち' },
              { dir: 'recv', h: '@cherry_yuna', txt: '生写真Vol.3×3 ⇄ ペンライト交換', meta: 'AW未設定 · 場所相談中', t: '3日前', status: '返信が必要', alert: true },
            ].map((r, i, arr) => (
              <ASRow key={i} colors={c} last={i === arr.length - 1} padding="14px">
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
                  <div style={{
                    width: 36, height: 36, borderRadius: 10,
                    background: `linear-gradient(135deg, ${c.lavender}33, ${c.sky}33)`,
                    color: c.lavender, fontSize: 12, fontWeight: 800,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    flex: '0 0 auto',
                  }}>{r.h[1].toUpperCase()}</div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 2 }}>
                      <span style={{
                        fontSize: 9.5, fontWeight: 700, color: '#fff',
                        background: r.dir === 'sent' ? c.sky : c.lavender,
                        padding: '1px 6px', borderRadius: 3, letterSpacing: 0.3,
                      }}>{r.dir === 'sent' ? '送信→' : '←受信'}</span>
                      <span style={{ fontSize: 12, fontWeight: 700 }}>{r.h}</span>
                      <span style={{ marginLeft: 'auto', fontSize: 10, color: c.mute }}>{r.t}</span>
                    </div>
                    <div style={{ fontSize: 12, fontWeight: 600, color: c.ink, marginBottom: 1 }}>{r.txt}</div>
                    <div style={{ fontSize: 10.5, color: c.mute, marginBottom: 4 }}>{r.meta}</div>
                    <div style={{
                      fontSize: 10.5, fontWeight: 700,
                      color: r.alert ? c.warn : c.lavender,
                    }}>
                      {r.alert && '● '}{r.status}
                    </div>
                  </div>
                </div>
              </ASRow>
            ))}
          </ASSection>
        </div>
      )}

      {/* Active — with 保留中 badge */}
      {!empty && tab === 'active' && (
        <div style={{ padding: '14px 18px 0' }}>
          <ASSection colors={c} label="進行中">
            {[
              { h: '@lumi_sua', txt: 'スア×1 ⇄ ヒナ×1', meta: '横浜アリーナ · 4/27 18:30 待ち合わせ', state: '合流5分前', tone: 'ok' },
              { h: '@kpop_kana', txt: 'ジウォン×2 ⇄ ミナ×2', meta: '東京ドーム · 5/4 17:00 物販前', state: '当日まで7日', tone: 'mute' },
            ].map((r, i, arr) => (
              <ASRow key={i} colors={c} last={i === arr.length - 1} padding="14px">
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
                  <div style={{
                    width: 36, height: 36, borderRadius: 10,
                    background: `linear-gradient(135deg, ${c.lavender}33, ${c.sky}33)`,
                    color: c.lavender, fontSize: 12, fontWeight: 800,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    flex: '0 0 auto',
                  }}>L</div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <span style={{ fontSize: 12, fontWeight: 700 }}>{r.h}</span>
                    </div>
                    <div style={{ fontSize: 12, color: c.ink }}>{r.txt}</div>
                    <div style={{ fontSize: 10.5, color: c.mute }}>{r.meta}</div>
                    <div style={{
                      marginTop: 4, fontSize: 10.5, fontWeight: 700,
                      color: r.tone === 'ok' ? c.ok : c.mute,
                    }}>{r.tone === 'ok' && '● '}{r.state}</div>
                  </div>
                </div>
              </ASRow>
            ))}
          </ASSection>

          {/* Disputed/holding section */}
          <ASSection colors={c} label="申告中・仲裁中" hint="評価保留">
            <ASRow colors={c} last padding="14px">
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
                <div style={{
                  width: 36, height: 36, borderRadius: 10,
                  background: `${c.warn}22`,
                  color: c.warn, fontSize: 12, fontWeight: 800,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flex: '0 0 auto',
                }}>!</div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 2 }}>
                    <span style={{ fontSize: 12, fontWeight: 700 }}>@lumi_sua</span>
                    <span style={{
                      fontSize: 9.5, fontWeight: 800, color: '#fff',
                      background: c.warn, padding: '1px 6px', borderRadius: 3, letterSpacing: 0.3,
                    }}>保留中</span>
                  </div>
                  <div style={{ fontSize: 12, color: c.ink }}>スア×1 ⇄ ヒナ×1</div>
                  <div style={{ fontSize: 10.5, color: c.mute }}>#DPT-2784 · 仲裁ステップ3/4</div>
                  <div style={{ marginTop: 4, fontSize: 10.5, fontWeight: 700, color: c.warn }}>
                    一次回答まで残り 6時間
                  </div>
                </div>
                <span style={{ fontSize: 14, color: c.lavender, alignSelf: 'center' }}>›</span>
              </div>
            </ASRow>
          </ASSection>
        </div>
      )}

      {/* Past */}
      {!empty && tab === 'past' && (
        <div style={{ padding: '14px 18px 0' }}>
          {/* Filter chips */}
          <div style={{ display: 'flex', gap: 6, marginBottom: 12, overflowX: 'auto' }}>
            {[
              { id: 'all', l: 'すべて 89' },
              { id: 'done', l: '完了 84' },
              { id: 'cancel', l: 'キャンセル 4' },
              { id: 'fail', l: '申告不成立 1' },
            ].map(f => (
              <button key={f.id} onClick={() => setPastFilter(f.id)} style={{
                padding: '6px 12px', borderRadius: 999,
                background: pastFilter === f.id ? c.ink : '#fff',
                color: pastFilter === f.id ? '#fff' : c.ink,
                border: pastFilter === f.id ? 'none' : `0.5px solid ${c.divide}`,
                fontFamily: 'inherit', fontSize: 11, fontWeight: 700,
                whiteSpace: 'nowrap', flex: '0 0 auto', cursor: 'pointer',
              }}>{f.l}</button>
            ))}
          </div>

          <ASSection colors={c} label="2025年4月" hint="新着順 ▾">
            {[
              { d: '4/19', h: '@pop_ria', txt: 'スア×1 ⇄ ヒナ×1', state: '完了', tone: 'ok', star: 5, link: true },
              { d: '4/12', h: '@kpop_kana', txt: 'ミナ×2 ⇄ ジウォン×2', state: '完了', tone: 'ok', star: 4, link: true },
              { d: '4/05', h: '@cherry_yuna', txt: 'シユン×1 ⇄ スア×1', state: 'キャンセル合意', tone: 'mute' },
              { d: '4/01', h: '@hana_lover', txt: 'ヒナ×3 ⇄ ミナ×3', state: '申告不成立', tone: 'warn', badge: '保留中' },
            ].map((r, i, arr) => (
              <ASRow key={i} colors={c} last={i === arr.length - 1} padding="14px">
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
                  <div style={{
                    width: 40, textAlign: 'center', flex: '0 0 auto',
                    fontSize: 10, color: c.mute, fontWeight: 700, marginTop: 2,
                  }}>{r.d}</div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 1 }}>
                      <span style={{ fontSize: 12, fontWeight: 700 }}>{r.h}</span>
                      {r.badge && (
                        <span style={{
                          fontSize: 9.5, fontWeight: 800, color: '#fff',
                          background: c.warn, padding: '1px 6px', borderRadius: 3,
                        }}>{r.badge}</span>
                      )}
                    </div>
                    <div style={{ fontSize: 12, color: c.ink }}>{r.txt}</div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
                      <span style={{
                        fontSize: 10.5, fontWeight: 700,
                        color: r.tone === 'ok' ? c.ok : r.tone === 'warn' ? c.warn : c.mute,
                      }}>{r.state}</span>
                      {r.star && (
                        <span style={{ fontSize: 10.5, color: c.mute }}>
                          {'★'.repeat(r.star)}<span style={{ color: c.divide }}>{'★'.repeat(5 - r.star)}</span>
                        </span>
                      )}
                    </div>
                    {r.link && (
                      <button style={{
                        marginTop: 6, padding: '4px 10px', borderRadius: 6,
                        background: c.subtle, color: c.lavender, border: 0,
                        fontFamily: 'inherit', fontSize: 10, fontWeight: 700,
                      }}>コレクションで見る ›</button>
                    )}
                  </div>
                </div>
              </ASRow>
            ))}
          </ASSection>
        </div>
      )}

      <ASBottomNav colors={c} active="trade" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// E. Report (規約違反通報)
// ─────────────────────────────────────────────────────────────
function ReportForm({ tweaks }) {
  const c = AS_C(tweaks);
  const [cat, setCat] = React.useState('harassment');
  const [body, setBody] = React.useState('');
  const cats = [
    { id: 'harassment', l: '嫌がらせ', sub: '誹謗中傷・つきまとい' },
    { id: 'spam', l: 'スパム', sub: '無関係な宣伝・大量送信' },
    { id: 'fake', l: '偽装', sub: 'なりすまし・架空アカウント' },
    { id: 'fraud', l: '詐欺', sub: '金銭要求・不正取引誘導' },
    { id: 'inappropriate', l: '不適切な内容', sub: '性的・暴力的・差別的な内容など' },
    { id: 'other', l: 'その他', sub: '上記に当てはまらない違反行為' },
  ];
  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 100,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <ASHeader colors={c} title="このユーザーを通報" sub="@kpop_xx について · Megrumサポートに送信" />
      <div style={{ padding: '14px 18px 0' }}>
        <div style={{
          padding: 12, borderRadius: 12,
          background: c.warnBg, border: `0.5px solid ${c.warn}40`,
          fontSize: 11.5, color: c.ink, lineHeight: 1.6, marginBottom: 14,
        }}>
          通報内容は<b>運営のみが確認</b>します（相手には通知されません）。<br />
          受付から<b>48〜72時間以内</b>に内容を確認します。
        </div>

        <ASSection colors={c} label="違反の種類">
          {cats.map((g, i) => (
            <ASRow key={g.id} colors={c} last={i === cats.length - 1} padding="0">
              <button onClick={() => setCat(g.id)} style={{
                width: '100%', padding: '13px 14px',
                background: cat === g.id ? `${c.lavender}10` : 'transparent',
                border: 0, fontFamily: 'inherit',
                display: 'flex', alignItems: 'flex-start', gap: 12,
                textAlign: 'left', cursor: 'pointer',
              }}>
                <div style={{
                  width: 18, height: 18, borderRadius: '50%',
                  border: `1.5px solid ${cat === g.id ? c.lavender : 'rgba(58,50,74,0.25)'}`,
                  background: cat === g.id ? c.lavender : 'transparent',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flex: '0 0 auto', marginTop: 1.5,
                }}>
                  {cat === g.id && <div style={{ width: 7, height: 7, borderRadius: '50%', background: '#fff' }} />}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 12.5, fontWeight: 700, color: c.ink }}>{g.l}</div>
                  <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>{g.sub}</div>
                </div>
              </button>
            </ASRow>
          ))}
        </ASSection>

        <ASSection colors={c} label="状況の詳細">
          <ASRow colors={c} last padding="12px">
            <textarea
              value={body}
              onChange={(e) => setBody(e.target.value)}
              placeholder="いつ・どこで・何が起きたか具体的にご記入ください（500字まで）"
              style={{
                width: '100%', minHeight: 110, resize: 'vertical',
                border: 0, outline: 'none',
                fontFamily: 'inherit', fontSize: 12.5,
                color: c.ink, lineHeight: 1.6, background: 'transparent',
                boxSizing: 'border-box', padding: 0,
              }}
            />
            <div style={{ fontSize: 10, color: c.mute, textAlign: 'right' }}>{body.length}/500</div>
          </ASRow>
        </ASSection>

        <ASSection colors={c} label="証跡（任意・最大3枚）">
          <ASRow colors={c} last padding="12px">
            <div style={{ display: 'flex', gap: 8 }}>
              {[0, 1, 2].map(i => (
                <div key={i} style={{
                  flex: 1, aspectRatio: '1', borderRadius: 10,
                  background: c.subtle, border: `1px dashed ${c.divide}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexDirection: 'column', gap: 3,
                }}>
                  <svg width="18" height="18" viewBox="0 0 18 18">
                    <path d="M9 4v10M4 9h10" stroke={c.hint} strokeWidth="1.4" strokeLinecap="round"/>
                  </svg>
                  <span style={{ fontSize: 9, color: c.hint }}>追加</span>
                </div>
              ))}
            </div>
          </ASRow>
        </ASSection>

        <div style={{ fontSize: 10.5, color: c.mute, lineHeight: 1.6, padding: '0 4px', marginBottom: 16 }}>
          ※ 虚偽の通報は規約違反となり、アカウント制限の対象となります<br />
          ※ 緊急性の高い案件（脅迫・実害発生など）は警察等の関係機関にもご相談ください
        </div>
      </div>
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '12px 18px 30px',
        background: 'rgba(255,255,255,0.94)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `0.5px solid ${c.divide}`,
        display: 'flex', gap: 8,
      }}>
        <button style={{
          flex: 1, height: 48, borderRadius: 14,
          background: '#fff', color: c.ink, border: `0.5px solid ${c.divide}`,
          fontFamily: 'inherit', fontSize: 13, fontWeight: 600,
        }}>キャンセル</button>
        <button disabled={body.length < 10} style={{
          flex: 2, height: 48, borderRadius: 14,
          background: body.length < 10 ? c.subtle : c.warn,
          color: body.length < 10 ? c.hint : '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 14, fontWeight: 700,
          boxShadow: body.length < 10 ? 'none' : `0 6px 16px ${c.warn}40`,
        }}>通報する</button>
      </div>
    </div>
  );
}

function ReportComplete({ tweaks }) {
  const c = AS_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 100,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <ASHeader colors={c} title="通報を受付けました" back={false} />
      <div style={{ padding: '14px 18px 0' }}>
        <div style={{
          padding: '24px 16px', textAlign: 'center',
          background: '#fff', border: `0.5px solid ${c.divide}`,
          borderRadius: 14, marginBottom: 14,
        }}>
          <div style={{
            width: 56, height: 56, borderRadius: '50%',
            background: `${c.ok}1a`, color: c.ok,
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
            marginBottom: 12,
          }}>
            <svg width="26" height="26" viewBox="0 0 26 26"><path d="M6 13l4 4 10-10" stroke={c.ok} strokeWidth="2.2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
          </div>
          <div style={{ fontSize: 16, fontWeight: 800, marginBottom: 4 }}>受付完了</div>
          <div style={{ fontSize: 11.5, color: c.mute, lineHeight: 1.6 }}>
            運営が48〜72時間以内に内容を確認します。<br />
            必要な対応がある場合のみご連絡します。
          </div>
        </div>

        <ASSection colors={c} label="受付情報">
          <ASRow colors={c}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ fontSize: 11.5, color: c.mute }}>受付番号</span>
              <span style={{ fontSize: 12, fontWeight: 700, fontFamily: '"Inter Tight", sans-serif' }}>#REP-3942</span>
            </div>
          </ASRow>
          <ASRow colors={c}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ fontSize: 11.5, color: c.mute }}>対象アカウント</span>
              <span style={{ fontSize: 12, fontWeight: 600 }}>@kpop_xx</span>
            </div>
          </ASRow>
          <ASRow colors={c}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ fontSize: 11.5, color: c.mute }}>違反の種類</span>
              <span style={{ fontSize: 12, fontWeight: 600 }}>嫌がらせ</span>
            </div>
          </ASRow>
          <ASRow colors={c} last>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ fontSize: 11.5, color: c.mute }}>受付日時</span>
              <span style={{ fontSize: 12, fontWeight: 600 }}>2025/04/28 14:32</span>
            </div>
          </ASRow>
        </ASSection>

        <ASSection colors={c} label="このユーザーをブロック">
          <ASRow colors={c} last padding="14px">
            <div style={{ fontSize: 12, color: c.ink, lineHeight: 1.6, marginBottom: 10 }}>
              ブロックすると、相手から打診・メッセージが届かなくなります。マッチングからも除外されます。
            </div>
            <button style={{
              width: '100%', height: 44, borderRadius: 12,
              background: c.warn, color: '#fff', border: 0,
              fontFamily: 'inherit', fontSize: 13, fontWeight: 700,
            }}>@kpop_xx をブロック</button>
          </ASRow>
        </ASSection>

      </div>
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '12px 18px 30px',
        background: 'rgba(255,255,255,0.94)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `0.5px solid ${c.divide}`,
      }}>
        <button style={{
          width: '100%', height: 48, borderRadius: 14,
          background: c.ink, color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 14, fontWeight: 700,
        }}>ホームに戻る</button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// F. Help / FAQ / Contact
// ─────────────────────────────────────────────────────────────
function HelpFAQ({ tweaks }) {
  const c = AS_C(tweaks);
  const [search, setSearch] = React.useState('');
  const cats = [
    {
      l: '初心者ガイド', items: [
        { q: 'Megrumの使い方を教えて', a: '推し設定→マッチ確認→打診の3ステップ' },
        { q: 'AW（合流可能枠）って何?', a: '「場所×時間×半径」で合流できる枠を宣言、イベントは任意...' },
      ],
    },
    {
      l: '交換マナー', items: [
        { q: '取引のキャンセルはどうする?', a: '進行中タブから「キャンセル」を選択...' },
        { q: '相手と揉めたら?', a: '取引詳細から「相違あり」を申告...' },
      ],
    },
    {
      l: 'トラブル対応', items: [
        { q: '相手が時間に現れません', a: '15分以上の遅刻は申告対象...' },
        { q: '受け取ったグッズが違う', a: '取引詳細から「相違あり」を申告...' },
      ],
    },
    {
      l: '機能の使い方', items: [
        { q: '在庫の登録方法', o: true },
        { q: 'コレクションのシェア', o: true },
      ],
    },
    {
      l: 'アカウント管理', items: [
        { q: 'パスワードを忘れた', o: true },
        { q: 'アカウント削除', o: true },
      ],
    },
  ];
  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 100,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <ASHeader colors={c} title="ヘルプ" />
      <div style={{ padding: '14px 18px 0' }}>
        {/* Search bar */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8,
          padding: '11px 14px', borderRadius: 12,
          background: '#fff', border: `0.5px solid ${c.divide}`,
          marginBottom: 14,
        }}>
          <svg width="14" height="14" viewBox="0 0 14 14">
            <circle cx="6" cy="6" r="4.5" stroke={c.mute} strokeWidth="1.4" fill="none"/>
            <path d="M9.5 9.5L13 13" stroke={c.mute} strokeWidth="1.4" strokeLinecap="round"/>
          </svg>
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="キーワードで検索（例: キャンセル）"
            style={{
              flex: 1, border: 0, outline: 'none',
              fontFamily: 'inherit', fontSize: 12.5, color: c.ink,
              background: 'transparent',
            }}
          />
        </div>

        {/* Quick links */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 18 }}>
          {[
            { l: '取引のトラブル', sub: '即対応' },
            { l: 'アカウント', sub: '本人確認・削除' },
          ].map(q => (
            <div key={q.l} style={{
              padding: 12, borderRadius: 12,
              background: '#fff', border: `0.5px solid ${c.divide}`,
            }}>
              <div style={{ fontSize: 12.5, fontWeight: 700, marginBottom: 1 }}>{q.l}</div>
              <div style={{ fontSize: 10.5, color: c.mute }}>{q.sub}</div>
            </div>
          ))}
        </div>

        {/* FAQ accordion */}
        {cats.map((cat, ci) => (
          <ASSection key={ci} colors={c} label={cat.l}>
            {cat.items.map((it, i, arr) => (
              <ASRow key={i} colors={c} last={i === arr.length - 1} padding="13px 14px">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 10 }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 12.5, fontWeight: 700, color: c.ink, marginBottom: it.a ? 4 : 0 }}>{it.q}</div>
                    {it.a && <div style={{ fontSize: 11.5, color: c.mute, lineHeight: 1.6 }}>{it.a}</div>}
                  </div>
                  <span style={{ fontSize: 14, color: c.lavender, marginTop: 2 }}>›</span>
                </div>
              </ASRow>
            ))}
          </ASSection>
        ))}

        {/* Contact CTA */}
        <div style={{
          padding: 16, borderRadius: 14,
          background: `linear-gradient(135deg, ${c.lavender}1a, ${c.sky}1a)`,
          border: `1px solid ${c.lavender}40`,
          marginBottom: 12,
        }}>
          <div style={{ fontSize: 13, fontWeight: 800, marginBottom: 4 }}>解決しない場合</div>
          <div style={{ fontSize: 11.5, color: c.mute, lineHeight: 1.6, marginBottom: 12 }}>
            運営に直接お問い合わせください。通常48時間以内にメールでご返信します。
          </div>
          <button style={{
            width: '100%', height: 44, borderRadius: 12,
            background: c.lavender, color: '#fff', border: 0,
            fontFamily: 'inherit', fontSize: 13, fontWeight: 700,
          }}>運営に問い合わせる</button>
        </div>
      </div>
    </div>
  );
}

function ContactForm({ tweaks }) {
  const c = AS_C(tweaks);
  const [cat, setCat] = React.useState('howto');
  const [body, setBody] = React.useState('');
  const cats = [
    { id: 'howto', l: '機能の使い方', sub: '操作方法・画面の見方' },
    { id: 'bug', l: '不具合報告', sub: '動かない・エラーが出る' },
    { id: 'identity', l: '本人確認', sub: '認証・確認書類について' },
    { id: 'feature', l: '機能要望', sub: 'こんな機能が欲しい' },
    { id: 'other', l: 'その他', sub: 'パスワード・退会など' },
  ];
  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 100,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <ASHeader colors={c} title="運営に問い合わせる" sub="メールで48時間以内にご返信します" />
      <div style={{ padding: '14px 18px 0' }}>

        <ASSection colors={c} label="カテゴリ">
          {cats.map((g, i) => (
            <ASRow key={g.id} colors={c} last={i === cats.length - 1} padding="0">
              <button onClick={() => setCat(g.id)} style={{
                width: '100%', padding: '13px 14px',
                background: cat === g.id ? `${c.lavender}10` : 'transparent',
                border: 0, fontFamily: 'inherit',
                display: 'flex', alignItems: 'flex-start', gap: 12,
                textAlign: 'left', cursor: 'pointer',
              }}>
                <div style={{
                  width: 18, height: 18, borderRadius: '50%',
                  border: `1.5px solid ${cat === g.id ? c.lavender : 'rgba(58,50,74,0.25)'}`,
                  background: cat === g.id ? c.lavender : 'transparent',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flex: '0 0 auto', marginTop: 1.5,
                }}>
                  {cat === g.id && <div style={{ width: 7, height: 7, borderRadius: '50%', background: '#fff' }} />}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 12.5, fontWeight: 700 }}>{g.l}</div>
                  <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>{g.sub}</div>
                </div>
              </button>
            </ASRow>
          ))}
        </ASSection>

        <ASSection colors={c} label="お問い合わせ内容">
          <ASRow colors={c} last padding="12px">
            <textarea
              value={body}
              onChange={(e) => setBody(e.target.value)}
              placeholder="ご質問・ご要望を詳しくお書きください（1000字まで）"
              style={{
                width: '100%', minHeight: 130, resize: 'vertical',
                border: 0, outline: 'none',
                fontFamily: 'inherit', fontSize: 12.5,
                color: c.ink, lineHeight: 1.6, background: 'transparent',
                boxSizing: 'border-box', padding: 0,
              }}
            />
            <div style={{ fontSize: 10, color: c.mute, textAlign: 'right' }}>{body.length}/1000</div>
          </ASRow>
        </ASSection>

        <ASSection colors={c} label="連絡先メールアドレス">
          <ASRow colors={c} last padding="12px">
            <input
              defaultValue="hana@example.com"
              style={{
                width: '100%', border: 0, outline: 'none',
                fontFamily: 'inherit', fontSize: 13, color: c.ink, background: 'transparent', padding: 0,
              }}
            />
            <div style={{ fontSize: 10.5, color: c.mute, marginTop: 6 }}>登録メールに送信されます</div>
          </ASRow>
        </ASSection>

        <ASSection colors={c} label="送信される情報">
          <ASRow colors={c}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ fontSize: 11.5, color: c.mute }}>アプリ版</span>
              <span style={{ fontSize: 12, fontWeight: 600, fontFamily: '"Inter Tight", sans-serif' }}>Megrum 0.9.2 (build 1042)</span>
            </div>
          </ASRow>
          <ASRow colors={c}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ fontSize: 11.5, color: c.mute }}>OS</span>
              <span style={{ fontSize: 12, fontWeight: 600 }}>iOS 17.4 · iPhone 15</span>
            </div>
          </ASRow>
          <ASRow colors={c} last>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ fontSize: 11.5, color: c.mute }}>アカウントID</span>
              <span style={{ fontSize: 12, fontWeight: 600, fontFamily: '"Inter Tight", sans-serif' }}>usr_8a3f2k</span>
            </div>
          </ASRow>
        </ASSection>

      </div>
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '12px 18px 30px',
        background: 'rgba(255,255,255,0.94)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `0.5px solid ${c.divide}`,
        display: 'flex', gap: 8,
      }}>
        <button style={{
          flex: 1, height: 48, borderRadius: 14,
          background: '#fff', color: c.ink, border: `0.5px solid ${c.divide}`,
          fontFamily: 'inherit', fontSize: 13, fontWeight: 600,
        }}>キャンセル</button>
        <button disabled={body.length < 5} style={{
          flex: 2, height: 48, borderRadius: 14,
          background: body.length < 5 ? c.subtle : `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: body.length < 5 ? c.hint : '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 14, fontWeight: 700,
        }}>送信する</button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// G. Settings — Top + AW list + Notifications
// ─────────────────────────────────────────────────────────────
function SettingsTop({ tweaks }) {
  const c = AS_C(tweaks);
  const groups = [
    {
      label: 'アカウント', items: [
        { l: 'プロフィール編集', sub: 'ハンドル・自己紹介' },
        { l: '推し設定', sub: 'LUMENA · スア / ヒナ' },
        { l: '本人確認', sub: '完了済', tone: 'ok' },
      ],
    },
    {
      label: '取引・AW', items: [
        { l: '自分のAW一覧（合流可能枠）', sub: '5件登録 · 直近 4/27', highlight: true },
        { l: '在庫の公開設定', sub: '公開' },
      ],
    },
    {
      label: '通知', items: [
        { l: '通知設定', sub: 'プッシュ・メール' },
        { l: '通知のミュート期間', sub: 'オフ' },
      ],
    },
    {
      label: 'プライバシー', items: [
        { l: 'ブロックリスト', sub: '2人' },
        { l: '公開範囲', sub: 'マッチした人にのみ' },
        { l: 'データのダウンロード', sub: '取引履歴・コレクション' },
      ],
    },
    {
      label: 'サポート', items: [
        { l: 'ヘルプ', sub: 'FAQ・問い合わせ' },
        { l: 'Megrumの使い方ツアー', sub: '3分で再確認' },
      ],
    },
    {
      label: '規約', items: [
        { l: '利用規約' },
        { l: 'プライバシーポリシー' },
        { l: 'コミュニティガイドライン' },
      ],
    },
    {
      label: 'アプリ情報', items: [
        { l: 'バージョン', sub: '0.9.2 (build 1042)', noChevron: true },
        { l: '最終起動', sub: '2025/04/28 14:32', noChevron: true },
        { l: '今月の取引数', sub: '12回', noChevron: true },
      ],
    },
    {
      label: 'アカウント操作', items: [
        { l: 'ログアウト', tone: 'mute' },
        { l: 'アカウント削除', tone: 'warn' },
      ],
    },
  ];
  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 100,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <ASHeader colors={c} title="設定" back={false} />
      <div style={{ padding: '14px 18px 0' }}>
        {/* Profile chip */}
        <div style={{
          padding: 14, borderRadius: 14,
          background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
          color: '#fff', display: 'flex', alignItems: 'center', gap: 12,
          marginBottom: 18,
          boxShadow: `0 8px 20px ${c.lavender}30`,
        }}>
          <div style={{
            width: 44, height: 44, borderRadius: 12,
            background: 'rgba(255,255,255,0.25)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 18, fontWeight: 800,
          }}>H</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14, fontWeight: 800, marginBottom: 1 }}>@hana_lumi</div>
            <div style={{ fontSize: 11, opacity: 0.9 }}>★4.9 · 取引89回 · コレクション20/32</div>
          </div>
          <span style={{ fontSize: 18, opacity: 0.7 }}>›</span>
        </div>

        {groups.map((g, gi) => (
          <ASSection key={gi} colors={c} label={g.label}>
            {g.items.map((it, i, arr) => (
              <ASRow key={i} colors={c} last={i === arr.length - 1} padding="13px 14px">
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10 }}>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{
                      fontSize: 12.5, fontWeight: it.highlight ? 800 : 600,
                      color: it.tone === 'warn' ? c.warn : it.tone === 'mute' ? c.mute : c.ink,
                    }}>{it.l}</div>
                    {it.sub && (
                      <div style={{
                        fontSize: 10.5, marginTop: 1,
                        color: it.tone === 'ok' ? c.ok : c.mute,
                        fontWeight: it.tone === 'ok' ? 700 : 500,
                      }}>{it.sub}</div>
                    )}
                  </div>
                  {!it.noChevron && it.tone !== 'warn' && it.tone !== 'mute' && (
                    <span style={{ fontSize: 14, color: c.lavender }}>›</span>
                  )}
                </div>
              </ASRow>
            ))}
          </ASSection>
        ))}
      </div>
      <ASBottomNav colors={c} active="me" />
    </div>
  );
}

// G-2: AW一覧管理ハブ
function MyAWList({ tweaks }) {
  const c = AS_C(tweaks);
  const aws = [
    { d: '4/27', l: '横浜アリーナ DAY1', kind: 'イベント', state: '今日 18:30〜19:30', ok: 3, hot: true },
    { d: '4/30', l: '渋谷駅周辺（合流可能枠）', kind: 'イベントなし', state: '明日 14:00〜16:00 · 半径500m', ok: 2 },
    { d: '5/04', l: '東京ドーム', kind: 'イベント', state: '残り6日', ok: 2 },
    { d: '5/10', l: '池袋エリア（合流可能枠）', kind: 'イベントなし', state: '土曜 終日フレキシブル · 半径1km', ok: 1 },
    { d: '5/18', l: '京セラドーム', kind: 'イベント', state: '残り20日', ok: 1 },
    { d: '6/15', l: '名古屋ドーム', kind: '未設定', state: '時間・場所が未入力', ok: 0, warn: true },
  ];
  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 100,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <ASHeader colors={c} title="自分のAW（合流可能枠）" sub="Availability Window · 5件登録 · 同時並行管理OK" right={
        <button style={{
          padding: '6px 12px', borderRadius: 999,
          background: c.lavender, color: '#fff', border: 0,
          fontFamily: 'inherit', fontSize: 11, fontWeight: 700,
        }}>+ 追加</button>
      } />
      <div style={{ padding: '14px 18px 0' }}>
        <ASSection colors={c} label="今後の予定" hint="日付昇順">
          {aws.map((aw, i, arr) => (
            <ASRow key={i} colors={c} last={i === arr.length - 1} padding="14px">
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
                <div style={{
                  width: 48, textAlign: 'center', flex: '0 0 auto',
                  padding: '6px 0', borderRadius: 8,
                  background: aw.hot ? `${c.lavender}1a` : c.subtle,
                  color: aw.hot ? c.lavender : c.ink,
                }}>
                  <div style={{
                    fontFamily: '"Inter Tight", sans-serif',
                    fontSize: 13, fontWeight: 800, lineHeight: 1,
                  }}>{aw.d}</div>
                  <div style={{ fontSize: 9, marginTop: 2, fontWeight: 700, opacity: 0.7 }}>{aw.kind}</div>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 2 }}>
                    <span style={{ fontSize: 12.5, fontWeight: 700 }}>{aw.l}</span>
                    {aw.hot && (
                      <span style={{
                        fontSize: 9, fontWeight: 800, color: '#fff',
                        background: c.lavender, padding: '1px 5px', borderRadius: 3,
                      }}>本日</span>
                    )}
                  </div>
                  <div style={{ fontSize: 10.5, color: aw.warn ? c.warn : c.mute, marginBottom: 3, fontWeight: aw.warn ? 700 : 500 }}>
                    {aw.warn && '● '}{aw.state}
                  </div>
                  <div style={{ fontSize: 10.5, color: c.mute }}>
                    取引予定 <b style={{ color: c.ink }}>{aw.ok}件</b> · {aw.warn ? '詳細を入力' : '招待を見る'}
                  </div>
                </div>
                <span style={{ fontSize: 14, color: c.lavender, alignSelf: 'center' }}>›</span>
              </div>
            </ASRow>
          ))}
        </ASSection>

        <ASSection colors={c} label="過去のAW">
          <ASRow colors={c} last padding="13px 14px">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>過去のAW履歴</div>
                <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>23件 · 取引89回・コレクション12枚追加</div>
              </div>
              <span style={{ fontSize: 14, color: c.lavender }}>›</span>
            </div>
          </ASRow>
        </ASSection>
      </div>
    </div>
  );
}

// G-3: Notification settings
function NotificationSettings({ tweaks }) {
  const c = AS_C(tweaks);
  const groups = [
    {
      label: 'プッシュ通知', items: [
        { l: '新しいマッチ', sub: 'おすすめ取引相手が見つかった時', on: true },
        { l: '打診を受信した', sub: '相手から取引のお誘い', on: true },
        { l: '打診への返信', sub: '送った打診に動きがあった時', on: true },
        { l: '取引当日リマインダー', sub: 'AW当日の朝・1時間前', on: true },
        { l: '相違あり申告', sub: '取引について申告が来た時', on: true },
        { l: '運営からのお知らせ', sub: '重要な情報のみ', on: true },
        { l: 'コレクション コンプ達成', sub: '推し別/全体のwishコンプ時', on: true },
      ],
    },
    {
      label: 'メール通知', items: [
        { l: '取引完了レポート', sub: '月1回のサマリ', on: true },
        { l: 'セキュリティ通知', sub: 'ログイン・パスワード変更', on: true },
        { l: 'キャンペーン情報', sub: '新機能・お得情報', on: false },
      ],
    },
    {
      label: 'サウンド', items: [
        { l: '通知音', sub: 'デフォルト' },
        { l: 'バイブレーション', on: true },
      ],
    },
  ];
  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 100,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <ASHeader colors={c} title="通知設定" sub="トピック別にON/OFFできます" />
      <div style={{ padding: '14px 18px 0' }}>

        {/* Mute schedule */}
        <ASSection colors={c} label="通知のミュート">
          <ASRow colors={c} padding="14px">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>夜間モード</div>
                <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>22:00 〜 7:00 は通知しない</div>
              </div>
              <Toggle on={true} c={c} />
            </div>
          </ASRow>
          <ASRow colors={c} last padding="14px">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>取引当日のみ即時通知</div>
                <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>夜間モード中も例外で通知</div>
              </div>
              <Toggle on={true} c={c} />
            </div>
          </ASRow>
        </ASSection>

        {groups.map((g, gi) => (
          <ASSection key={gi} colors={c} label={g.label}>
            {g.items.map((it, i, arr) => (
              <ASRow key={i} colors={c} last={i === arr.length - 1} padding="13px 14px">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 10 }}>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 12.5, fontWeight: 700 }}>{it.l}</div>
                    {it.sub && <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>{it.sub}</div>}
                  </div>
                  {it.on !== undefined ? (
                    <Toggle on={it.on} c={c} />
                  ) : (
                    <span style={{ fontSize: 14, color: c.lavender }}>›</span>
                  )}
                </div>
              </ASRow>
            ))}
          </ASSection>
        ))}
      </div>
    </div>
  );
}

function Toggle({ on, c }) {
  return (
    <div style={{
      width: 38, height: 22, borderRadius: 999,
      background: on ? c.lavender : c.divide,
      position: 'relative', flex: '0 0 auto',
      transition: 'background 0.2s',
    }}>
      <div style={{
        position: 'absolute', top: 2, left: on ? 18 : 2,
        width: 18, height: 18, borderRadius: '50%',
        background: '#fff', boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
        transition: 'left 0.2s',
      }} />
    </div>
  );
}

// __MVP_EXPORTS__
Object.assign(window, {
  TradeTab, ReportForm, ReportComplete, HelpFAQ, ContactForm,
  SettingsTop, MyAWList, NotificationSettings,
});
