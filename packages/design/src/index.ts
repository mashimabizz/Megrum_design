export const megrumColors = {
  background: "#fbf9fc",
  surface: "#ffffff",
  ink: "#3a324a",
  mutedInk: "#3a324a8c",
  lavender: "#a695d8",
  sky: "#a8d4e6",
  pink: "#f3c5d4",
  warn: "#d9826b",
  ok: "#22c55e",
} as const;

export const megrumRadii = {
  sm: 10,
  md: 14,
  lg: 18,
  xl: 24,
  pill: 999,
} as const;

export const megrumSpacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  xxl: 32,
} as const;

export const megrumShadows = {
  card: {
    shadowColor: "#3a324a",
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 18,
    elevation: 3,
  },
  floating: {
    shadowColor: "#3a324a",
    shadowOffset: { width: 0, height: 12 },
    shadowOpacity: 0.14,
    shadowRadius: 24,
    elevation: 6,
  },
} as const;
