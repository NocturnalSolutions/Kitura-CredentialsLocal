import Foundation
import Kitura
import KituraNet
import Credentials

public class CredentialsLocal: CredentialsPluginProtocol {
    public var name: String = "Local"

    public var usersCache: NSCache<NSString, BaseCacheElement>?

    // Our plugin does redirect, but not for the sake of logging in, even though
    // it does. I guess what I'm saying is that this parameter confuses me.
    public var redirecting: Bool = false

    public func authenticate(request: RouterRequest, response: RouterResponse, options: [String : Any], onSuccess: @escaping (UserProfile) -> Void, onFailure: @escaping (HTTPStatusCode?, [String : String]?) -> Void, onPass: @escaping (HTTPStatusCode?, [String : String]?) -> Void, inProgress: @escaping () -> Void) {
        // That this method got called means that a user session was not loaded.
        if options.index(forKey: "failureRedirect") != nil {
            // Trigger the redirect.
            inProgress()
        }
        else {
            // Show access denied page.
            onFailure(nil, nil)
        }
    }

    public init() {}
}

