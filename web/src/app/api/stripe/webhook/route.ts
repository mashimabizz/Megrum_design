import { createHmac, timingSafeEqual } from "crypto";
import { createServiceRoleClient } from "@/lib/supabase/server";

export const runtime = "nodejs";

type StripeObject = Record<string, unknown>;
type StripeEvent = {
  id: string;
  type: string;
  data: {
    object: StripeObject;
  };
};

type ServiceSupabase = ReturnType<typeof createServiceRoleClient>;

const ACTIVE_SUBSCRIPTION_STATUSES = new Set(["active", "trialing"]);

export async function POST(req: Request) {
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!webhookSecret) {
    return Response.json(
      { error: "STRIPE_WEBHOOK_SECRET is not configured" },
      { status: 500 },
    );
  }

  const rawBody = await req.text();
  const signature = req.headers.get("stripe-signature");
  if (!signature || !verifyStripeSignature(rawBody, signature, webhookSecret)) {
    return Response.json({ error: "invalid signature" }, { status: 400 });
  }

  let event: StripeEvent;
  try {
    event = JSON.parse(rawBody) as StripeEvent;
  } catch {
    return Response.json({ error: "invalid json" }, { status: 400 });
  }

  if (!event.id || !event.type || !event.data?.object) {
    return Response.json({ error: "invalid event" }, { status: 400 });
  }

  const adminSupabase = createServiceRoleClient();
  const { error: insertError } = await adminSupabase
    .from("stripe_webhook_events")
    .insert({
      event_id: event.id,
      event_type: event.type,
      payload: event,
      status: "processing",
    });

  if (insertError) {
    if (insertError.code === "23505") {
      return Response.json({ received: true, duplicate: true });
    }
    return Response.json({ error: insertError.message }, { status: 500 });
  }

  try {
    const result = await processStripeEvent(adminSupabase, event);
    await adminSupabase
      .from("stripe_webhook_events")
      .update({
        status: result.status,
        processed_at: new Date().toISOString(),
        last_error: null,
      })
      .eq("event_id", event.id);
    return Response.json({ received: true, ...result });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    await adminSupabase
      .from("stripe_webhook_events")
      .update({
        status: "failed",
        processed_at: new Date().toISOString(),
        last_error: message,
      })
      .eq("event_id", event.id);
    return Response.json({ error: message }, { status: 500 });
  }
}

async function processStripeEvent(
  adminSupabase: ServiceSupabase,
  event: StripeEvent,
) {
  if (
    event.type === "customer.subscription.created" ||
    event.type === "customer.subscription.updated" ||
    event.type === "customer.subscription.deleted"
  ) {
    const result = await upsertStripeSubscription(
      adminSupabase,
      event.data.object,
      event.type,
    );
    return result;
  }

  return { status: "ignored" as const, ignored: event.type };
}

async function upsertStripeSubscription(
  adminSupabase: ServiceSupabase,
  subscription: StripeObject,
  eventType: string,
) {
  const metadata = readObject(subscription.metadata);
  const subscriptionId = readString(subscription.id);
  const customerId = readString(subscription.customer);
  const status =
    eventType === "customer.subscription.deleted"
      ? "canceled"
      : readString(subscription.status) ?? "incomplete";

  if (!subscriptionId) {
    throw new Error("Stripe subscription id is missing");
  }

  const userId =
    readString(metadata.user_id) ??
    (customerId
      ? await findUserIdByStripeCustomer(adminSupabase, customerId)
      : null);
  if (!userId) {
    return {
      status: "ignored" as const,
      reason: "user_id metadata or known customer was not found",
    };
  }

  const firstPrice = readFirstPrice(subscription);
  const planType = normalizePlanType(
    readString(metadata.plan_type),
    readString(firstPrice?.recurring_interval),
    readString(firstPrice?.product),
  );
  const featureKey = featureKeyForPlanType(planType);

  const { data, error } = await adminSupabase
    .from("subscriptions")
    .upsert(
      {
        user_id: userId,
        plan_type: planType,
        status,
        started_at: unixSecondsToIso(subscription.created),
        current_period_start: unixSecondsToIso(subscription.current_period_start),
        current_period_end: unixSecondsToIso(subscription.current_period_end),
        cancelled_at: unixSecondsToIso(subscription.canceled_at),
        cancel_at_period_end: readBoolean(subscription.cancel_at_period_end),
        transaction_provider: "stripe",
        transaction_provider_subscription_id: subscriptionId,
        transaction_provider_customer_id: customerId,
        price_id: firstPrice?.id ?? null,
        product_id: firstPrice?.product ?? null,
        metadata,
      },
      { onConflict: "transaction_provider,transaction_provider_subscription_id" },
    )
    .select("id, user_id, status, current_period_end")
    .single();

  if (error) throw new Error(error.message);

  const active = ACTIVE_SUBSCRIPTION_STATUSES.has(status);
  const expiresAt = (data.current_period_end as string | null) ?? null;
  const { data: entitlement, error: entitlementError } = await adminSupabase
    .from("user_entitlements")
    .upsert(
      {
        user_id: userId,
        feature_key: featureKey,
        active,
        source: "subscription",
        subscription_id: data.id,
        override_id: null,
        expires_at: expiresAt,
        metadata: {},
      },
      { onConflict: "user_id,feature_key" },
    )
    .select("user_id, feature_key, active, source, subscription_id, expires_at")
    .single();

  if (entitlementError) throw new Error(entitlementError.message);

  await adminSupabase.from("admin_audit_logs").insert({
    actor_user_id: null,
    action: "subscription.stripe_webhook",
    target_type: "subscription",
    target_id: data.id,
    after_state: entitlement,
    metadata: {
      stripe_event_type: eventType,
      feature_key: featureKey,
      stripe_subscription_id: subscriptionId,
      stripe_customer_id: customerId,
    },
  });

  return {
    status: "processed" as const,
    subscription_id: data.id as string,
    entitlement_active: active,
  };
}

