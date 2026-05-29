import { StyleSheet, View, type StyleProp, type ViewStyle } from "react-native";
import { megrumColors, megrumRadii } from "../theme/tokens";

type SkeletonBlockProps = {
  height?: number;
  radius?: number;
  style?: StyleProp<ViewStyle>;
  width?: number | `${number}%`;
};

export function SkeletonBlock({
  height = 12,
  radius = 999,
  style,
  width = "100%",
}: SkeletonBlockProps) {
  return (
    <View
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
      style={[styles.block, { borderRadius: radius, height, width }, style]}
    />
  );
}

export function SkeletonPillRow({ count = 3 }: { count?: number }) {
  return (
    <View style={styles.pillRow}>
      {Array.from({ length: count }).map((_, index) => (
        <SkeletonBlock
          key={`pill-${index}`}
          height={30}
          radius={999}
          style={styles.pill}
        />
      ))}
    </View>
  );
}

export function GroomRailSkeleton() {
  return (
    <View style={styles.railRow}>
      {Array.from({ length: 5 }).map((_, index) => (
        <View key={`groom-${index}`} style={styles.railItem}>
          <SkeletonBlock height={64} radius={32} style={styles.railCircle} />
          <SkeletonBlock height={9} width="68%" />
        </View>
      ))}
    </View>
  );
}

export function GoodsGridSkeleton({
  columns = 3,
  count = 9,
  tileHeight = 126,
}: {
  columns?: number;
  count?: number;
  tileHeight?: number;
}) {
  const rows = Math.ceil(count / columns);
  return (
    <View style={styles.grid}>
      {Array.from({ length: rows }).map((_, rowIndex) => (
        <View key={`grid-row-${rowIndex}`} style={styles.gridRow}>
          {Array.from({ length: columns }).map((__, columnIndex) => {
            const itemIndex = rowIndex * columns + columnIndex;
            return (
              <View key={`grid-${rowIndex}-${columnIndex}`} style={styles.gridCell}>
                {itemIndex < count ? (
                  <View style={[styles.gridTile, { minHeight: tileHeight }]}>
                    <SkeletonBlock height={tileHeight - 54} radius={13} />
                    <SkeletonBlock height={10} width="82%" />
                    <SkeletonBlock height={9} width="58%" />
                  </View>
                ) : null}
              </View>
            );
          })}
        </View>
      ))}
    </View>
  );
}

export function ListingDeckSkeleton({ count = 3 }: { count?: number }) {
  return (
    <View style={styles.stack}>
      <View style={styles.deckHeader}>
        <SkeletonBlock height={16} width="36%" />
        <SkeletonBlock height={22} width={44} />
      </View>
      {Array.from({ length: count }).map((_, index) => (
        <View key={`listing-${index}`} style={styles.listingCard}>
          <View style={styles.listingTopRow}>
            <SkeletonBlock height={18} width="46%" />
            <SkeletonBlock height={24} width={62} />
          </View>
          <View style={styles.miniGoodsRow}>
            <SkeletonBlock height={58} radius={12} style={styles.miniGoods} />
            <SkeletonBlock height={58} radius={12} style={styles.miniGoods} />
            <SkeletonBlock height={58} radius={12} style={styles.miniGoods} />
          </View>
          <SkeletonBlock height={11} width="74%" />
        </View>
      ))}
    </View>
  );
}

export function TransactionListSkeleton({ count = 5 }: { count?: number }) {
  return (
    <View style={styles.stack}>
      {Array.from({ length: count }).map((_, index) => (
        <View key={`transaction-${index}`} style={styles.transactionCard}>
          <View style={styles.transactionHeader}>
            <SkeletonBlock height={42} radius={21} width={42} />
            <View style={styles.transactionCopy}>
              <SkeletonBlock height={13} width="46%" />
              <SkeletonBlock height={10} width="66%" />
            </View>
            <SkeletonBlock height={26} width={72} />
          </View>
          <View style={styles.tradeRow}>
            <SkeletonBlock height={58} radius={13} style={styles.tradeTile} />
            <SkeletonBlock height={28} radius={14} width={28} />
            <SkeletonBlock height={58} radius={13} style={styles.tradeTile} />
          </View>
          <SkeletonBlock height={10} width="88%" />
        </View>
      ))}
    </View>
  );
}

export function HomeFeedSkeleton() {
  return (
    <View style={styles.stack}>
      <GroomRailSkeleton />
      {Array.from({ length: 2 }).map((_, sectionIndex) => (
        <View key={`home-section-${sectionIndex}`} style={styles.homeSection}>
          <SkeletonBlock height={20} width="42%" />
          <View style={styles.homeShelfRow}>
            <SkeletonBlock height={162} radius={18} style={styles.homeShelfTile} />
            <SkeletonBlock height={162} radius={18} style={styles.homeShelfTile} />
          </View>
          <View style={styles.homeShelfRow}>
            <SkeletonBlock height={128} radius={18} style={styles.homeShelfTile} />
            <SkeletonBlock height={128} radius={18} style={styles.homeShelfTile} />
          </View>
        </View>
      ))}
    </View>
  );
}

export function ProposalChoiceSkeleton({ count = 5 }: { count?: number }) {
  return (
    <View style={styles.proposalList}>
      {Array.from({ length: count }).map((_, index) => (
        <View key={`proposal-${index}`} style={styles.proposalCard}>
          <SkeletonBlock height={76} radius={16} width={76} />
          <View style={styles.proposalCopy}>
            <SkeletonBlock height={15} width="72%" />
            <SkeletonBlock height={11} width="54%" />
            <SkeletonBlock height={22} width="46%" />
          </View>
          <SkeletonBlock height={26} radius={13} width={26} />
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  block: {
    backgroundColor: "rgba(166,149,216,0.14)",
    overflow: "hidden",
  },
  pillRow: {
    flexDirection: "row",
    gap: 8,
  },
  pill: {
    flex: 1,
  },
  railRow: {
    flexDirection: "row",
    gap: 13,
    paddingVertical: 4,
  },
  railItem: {
    alignItems: "center",
    gap: 7,
    width: 70,
  },
  railCircle: {
    borderColor: "rgba(166,149,216,0.18)",
    borderWidth: 1,
  },
  grid: {
    gap: 12,
  },
  gridRow: {
    flexDirection: "row",
    gap: 10,
  },
  gridCell: {
    flex: 1,
  },
  gridTile: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.12)",
    borderRadius: 16,
    borderWidth: 1,
    gap: 9,
    padding: 8,
  },
  stack: {
    gap: 14,
  },
  deckHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  listingCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.14)",
    borderRadius: 18,
    borderWidth: 1,
    gap: 12,
    padding: 14,
  },
  listingTopRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  miniGoodsRow: {
    flexDirection: "row",
    gap: 8,
  },
  miniGoods: {
    flex: 1,
  },
  transactionCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.12)",
    borderRadius: 18,
    borderWidth: 1,
    gap: 13,
    padding: 14,
  },
  transactionHeader: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
  },
  transactionCopy: {
    flex: 1,
    gap: 8,
  },
  tradeRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 9,
  },
  tradeTile: {
    flex: 1,
  },
  homeSection: {
    gap: 12,
  },
  homeShelfRow: {
    flexDirection: "row",
    gap: 12,
  },
  homeShelfTile: {
    backgroundColor: "rgba(166,149,216,0.12)",
    flex: 1,
  },
  proposalList: {
    gap: 10,
  },
  proposalCard: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.14)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    flexDirection: "row",
    gap: 12,
    padding: 12,
  },
  proposalCopy: {
    flex: 1,
    gap: 9,
  },
});
