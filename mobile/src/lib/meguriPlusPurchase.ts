import {
  endConnection,
  fetchProducts,
  getActiveSubscriptions,
  initConnection,
  requestPurchase,
} from "expo-iap";

export const MEGURI_PLUS_PRODUCT_ID =
  process.env.EXPO_PUBLIC_MEGURI_PLUS_PRODUCT_ID ?? "megrum.meguri.plus.monthly";

export async function fetchMeguriPlusStoreProducts() {
  await initConnection();
  return fetchProducts({
    skus: [MEGURI_PLUS_PRODUCT_ID],
    type: "subs",
  });
}

export async function requestMeguriPlusStorePurchase() {
  await initConnection();
  return requestPurchase({
    request: {
      apple: { sku: MEGURI_PLUS_PRODUCT_ID },
      google: { skus: [MEGURI_PLUS_PRODUCT_ID], subscriptionOffers: [] },
    },
    type: "subs",
  });
}

export async function hasMeguriPlusStoreSubscription() {
  await initConnection();
  return getActiveSubscriptions([MEGURI_PLUS_PRODUCT_ID]).then(
    (subscriptions) => subscriptions.length > 0,
  );
}

export async function closeMeguriPlusStoreConnection() {
  await endConnection().catch(() => undefined);
}
