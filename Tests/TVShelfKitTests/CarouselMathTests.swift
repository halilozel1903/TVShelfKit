import Testing
@testable import TVShelfKit

@Suite("CarouselMath")
struct CarouselMathTests {
    @Test(arguments: [
        (0, 5, 0), (4, 5, 4), (5, 5, 0), (7, 5, 2), (-1, 5, 4), (-6, 5, 4), (3, 0, 0), (3, -2, 0),
    ])
    func wrapped(index: Int, count: Int, expected: Int) {
        #expect(CarouselMath.wrapped(index, count: count) == expected)
    }

    @Test func clampedStaysInRange() {
        #expect(CarouselMath.clamped(-3, count: 4) == 0)
        #expect(CarouselMath.clamped(2, count: 4) == 2)
        #expect(CarouselMath.clamped(9, count: 4) == 3)
        #expect(CarouselMath.clamped(9, count: 0) == 0)
    }

    @Test func nextAndPreviousWrapAround() {
        #expect(CarouselMath.next(after: 0, count: 3) == 1)
        #expect(CarouselMath.next(after: 2, count: 3) == 0)
        #expect(CarouselMath.previous(before: 0, count: 3) == 2)
        #expect(CarouselMath.previous(before: 1, count: 3) == 0)
        #expect(CarouselMath.next(after: 0, count: 1) == 0)
        #expect(CarouselMath.next(after: 0, count: 0) == 0)
    }

    @Test func shortestDistancePicksTheShorterWay() {
        #expect(CarouselMath.shortestDistance(from: 0, to: 1, count: 5) == 1)
        #expect(CarouselMath.shortestDistance(from: 0, to: 4, count: 5) == -1)
        #expect(CarouselMath.shortestDistance(from: 4, to: 0, count: 5) == 1)
        #expect(CarouselMath.shortestDistance(from: 1, to: 3, count: 4) == 2)
        #expect(CarouselMath.shortestDistance(from: 2, to: 2, count: 4) == 0)
        #expect(CarouselMath.shortestDistance(from: 0, to: 3, count: 0) == 0)
    }

    @Test func paging() {
        #expect(CarouselMath.pageCount(itemCount: 0, perPage: 5) == 0)
        #expect(CarouselMath.pageCount(itemCount: 10, perPage: 5) == 2)
        #expect(CarouselMath.pageCount(itemCount: 11, perPage: 5) == 3)
        #expect(CarouselMath.pageCount(itemCount: 11, perPage: 0) == 0)
        #expect(CarouselMath.page(containing: 0, perPage: 5) == 0)
        #expect(CarouselMath.page(containing: 4, perPage: 5) == 0)
        #expect(CarouselMath.page(containing: 5, perPage: 5) == 1)
        #expect(CarouselMath.page(containing: -2, perPage: 5) == 0)
    }

    @Test func visibleCount() {
        // 1920 wide, 240 wide cards, 40 spacing: (1920 + 40) / 280 = 7
        #expect(CarouselMath.visibleCount(containerWidth: 1920, itemWidth: 240, spacing: 40) == 7)
        #expect(CarouselMath.visibleCount(containerWidth: 100, itemWidth: 240, spacing: 40) == 1)
        #expect(CarouselMath.visibleCount(containerWidth: 1000, itemWidth: 0, spacing: 40) == 1)
        #expect(CarouselMath.visibleCount(containerWidth: .nan, itemWidth: 240, spacing: 40) == 1)
    }
}

@Suite("ParallaxMath")
struct ParallaxMathTests {
    @Test func normalizedPosition() {
        #expect(ParallaxMath.normalizedPosition(midX: 960, containerWidth: 1920) == 0)
        #expect(ParallaxMath.normalizedPosition(midX: 0, containerWidth: 1920) == -1)
        #expect(ParallaxMath.normalizedPosition(midX: 1920, containerWidth: 1920) == 1)
        #expect(ParallaxMath.normalizedPosition(midX: 1440, containerWidth: 1920) == 0.5)
        #expect(ParallaxMath.normalizedPosition(midX: 5000, containerWidth: 1920) == 1)
        #expect(ParallaxMath.normalizedPosition(midX: 10, containerWidth: 0) == 0)
    }

    @Test func offsetMovesAgainstThePosition() {
        #expect(ParallaxMath.offset(midX: 960, containerWidth: 1920, maxOffset: 24) == 0)
        #expect(ParallaxMath.offset(midX: 1920, containerWidth: 1920, maxOffset: 24) == -24)
        #expect(ParallaxMath.offset(midX: 0, containerWidth: 1920, maxOffset: 24) == 24)
        #expect(ParallaxMath.offset(midX: 1440, containerWidth: 1920, maxOffset: 24) == -12)
        #expect(ParallaxMath.offset(midX: 0, containerWidth: 1920, maxOffset: 0) == 0)
        #expect(ParallaxMath.offset(midX: 0, containerWidth: 1920, maxOffset: .infinity) == 0)
    }
}
