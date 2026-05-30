import { router, type Href } from "expo-router";

export function goToTabRoot(href: Href) {
  router.dismissTo(href, { withAnchor: true });
}
