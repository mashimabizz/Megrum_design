-- =====================================================================
-- iter80-D4: dispute の相手側（respondent）反論フロー
-- =====================================================================
-- 仕様: Megrum/c-dispute.jsx の D4Respondent
--
-- respondent は dispute を受けて 3 択：
--   accepted  事実を認める → 即 closed / outcome=cancelled
--   disputed  反論を提出 → status=arbitrating（運営仲裁）
--   silent    24h 無回答 → arbitrating（事実推定で進行）
--
-- 反論内容は respondent_response_text + respondent_evidence_urls に保存。

alter table public.disputes
  add column if not exists respondent_response text
    check (
      respondent_response is null
      or respondent_response in ('accepted', 'disputed', 'silent')
    ),
  add column if not exists respondent_response_text text
    check (
      respondent_response_text is null or length(respondent_response_text) <= 4000
    ),
  add column if not exists respondent_evidence_urls text[] not null default '{}',
  add column if not exists respondent_responded_at timestamptz;

comment on column public.disputes.respondent_response is
  'respondent の反論／受諾／無回答（accepted / disputed / silent）';
comment on column public.disputes.respondent_evidence_urls is
  'respondent が追加で提出した証跡 URL（最大 3 枚）';

-- =====================================================================
-- 完了
-- =====================================================================
