struct GoodsImageSkeletonPresentationState: Equatable {
    var isPulsing = false

    var opacity: Double {
        isPulsing ? 0.72 : 1
    }

    mutating func startPulsing() {
        isPulsing = true
    }
}
