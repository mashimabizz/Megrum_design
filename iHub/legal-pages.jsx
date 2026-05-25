// ─────────────────────────────────────────────────────────────
// legal-pages.jsx — 法的ページ3画面
// 利用規約 / プライバシーポリシー / 特定商取引法に基づく表記
// ※ 内容はモック。実運用前に法務確認必須
// ─────────────────────────────────────────────────────────────

const LP_C = (t) => ({
  lavender: t.primary,
  sky: t.secondary,
  pink: t.accent,
  ink: '#3a324a',
  mute: 'rgba(58,50,74,0.55)',
  hint: 'rgba(58,50,74,0.4)',
  subtle: 'rgba(58,50,74,0.06)',
  divide: 'rgba(58,50,74,0.08)',
  bg: '#fbf9fc',
});

function LPHeader({ colors: c, title, sub }) {
  return (
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
          <div style={{ fontSize: 15, fontWeight: 700, color: c.ink }}>{title}</div>
          {sub && <div style={{ fontSize: 11, color: c.mute, marginTop: 1 }}>{sub}</div>}
        </div>
      </div>
    </div>
  );
}

function LPArticle({ num, title, children, colors: c }) {
  return (
    <div style={{ marginBottom: 22 }}>
      <div style={{
        fontSize: 13, fontWeight: 700, color: c.ink,
        marginBottom: 8,
        display: 'flex', alignItems: 'baseline', gap: 8,
      }}>
        {num && (
          <span style={{
            color: c.lavender,
            fontFamily: '"Inter Tight", system-ui',
            fontSize: 11, letterSpacing: 0.3,
            padding: '2px 8px', borderRadius: 999,
            background: `${c.lavender}14`,
          }}>{num}</span>
        )}
        <span>{title}</span>
      </div>
      <div style={{ fontSize: 12, color: c.ink, lineHeight: 1.8 }}>
        {children}
      </div>
    </div>
  );
}

function LPInfoBox({ colors: c, children, tone = 'info' }) {
  const bg = tone === 'warn' ? `${c.pink}14` : `${c.lavender}10`;
  const border = tone === 'warn' ? `${c.pink}55` : `${c.lavender}30`;
  return (
    <div style={{
      padding: '12px 14px', borderRadius: 12,
      background: bg, border: `1px solid ${border}`,
      fontSize: 12, color: c.ink, lineHeight: 1.7,
      marginBottom: 18,
    }}>{children}</div>
  );
}

