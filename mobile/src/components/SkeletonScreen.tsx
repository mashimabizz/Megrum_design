import {
  StyleSheet,
  View,
  type StyleProp,
  type ViewStyle,
  useWindowDimensions,
} from "react-native";
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

export function FilterRowsSkeleton({ rows = 2 }: { rows?: number }) {
  return (
    <View style={styles.filterRows}>
      {Array.from({ length: rows }).map((_, rowIndex) => (
        <View key={`filter-row-${rowIndex}`} style={styles.filterRow}>
          <SkeletonBlock height={10} radius={5} width={30} />
          <View style={styles.filterChipRow}>
            {[58, 78, 68, 86].map((width, chipIndex) => (
              <SkeletonBlock
                key={`filter-chip-${rowIndex}-${chipIndex}`}
                height={28}
                radius={999}
                width={width}
              />
            ))}
          </View>
        </View>
      ))}
    </View>
  );
}

export function GroomRailSkeleton({ count = 4 }: { count?: number }) {
  return (
    <View style={styles.railRow}>
      {Array.from({ length: count }).map((_, index) => (
        <View key={`groom-${index}`} style={styles.railItem}>
          <SkeletonBlock height={74} radius={999} style={styles.railCircle} />
          <SkeletonBlock height={10} width={58} />
        </View>
      ))}
    </View>
  );
}

export function GoodsGridSkeleton({
  columns = 3,
  count = 9,
  includeAddTile = false,
  showBottomStrip = true,
  showTopRow = false,
}: {
  columns?: number;
  count?: number;
  includeAddTile?: boolean;
  showBottomStrip?: boolean;
  showTopRow?: boolean;
}) {
  const { width } = useWindowDimensions();
  const screenPadding = 36;
  const gap = columns === 3 ? 10 : columns === 4 ? 8 : 6;
  const tileWidth = (width - screenPadding - gap * (columns - 1)) / columns;
  const tileHeight = tileWidth * 1.34;
  const cells = includeAddTile ? count + 1 : count;

  return (
    <View style={[styles.goodsGrid, { gap }]}>
      {Array.from({ length: cells }).map((_, index) => {
        const addTile = includeAddTile && index === 0;
        return (
          <View
            key={`goods-grid-${index}`}
            style={[
              styles.goodsTile,
              addTile ? styles.goodsAddTile : null,
              {
                height: tileHeight,
                width: tileWidth,
              },
            ]}
          >
            {addTile ? (
              <>
                <SkeletonBlock height={28} radius={14} width={28} />
                <SkeletonBlock height={10} radius={5} width="42%" />
              </>
            ) : (
              <>
                {showTopRow ? (
                  <View style={styles.goodsTileTopRow}>
                    <SkeletonBlock height={21} radius={6} style={styles.goodsTileTitlePlate} />
                    <SkeletonBlock height={21} radius={6} width={42} />
                  </View>
                ) : null}
                {showBottomStrip ? (
                  <View style={styles.goodsTileBottomStrip}>
                    <SkeletonBlock height={10} radius={5} width="74%" />
                  </View>
                ) : null}
              </>
            )}
          </View>
        );
      })}
    </View>
  );
}

export function ListingDeckSkeleton({ count = 3 }: { count?: number }) {
  return (
    <View style={styles.deckSection}>
      <View style={styles.deckHeader}>
        <SkeletonBlock height={16} radius={8} width={76} />
        <SkeletonBlock height={24} radius={12} width={48} />
      </View>
      <View style={styles.deckList}>
        {Array.from({ length: count }).map((_, index) => (
          <View key={`listing-${index}`} style={styles.deckCard}>
            <View style={styles.deckTop}>
              <SkeletonBlock height={26} radius={999} width={62} />
              <SkeletonBlock height={11} radius={6} style={styles.deckMeta} />
              <View style={styles.deckActions}>
                <SkeletonBlock height={28} radius={14} width={28} />
                <SkeletonBlock height={28} radius={14} width={28} />
              </View>
            </View>
            <View style={styles.deckSide}>
              <SkeletonBlock height={19} radius={999} width={42} />
              <View style={styles.deckGoodsGrid}>
                {Array.from({ length: 3 }).map((__, tileIndex) => (
                  <View key={`listing-have-${index}-${tileIndex}`} style={styles.deckGoodsTile}>
                    <SkeletonBlock height={54} radius={18} width={54} />
                    <SkeletonBlock height={9} radius={5} width={50} />
                    <SkeletonBlock height={9} radius={5} width={38} />
                  </View>
                ))}
              </View>
            </View>
            <View style={styles.deckCord}>
              <SkeletonBlock height={2} radius={1} width={74} />
              <SkeletonBlock height={28} radius={999} style={styles.deckKnot} width={28} />
            </View>
            <View style={styles.deckSide}>
              <SkeletonBlock height={19} radius={999} width={56} />
              <View style={styles.deckGoodsGrid}>
                {Array.from({ length: 3 }).map((__, tileIndex) => (
                  <View key={`listing-want-${index}-${tileIndex}`} style={styles.deckGoodsTile}>
                    <SkeletonBlock height={54} radius={18} width={54} />
                    <SkeletonBlock height={9} radius={5} width={50} />
                    <SkeletonBlock height={9} radius={5} width={38} />
                  </View>
                ))}
              </View>
            </View>
          </View>
        ))}
      </View>
    </View>
  );
}

