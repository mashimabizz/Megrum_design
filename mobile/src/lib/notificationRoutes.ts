import type { Href } from "expo-router";

export function routeFromNotificationLinkPath(path: string | null): Href | null {
  if (!path) return null;
  if (path === "/" || path === "/profile" || path === "/search") return path as Href;
  const meguriLetters = path.match(/^\/meguri-letters(?:\?(.*))?$/);
  if (meguriLetters) {
    const params = new URLSearchParams(meguriLetters[1] ?? "");
    return {
      pathname: "/meguri-letters",
      params: {
        open: params.get("open") ?? undefined,
        userId: params.get("userId") ?? undefined,
      },
    } as Href;
  }
  const meguriBoardThread = path.match(/^\/meguri-board-thread(?:\?(.*))?$/);
  if (meguriBoardThread) {
    const params = new URLSearchParams(meguriBoardThread[1] ?? "");
    const id = params.get("id");
    if (!id) return null;
    return {
      pathname: "/meguri-board-thread",
      params: {
        id,
        viewMode: params.get("viewMode") ?? undefined,
      },
    } as Href;
  }
  const dispute = path.match(/^\/disputes\/([^/]+)/);
  if (dispute) {
    return { pathname: "/dispute-detail", params: { id: dispute[1] } } as Href;
  }
  const proposal = path.match(/^\/proposals\/([^/]+)/);
  if (proposal) {
    return { pathname: "/transaction-detail", params: { id: proposal[1] } } as Href;
  }
  const transaction = path.match(/^\/transactions\/([^/]+)/);
  if (transaction) {
    if (path.endsWith("/capture")) {
      return { pathname: "/transaction-capture", params: { id: transaction[1] } } as Href;
    }
    if (path.endsWith("/approve")) {
      return { pathname: "/transaction-approve", params: { id: transaction[1] } } as Href;
    }
    if (path.endsWith("/rate")) {
      return { pathname: "/transaction-rate", params: { id: transaction[1] } } as Href;
    }
    if (path.includes("/cancel-or-late")) {
      const kind = path.includes("kind=late") ? "late" : "cancel";
      return {
        pathname: "/transaction-cancel-or-late",
        params: { id: transaction[1], kind },
      } as Href;
    }
    return { pathname: "/transaction-detail", params: { id: transaction[1] } } as Href;
  }
  const user = path.match(/^\/users\/([^/]+)/);
  if (user) {
    return { pathname: "/user-profile", params: { id: user[1] } } as Href;
  }
  return null;
}
