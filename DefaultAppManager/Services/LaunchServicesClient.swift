import CoreServices
import Foundation

final class LaunchServicesClient {
    func defaultHandler(for fileType: FileType) -> String? {
        guard let value = LSCopyDefaultRoleHandlerForContentType(fileType.utiIdentifier as CFString, .all)?.takeRetainedValue() else {
            return nil
        }
        return value as String
    }

    func handlers(for fileType: FileType) -> [String] {
        guard let values = LSCopyAllRoleHandlersForContentType(fileType.utiIdentifier as CFString, .all)?.takeRetainedValue() as? [String] else {
            return []
        }
        return values
    }

    func setDefaultHandler(_ bundleIdentifier: String, for fileType: FileType) throws {
        let status = LSSetDefaultRoleHandlerForContentType(fileType.utiIdentifier as CFString, .all, bundleIdentifier as CFString)
        guard status == noErr else {
            throw LaunchServicesError.setDefaultFailed(status)
        }
    }
}

enum LaunchServicesError: LocalizedError {
    case setDefaultFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .setDefaultFailed(let status):
            return "LaunchServices could not update the default app. OSStatus: \(status)"
        }
    }
}
