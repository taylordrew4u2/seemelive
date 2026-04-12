//
//  PersistenceTests.swift
//  SEE ME LIVETests
//
//  Tests for PersistenceController Core Data stack.
//

import XCTest
import CoreData
@testable import SEE_ME_LIVE

final class PersistenceTests: XCTestCase {

    // MARK: - In-Memory Store

    func testInMemoryContainer_loadsSuccessfully() {
        let controller = PersistenceController(inMemory: true)
        let ctx = controller.container.viewContext
        XCTAssertNotNil(ctx, "View context should not be nil")
    }

    func testInMemoryContainer_canCreateShow() {
        let controller = PersistenceController(inMemory: true)
        let ctx = controller.container.viewContext

        let show = Show(context: ctx)
        show.title = "Test Show"
        show.venue = "Test Venue"
        show.date = Date()
        show.userID = "test-user"

        controller.save(context: ctx)

        let fetch: NSFetchRequest<Show> = Show.fetchRequest()
        let results = try? ctx.fetch(fetch)
        XCTAssertEqual(results?.count, 1)
        XCTAssertEqual(results?.first?.title, "Test Show")
    }

    func testSave_withNoChanges_doesNotThrow() {
        let controller = PersistenceController(inMemory: true)
        let ctx = controller.container.viewContext
        // Should be a no-op, not crash
        controller.save(context: ctx)
    }

    func testSave_withChanges_persistsData() {
        let controller = PersistenceController(inMemory: true)
        let ctx = controller.container.viewContext

        let show = Show(context: ctx)
        show.title = "Saved Show"
        show.venue = "Club"
        show.date = Date()

        controller.save(context: ctx)

        // Verify by re-fetching
        let fetch: NSFetchRequest<Show> = Show.fetchRequest()
        fetch.predicate = NSPredicate(format: "title == %@", "Saved Show")
        let results = try? ctx.fetch(fetch)
        XCTAssertEqual(results?.count, 1)
    }

    func testContainer_mergesPolicyIsObjectTrump() {
        let controller = PersistenceController(inMemory: true)
        let policy = controller.container.viewContext.mergePolicy as? NSMergePolicy
        XCTAssertEqual(policy, NSMergeByPropertyObjectTrumpMergePolicy as? NSMergePolicy)
    }

    func testContainer_automaticallyMergesChangesFromParent() {
        let controller = PersistenceController(inMemory: true)
        XCTAssertTrue(controller.container.viewContext.automaticallyMergesChangesFromParent)
    }

    // MARK: - Multiple Shows

    func testMultipleShows_canBeCreatedAndFetched() {
        let controller = PersistenceController(inMemory: true)
        let ctx = controller.container.viewContext

        for i in 0..<5 {
            let show = Show(context: ctx)
            show.title = "Show \(i)"
            show.venue = "Venue \(i)"
            show.date = Date()
        }
        controller.save(context: ctx)

        let fetch: NSFetchRequest<Show> = Show.fetchRequest()
        let results = try? ctx.fetch(fetch)
        XCTAssertEqual(results?.count, 5)
    }

    // MARK: - Delete

    func testDelete_removesShow() {
        let controller = PersistenceController(inMemory: true)
        let ctx = controller.container.viewContext

        let show = Show(context: ctx)
        show.title = "To Delete"
        show.date = Date()
        controller.save(context: ctx)

        ctx.delete(show)
        controller.save(context: ctx)

        let fetch: NSFetchRequest<Show> = Show.fetchRequest()
        let results = try? ctx.fetch(fetch)
        XCTAssertEqual(results?.count, 0)
    }

    // MARK: - Background Context

    func testNewBackgroundContext_isNotNil() {
        let controller = PersistenceController(inMemory: true)
        let bgContext = controller.container.newBackgroundContext()
        XCTAssertNotNil(bgContext)
    }
}
