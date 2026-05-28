// ─────────────────────────────────────────────────────────────
// C-3 Dispute Flow — 相違あり詳細 + 取引キャンセル・遅刻通知
// 7 screens · 事務的・中立トーン · 24h SLA · 申告中は新規打診のみ制限
// ─────────────────────────────────────────────────────────────

const D_C = (tweaks) => ({
  lavender: tweaks.primary,
  sky: tweaks.secondary,
  pink: tweaks.accent,
  ink: '#3a324a',
  mute: 'rgba(58,50,74,0.55)',
  hint: 'rgba(58,50,74,0.4)',
  subtle: 'rgba(58,50,74,0.06)',
  divide: 'rgba(58,50,74,0.08)',
  bg: '#fbf9fc',
  warn: '#d9826b',
  warnBg: '#fdf3ed',
  ok: '#7a9a8a',
});

// ─────────────────────────────────────────────────────────────
// Shared chrome
// ─────────────────────────────────────────────────────────────
function DHeader({ colors: c, title, sub, step, total = 6, back = true }) {
  return (
    <div style={{
      position: 'absolute', top: 0, left: 0, right: 0,
      paddingTop: 54, padding: '54px 18px 12px',
      background: 'rgba(255,255,255,0.92)',
      backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
      borderBottom: `0.5px solid ${c.divide}`,
      zIndex: 10,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: sub ? 4 : 0 }}>
        {back && (
          <svg width="10" height="16" viewBox="0 0 10 16" style={{ flex: '0 0 auto' }}>
            <path d="M8 1L2 8l6 7" stroke={c.ink} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        )}
        <div style={{ flex: 1, fontSize: 15, fontWeight: 700, color: c.ink }}>{title}</div>
        {step && (
          <div style={{
            fontSize: 10.5, color: c.mute, fontWeight: 700, letterSpacing: 0.4,
            padding: '3px 8px', borderRadius: 6, background: c.subtle,
          }}>{step}/{total}</div>
        )}
      </div>
      {sub && <div style={{ fontSize: 11.5, color: c.mute, paddingLeft: back ? 20 : 0 }}>{sub}</div>}
    </div>
  );
}

function DSection({ children, label, colors: c }) {
  return (
    <div style={{ marginBottom: 14 }}>
      {label && (
        <div style={{
          fontSize: 10.5, color: c.mute, fontWeight: 700,
          letterSpacing: 0.6, textTransform: 'uppercase',
          padding: '0 4px', marginBottom: 8,
        }}>{label}</div>
      )}
      <div style={{
        background: '#fff', borderRadius: 14,
        border: `0.5px solid ${c.divide}`,
        overflow: 'hidden',
      }}>{children}</div>
    </div>
  );
}

function DRow({ children, last, colors: c, padding = '12px 14px' }) {
  return (
    <div style={{
      padding,
      borderBottom: last ? 'none' : `0.5px solid ${c.divide}`,
    }}>{children}</div>
  );
}

function DStickyCTA({ colors: c, primary, secondary, primaryDisabled, primaryStyle }) {
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 0,
      padding: '12px 18px 30px',
      background: 'rgba(255,255,255,0.94)',
      backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
      borderTop: `0.5px solid ${c.divide}`,
      display: 'flex', gap: 8,
    }}>
      {secondary && (
        <button style={{
          flex: 1, height: 48, borderRadius: 14,
          background: '#fff', color: c.ink,
          border: `0.5px solid ${c.subtle}`,
          fontFamily: 'inherit', fontSize: 13.5, fontWeight: 600,
        }}>{secondary}</button>
      )}
      <button disabled={primaryDisabled} style={{
        flex: 2, height: 48, borderRadius: 14,
        background: primaryDisabled
          ? c.subtle
          : (primaryStyle === 'warn'
            ? c.warn
            : `linear-gradient(135deg, ${c.lavender}, ${c.sky})`),
        color: primaryDisabled ? c.hint : '#fff',
        border: 0, fontFamily: 'inherit',
        fontSize: 14.5, fontWeight: 700, letterSpacing: 0.4,
        boxShadow: primaryDisabled ? 'none'
          : (primaryStyle === 'warn' ? `0 6px 16px ${c.warn}50` : `0 6px 16px ${c.lavender}50`),
      }}>{primary}</button>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 1. カテゴリ選択