async function findUserIdByStripeCustomer(
  adminSupabase: ServiceSupabase,
  customerId: string,
) {
  const { data, error } = await adminSupabase
    .from("subscriptions")
    .select("user_id")
    .eq("transaction_provider", "stripe")
    .eq("transaction_provider_customer_id", customerId)
    .order("updated_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) throw new Error(error.message);
  return (data?.user_id as string | undefined) ?? null;
}

function verifyStripeSignature(
  rawBody: string,
  signatureHeader: string,
  secret: string,
) {
  const parts = signatureHeader.split(",");
  const timestamp = parts
    .find((part) => part.startsWith("t="))
    ?.slice(2);
  const signatures = parts
    .filter((part) => part.startsWith("v1="))
    .map((part) => part.slice(3));

  if (!timestamp || signatures.length === 0) return false;
  const timestampMs = Number(timestamp) * 1000;
  if (!Number.isFinite(timestampMs)) return false;
  if (Math.abs(Date.now() - timestampMs) > 5 * 60 * 1000) return false;

  const expected = createHmac("sha256", secret)
    .update(`${timestamp}.${rawBody}`, "utf8")
    .digest("hex");
  const expectedBuffer = Buffer.from(expected, "hex");

  return signatures.some((signature) => {
    const signatureBuffer = Buffer.from(signature, "hex");
    if (signatureBuffer.length !== expectedBuffer.length) return false;
    return timingSafeEqual(signatureBuffer, expectedBuffer);
  });
}

function readObject(value: unknown): Record<string, unknown> {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return {};
}

function readString(value: unknown) {
  return typeof value === "string" && value.length > 0 ? value : null;
}

function readBoolean(value: unknown) {
  return value === true;
}

function unixSecondsToIso(value: unknown) {
  if (typeof value !== "number" || !Number.isFinite(value)) return null;
  return new Date(value * 1000).toISOString();
}

function readFirstPrice(subscription: StripeObject) {
  const items = readObject(subscription.items);
  const data = Array.isArray(items.data) ? items.data : [];
  const firstItem = readObject(data[0]);
  const price = readObject(firstItem.price);
  const recurring = readObject(price.recurring);
  return {
    id: readString(price.id),
    product: readString(price.product),
    recurring_interval: readString(recurring.interval),
  };
}

function normalizePlanType(
  metadataPlanType: string | null,
  recurringInterval: string | null,
  productId: string | null,
) {
  if (metadataPlanType === "megrum_plus_monthly") {
    return "megrum_plus_monthly";
  }
  if (metadataPlanType === "monthly" || metadataPlanType === "premium_monthly") {
    return "premium_monthly";
  }
  if (metadataPlanType === "yearly" || metadataPlanType === "premium_yearly") {
    return "premium_yearly";
  }
  if (metadataPlanType === "meguri_plus_monthly") {
    return "meguri_plus_monthly";
  }
  if (productId === "megrum.plus.monthly") {
    return "megrum_plus_monthly";
  }
  return recurringInterval === "year" ? "premium_yearly" : "premium_monthly";
}

function featureKeyForPlanType(planType: string) {
  if (planType === "megrum_plus_monthly") {
    return "megrum_plus";
  }
  return planType === "meguri_plus_monthly" ? "meguri_plus" : "premium";
}
