import { HeaderBack } from "@/components/auth/HeaderBack";
import { LPArticle, LPFooter, LPInfoBox } from "../_components";

export const metadata = {
  title: "プライバシーポリシー — Megrum",
};

export default function PrivacyPage() {
  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack
        title="プライバシーポリシー"
        sub="最終更新日：2026年4月30日"
        backHref="/"
      />
      <div className="mx-auto w-full max-w-md flex-1 overflow-y-auto px-5 pb-12 pt-4">
        <LPInfoBox>
          Megrum
          運営者（以下「当社」）は、利用者の個人情報を尊重し、適切に取り扱うことを社会的責務と認識し、関連法令を遵守するとともに、本プライバシーポリシーに従って個人情報を取り扱います。
        </LPInfoBox>

        <LPArticle num="1" title="取得する個人情報">
          当社は、本サービスの提供にあたり、以下の情報を取得することがあります。
          <br />
          ・メールアドレス
          <br />
          ・ハンドル名・プロフィール情報
          <br />
          ・性別・主な活動エリア（任意）
          <br />
          ・推し設定（推しグループ・メンバー）
          <br />
          ・登録した在庫・ウィッシュリスト情報
          <br />
          ・取引履歴・取引証跡画像
          <br />
          ・位置情報（AW 設定時、許可された場合のみ）
          <br />
          ・端末情報（OS・ブラウザ・アプリバージョン）
          <br />
          ・利用ログ・アクセス情報
        </LPArticle>

        <LPArticle num="2" title="利用目的">
          取得した個人情報は、以下の目的で利用します。
          <br />
          ・本サービスの提供・運営・改善
          <br />
          ・利用者間のマッチング・取引仲介
          <br />
          ・本人確認・不正利用の防止
          <br />
          ・問い合わせ対応・サポート提供
          <br />
          ・規約違反の調査・対応
          <br />
          ・統計データの作成（個人を識別できない形式）
          <br />
          ・新サービス・機能の通知（利用者の同意を得た場合）
        </LPArticle>

        <LPArticle num="3" title="第三者提供">
          当社は、以下の場合を除き、利用者の同意なく個人情報を第三者に提供しません。
          <br />
          ・法令に基づく場合
          <br />
          ・人の生命、身体または財産の保護のために必要がある場合
          <br />
          ・公衆衛生の向上または児童の健全な育成の推進のために必要がある場合
          <br />
          ・国の機関等の法令の定める事務の遂行に協力する必要がある場合
        </LPArticle>

        <LPArticle num="4" title="安全管理措置">
          当社は、個人情報の漏洩、滅失または毀損の防止その他の個人情報の安全管理のために、必要かつ適切な措置を講じます。アクセス制限・通信の暗号化・ストレージの暗号化等の技術的措置、および従業員教育・規程整備等の組織的措置を実施しています。
        </LPArticle>

        <LPArticle num="5" title="個人情報の開示・訂正・削除">
          利用者は、当社が保有する自己の個人情報について、開示・訂正・追加・削除を請求できます。請求は本サービスの「設定
          → アカウント削除」または下記の問い合わせ窓口にて受け付けます。
        </LPArticle>

        <LPArticle num="6" title="Cookie・類似技術">
          本サービスでは、利用者の利便性向上のために Cookie
          および類似技術を使用することがあります。利用者はブラウザの設定により
          Cookie
          の使用を制限できますが、その場合、本サービスの一部機能が利用できなくなる可能性があります。
        </LPArticle>

        <LPArticle num="7" title="未成年者の個人情報">
          本サービスは満 13
          歳以上の方を対象としています。未成年者が本サービスを利用する場合は、親権者の同意のもとでご利用ください。
        </LPArticle>

        <LPArticle num="8" title="お問い合わせ窓口">
          個人情報の取り扱いに関するお問い合わせは、以下の窓口までご連絡ください。
          <br />
          <br />
          <b className="text-[#3a324a]">Megrum 個人情報保護管理者</b>
          <br />
          メール：support@megrum.jp
          <br />
          受付時間：平日 10:00〜18:00（土日祝・年末年始を除く）
        </LPArticle>

        <LPArticle num="9" title="ポリシーの変更">
          当社は、必要に応じて本ポリシーを変更することがあります。変更後の内容は、本サービス上で公表した時点から適用されます。
        </LPArticle>

        <LPFooter updatedAt="制定：2026 年 4 月 30 日" />
      </div>
    </main>
  );
}
