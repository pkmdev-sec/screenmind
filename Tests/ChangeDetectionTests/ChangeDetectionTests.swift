import Testing
@testable import ChangeDetection

@Test func changeDetectionActorInitializes() async {
    let actor = ChangeDetectionActor()
    let stats = await actor.stats
    #expect(stats.total == 0)
    #expect(stats.filtered == 0)
}

@Test func imageDifferentiatorIdenticalHashes() {
    let diff = ImageDifferentiator.difference(hash1: 0xFFFF, hash2: 0xFFFF)
    #expect(diff == 0.0)
}

@Test func imageDifferentiatorDifferentHashes() {
    let diff = ImageDifferentiator.difference(hash1: 0, hash2: UInt64.max)
    #expect(diff == 1.0)
}
