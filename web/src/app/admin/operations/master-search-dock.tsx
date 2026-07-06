"use client";

import { useMemo, useState } from "react";

type DockGroup = {
  id: string;
  name: string;
  kind: string;
  genreName: string;
};

type DockCharacter = {
  id: string;
  name: string;
  aliases: string[];
  groupName: string;
};

/// 推しマスタ検索ドック：画面左下に固定表示し、ページ遷移なしで
/// 入力と同時にL1/L2マスタを絞り込んで表示する。
export function MasterSearchDock({
  groups,
  characters,
}: {
  groups: DockGroup[];
  characters: DockCharacter[];
}) {
  const [query, setQuery] = useState("");
  const [isOpen, setIsOpen] = useState(false);

  const normalized = query.trim().toLowerCase();
  const matchedGroups = useMemo(
    () =>
      normalized
        ? groups.filter((group) => group.name.toLowerCase().includes(normalized)).slice(0, 20)
        : [],
    [groups, normalized],
  );
  const matchedCharacters = useMemo(
    () =>
      normalized
        ? characters
            .filter(
              (character) =>
                character.name.toLowerCase().includes(normalized) ||
                character.aliases.some((alias) => alias.toLowerCase().includes(normalized)) ||
                character.groupName.toLowerCase().includes(normalized),
            )
            .slice(0, 20)
        : [],
    [characters, normalized],
  );

  return (
    <div className="fixed bottom-4 left-4 z-50 w-[360px]">
      {isOpen && normalized && (
        <div className="mb-2 max-h-[46vh] overflow-y-auto rounded-xl border border-slate-200 bg-white p-3 shadow-xl">
          <div className="text-[11px] font-black text-slate-900">
            L1マスタ {matchedGroups.length}件
          </div>
          {matchedGroups.length === 0 ? (
            <p className="mt-1 text-[11px] font-semibold text-slate-400">一致なし</p>
          ) : (
            <ul className="mt-1 space-y-1">
              {matchedGroups.map((group) => (
                <li key={group.id} className="rounded-md bg-slate-50 px-2 py-1.5">
                  <div className="text-[12px] font-black text-slate-900">
                    {group.name}
                    <span className="ml-2 text-[10.5px] font-bold text-slate-500">
                      {group.genreName} / {group.kind}
                    </span>
                  </div>
                  <div className="font-mono text-[9.5px] text-slate-400">{group.id}</div>
                </li>
              ))}
            </ul>
          )}

          <div className="mt-3 text-[11px] font-black text-slate-900">
            L2マスタ {matchedCharacters.length}件
          </div>
          {matchedCharacters.length === 0 ? (
            <p className="mt-1 text-[11px] font-semibold text-slate-400">一致なし</p>
          ) : (
            <ul className="mt-1 space-y-1">
              {matchedCharacters.map((character) => (
                <li key={character.id} className="rounded-md bg-slate-50 px-2 py-1.5">
                  <div className="text-[12px] font-black text-slate-900">
                    {character.name}
                    <span className="ml-2 text-[10.5px] font-bold text-slate-500">
                      {character.groupName}
                    </span>
                  </div>
                  <div className="font-mono text-[9.5px] text-slate-400">{character.id}</div>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}

      <div className="flex items-center gap-2 rounded-xl border border-slate-200 bg-white p-2 shadow-xl">
        <span className="pl-1 text-[11px] font-black text-slate-500">マスタ検索</span>
        <input
          value={query}
          onChange={(event) => {
            setQuery(event.target.value);
            setIsOpen(true);
          }}
          onFocus={() => setIsOpen(true)}
          placeholder="L1 / L2名で即時検索"
          className="h-9 flex-1 rounded-lg border border-slate-200 bg-white px-3 text-[13px] font-semibold text-slate-900 outline-none focus:border-megrum-lavender focus:ring-2 focus:ring-megrum-lavender/20"
        />
        {query && (
          <button
            type="button"
            onClick={() => {
              setQuery("");
              setIsOpen(false);
            }}
            className="rounded-md px-2 py-1 text-[11px] font-black text-slate-400 hover:text-slate-600"
          >
            クリア
          </button>
        )}
      </div>
    </div>
  );
}
