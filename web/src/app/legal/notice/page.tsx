import { HeaderBack } from "@/components/auth/HeaderBack";
import {
  LPArticle,
  LPDataRow,
  LPFooter,
  LPInfoBox,
} from "../_components";

export const metadata = {
  title: "特定商取引法に基づく表記 — iHub",
};

export default function LegalNoticePage() {
  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack
        title="特定商取引法に基づく表記"
        sub="運営事業者情報"
        backHref="/"
      />
      <div className="mx-auto w-full max-w-md flex-1 overflow-y-auto px-5 pb-12 pt-4">
        <LPInfoBox>
          特定商取引法第 11
          条（通信販売についての広告）に基づき、運営事業者の情報を表示します。
        </LPInfoBox>

        {/* 事業者情報 */}
        <div className="mb-4 rounded-[14px] border border-[#3a324a14] bg-white px-3.5">
          <LPDataRow
            label="代表者名"
            value={
              <>
                非公表
                <br />
                <span className="text-[11px] text-[#3a324a8c]">
                  ※代表者のプライバシーに関わる事項のため公表しておりません。理由を明示のうえお問い合わせをいただきましたら、遅滞なく回答いたします。
                </span>
              </>
            }
          />
          <LPDataRow
            label="所在地"
            value={
              <>
                非公表
                <br />
                <span className="text-[11px] text-[#3a324a8c]">※同上</span>
              </>
            }
          />
          <LPDataRow
            label="電話番号"
            value={
              <>
                非公表
                <br />
                <span className="text-[11px] text-[#3a324a8c]">
                  ※同上、お問い合わせは原則メールで承ります
                </span>
              </>
            }
          />
          <LPDataRow label="メールアドレス" value="support@ihub.tokyo" />
          <LPDataRow
            label="受付時間"
            value="平日 10:00〜18:00（土日祝・年末年始を除く）"
            isLast
          />
        </div>

        {/* サービス情報 */}
        <div className="mb-4 rounded-[14px] border border-[#3a324a14] bg-white px-3.5">
          <LPDataRow label="サービス名" value="iHub（アイハブ）" />
          <LPDataRow
            label="サービス内容"
            value={
              <>
                個人間グッズ交換マッチングプラットフォーム
                <br />
                <span className="text-[11px] text-[#3a324a8c]">
                  利用者間の物々交換を仲介するサービスを提供します
                </span>
              </>
            }
          />
          <LPDataRow
            label="基本料金"
            value={
              <>
                <b className="text-[#3a324a]">マッチング・取引機能は無料</b>
                <br />
                <span className="text-[11px] text-[#3a324a8c]">
                  ※ コア機能（マッチング・打診・取引・申告）は永久無料
                </span>
              </>
            }
          />
          <LPDataRow
            label="有料機能"
            value={
              <>
                <b>ブースト</b>：単発 ¥150 / 5 個 ¥600 / 10 個 ¥1,000
                <br />
                <b>Premium 会員</b>：月額 ¥500 / 年額 ¥4,800
                <br />
                <b>めぐりPlus</b>：月額 ¥1,000
                <br />
                <span className="text-[11px] text-[#3a324a8c]">
                  ※ すべて税込。Phase β 以降に提供予定
                </span>
              </>
            }
          />
          <LPDataRow
            label="支払方法"
            value={
              <>
                クレジットカード（Stripe）
                <br />
                Apple In-App Purchase / Google Play Billing
              </>
            }
          />
          <LPDataRow label="支払時期" value="購入時即時" />
          <LPDataRow
            label="商品引渡し時期"
            value="決済完了即時（デジタルコンテンツのため）"
          />
          <LPDataRow
            label="返品・解約"
            value={
              <>
                <b>ブースト</b>：未使用分は 30 日以内なら返金可
                <br />
                <b>Premium 会員</b>
                ・<b>めぐりPlus</b>
                ：いつでも解約可（期間終了まで使用可、中途返金なし）
              </>
            }
            isLast
          />
        </div>

        <LPInfoBox tone="warn">
          <b>本サービスにおける取引の性質について</b>
          <br />
          iHub は利用者間の
          <b>物々交換（金銭授受を伴わない交換）</b>を仲介するプラットフォームです。当社は取引の当事者ではなく、利用者間の合意による交換を支援する立場です。利用者間で発生した取引に関する責任は、原則として当事者間で負うものとします。
        </LPInfoBox>

        <LPArticle num="補足" title="商品の引き渡し時期・方法">
          利用者間の合意に基づく現地交換（対面手渡し）が原則です。郵送による交換は
          MVP 範囲外とします。
        </LPArticle>

        <LPArticle num="補足" title="返品・キャンセル">
          交換成立後の返品については、利用者間の合意により対応するものとします。明らかな相違（受け取った点数が少ない・状態が著しく異なる等）があった場合は、本サービス内の「申告」フローよりご対応ください。
        </LPArticle>

        <LPFooter updatedAt="掲載日：2026 年 5 月 1 日" />
      </div>
    </main>
  );
}
