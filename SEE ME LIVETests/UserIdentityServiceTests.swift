//
//  UserIdentityServiceTests.swift
//  SEE ME LIVETests
//
//  Tests for UserIdentityService stable UUID generation.
//

import XCTest
@testable import SEE_ME_LIVE

final class UserIdentityServiceTests: XCTestCase {

    @MainActor
    func testUserID_isNotEmpty() {
        let userID = UserIdentityService.shared.userID
        XCTAssertFalse(userID.isEmpty)
    }

    @MainActor
    func testUserID_isValidUUID() {
        let userID = UserIdentityService.shared.userID
        XCTAssertNotNil(UUID(uuidString: userID), "User ID should be a valid UUID")
    }

    @MainActor
    func testUserID_isStableAcrossCalls() {
        let id1 = UserIdentityService.shared.userID
        let id2 = UserIdentityService.shared.userID
        XCTAssertEqual(id1, id2, "User ID should be the same on subsequent calls")
    }
}
