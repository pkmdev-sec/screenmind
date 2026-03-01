import Testing
@testable import CaptureCore

@Test func captureActorInitializes() async {
    let actor = ScreenCaptureActor()
    _ = actor // Ensure it compiles and initializes
}
