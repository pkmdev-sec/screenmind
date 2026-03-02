import Foundation

/// Protocol for background processing service.
/// TODO: Extract to XPC service for true background processing with reduced main app CPU usage.
///
/// Future XPC Implementation:
/// 1. Create new XPC service target: ScreenMindWorker
/// 2. Implement this protocol in XPC service
/// 3. Use NSXPCConnection to communicate between main app and service
/// 4. Run OCR/AI processing in low-priority background queue
/// 5. Persist queue to survive app restarts
///
/// Current Implementation: Runs in-process (same behavior as existing pipeline).
public protocol ScreenMindProcessingService {
    /// Process OCR on image data.
    /// - Parameters:
    ///   - imageData: PNG or JPEG image data
    ///   - completion: Returns recognized text or error
    func processOCR(imageData: Data, completion: @escaping (Result<String, Error>) -> Void)

    /// Generate AI note from text.
    /// - Parameters:
    ///   - text: OCR text input
    ///   - appName: Source application name
    ///   - completion: Returns generated note JSON or error
    func generateNote(text: String, appName: String, completion: @escaping (Result<Data, Error>) -> Void)
}

/// Stub implementation that runs in-process.
/// TODO: Replace with XPC service implementation in Phase 5.4 follow-up.
public final class InProcessScreenMindService: NSObject, ScreenMindProcessingService {
    public func processOCR(imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        // TODO: Implement in-process OCR using existing OCRProcessingActor
        completion(.failure(NSError(domain: "com.screenmind.service", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "In-process OCR not yet implemented — use direct OCRProcessingActor"
        ])))
    }

    public func generateNote(text: String, appName: String, completion: @escaping (Result<Data, Error>) -> Void) {
        // TODO: Implement in-process AI generation using existing AIProcessingActor
        completion(.failure(NSError(domain: "com.screenmind.service", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "In-process AI generation not yet implemented — use direct AIProcessingActor"
        ])))
    }
}

/// XPC Service connection helper (for future implementation).
/// TODO: Uncomment and implement when XPC target is added.
/*
public final class XPCScreenMindService: NSObject, ScreenMindProcessingService {
    private let connection: NSXPCConnection

    public init() {
        connection = NSXPCConnection(serviceName: "com.screenmind.worker")
        connection.remoteObjectInterface = NSXPCInterface(with: ScreenMindProcessingService.self)
        connection.resume()
    }

    public func processOCR(imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let service = connection.remoteObjectProxyWithErrorHandler { error in
            completion(.failure(error))
        } as? ScreenMindProcessingService

        service?.processOCR(imageData: imageData, completion: completion)
    }

    public func generateNote(text: String, appName: String, completion: @escaping (Result<Data, Error>) -> Void) {
        let service = connection.remoteObjectProxyWithErrorHandler { error in
            completion(.failure(error))
        } as? ScreenMindProcessingService

        service?.generateNote(text: text, appName: appName, completion: completion)
    }

    deinit {
        connection.invalidate()
    }
}
*/