// ─────────────────────────────────────────────────────────────
function D1Category({ tweaks }) {
  const c = D_C(tweaks);
  const [sel, setSel] = React.useState(1);
  const cats = [
    { id: 'short', l: '受け取った点数が少ない', sub: '合意した枚数より少なかった' },
    { id: 'wrong', l: 'グッズが違う / 状態が悪い', sub: '別メンバー・偽物・破損など' },
    { id: 'noshow', l: '相手が現れなかった', sub: '合流時間に来なかった・連絡途絶' },
    { id: 'cancel', l: '合意済みのキャンセル', sub: '事前に双方合意した取消・体調不良など' },
    { id: 'other', l: 'その他', sub: '上記に当てはまらない' },
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
      <DHeader colors={c} title="この取引について報告" sub="該当する項目を1つ選んでください" step={1} />
      <div style={{ padding: '14px 18px 0' }}>
        <div style={{
          padding: 12, borderRadius: 12,
          background: c.warnBg, border: `0.5px solid ${c.warn}40`,
          display: 'flex', gap: 10, marginBottom: 14,
        }}>
          <div style={{
            width: 22, height: 22, borderRadius: '50%',
            background: c.warn, color: '#fff',
            fontSize: 13, fontWeight: 800,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flex: '0 0 auto', marginTop: 1,
          }}>!</div>
          <div style={{ fontSize: 11.5, color: c.ink, lineHeight: 1.6 }}>
            事実関係の確認のため、<b>送信後は内容を編集できません</b>。<br />
            あなたのアカウント名は相手に共有されます。<br />
            申告は運営が24時間以内に確認します。
          </div>
        </div>

        <DSection colors={c} label="取引">
          <DRow colors={c} last>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10,
                background: `linear-gradient(135deg, ${c.lavender}33, ${c.sky}33)`,
                color: c.lavender, fontSize: 12, fontWeight: 800,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>L</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>@lumi_sua</div>
                <div style={{ fontSize: 10.5, color: c.mute }}>横浜アリーナ · 4/27 18:30 · スア⇄ヒナ各1</div>
              </div>
            </div>
          </DRow>
        </DSection>

        <DSection colors={c} label="該当する項目">
          {cats.map((cat, i) => (
            <DRow key={cat.id} colors={c} last={i === cats.length - 1} padding="0">
              <button onClick={() => setSel(i)} style={{
                width: '100%', padding: '13px 14px',
                background: sel === i ? `${c.lavender}10` : 'transparent',
                border: 0, fontFamily: 'inherit',
                display: 'flex', alignItems: 'flex-start', gap: 12,
                textAlign: 'left', cursor: 'pointer',
              }}>
                <div style={{
                  width: 18, height: 18, borderRadius: '50%',
                  border: `1.5px solid ${sel === i ? c.lavender : 'rgba(58,50,74,0.25)'}`,
                  background: sel === i ? c.lavender : 'transparent',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flex: '0 0 auto', marginTop: 1,
                }}>
                  {sel === i && <svg width="9" height="7" viewBox="0 0 9 7"><path d="M1 3.5L3.5 6 8 1" stroke="#fff" strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: sel === i ? 700 : 500, color: c.ink }}>{cat.l}</div>
                  <div style={{ fontSize: 10.5, color: c.mute, marginTop: 2 }}>{cat.sub}</div>
                </div>
              </button>
            </DRow>
          ))}
        </DSection>
      </div>
      <DStickyCTA colors={c} primary="次へ：詳細を入力" secondary="戻る" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 2. 証跡追加
// ─────────────────────────────────────────────────────────────
function D2Evidence({ tweaks, mode = 'required' }) {
  const c = D_C(tweaks);
  const [text, setText] = React.useState('合流場所と時間に行きましたが、相手から「点数が3枚しか集まっていない（合意は5枚）」と言われ、3枚で受け取りました。チャットで合意した5枚の証跡が残っています。');
  const skippable = mode === 'noshow';
  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 100,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <DHeader colors={c} title="事実と証跡を追加" sub={skippable ? '相手が現れなかった' : '受け取った点数が少ない'} step={2} />
      <div style={{ padding: '14px 18px 0' }}>

        <DSection colors={c} label={`証跡写真${skippable ? '（任意）' : '（必須）'}`}>
          <DRow colors={c} last padding="14px">
            <div style={{ fontSize: 11.5, color: c.mute, marginBottom: 10, lineHeight: 1.5 }}>
              C-3で撮影した取引完了時の証跡写真は自動添付されます。
              {!skippable && <><br />必要に応じて追加の写真をアップロードしてください。</>}
            </div>
            <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
              <div style={{
                flex: 1, aspectRatio: '4/5', borderRadius: 10,
                background: `linear-gradient(135deg, ${c.lavender}25, ${c.sky}25)`,
                position: 'relative',
                border: `0.5px solid ${c.divide}`,
              }}>
                <div style={{
                  position: 'absolute', top: 6, left: 6,
                  fontSize: 8.5, padding: '2px 6px', borderRadius: 4,
                  background: 'rgba(255,255,255,0.92)', color: c.ink, fontWeight: 700,
                }}>取引完了時 · 自動</div>
                <div style={{ position: 'absolute', bottom: 8, left: 8, fontSize: 9, color: c.mute }}>4/27 18:43</div>
              </div>
              <div style={{
                flex: 1, aspectRatio: '4/5', borderRadius: 10,
                background: c.subtle,
                border: `1px dashed ${c.hint}`,
                display: 'flex', flexDirection: 'column',
                alignItems: 'center', justifyContent: 'center',
                color: c.mute, fontSize: 10, gap: 4,
              }}>
                <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
                  <rect x="2" y="4" width="14" height="11" rx="1.5" stroke={c.mute} strokeWidth="1.2"/>
                  <circle cx="9" cy="10" r="2.5" stroke={c.mute} strokeWidth="1.2"/>
                  <path d="M6 4l1-1.5h4L12 4" stroke={c.mute} strokeWidth="1.2"/>
                </svg>
                追加
              </div>
              <div style={{
                flex: 1, aspectRatio: '4/5', borderRadius: 10,
                background: c.subtle,
                border: `1px dashed ${c.hint}`,
              }} />
            </div>
            <div style={{ fontSize: 10.5, color: c.mute }}>任意で最大3枚まで追加できます</div>
          </DRow>
        </DSection>

        <DSection colors={c} label="事実メモ">
          <DRow colors={c} last padding="0">
            <textarea value={text} onChange={(e) => setText(e.target.value)} rows={6} style={{
              width: '100%', padding: 14, border: 0,
              fontFamily: 'inherit', fontSize: 12.5, lineHeight: 1.6,
              color: c.ink, resize: 'none', boxSizing: 'border-box',
              background: 'transparent', outline: 'none',
            }} />
          </DRow>
        </DSection>

        <div style={{
          padding: '10px 12px', borderRadius: 10,
          background: `${c.lavender}10`, marginBottom: 14,
          fontSize: 10.5, color: c.ink, lineHeight: 1.6,
        }}>
          <b>📝 書き方のコツ</b><br />
          • 時系列で事実を整理してください（◯時に何が起きたか）<br />
          • 推測・感情ではなく観察した事実を<br />
          • 該当するチャットメッセージは運営が自動で照合します
        </div>
      </div>
      <DStickyCTA colors={c} primary="申告を送信" secondary="戻る" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 3. 送信完了 · 凍結状況説明
// ─────────────────────────────────────────────────────────────
function D3Submitted({ tweaks }) {
  const c = D_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 100,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <DHeader colors={c} title="申告を送信しました" step={3} back={false} />
      <div style={{ padding: '20px 18px 0', textAlign: 'center' }}>
        <div style={{
          width: 56, height: 56, borderRadius: '50%',
          background: c.subtle, color: c.ink,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          margin: '0 auto 12px',
        }}>
          <svg width="26" height="26" viewBox="0 0 26 26" fill="none">
            <circle cx="13" cy="13" r="11" stroke={c.lavender} strokeWidth="1.6"/>
            <path d="M8 13l3 3 7-7" stroke={c.lavender} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
        <div style={{ fontSize: 18, fontWeight: 800, marginBottom: 4 }}>受付番号 #DPT-2784</div>
        <div style={{ fontSize: 12, color: c.mute, marginBottom: 18 }}>運営が24時間以内に一次回答します</div>
      </div>

      <div style={{ padding: '0 18px' }}>
        <DSection colors={c} label="今後の流れ">
          {[
            { n: '1', l: '相手に通知', s: '事実確認の機会を提供（最大24h）', state: 'now' },
            { n: '2', l: '運営による事実確認', s: 'チャット履歴・証跡を双方分照合', state: 'next' },
            { n: '3', l: '一次回答', s: '24時間以内 · プッシュ通知', state: 'next' },
            { n: '4', l: '結果通知 / 評価反映', s: '取引完了 or 取消 or 追加調査', state: 'next' },
          ].map((s, i, arr) => (
            <DRow key={i} colors={c} last={i === arr.length - 1}>
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
                <div style={{
                  width: 22, height: 22, borderRadius: '50%',
                  background: s.state === 'now' ? c.lavender : c.subtle,
                  color: s.state === 'now' ? '#fff' : c.mute,
                  fontSize: 11, fontWeight: 800,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flex: '0 0 auto', marginTop: 1,
                }}>{s.n}</div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 12.5, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 6 }}>
                    {s.l}
                    {s.state === 'now' && (
                      <span style={{
                        fontSize: 9, padding: '1px 6px', borderRadius: 4,
                        background: c.lavender, color: '#fff', fontWeight: 700,
                      }}>進行中</span>
                    )}
                  </div>
                  <div style={{ fontSize: 11, color: c.mute, marginTop: 2 }}>{s.s}</div>
                </div>
              </div>
            </DRow>
          ))}
        </DSection>

        <DSection colors={c} label="申告中の制限">
          <DRow colors={c}>
            <div style={{ fontSize: 12, lineHeight: 1.6, color: c.ink }}>
              <b>新規打診のみ一時制限</b>されます<br />
              <span style={{ color: c.mute, fontSize: 11 }}>既に進行中の取引は通常通り続行できます · 相手側も同じ制限</span>
            </div>
          </DRow>
          <DRow colors={c} last>
            <div style={{ fontSize: 12, lineHeight: 1.6, color: c.ink }}>
              <b>評価の反映は保留</b>されます<br />
              <span style={{ color: c.mute, fontSize: 11 }}>結論が出るまで★・取引数に算入されません</span>
            </div>
          </DRow>
        </DSection>
      </div>
      <DStickyCTA colors={c} primary="ホームに戻る" secondary="ステータスを見る" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 4. 相手側 · 反論要請
// ─────────────────────────────────────────────────────────────
function D4Respondent({ tweaks }) {
  const c = D_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 100,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <DHeader colors={c} title="事実確認のお願い" sub="あなたに関する申告が届きました" step={4} back={false} />
      <div style={{ padding: '14px 18px 0' }}>

        <div style={{
          padding: '14px',
          background: c.warnBg,
          border: `0.5px solid ${c.warn}40`,
          borderRadius: 14, marginBottom: 14,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
            <div style={{
              width: 22, height: 22, borderRadius: '50%',
              background: c.warn, color: '#fff', fontSize: 12, fontWeight: 800,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>!</div>
            <div style={{ fontSize: 13, fontWeight: 800 }}>申告がありました</div>
          </div>
          <div style={{ fontSize: 11.5, color: c.ink, lineHeight: 1.6, marginBottom: 6 }}>
            事実確認にご協力ください。以下の内容についてあなたの認識をお聞かせください。
          </div>
          <div style={{ fontSize: 10.5, color: c.mute }}>
            回答期限：4/28 18:43（残り 23時間50分）
          </div>
        </div>

        <DSection colors={c} label="申告内容">
          <DRow colors={c}>
            <div style={{ fontSize: 10.5, color: c.mute, marginBottom: 4 }}>申告者</div>
            <div style={{ fontSize: 12.5, fontWeight: 700 }}>@hina_collect</div>
          </DRow>
          <DRow colors={c}>
            <div style={{ fontSize: 10.5, color: c.mute, marginBottom: 4 }}>カテゴリ</div>
            <div style={{ fontSize: 12.5, fontWeight: 700 }}>受け取った点数が少ない</div>
          </DRow>
          <DRow colors={c} last>
            <div style={{ fontSize: 10.5, color: c.mute, marginBottom: 4 }}>取引</div>
            <div style={{ fontSize: 12.5, fontWeight: 600 }}>横浜アリーナ · 4/27 18:30 · スア⇄ヒナ各1</div>
          </DRow>
        </DSection>

        <DSection colors={c} label="あなたの選択">
          {[
            { l: '事実です。間違いを認めます', s: '取引は取消・★は据え置き', tone: 'warn' },
            { l: '事実と異なります。反論を提出します', s: '次画面で詳細を入力（推奨）', tone: 'primary' },
            { l: '回答せず24時間経過', s: '申告内容が事実と推定されます', tone: 'mute' },
          ].map((opt, i, arr) => (
            <DRow key={i} colors={c} last={i === arr.length - 1} padding="0">
              <button style={{
                width: '100%', padding: '13px 14px',
                background: 'transparent', border: 0, fontFamily: 'inherit',
                textAlign: 'left', cursor: 'pointer',
              }}>
                <div style={{ fontSize: 12.5, fontWeight: 600, color: c.ink, marginBottom: 2 }}>{opt.l}</div>
                <div style={{
                  fontSize: 10.5,
                  color: opt.tone === 'warn' ? c.warn : (opt.tone === 'primary' ? c.lavender : c.mute),
                  fontWeight: opt.tone === 'mute' ? 400 : 600,
                }}>→ {opt.s}</div>
              </button>
            </DRow>
          ))}
        </DSection>
      </div>
      <DStickyCTA colors={c} primary="反論を提出する" secondary="認める" primaryStyle={null} />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 5. 仲裁中ステータス
// ─────────────────────────────────────────────────────────────
function D5Arbitration({ tweaks, respondentResponse = 'disputed' }) {
  const c = D_C(tweaks);
  const responseRow =
    respondentResponse === 'accepted'
      ? { l: '相手が事実を認める', t: '4/27 22:14', done: true, sub: '認める', subTone: 'ok' }
      : respondentResponse === 'silent'
      ? { l: '相手からの回答', t: '24h無回答 · 事実推定', done: true, sub: '無回答', subTone: 'mute' }
      : { l: '相手の回答受領', t: '4/27 23:48', done: true, sub: '反論あり', subTone: 'warn' };
  const subTitle =
    respondentResponse === 'accepted'
      ? '#DPT-2784 · 相手が認めたため迅速処理中'
      : respondentResponse === 'silent'
      ? '#DPT-2784 · 相手無回答により事実推定で進行'
      : '#DPT-2784 · 受け取った点数が少ない';
  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 30,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <DHeader colors={c} title="仲裁ステータス" sub={subTitle} step={5} />
      <div style={{ padding: '14px 18px 0' }}>

        <DSection colors={c} label="進捗">
          <DRow colors={c} last padding="14px">
            {[
              { l: '申告受付', t: '4/27 19:12', done: true },
              responseRow,
              { l: '運営による事実確認', t: '進行中', current: true },
              { l: '一次回答', t: '4/28 19:12 まで', done: false },
            ].map((s, i, arr) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'flex-start', gap: 10,
                paddingBottom: i === arr.length - 1 ? 0 : 14,
                position: 'relative',
              }}>
                {i < arr.length - 1 && (
                  <div style={{
                    position: 'absolute', left: 9, top: 22, bottom: -2, width: 1.5,
                    background: s.done ? c.lavender : c.divide,
                  }} />
                )}
                <div style={{
                  width: 20, height: 20, borderRadius: '50%',
                  background: s.done ? c.lavender : (s.current ? '#fff' : c.subtle),
                  border: s.current ? `2px solid ${c.lavender}` : 'none',
                  color: '#fff', fontSize: 10, fontWeight: 800,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flex: '0 0 auto', position: 'relative', zIndex: 1,
                }}>
                  {s.done && <svg width="10" height="8" viewBox="0 0 10 8"><path d="M1 4l3 3 5-6" stroke="#fff" strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>}
                  {s.current && <div style={{ width: 8, height: 8, borderRadius: '50%', background: c.lavender }} />}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 12.5, fontWeight: s.current ? 700 : 600, color: c.ink }}>
                    {s.l}
                    {s.sub && <span style={{ marginLeft: 6, fontSize: 10, padding: '1px 5px', borderRadius: 4,
                      background: s.subTone === 'ok' ? `${c.ok}22` : s.subTone === 'mute' ? c.subtle : `${c.warn}20`,
                      color: s.subTone === 'ok' ? c.ok : s.subTone === 'mute' ? c.mute : c.warn,
                      fontWeight: 700,
                    }}>{s.sub}</span>}
                  </div>
                  <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>{s.t}</div>
                </div>
              </div>
            ))}
          </DRow>
        </DSection>

        <DSection colors={c} label="提出済み証跡">
          <DRow colors={c}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>あなたの提出</div>
                <div style={{ fontSize: 10.5, color: c.mute }}>写真 1枚 · チャット履歴自動照合済</div>
              </div>
              <span style={{ fontSize: 10.5, color: c.lavender, fontWeight: 700 }}>詳細 ›</span>
            </div>
          </DRow>
          <DRow colors={c} last>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>相手の反論</div>
                <div style={{ fontSize: 10.5, color: c.mute }}>テキスト + 写真 1枚</div>
              </div>
              <span style={{ fontSize: 10.5, color: c.lavender, fontWeight: 700 }}>詳細 ›</span>
            </div>
          </DRow>
        </DSection>

        <DSection colors={c} label="現在の制限">
          <DRow colors={c}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ fontSize: 12, color: c.ink }}>新規打診</div>
              <div style={{ fontSize: 11, color: c.warn, fontWeight: 700 }}>制限中</div>
            </div>
          </DRow>
          <DRow colors={c}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ fontSize: 12, color: c.ink }}>進行中の取引（2件）</div>
              <div style={{ fontSize: 11, color: c.ok, fontWeight: 700 }}>継続可能</div>
            </div>
          </DRow>
          <DRow colors={c} last>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ fontSize: 12, color: c.ink }}>★・取引数の集計</div>
              <div style={{ fontSize: 11, color: c.warn, fontWeight: 700 }}>保留</div>
            </div>
          </DRow>
        </DSection>

        <button style={{
          width: '100%', padding: '14px 16px', borderRadius: 14,
          background: '#fff', border: `0.5px solid ${c.divide}`,
          fontFamily: 'inherit', fontSize: 13, fontWeight: 600, color: c.ink,
          textAlign: 'left',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <span>運営に追加情報を送る</span>
          <span style={{ color: c.lavender }}>›</span>
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 5d. 運営からの追加質問リクエスト
// ─────────────────────────────────────────────────────────────
function D5dAdditionalInfo({ tweaks }) {
  const c = D_C(tweaks);
  const [reply, setReply] = React.useState('');
  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 100,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <DHeader colors={c} title="運営からの追加質問" sub="#DPT-2784 · 24時間以内にご回答ください" step="5d" total={6} />
      <div style={{ padding: '14px 18px 0' }}>

        {/* SLA banner */}
        <div style={{
          padding: 12, borderRadius: 12,
          background: c.warnBg, border: `0.5px solid ${c.warn}40`,
          display: 'flex', gap: 10, marginBottom: 14, alignItems: 'center',
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: 10,
            background: c.warn, color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flex: '0 0 auto',
            fontFamily: '"Inter Tight", sans-serif',
            fontSize: 11, fontWeight: 800, lineHeight: 1,
          }}>
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: 13 }}>23</div>
              <div style={{ fontSize: 7, fontWeight: 700, opacity: 0.9 }}>:42</div>
            </div>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12, fontWeight: 800, color: c.warn, marginBottom: 2 }}>残り 23時間42分</div>
            <div style={{ fontSize: 10.5, color: c.ink, lineHeight: 1.5 }}>
              無回答の場合、提出済み証跡のみで判断します
            </div>
          </div>
        </div>

        {/* Operator question */}
        <DSection colors={c} label="運営からの質問">
          <DRow colors={c} last>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
              <div style={{
                width: 24, height: 24, borderRadius: 7,
                background: `linear-gradient(135deg, ${c.lavender}, ${c.sky})`,
                color: '#fff', fontSize: 10, fontWeight: 800,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>Mg</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12, fontWeight: 700 }}>Megrumサポート</div>
                <div style={{ fontSize: 10, color: c.mute }}>4/28 11:08</div>
              </div>
            </div>
            <div style={{ fontSize: 12.5, color: c.ink, lineHeight: 1.7 }}>
              提出いただいた写真について、撮影時刻と場所が分かるものがあれば追加でご提出ください。<br />
              （例：取引完了直後の会場前で撮影した写真、メモアプリのタイムスタンプ等）
            </div>
            <div style={{
              marginTop: 10, padding: 10, borderRadius: 8,
              background: c.subtle,
              fontSize: 11, color: c.mute, lineHeight: 1.6,
            }}>
              ※ 提出が困難な場合は「該当する証跡なし」を選び、状況をテキストでご説明ください
            </div>
          </DRow>
        </DSection>

        {/* Reply textarea */}
        <DSection colors={c} label="あなたの回答">
          <DRow colors={c} last padding="12px">
            <textarea
              value={reply}
              onChange={(e) => setReply(e.target.value)}
              placeholder="状況を説明してください（500字まで）"
              style={{
                width: '100%', minHeight: 100, resize: 'vertical',
                border: 0, outline: 'none',
                fontFamily: 'inherit', fontSize: 12.5,
                color: c.ink, lineHeight: 1.6, background: 'transparent',
                boxSizing: 'border-box', padding: 0,
              }}
            />
            <div style={{ fontSize: 10, color: c.mute, textAlign: 'right' }}>{reply.length}/500</div>
          </DRow>
        </DSection>

        {/* Add evidence */}
        <DSection colors={c} label="追加証跡（任意）">
          <DRow colors={c} last padding="12px">
            <div style={{ display: 'flex', gap: 8, marginBottom: 8 }}>
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
            <button style={{
              width: '100%', padding: '8px 12px', borderRadius: 8,
              background: 'transparent', border: `0.5px solid ${c.divide}`,
              fontFamily: 'inherit', fontSize: 11.5, color: c.mute, fontWeight: 600,
            }}>該当する証跡なし</button>
          </DRow>
        </DSection>
      </div>
      <DStickyCTA colors={c} primary="運営に送信" secondary="下書き保存" primaryDisabled={reply.length === 0} />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 6. 結果通知
