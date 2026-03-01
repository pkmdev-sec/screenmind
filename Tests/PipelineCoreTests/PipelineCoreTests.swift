import Testing
@testable import PipelineCore

@Test func pipelineStatsInit() {
    let stats = PipelineStats(
        totalFrames: 100,
        filteredFrames: 80,
        significantFrames: 20,
        ocrProcessed: 15,
        avgOCRTime: 0.05,
        aiRequests: 10,
        aiLimit: 100
    )
    #expect(stats.totalFrames == 100)
    #expect(stats.significantFrames == 20)
    #expect(stats.aiRequests == 10)
}
