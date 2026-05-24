import { useEffect, useState } from "react";
import { Image } from "react-native";

const readyImageUrls = new Set<string>();

export function useImageReady(src?: string | null): boolean {
  const [ready, setReady] = useState(() => !src || readyImageUrls.has(src));

  useEffect(() => {
    let cancelled = false;

    if (!src) {
      setReady(true);
      return () => {
        cancelled = true;
      };
    }

    if (readyImageUrls.has(src)) {
      setReady(true);
      return () => {
        cancelled = true;
      };
    }

    setReady(false);
    Image.prefetch(src)
      .then(() => {
        readyImageUrls.add(src);
        if (!cancelled) setReady(true);
      })
      .catch(() => {
        // Broken images should not keep the card permanently hidden.
        readyImageUrls.add(src);
        if (!cancelled) setReady(true);
      });

    return () => {
      cancelled = true;
    };
  }, [src]);

  return ready;
}
