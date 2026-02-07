//
//  SpikersTests.swift
//  SpikersTests
//
//  Created by Danyang Zhao on 2/7/26.
//

import Testing
@testable import Spikers

struct SpikersTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    // MARK: - NotificationManager Tests

    @Test func notificationManagerStartsWithNoPermission() async throws {
        let manager = NotificationManager.shared
        // On first launch (before user grants permission), permission should not be granted
        // Note: In tests, we can't actually trigger the system permission dialog,
        // but we can verify the initial state
        #expect(manager.deviceToken == nil)
    }

    @Test func notificationManagerHandlesDeviceToken() async throws {
        let manager = NotificationManager.shared

        // Simulate receiving a device token from APNs
        // A real token is 32 bytes, but we'll use a shorter one for testing
        let fakeTokenData = Data([0xAB, 0xCD, 0xEF, 0x12, 0x34])
        manager.handleDeviceToken(fakeTokenData)

        // Give a moment for the async token handling to complete
        try await Task.sleep(for: .milliseconds(100))

        // The token should be converted to a hex string
        #expect(manager.deviceToken == "abcdef1234")
    }

    // MARK: - NotificationService Tests

    @Test func notificationServiceEndpointPaths() async throws {
        // Verify the API client is configured with the correct base URL
        let client = APIClient.shared
        #expect(client.baseURL == "https://spikers-production.up.railway.app")
    }
}