export function TransactionListSkeleton({ count = 5 }: { count?: number }) {
  return (
    <View style={styles.stackTight}>
      {Array.from({ length: count }).map((_, index) => (
        <View key={`transaction-${index}`} style={styles.transactionCard}>
          <View style={styles.transactionHeader}>
            <SkeletonBlock height={34} radius={12} width={34} />
            <View style={styles.transactionCopy}>
              <SkeletonBlock height={13} radius={7} width="44%" />
              <SkeletonBlock height={10} radius={5} width="28%" />
            </View>
            <SkeletonBlock height={23} radius={999} width={58} />
          </View>

          <View style={styles.transactionStatusLine}>
            <SkeletonBlock height={22} radius={999} width={88} />
            <SkeletonBlock height={22} radius={999} width={72} />
          </View>

          <View style={styles.tradePair}>
            <View style={styles.tradeSide}>
              <SkeletonBlock height={10} radius={5} width={48} />
              <View style={styles.tradeItems}>
                <SkeletonBlock height={42} radius={8} width={32} />
                <SkeletonBlock height={42} radius={8} width={32} />
                <SkeletonBlock height={42} radius={8} width={32} />
              </View>
            </View>
            <View style={styles.arrows}>
              <SkeletonBlock height={14} radius={7} width={18} />
              <SkeletonBlock height={14} radius={7} width={18} />
            </View>
            <View style={styles.tradeSide}>
              <SkeletonBlock height={10} radius={5} style={styles.tradeLabelRight} width={48} />
              <View style={[styles.tradeItems, styles.tradeItemsRight]}>
                <SkeletonBlock height={42} radius={8} width={32} />
                <SkeletonBlock height={42} radius={8} width={32} />
                <SkeletonBlock height={42} radius={8} width={32} />
              </View>
            </View>
          </View>

          <View style={styles.meetupLine}>
            <SkeletonBlock height={11} radius={6} style={styles.meetupText} />
            <SkeletonBlock height={11} radius={6} style={styles.meetupPlace} />
          </View>
        </View>
      ))}
    </View>
  );
}

export function HomeFeedSkeleton() {
  const { width } = useWindowDimensions();
  const tileWidth = Math.max(128, Math.min(148, (width - 54) / 2.55));
  const tileHeight = tileWidth * 1.16;

  return (
    <View style={styles.stack}>
      {Array.from({ length: 2 }).map((_, sectionIndex) => (
        <View key={`home-section-${sectionIndex}`} style={styles.homeSection}>
          <View style={styles.homeSectionHeader}>
            <SkeletonBlock height={29} radius={8} width="54%" />
          </View>
          {Array.from({ length: 2 }).map((__, rowIndex) => (
            <View key={`home-row-${sectionIndex}-${rowIndex}`} style={styles.homeShelfRowWrap}>
              <View style={styles.homeRowTitleLine}>
                <SkeletonBlock height={13} radius={7} width={112} />
                <SkeletonBlock height={11} radius={6} width={58} />
              </View>
              <View style={styles.homeShelfRow}>
                {Array.from({ length: 3 }).map((___, tileIndex) => (
                  <View
                    key={`home-tile-${sectionIndex}-${rowIndex}-${tileIndex}`}
                    style={[
                      styles.homeShelfTile,
                      {
                        height: tileHeight,
                        width: tileWidth,
                      },
                    ]}
                  >
                    <SkeletonBlock
                      height={22}
                      radius={999}
                      style={styles.homeTagOverlay}
                      width="58%"
                    />
                  </View>
                ))}
              </View>
            </View>
          ))}
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
          <SkeletonBlock height={82} radius={15} width={66} />
          <View style={styles.proposalCopy}>
            <SkeletonBlock height={15} radius={8} width="72%" />
            <SkeletonBlock height={11} radius={6} width="54%" />
            <SkeletonBlock height={22} radius={999} width="46%" />
          </View>
          <SkeletonBlock height={26} radius={13} width={26} />
        </View>
      ))}
    </View>
  );
}

