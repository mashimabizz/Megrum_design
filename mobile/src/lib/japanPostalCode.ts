export type JapanesePostalAddress = {
  city: string;
  postalCode: string;
  prefecture: string;
  town: string;
};

type ZipCloudResult = {
  address1?: unknown;
  address2?: unknown;
  address3?: unknown;
  zipcode?: unknown;
};

type ZipCloudResponse = {
  message?: unknown;
  results?: unknown;
  status?: unknown;
};

export async function lookupJapanesePostalCode(
  postalCode: string,
): Promise<JapanesePostalAddress | null> {
  const digits = postalCode.replace(/[^\d]/g, "").slice(0, 7);
  if (digits.length !== 7) return null;

  const response = await fetch(
    `https://zipcloud.ibsnet.co.jp/api/search?zipcode=${digits}`,
  );
  if (!response.ok) {
    throw new Error("郵便番号検索に失敗しました");
  }

  const payload = (await response.json()) as ZipCloudResponse;
  if (payload.status !== 200) {
    throw new Error(
      typeof payload.message === "string" && payload.message.trim()
        ? payload.message
        : "郵便番号検索に失敗しました",
    );
  }

  const results = Array.isArray(payload.results) ? payload.results : [];
  const first = results[0] as ZipCloudResult | undefined;
  if (!first) return null;

  return {
    city: asText(first.address2),
    postalCode: asText(first.zipcode) || digits,
    prefecture: asText(first.address1),
    town: asText(first.address3),
  };
}

function asText(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}