function LPDataRow({ label, value, colors: c, last }) {
  return (
    <div style={{
      display: 'flex', padding: '12px 0',
      borderBottom: last ? 'none' : `0.5px solid ${c.divide}`,
      gap: 12,
    }}>
      <div style={{
        fontSize: 11, color: c.mute, fontWeight: 600,
        width: 110, flexShrink: 0,
      }}>{label}</div>
      <div style={{ fontSize: 12.5, color: c.ink, fontWeight: 500, lineHeight: 1.6 }}>
        {value}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 1. Terms of Service - 利用規約
// ─────────────────────────────────────────────────────────────
function TermsOfService({ tweaks }) {
  const c = LP_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      <LPHeader colors={c} title="利用規約" sub="最終更新日：2026年4月30日" />
      <div style={{ padding: '20px 22px 0' }}>
        <LPInfoBox colors={c}>
          この利用規約（以下「本規約」）は、iHub 運営者（以下「当社」）が提供するグッズ交換プラットフォーム「iHub」（以下「本サービス」）の利用条件を定めるものです。本サービスをご利用の方（以下「利用者」）は、本規約に同意したうえでご利用ください。
        </LPInfoBox>

        <LPArticle num="第1条" title="本規約の適用" colors={c}>
          1. 本規約は、本サービスの利用に関する当社と利用者との間の権利義務関係を定めることを目的とし、利用者と当社との間の本サービスの利用に関わる一切の関係に適用されます。<br/>
          2. 当社が本サービス上で掲載するガイドラインや個別規定は、本規約の一部を構成するものとします。
        </LPArticle>

        <LPArticle num="第2条" title="利用資格・年齢制限" colors={c}>
          1. 本サービスの利用は、満13歳以上の方に限ります。<br/>
          2. 未成年者が本サービスを利用する場合は、親権者の同意を得たものとみなします。<br/>
          3. 反社会的勢力に該当する方、過去に当社から利用停止処分を受けた方は本サービスを利用できません。
        </LPArticle>

        <LPArticle num="第3条" title="アカウント登録" colors={c}>
          1. 利用者は、当社所定の方法により正確な情報をもってアカウント登録を行うものとします。<br/>
          2. 利用者は、登録情報に変更があった場合、速やかに当社所定の方法で変更手続きを行うものとします。<br/>
          3. アカウント情報の管理は利用者の責任で行うものとし、第三者に譲渡・貸与してはなりません。
        </LPArticle>

        <LPArticle num="第4条" title="利用者の義務" colors={c}>
          利用者は、本サービスの利用にあたり、以下の事項を遵守するものとします。<br/>
          ・関係法令および本規約を遵守すること<br/>
          ・他の利用者に対して誠実に対応すること<br/>
          ・取引において合意した内容を遵守すること<br/>
          ・本サービスの円滑な運営に協力すること
        </LPArticle>

        <LPArticle num="第5条" title="禁止事項" colors={c}>
          利用者は、以下の行為を行ってはなりません。<br/>
          ・法令、公序良俗に違反する行為<br/>
          ・犯罪行為に関連する行為<br/>
          ・他の利用者または第三者の権利を侵害する行為<br/>
          ・なりすまし、虚偽情報の登録<br/>
          ・本サービスを通じた金銭の授受、現金売買<br/>
          ・公式に禁止されているグッズの取引<br/>
          ・スパム、嫌がらせ、つきまとい、誹謗中傷<br/>
          ・偽造品・違法コピーの取引<br/>
          ・本サービスの運営を妨害する行為<br/>
          ・その他、当社が不適切と判断する行為
        </LPArticle>

        <LPArticle num="第6条" title="取引・交換について" colors={c}>
          1. 本サービスは利用者間のグッズ交換を仲介するプラットフォームを提供するものであり、当社は取引の当事者ではありません。<br/>
          2. 取引に関するトラブルは、原則として当事者間で解決するものとします。当社は必要に応じて仲裁を行いますが、解決を保証するものではありません。<br/>
          3. 取引証跡（D-2 写真）の偽造・改ざんは禁止します。<br/>
          4. 当社は、必要に応じて利用者間のメッセージや取引情報を確認することがあります。
        </LPArticle>

        <LPArticle num="第7条" title="知的財産権" colors={c}>
          本サービスに関する一切の知的財産権は、当社または正当な権利者に帰属します。利用者が投稿したコンテンツについて、利用者は本サービスの運営に必要な範囲で当社に利用許諾を与えるものとします。
        </LPArticle>

        <LPArticle num="第8条" title="サービスの変更・停止" colors={c}>
          当社は、利用者への事前の通知なく、本サービスの内容を変更し、または提供を停止・終了することができるものとします。これにより利用者または第三者に損害が生じた場合でも、当社は一切の責任を負いません。
        </LPArticle>

        <LPArticle num="第9条" title="アカウントの削除・利用停止" colors={c}>
          1. 利用者は、いつでも自らの意思によりアカウントを削除できます。<br/>
          2. 当社は、利用者が本規約に違反した場合、または違反のおそれがあると判断した場合、事前の通知なくアカウントを削除または利用停止できるものとします。
        </LPArticle>

        <LPArticle num="第10条" title="免責事項" colors={c}>
          1. 当社は、本サービスに関して、その完全性、正確性、確実性、有用性等につき、いかなる保証も行いません。<br/>
          2. 利用者間で生じた一切のトラブルについて、当社は責任を負いません。<br/>
          3. 当社の責に帰すべき事由により利用者に損害が生じた場合でも、その損害賠償の範囲は通常生ずべき直接の損害に限られ、当社の故意または重過失による場合を除き、過去6ヶ月の利用料金（無料のサービスについては0円）を上限とします。
        </LPArticle>

        <LPArticle num="第11条" title="規約の変更" colors={c}>
          当社は、必要と判断した場合、本規約を変更できるものとします。変更後の規約は、本サービス上に掲載した時点から効力を生じます。
        </LPArticle>

        <LPArticle num="第12条" title="準拠法・裁判管轄" colors={c}>
          1. 本規約の準拠法は日本法とします。<br/>
          2. 本サービスに関する紛争については、東京地方裁判所を第一審の専属的合意管轄裁判所とします。
        </LPArticle>

        <div style={{
          fontSize: 11, color: c.mute, lineHeight: 1.7,
          textAlign: 'right', paddingTop: 18, paddingBottom: 30,
          borderTop: `0.5px solid ${c.divide}`,
        }}>
          附則：本規約は 2026年4月30日 から施行します。<br/>
          iHub 運営者
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 2. Privacy Policy - プライバシーポリシー
// ─────────────────────────────────────────────────────────────
function PrivacyPolicy({ tweaks }) {
  const c = LP_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      <LPHeader colors={c} title="プライバシーポリシー" sub="最終更新日:2026年4月30日" />
      <div style={{ padding: '20px 22px 0' }}>
        <LPInfoBox colors={c}>
          iHub 運営者（以下「当社」）は、利用者の個人情報を尊重し、適切に取り扱うことを社会的責務と認識し、関連法令を遵守するとともに、本プライバシーポリシーに従って個人情報を取り扱います。
        </LPInfoBox>

        <LPArticle num="1" title="取得する個人情報" colors={c}>
          当社は、本サービスの提供にあたり、以下の情報を取得することがあります。<br/>
          ・メールアドレス<br/>
          ・ハンドル名・プロフィール情報<br/>
          ・性別・主な活動エリア（任意）<br/>
          ・推し設定（推しグループ・メンバー）<br/>
          ・登録した在庫・ウィッシュリスト情報<br/>
          ・取引履歴・取引証跡画像<br/>
          ・位置情報（AW設定時、許可された場合のみ）<br/>
          ・端末情報（OS・ブラウザ・アプリバージョン）<br/>
          ・利用ログ・アクセス情報
        </LPArticle>

        <LPArticle num="2" title="利用目的" colors={c}>
          取得した個人情報は、以下の目的で利用します。<br/>
          ・本サービスの提供・運営・改善<br/>
          ・利用者間のマッチング・取引仲介<br/>
          ・本人確認・不正利用の防止<br/>
          ・問い合わせ対応・サポート提供<br/>
          ・規約違反の調査・対応<br/>
          ・統計データの作成（個人を識別できない形式）<br/>
          ・新サービス・機能の通知（利用者の同意を得た場合）
        </LPArticle>

        <LPArticle num="3" title="第三者提供" colors={c}>
          当社は、以下の場合を除き、利用者の同意なく個人情報を第三者に提供しません。<br/>
          ・法令に基づく場合<br/>
          ・人の生命、身体または財産の保護のために必要がある場合<br/>
          ・公衆衛生の向上または児童の健全な育成の推進のために必要がある場合<br/>
          ・国の機関等の法令の定める事務の遂行に協力する必要がある場合
        </LPArticle>

        <LPArticle num="4" title="安全管理措置" colors={c}>
          当社は、個人情報の漏洩、滅失または毀損の防止その他の個人情報の安全管理のために、必要かつ適切な措置を講じます。アクセス制限・通信の暗号化・ストレージの暗号化等の技術的措置、および従業員教育・規程整備等の組織的措置を実施しています。
        </LPArticle>

        <LPArticle num="5" title="個人情報の開示・訂正・削除" colors={c}>
          利用者は、当社が保有する自己の個人情報について、開示・訂正・追加・削除を請求できます。請求は本サービスの「設定 → アカウント削除」または下記の問い合わせ窓口にて受け付けます。
        </LPArticle>

        <LPArticle num="6" title="Cookie・類似技術" colors={c}>
          本サービスでは、利用者の利便性向上のために Cookie および類似技術を使用することがあります。利用者はブラウザの設定により Cookie の使用を制限できますが、その場合、本サービスの一部機能が利用できなくなる可能性があります。
        </LPArticle>

        <LPArticle num="7" title="未成年者の個人情報" colors={c}>
          本サービスは満13歳以上の方を対象としています。未成年者が本サービスを利用する場合は、親権者の同意のもとでご利用ください。
        </LPArticle>

        <LPArticle num="8" title="お問い合わせ窓口" colors={c}>
          個人情報の取り扱いに関するお問い合わせは、以下の窓口までご連絡ください。<br/>
          <br/>
          <b style={{ color: c.ink }}>iHub 個人情報保護管理者</b><br/>
          メール：support@ihub.tokyo<br/>
          受付時間：平日 10:00〜18:00（土日祝・年末年始を除く）
        </LPArticle>

        <LPArticle num="9" title="ポリシーの変更" colors={c}>
          当社は、必要に応じて本ポリシーを変更することがあります。変更後の内容は、本サービス上で公表した時点から適用されます。
        </LPArticle>

        <div style={{
          fontSize: 11, color: c.mute, lineHeight: 1.7,
          textAlign: 'right', paddingTop: 18, paddingBottom: 30,
          borderTop: `0.5px solid ${c.divide}`,
        }}>
          制定：2026年4月30日<br/>
          iHub 運営者
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 3. Legal Notice - 特定商取引法に基づく表記
// ─────────────────────────────────────────────────────────────
function LegalNotice({ tweaks }) {
  const c = LP_C(tweaks);
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: c.bg, fontFamily: '"Noto Sans JP", -apple-system, system-ui',
      color: c.ink, paddingTop: 96, paddingBottom: 30,
      boxSizing: 'border-box', overflowY: 'auto',
    }}>
      <LPHeader colors={c} title="特定商取引法に基づく表記" sub="運営事業者情報" />
      <div style={{ padding: '20px 22px 0' }}>
        <LPInfoBox colors={c}>
          特定商取引法第11条（通信販売についての広告）に基づき、運営事業者の情報を表示します。
        </LPInfoBox>

        <div style={{
          background: '#fff', borderRadius: 14,
          border: `0.5px solid ${c.divide}`,
          padding: '4px 16px', marginBottom: 18,
        }}>
          <LPDataRow colors={c} label="代表者名" value={
            <>非公表<br/><span style={{ fontSize: 11, color: c.mute }}>※代表者のプライバシーに関わる事項のため公表しておりません。理由を明示のうえ問い合わせをいただきましたら、遅滞なく回答いたします。</span></>
          } />
          <LPDataRow colors={c} label="所在地" value={
            <>非公表<br/><span style={{ fontSize: 11, color: c.mute }}>※同上</span></>
          } />
          <LPDataRow colors={c} label="電話番号" value={
            <>非公表<br/><span style={{ fontSize: 11, color: c.mute }}>※同上、お問い合わせは原則メールで承ります</span></>
          } />
          <LPDataRow colors={c} label="メールアドレス" value="support@ihub.tokyo" />
          <LPDataRow colors={c} label="受付時間" value="平日 10:00〜18:00（土日祝・年末年始を除く）" last />
        </div>

        <div style={{
          background: '#fff', borderRadius: 14,
          border: `0.5px solid ${c.divide}`,
          padding: '4px 16px', marginBottom: 18,
        }}>
          <LPDataRow colors={c} label="サービス名" value="iHub（アイハブ）" />
          <LPDataRow colors={c} label="サービス内容" value={
            <>個人間グッズ交換マッチングプラットフォーム<br/><span style={{ fontSize: 11, color: c.mute }}>利用者間の物々交換を仲介するサービスを提供します</span></>
          } />
          <LPDataRow colors={c} label="基本料金" value={
            <><b style={{ color: c.ink }}>マッチング・取引機能は無料</b><br/><span style={{ fontSize: 11, color: c.mute }}>※コア機能（マッチング・打診・取引・dispute）は永久無料</span></>
          } />
          <LPDataRow colors={c} label="有料機能" value={
            <>
              <b>ブースト</b>：単発 ¥150 / 5個 ¥600 / 10個 ¥1,000<br/>
              <b>Premium 会員</b>：月額 ¥500 / 年額 ¥4,800<br/>
              <b>めぐりPlus</b>：月額 ¥1,000<br/>
              <span style={{ fontSize: 11, color: c.mute }}>※すべて税込。Phase β 以降に提供予定</span>
            </>
          } />
          <LPDataRow colors={c} label="支払方法" value={
            <>クレジットカード（Stripe）<br/>Apple In-App Purchase / Google Play Billing</>
          } />
          <LPDataRow colors={c} label="支払時期" value="購入時即時" />
          <LPDataRow colors={c} label="商品引渡し時期" value={
            <>決済完了即時（デジタルコンテンツのため）</>
          } />
          <LPDataRow colors={c} label="返品・解約" value={
            <>
              <b>ブースト</b>：未使用分は30日以内なら返金可<br/>
              <b>Premium 会員・めぐりPlus</b>：いつでも解約可（期間終了まで使用可、中途返金なし）
            </>
          } last />
        </div>

        <LPInfoBox colors={c} tone="warn">
          <b>本サービスにおける取引の性質について</b><br/>
          iHubは利用者間の<b>物々交換（金銭授受を伴わない交換）</b>を仲介するプラットフォームです。当社は取引の当事者ではなく、利用者間の合意による交換を支援する立場です。利用者間で発生した取引に関する責任は、原則として当事者間で負うものとします。
        </LPInfoBox>

        <LPArticle num="補足" title="商品の引き渡し時期・方法" colors={c}>
          利用者間の合意に基づく現地交換（対面手渡し）が原則です。郵送による交換はMVP範囲外とします。
        </LPArticle>

        <LPArticle num="補足" title="返品・キャンセル" colors={c}>
          交換成立後の返品については、利用者間の合意により対応するものとします。明らかな相違（受け取った点数が少ない・状態が著しく異なる等）があった場合は、本サービス内の「相違あり」申告フローよりご対応ください。
        </LPArticle>

        <div style={{
          fontSize: 11, color: c.mute, lineHeight: 1.7,
          textAlign: 'right', paddingTop: 18, paddingBottom: 30,
          borderTop: `0.5px solid ${c.divide}`,
        }}>
          掲載日：2026年5月1日<br/>
          iHub 運営
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { TermsOfService, PrivacyPolicy, LegalNotice });
