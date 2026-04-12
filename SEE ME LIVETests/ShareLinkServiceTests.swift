//
//  ShareLinkServiceTests.swift
//  SEE ME LIVETests
//
//  Tests for ShareLinkService URL generation.
//

import XCTest
@testable import SEE_ME_LIVE

final class ShareLinkServiceTests: XCTestCase {

    // MARK: - Share URL

    @MainActor
    func testShareURL_containsBaseURL() {
        let url = ShareLinkService.shareURL(for: "test-user-123")
        XCTAssertTrue(url.absoluteString.contains("taylordrew4u2.github.io/seemelive"))
    }

    @MainActor
    func testShareURL_containsUserID() {
        let url = ShareLinkService.shareURL(for: "test-user-123")
        XCTAssertTrue(url.absoluteString.contains("user=test-user-123"))
    }

    // MARK: - Calendar Feed URL

    @MainActor
    func testCalendarFeedURL_containsCalendarPath() {
        let url = ShareLinkService.calendarFeedURL(for: "test-user-456")
        XCTAssertTrue(url.absoluteString.contains("calendar.ics"))
    }

    @MainActor
    func testCalendarFeedURL_containsUserID() {
        let url = ShareLinkService.calendarFeedURL(for: "test-user-456")
        XCTAssertTrue(url.absoluteString.contains("user=test-user-456"))
    }

    // MARK: - Current URLs use UserIdentityService

    @MainActor
    func testCurrentShareURL_isNotEmpty() {
        let url = ShareLinkService.currentShareURL
        XCTAssertFalse(url.absoluteString.isEmpty)
    }

    @MainActor
    func testCurrentCalendarFeedURL_isNotEmpty() {
        let url = ShareLinkService.currentCalendarFeedURL
        XCTAssertFalse(url.absoluteString.isEmpty)
    }
}
