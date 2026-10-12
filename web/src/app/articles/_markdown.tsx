import Link from "next/link";
import type { ReactNode } from "react";

/**
 * Markdown サブセットを React 要素へ描画する（notes/82 §4C・raw HTML 無効）。
 * dangerouslySetInnerHTML を使わないため XSS 安全。対応：見出し(##/###)、段落、
 * 箇条書き(-)、番号付き(1.)、引用(>)、水平線(---)、**強調**、[リンク](url)、`コード`。
 */

const linkClass =
  "font-bold text-violet-700 underline decoration-megrum-lavender/40 underline-offset-4 transition hover:text-violet-900";

function renderInline(text: string, keyPrefix: string): ReactNode[] {
  const nodes: ReactNode[] = [];
  const regex =
    /(\*\*([^*]+)\*\*)|(\[([^\]]+)\]\(([^)]+)\))|(`([^`]+)`)/g;
  let last = 0;
  let index = 0;
  let match: RegExpExecArray | null;
  while ((match = regex.exec(text)) !== null) {
    if (match.index > last) nodes.push(text.slice(last, match.index));
    if (match[2] !== undefined) {
      nodes.push(
        <strong key={`${keyPrefix}-b${index}`} className="font-black text-slate-900">
          {match[2]}
        </strong>,
      );
    } else if (match[4] !== undefined) {
      const label = match[4];
      const href = match[5];
      nodes.push(
        href.startsWith("/") ? (
          <Link key={`${keyPrefix}-l${index}`} href={href} className={linkClass}>
            {label}
          </Link>
        ) : (
          <a
            key={`${keyPrefix}-l${index}`}
            href={href}
            target="_blank"
            rel="noopener noreferrer"
            className={linkClass}
          >
            {label}
          </a>
        ),
      );
    } else if (match[7] !== undefined) {
      nodes.push(
        <code
          key={`${keyPrefix}-c${index}`}
          className="rounded bg-slate-100 px-1.5 py-0.5 text-[13px] text-slate-800"
        >
          {match[7]}
        </code>,
      );
    }
    last = match.index + match[0].length;
    index++;
  }
  if (last < text.length) nodes.push(text.slice(last));
  return nodes;
}

function isBlockStart(line: string): boolean {
  return (
    line.startsWith("## ") ||
    line.startsWith("### ") ||
    line.startsWith("> ") ||
    /^-\s/.test(line) ||
    /^\d+\.\s/.test(line) ||
    line.trim() === "---"
  );
}

export function Markdown({ content }: { content: string }) {
  const lines = content.split(/\r?\n/);
  const blocks: ReactNode[] = [];
  let i = 0;
  let key = 0;

  while (i < lines.length) {
    const line = lines[i];
    if (line.trim() === "") {
      i++;
      continue;
    }
    if (line.startsWith("## ")) {
      blocks.push(
        <h2
          key={key}
          className="mt-10 text-[22px] font-black tracking-tight text-slate-950 md:text-[26px]"
        >
          {renderInline(line.slice(3), `h2-${key}`)}
        </h2>,
      );
      key++;
      i++;
      continue;
    }
    if (line.startsWith("### ")) {
      blocks.push(
        <h3 key={key} className="mt-8 text-[18px] font-black text-slate-900">
          {renderInline(line.slice(4), `h3-${key}`)}
        </h3>,
      );
      key++;
      i++;
      continue;
    }
    if (line.trim() === "---") {
      blocks.push(<hr key={key} className="my-8 border-slate-200" />);
      key++;
      i++;
      continue;
    }
    if (line.startsWith("> ")) {
      const quote: string[] = [];
      while (i < lines.length && lines[i].startsWith("> ")) {
        quote.push(lines[i].slice(2));
        i++;
      }
      blocks.push(
        <blockquote
          key={key}
          className="my-5 border-l-4 border-megrum-lavender/40 pl-4 text-[15px] font-medium leading-8 text-slate-600"
        >
          {renderInline(quote.join(" "), `q-${key}`)}
        </blockquote>,
      );
      key++;
      continue;
    }
    if (/^-\s/.test(line)) {
      const items: string[] = [];
      while (i < lines.length && /^-\s/.test(lines[i])) {
        items.push(lines[i].replace(/^-\s/, ""));
        i++;
      }
      blocks.push(
        <ul
          key={key}
          className="my-5 list-disc space-y-2 pl-6 text-[15px] font-medium leading-8 text-slate-700"
        >
          {items.map((item, j) => (
            <li key={j}>{renderInline(item, `ul-${key}-${j}`)}</li>
          ))}
        </ul>,
      );
      key++;
      continue;
    }
    if (/^\d+\.\s/.test(line)) {
      const items: string[] = [];
      while (i < lines.length && /^\d+\.\s/.test(lines[i])) {
        items.push(lines[i].replace(/^\d+\.\s/, ""));
        i++;
      }
      blocks.push(
        <ol
          key={key}
          className="my-5 list-decimal space-y-2 pl-6 text-[15px] font-medium leading-8 text-slate-700"
        >
          {items.map((item, j) => (
            <li key={j}>{renderInline(item, `ol-${key}-${j}`)}</li>
          ))}
        </ol>,
      );
      key++;
      continue;
    }
    // 段落：空行または次のブロック開始まで
    const paragraph: string[] = [];
    while (
      i < lines.length &&
      lines[i].trim() !== "" &&
      !isBlockStart(lines[i])
    ) {
      paragraph.push(lines[i]);
      i++;
    }
    blocks.push(
      <p
        key={key}
        className="my-4 text-[15px] font-medium leading-8 text-slate-700"
      >
        {renderInline(paragraph.join(" "), `p-${key}`)}
      </p>,
    );
    key++;
  }

  return <div className="text-pretty">{blocks}</div>;
}
