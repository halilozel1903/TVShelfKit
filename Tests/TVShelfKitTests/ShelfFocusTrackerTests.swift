import Testing
@testable import TVShelfKit

@Suite("ShelfFocusTracker")
struct ShelfFocusTrackerTests {
    private let trending1 = ShelfFocusID(shelfID: "trending", itemID: "1")
    private let trending3 = ShelfFocusID(shelfID: "trending", itemID: "3")
    private let top9 = ShelfFocusID(shelfID: "top", itemID: "9")

    @Test func startsIdleAndAllowsHeroAdvance() {
        let tracker = ShelfFocusTracker()
        #expect(tracker.phase == .idle)
        #expect(tracker.current == nil)
        #expect(tracker.selected == nil)
        #expect(tracker.allowsHeroAutoAdvance)
    }

    @Test func focusingACardStartsBrowsingAndPausesTheHero() {
        var tracker = ShelfFocusTracker()
        let phase = tracker.handle(.focusItem(trending1))
        #expect(phase == .browsing)
        #expect(tracker.current == trending1)
        #expect(!tracker.allowsHeroAutoAdvance)
    }

    @Test func remembersTheLastItemOfEveryShelf() {
        var tracker = ShelfFocusTracker()
        tracker.handle(.focusItem(trending1))
        tracker.handle(.focusItem(top9))
        tracker.handle(.focusItem(trending3))
        #expect(tracker.remembered(in: "trending") == "3")
        #expect(tracker.remembered(in: "top") == "9")
        #expect(tracker.remembered(in: "missing") == nil)
    }

    @Test func leavingACardGoesIdle() {
        var tracker = ShelfFocusTracker()
        tracker.handle(.focusItem(trending1))
        let phase = tracker.handle(.leaveItem)
        #expect(phase == .idle)
        #expect(tracker.current == nil)
        #expect(tracker.remembered(in: "trending") == "1")
    }

    @Test func heroFocusAllowsAdvanceAndIgnoresLateLeaveItem() {
        var tracker = ShelfFocusTracker()
        tracker.handle(.focusItem(trending1))
        // Focus moves up into the hero; the two focus systems may report in either order.
        tracker.handle(.focusHero)
        let phase = tracker.handle(.leaveItem)
        #expect(phase == .hero)
        #expect(tracker.allowsHeroAutoAdvance)

        let afterLeave = tracker.handle(.leaveHero)
        #expect(afterLeave == .idle)
    }

    @Test func leaveHeroDoesNotOverrideBrowsing() {
        var tracker = ShelfFocusTracker()
        tracker.handle(.focusHero)
        tracker.handle(.focusItem(trending1))
        let phase = tracker.handle(.leaveHero)
        #expect(phase == .browsing)
    }

    @Test func selectingPresentsAndPausesTheHero() {
        var tracker = ShelfFocusTracker()
        tracker.handle(.focusItem(trending1))
        let phase = tracker.handle(.select(trending3))
        #expect(phase == .presenting)
        #expect(tracker.selected == trending3)
        #expect(tracker.current == trending3)
        #expect(tracker.remembered(in: "trending") == "3")
        #expect(!tracker.allowsHeroAutoAdvance)
    }

    @Test func focusLossWhilePresentingKeepsTheCardToRestore() {
        var tracker = ShelfFocusTracker()
        tracker.handle(.select(trending3))
        tracker.handle(.leaveItem)
        tracker.handle(.leaveHero)
        #expect(tracker.phase == .presenting)
        #expect(tracker.current == trending3)

        let phase = tracker.handle(.dismiss)
        #expect(phase == .browsing)
        #expect(tracker.selected == nil)
        #expect(tracker.current == trending3)
    }

    @Test func dismissAfterHeroSelectionReturnsToTheHero() {
        var tracker = ShelfFocusTracker()
        tracker.handle(.focusHero)
        tracker.handle(.select(.hero("featured-1")))
        let phase = tracker.handle(.dismiss)
        #expect(phase == .hero)
    }

    @Test func focusAfterPresentingEndsThePresentation() {
        var tracker = ShelfFocusTracker()
        tracker.handle(.select(trending3))
        let phase = tracker.handle(.focusItem(top9))
        #expect(phase == .browsing)
        #expect(tracker.selected == nil)
    }

    @Test func dismissWithoutPresentationDoesNothing() {
        var tracker = ShelfFocusTracker()
        tracker.handle(.focusItem(trending1))
        let phase = tracker.handle(.dismiss)
        #expect(phase == .browsing)
        #expect(tracker.current == trending1)
    }
}