export function BoardThreadListSkeleton({ count = 3 }: { count?: number }) {
  return (
    <View style={styles.boardThreadList}>
      {Array.from({ length: count }).map((_, index) => (
        <View key={`board-thread-${index}`} style={styles.boardThreadCard}>
          <View style={styles.boardThreadTopRow}>
            <SkeletonBlock height={11} radius={6} width="44%" />
            <SkeletonBlock height={11} radius={6} width={42} />
          </View>
          <SkeletonBlock height={18} radius={9} width="72%" />
          <View style={styles.boardThreadBodyLines}>
            <SkeletonBlock height={12} radius={6} width="92%" />
            <SkeletonBlock height={12} radius={6} width="68%" />
          </View>
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
  filterRows: {
    gap: 6,
    marginHorizontal: -18,
    paddingLeft: 18,
  },
  filterRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 6,
    minHeight: 30,
  },
  filterChipRow: {
    flexDirection: "row",
    gap: 6,
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
  },
  railItem: {
    alignItems: "center",
    gap: 6,
    width: 80,
  },
  railCircle: {
    borderColor: "rgba(166,149,216,0.18)",
    borderWidth: 1,
    width: 74,
  },
  goodsGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    paddingBottom: 18,
  },
  goodsTile: {
    backgroundColor: "rgba(58,50,74,0.05)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 13,
    borderWidth: 1,
    overflow: "hidden",
    position: "relative",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 3, height: 6 },
    shadowOpacity: 0.08,
    shadowRadius: 9,
  },
  goodsAddTile: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.54)",
    borderStyle: "dashed",
    borderWidth: 1.5,
    gap: 8,
    justifyContent: "center",
  },
  goodsTileTopRow: {
    alignItems: "flex-start",
    flexDirection: "row",
    gap: 4,
    left: 6,
    position: "absolute",
    right: 6,
    top: 6,
  },
  goodsTileTitlePlate: {
    flex: 1,
  },
  goodsTileBottomStrip: {
    backgroundColor: "rgba(255,255,255,0.92)",
    bottom: 0,
    left: 0,
    paddingBottom: 6,
    paddingHorizontal: 7,
    paddingTop: 14,
    position: "absolute",
    right: 0,
  },
  stack: {
    gap: 14,
  },
  stackTight: {
    gap: 10,
  },
  deckSection: {
    marginHorizontal: -18,
  },
  deckHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: 18,
  },
  deckList: {
    gap: 12,
    paddingBottom: 4,
    paddingHorizontal: 18,
    paddingTop: 8,
  },
  deckCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.34)",
    borderRadius: 22,
    borderWidth: 1,
    minHeight: 246,
    overflow: "hidden",
    padding: 13,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 16 },
    shadowOpacity: 0.13,
    shadowRadius: 26,
  },
  deckTop: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
  },
  deckMeta: {
    flex: 1,
  },
  deckActions: {
    flexDirection: "row",
    gap: 5,
  },
  deckSide: {
    backgroundColor: "rgba(255,255,255,0.62)",
    borderColor: "rgba(58,50,74,0.06)",
    borderRadius: 16,
    borderWidth: 1,
    gap: 8,
    marginTop: 10,
    padding: 10,
  },
  deckGoodsGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  deckGoodsTile: {
    alignItems: "center",
    gap: 5,
    width: 64,
  },
  deckCord: {
    alignItems: "center",
    alignSelf: "center",
    height: 28,
    justifyContent: "center",
    marginTop: 10,
    width: 74,
  },
  deckKnot: {
    position: "absolute",
  },
  transactionCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 17,
    borderWidth: 1,
    overflow: "hidden",
    padding: 12,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 16,
  },
  transactionHeader: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
  },
  transactionCopy: {
    flex: 1,
    gap: 5,
  },
  transactionStatusLine: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
    marginTop: 9,
  },
  tradePair: {
    alignItems: "center",
    backgroundColor: "rgba(168,212,230,0.10)",
    borderRadius: 15,
    flexDirection: "row",
    gap: 8,
    marginTop: 9,
    padding: 9,
  },
  tradeSide: {
    flex: 1,
  },
  tradeItems: {
    flexDirection: "row",
    gap: 5,
  },
  tradeItemsRight: {
    justifyContent: "flex-end",
  },
  tradeLabelRight: {
    alignSelf: "flex-end",
  },
  arrows: {
    alignItems: "center",
    gap: 3,
    width: 22,
  },
  meetupLine: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
    marginTop: 9,
  },
  meetupText: {
    flex: 1,
  },
  meetupPlace: {
    flex: 1,
  },
  homeSection: {
    gap: 10,
  },
  homeSectionHeader: {
    marginHorizontal: -18,
    paddingBottom: 10,
    paddingHorizontal: 18,
    paddingTop: 12,
  },
  homeShelfRowWrap: {
    gap: 4,
  },
  homeRowTitleLine: {
    alignItems: "baseline",
    flexDirection: "row",
    gap: 6,
    paddingHorizontal: 1,
  },
  homeShelfRow: {
    flexDirection: "row",
    gap: 12,
    overflow: "hidden",
    paddingBottom: 15,
    paddingTop: 9,
  },
  homeShelfTile: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: 16,
    overflow: "hidden",
    position: "relative",
  },
  homeTagOverlay: {
    bottom: 7,
    left: 8,
    position: "absolute",
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
    padding: 10,
  },
  proposalCopy: {
    flex: 1,
    gap: 9,
  },
  boardThreadList: {
    gap: 10,
  },
  boardThreadCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.18)",
    borderRadius: 20,
    borderWidth: 1,
    gap: 7,
    padding: 14,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.08,
    shadowRadius: 20,
  },
  boardThreadTopRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
    justifyContent: "space-between",
  },
  boardThreadBodyLines: {
    gap: 6,
  },
});
