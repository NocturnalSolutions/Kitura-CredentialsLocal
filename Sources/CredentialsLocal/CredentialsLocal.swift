import Foundation
import Kitura
import KituraNet
import Credentials

public class CredentialsLocal: CredentialsPluginProtocol {
    public var name: String = "Local"

    public var usersCache: NSCache<NSString, BaseCacheElement>?

    public var redirecting: Bool

    /// Path user should be redirected to if not logged in; nil if no
    /// redirection should happen.
    public let loginPagePath: String?

    public func authenticate(request: RouterRequest, response: RouterResponse, options: [String : Any], onSuccess: @escaping (UserProfile) -> Void, onFailure: @escaping (HTTPStatusCode?, [String : String]?) -> Void, onPass: @escaping (HTTPStatusCode?, [String : String]?) -> Void, inProgress: @escaping () -> Void) {
        // That this method got called means that a user session was not loaded.
        if let redirectTo = loginPagePath {
            try? response.redirect(redirectTo)
            inProgress()
        }
        else {
            onFailure(nil, nil)
        }
    }

    /// Initialize with an optional login page path.
    ///
    /// - Parameter loginPagePath: If nil, a non-authenticated user will be
    ///                            shown an error page; otherwise they will be
    ///                            redirected to this path, with a GET parameter
    ///                            of "redirectTo" corresponding to the path
    ///                            they were trying to access.
    public init(loginPagePath: String? = nil) {
        self.loginPagePath = loginPagePath
        redirecting = self.loginPagePath != nil
    }
}