// ─────────────────────────────────────────────────────────────
function D6Result({ tweaks, outcome = 'cancelled' }) {
  const c = D_C(tweaks);
  const variants = {
    cancelled: {
      title: '取引取消が認められました',
      sub: '#DPT-2784 · 申告内容が事実と確認されました',
      icon: 'check',
      tone: c.ok,
      summary: '相手から取消の同意を得ました。取引は無効となり、両者の評価には反映されません。',
      actions: [
        { l: '相手の評価', v: '保留→取消（影響なし）' },
        { l: 'あなたの評価', v: '保留→影響なし' },
        { l: '取引数', v: '加算されません' },
      ],
    },
    upheld: {
      title: '相手側の説明が認められました',
      sub: '申告不成立 · 評価入力フェーズに戻ります',
      icon: 'x',
      tone: c.mute,
      summary: '提出された証跡から、相手の説明が事実と判断されました。取引は完了として処理されます。',
      actions: [
        { l: '相手の評価', v: '★4 として反映' },
        { l: 'あなたの評価', v: '通常通り反映' },
        { l: '取引数', v: '+1' },
      ],
    },
  };
  const v = variants[outcome] || variants.cancelled;

  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 100,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <DHeader colors={c} title="運営からの回答" step={6} back={false} />
      <div style={{ padding: '14px 18px 0' }}>

        <div style={{
          padding: '20px 16px',
          background: '#fff',
          border: `0.5px solid ${c.divide}`,
          borderRadius: 14, marginBottom: 14, textAlign: 'center',
        }}>
          <div style={{
            width: 48, height: 48, borderRadius: '50%',
            background: `${v.tone}1a`, color: v.tone,
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
            marginBottom: 10,
          }}>
            {v.icon === 'check' ? (
              <svg width="22" height="22" viewBox="0 0 22 22"><path d="M5 11l4 4 9-9" stroke={v.tone} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
            ) : (
              <svg width="22" height="22" viewBox="0 0 22 22"><path d="M6 6l10 10M16 6L6 16" stroke={v.tone} strokeWidth="2" fill="none" strokeLinecap="round"/></svg>
            )}
          </div>
          <div style={{ fontSize: 16, fontWeight: 800, marginBottom: 4 }}>{v.title}</div>
          <div style={{ fontSize: 11, color: c.mute }}>{v.sub}</div>
        </div>

        <DSection colors={c} label="運営からのコメント">
          <DRow colors={c} last>
            <div style={{ fontSize: 12, color: c.ink, lineHeight: 1.7 }}>
              {v.summary}
            </div>
            <div style={{ fontSize: 10.5, color: c.mute, marginTop: 8 }}>
              4/28 14:32 · Megrumサポート
            </div>
          </DRow>
        </DSection>

        <DSection colors={c} label="評価・取引への反映">
          {v.actions.map((a, i, arr) => (
            <DRow key={i} colors={c} last={i === arr.length - 1}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <div style={{ fontSize: 12, color: c.mute }}>{a.l}</div>
                <div style={{ fontSize: 12, fontWeight: 700, color: c.ink }}>{a.v}</div>
              </div>
            </DRow>
          ))}
        </DSection>

        <button style={{
          width: '100%', padding: '12px 16px', borderRadius: 12,
          background: 'transparent', border: 0,
          fontFamily: 'inherit', fontSize: 12, color: c.mute, fontWeight: 600,
          textAlign: 'center',
        }}>結果に異議がある場合は再審査を申請</button>
      </div>
      <DStickyCTA colors={c} primary="ホームに戻る" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 7. 取引キャンセル / 遅刻通知（同ファイル統合 · 軽量フロー）
// ─────────────────────────────────────────────────────────────
function D7CancelOrLate({ tweaks, kind = 'cancel' }) {
  const c = D_C(tweaks);
  const isCancel = kind === 'cancel';
  const [reason, setReason] = React.useState(0);

  const cancelReasons = [
    '体調不良 / 急用',
    '会場・時間が合わなくなった',
    '他で交換が成立した',
    '相手と連絡がつかなくなった',
    'その他',
  ];
  const lateReasons = [
    '電車遅延 / 交通機関',
    '会場での合流に時間がかかる',
    '前の取引が押している',
    'その他',
  ];
  const reasons = isCancel ? cancelReasons : lateReasons;
  const lateAmounts = ['10分', '20分', '30分', '1時間', '1時間以上'];
  const [late, setLate] = React.useState(1);

  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 100,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <DHeader
        colors={c}
        title={isCancel ? '取引をキャンセル' : '遅刻を連絡'}
        sub={isCancel ? '相手と合意の上で取り消します' : '到着が遅れる旨を相手に通知'}
      />
      <div style={{ padding: '14px 18px 0' }}>

        <DSection colors={c} label="取引">
          <DRow colors={c} last>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10,
                background: `linear-gradient(135deg, ${c.lavender}33, ${c.sky}33)`,
                color: c.lavender, fontSize: 12, fontWeight: 800,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>L</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>@lumi_sua</div>
                <div style={{ fontSize: 10.5, color: c.mute }}>横浜アリーナ · 18:30 西ゲート</div>
              </div>
            </div>
          </DRow>
        </DSection>

        {!isCancel && (
          <DSection colors={c} label="どのくらい遅れますか">
            <DRow colors={c} last padding="12px 14px">
              <div style={{ display: 'flex', gap: 6 }}>
                {lateAmounts.map((a, i) => (
                  <button key={a} onClick={() => setLate(i)} style={{
                    flex: 1, padding: '8px 0', borderRadius: 10,
                    background: late === i ? c.lavender : c.subtle,
                    color: late === i ? '#fff' : c.ink,
                    border: 0, fontFamily: 'inherit',
                    fontSize: 11, fontWeight: 700,
                  }}>{a}</button>
                ))}
              </div>
            </DRow>
          </DSection>
        )}

        <DSection colors={c} label="理由">
          {reasons.map((r, i, arr) => (
            <DRow key={i} colors={c} last={i === arr.length - 1} padding="0">
              <button onClick={() => setReason(i)} style={{
                width: '100%', padding: '12px 14px',
                background: reason === i ? `${c.lavender}10` : 'transparent',
                border: 0, fontFamily: 'inherit', textAlign: 'left',
                display: 'flex', alignItems: 'center', gap: 10,
              }}>
                <div style={{
                  width: 16, height: 16, borderRadius: '50%',
                  border: `1.5px solid ${reason === i ? c.lavender : 'rgba(58,50,74,0.25)'}`,
                  background: reason === i ? c.lavender : 'transparent',
                  flex: '0 0 auto',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  {reason === i && <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#fff' }} />}
                </div>
                <span style={{ fontSize: 12.5, fontWeight: reason === i ? 700 : 500, color: c.ink }}>{r}</span>
              </button>
            </DRow>
          ))}
        </DSection>

        <DSection colors={c} label="メッセージ（任意）">
          <DRow colors={c} last padding="0">
            <textarea placeholder={isCancel ? '相手への一言を添えると印象が変わります' : '会場到着後に再連絡します など'} rows={3} style={{
              width: '100%', padding: 14, border: 0,
              fontFamily: 'inherit', fontSize: 12.5, lineHeight: 1.6,
              color: c.ink, resize: 'none', boxSizing: 'border-box',
              background: 'transparent', outline: 'none',
            }} />
          </DRow>
        </DSection>

        <div style={{
          padding: '10px 12px', borderRadius: 10,
          background: isCancel ? c.warnBg : `${c.lavender}10`,
          fontSize: 10.5, color: c.ink, lineHeight: 1.6, marginBottom: 14,
        }}>
          {isCancel ? (
            <><b>📝 キャンセルについて</b><br />
              • 相手の同意があれば双方の評価に影響しません<br />
              • 相手が同意しない場合、運営仲裁に進みます（C-3 異常系）<br />
              • 当日24時間以内のキャンセルは「直前キャンセル」として履歴に残ります</>
          ) : (
            <><b>📝 遅刻について</b><br />
              • 相手にプッシュ通知が届きます<br />
              • 30分以上の場合、相手は取引キャンセルを選択できます<br />
              • 連絡なしの遅刻は履歴に残ります</>
          )}
        </div>
      </div>
      <DStickyCTA
        colors={c}
        primary={isCancel ? 'キャンセルを送信' : '遅刻を通知'}
        secondary="戻る"
        primaryStyle={isCancel ? 'warn' : null}
      />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 6c. 再審査申立てフォーム
// ─────────────────────────────────────────────────────────────
function D6cReappeal({ tweaks }) {
  const c = D_C(tweaks);
  const [reason, setReason] = React.useState('');
  const [grounds, setGrounds] = React.useState(0);
  const groundsList = [
    { id: 'newev', l: '新しい証跡がある', sub: '当時提出できなかった写真・記録など' },
    { id: 'misjudge', l: '事実の判断に納得できない', sub: '提出済み証跡の解釈について再考を求める' },
    { id: 'misapply', l: 'ルールのあてはめが違う気がする', sub: '判定基準が今回のケースに合わない' },
    { id: 'other', l: 'その他', sub: '上記に当てはまらない理由' },
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
      <DHeader colors={c} title="再審査の申立て" sub="#DPT-2784 · 申立て期限 5/5 まで（7日間）" step="6c" total={6} />
      <div style={{ padding: '14px 18px 0' }}>

        <div style={{
          padding: 12, borderRadius: 12,
          background: c.warnBg, border: `0.5px solid ${c.warn}40`,
          display: 'flex', gap: 10, marginBottom: 14,
        }}>
          <div style={{
            width: 22, height: 22, borderRadius: '50%',
            background: c.warn, color: '#fff',
            fontSize: 13, fontWeight: 800,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flex: '0 0 auto', marginTop: 1,
          }}>!</div>
          <div style={{ fontSize: 11.5, color: c.ink, lineHeight: 1.6 }}>
            再審査は<b>1取引につき1回まで</b>申立て可能です。<br />
            運営が48時間以内に再審査の可否を判断します。
          </div>
        </div>

        <DSection colors={c} label="申立ての理由">
          {groundsList.map((g, i) => (
            <DRow key={g.id} colors={c} last={i === groundsList.length - 1} padding="0">
              <button onClick={() => setGrounds(i)} style={{
                width: '100%', padding: '13px 14px',
                background: grounds === i ? `${c.lavender}10` : 'transparent',
                border: 0, fontFamily: 'inherit',
                display: 'flex', alignItems: 'flex-start', gap: 12,
                textAlign: 'left', cursor: 'pointer',
              }}>
                <div style={{
                  width: 18, height: 18, borderRadius: '50%',
                  border: `1.5px solid ${grounds === i ? c.lavender : 'rgba(58,50,74,0.25)'}`,
                  background: grounds === i ? c.lavender : 'transparent',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flex: '0 0 auto', marginTop: 1.5,
                }}>
                  {grounds === i && <div style={{ width: 7, height: 7, borderRadius: '50%', background: '#fff' }} />}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 12.5, fontWeight: 700, color: c.ink }}>{g.l}</div>
                  <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>{g.sub}</div>
                </div>
              </button>
            </DRow>
          ))}
        </DSection>

        <DSection colors={c} label="申立ての具体的な内容">
          <DRow colors={c} last padding="12px">
            <textarea
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="判断に納得いかない理由・新しい事実・補足情報を具体的にご記入ください（500字まで）"
              style={{
                width: '100%', minHeight: 110, resize: 'vertical',
                border: 0, outline: 'none',
                fontFamily: 'inherit', fontSize: 12.5,
                color: c.ink, lineHeight: 1.6, background: 'transparent',
                boxSizing: 'border-box', padding: 0,
              }}
            />
            <div style={{ fontSize: 10, color: c.mute, textAlign: 'right' }}>{reason.length}/500</div>
          </DRow>
        </DSection>

        <DSection colors={c} label="追加証跡（任意）">
          <DRow colors={c} last padding="12px">
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
          </DRow>
        </DSection>

        <div style={{ fontSize: 10.5, color: c.mute, lineHeight: 1.6, padding: '0 4px', marginBottom: 16 }}>
          ※ 申立て中は本取引の評価・取引数への反映が一時的に保留されます<br />
          ※ 虚偽の申立てが確認された場合、アカウント制限の対象となります
        </div>
      </div>
      <DStickyCTA colors={c} primary="再審査を申立てる" secondary="戻る" primaryDisabled={reason.length < 20} primaryStyle="warn" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 6d. 再審査受付ステータス
// ─────────────────────────────────────────────────────────────
function D6dReappealReceived({ tweaks }) {
  const c = D_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', background: c.bg,
      fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, position: 'relative',
      paddingTop: 100, paddingBottom: 100,
      overflowY: 'auto', boxSizing: 'border-box',
      fontFeatureSettings: '"palt"',
    }}>
      <DHeader colors={c} title="再審査ステータス" sub="#DPT-2784-RE · 受付完了" step="6d" total={6} back={false} />
      <div style={{ padding: '14px 18px 0' }}>

        <div style={{
          padding: '20px 16px',
          background: '#fff',
          border: `0.5px solid ${c.divide}`,
          borderRadius: 14, marginBottom: 14, textAlign: 'center',
        }}>
          <div style={{
            width: 48, height: 48, borderRadius: '50%',
            background: `${c.lavender}1a`, color: c.lavender,
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
            marginBottom: 10,
          }}>
            <svg width="22" height="22" viewBox="0 0 22 22">
              <path d="M11 6v5l3 2" stroke={c.lavender} strokeWidth="2" fill="none" strokeLinecap="round"/>
              <circle cx="11" cy="11" r="8" stroke={c.lavender} strokeWidth="1.6" fill="none"/>
            </svg>
          </div>
          <div style={{ fontSize: 16, fontWeight: 800, marginBottom: 4 }}>再審査受付中</div>
          <div style={{ fontSize: 11, color: c.mute }}>運営が48時間以内に可否を判断します</div>
        </div>

        <DSection colors={c} label="進捗">
          <DRow colors={c} last padding="14px">
            {[
              { l: '再審査申立て受付', t: '5/2 09:14', done: true },
              { l: '運営による可否判断', t: '5/4 09:14 まで · 進行中', current: true },
              { l: '再審査の実施 / 却下通知', t: '可否判断後', done: false },
              { l: '最終結果', t: '実施の場合 5/8 まで', done: false },
            ].map((s, i, arr) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'flex-start', gap: 10,
                paddingBottom: i === arr.length - 1 ? 0 : 14,
                position: 'relative',
              }}>
                {i < arr.length - 1 && (
                  <div style={{
                    position: 'absolute', left: 9, top: 22, bottom: -2, width: 1.5,
                    background: s.done ? c.lavender : c.divide,
                  }} />
                )}
                <div style={{
                  width: 20, height: 20, borderRadius: '50%',
                  background: s.done ? c.lavender : (s.current ? '#fff' : c.subtle),
                  border: s.current ? `2px solid ${c.lavender}` : 'none',
                  color: '#fff', fontSize: 10, fontWeight: 800,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flex: '0 0 auto', position: 'relative', zIndex: 1,
                }}>
                  {s.done && <svg width="10" height="8" viewBox="0 0 10 8"><path d="M1 4l3 3 5-6" stroke="#fff" strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>}
                  {s.current && <div style={{ width: 8, height: 8, borderRadius: '50%', background: c.lavender }} />}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 12.5, fontWeight: s.current ? 700 : 600, color: c.ink }}>{s.l}</div>
                  <div style={{ fontSize: 10.5, color: c.mute, marginTop: 1 }}>{s.t}</div>
                </div>
              </div>
            ))}
          </DRow>
        </DSection>

        <DSection colors={c} label="申立て内容">
          <DRow colors={c}>
            <div style={{ fontSize: 10.5, color: c.mute, marginBottom: 4 }}>理由区分</div>
            <div style={{ fontSize: 12.5, fontWeight: 700, color: c.ink }}>新しい証跡がある</div>
          </DRow>
          <DRow colors={c} last>
            <div style={{ fontSize: 10.5, color: c.mute, marginBottom: 4 }}>申立て本文</div>
            <div style={{ fontSize: 12, color: c.ink, lineHeight: 1.6 }}>
              当日は会場が混雑しており撮影できませんでしたが、後日会場関係者から提供された記録を入手したため再審査を申立てます。
            </div>
            <div style={{ fontSize: 10.5, color: c.mute, marginTop: 6 }}>追加証跡: 写真2枚</div>
          </DRow>
        </DSection>

        <DSection colors={c} label="現在の状態">
          <DRow colors={c}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ fontSize: 12, color: c.ink }}>本取引の評価・取引数</div>
              <div style={{ fontSize: 11, color: c.warn, fontWeight: 700 }}>再保留</div>
            </div>
          </DRow>
          <DRow colors={c} last>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ fontSize: 12, color: c.ink }}>新規打診・進行中の取引</div>
              <div style={{ fontSize: 11, color: c.ok, fontWeight: 700 }}>制限なし</div>
            </div>
          </DRow>
        </DSection>
      </div>
      <DStickyCTA colors={c} primary="ホームに戻る" secondary="申立て取下げ" />
    </div>
  );
}

// __MVP_EXPORTS__
Object.assign(window, { D1Category, D2Evidence, D3Submitted, D4Respondent, D5Arbitration, D5dAdditionalInfo, D6Result, D6cReappeal, D6dReappealReceived, D7CancelOrLate });
