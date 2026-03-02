import Foundation
import Testing
@testable import PipelineCore

// MARK: - ScreenMindProcessingService Protocol Tests

@Test func inProcessServiceInitializes() {
    let service = InProcessScreenMindService()
    _ = service
}

@Test func inProcessServiceOCRReturnsNotImplemented() {
    let service = InProcessScreenMindService()
    let expectation = expectation(description: "OCR completion called")

    service.processOCR(imageData: Data()) { result in
        switch result {
        case .success:
            #expect(Bool(false), "Should not succeed - not implemented")
        case .failure(let error):
            let nsError = error as NSError
            #expect(nsError.domain == "com.screenmind.service")
            #expect(nsError.code == -1)
            #expect(nsError.localizedDescription.contains("not yet implemented"))
        }
        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
}

@Test func inProcessServiceGenerateNoteReturnsNotImplemented() {
    let service = InProcessScreenMindService()
    let expectation = expectation(description: "Generate note completion called")

    service.generateNote(text: "Test", appName: "TestApp") { result in
        switch result {
        case .success:
            #expect(Bool(false), "Should not succeed - not implemented")
        case .failure(let error):
            let nsError = error as NSError
            #expect(nsError.domain == "com.screenmind.service")
            #expect(nsError.code == -1)
            #expect(nsError.localizedDescription.contains("not yet implemented"))
        }
        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
}

// MARK: - Protocol Conformance Tests

@Test func inProcessServiceConformsToProtocol() {
    let service: any ScreenMindProcessingService = InProcessScreenMindService()
    _ = service
    // Compile-time check that InProcessScreenMindService conforms to protocol
}

// MARK: - Helper for async expectations

private func expectation(description: String) -> XCTestExpectation {
    XCTestExpectation(description: description)
}

private func wait(for expectations: [XCTestExpectation], timeout: TimeInterval) {
    let waiter = XCTWaiter()
    waiter.wait(for: expectations, timeout: timeout)
}

private class XCTestExpectation {
    let description: String
    private var isFulfilled = false

    init(description: String) {
        self.description = description
    }

    func fulfill() {
        isFulfilled = true
    }

    var fulfilled: Bool {
        isFulfilled
    }
}

private class XCTWaiter {
    func wait(for expectations: [XCTestExpectation], timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if expectations.allSatisfy({ $0.fulfilled }) {
                return
            }
            Thread.sleep(forTimeInterval: 0.01)
        }
    }
}
