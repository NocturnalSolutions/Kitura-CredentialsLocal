import Foundation
import Kitura
import KituraNet
import Credentials

public class CredentialsLocal: CredentialsPluginProtocol {
    public let name: String = "Local"

    public var usersCache: NSCache<NSString, BaseCacheElement>?

    public let redirecting: Bool = true

    // POST fields to find the username and password in.
    public var usernamePostField: String = "username"
    public var passwordPostField: String = "password"

    private var verifyPassword: VerifyPassword? = nil

    public func authenticate(request: RouterRequest, response: RouterResponse, options: [String : Any], onSuccess: @escaping (UserProfile) -> Void, onFailure: @escaping (HTTPStatusCode?, [String : String]?) -> Void, onPass: @escaping (HTTPStatusCode?, [String : String]?) -> Void, inProgress: @escaping () -> Void) {
        // That this method got called means that a user session was not loaded.
        guard let verifyPassword = verifyPassword, let post = request.body?.asURLEncoded, let user = post[usernamePostField], let pass = post[passwordPostField] else {
            onPass(nil, nil)
            return
        }
        verifyPassword(user, pass) { userProfile in
            if let userProfile = userProfile {
                onSuccess(userProfile)
            }
            else {
                onFailure(.forbidden, nil)
            }
        }
    }

    public init(verifyPassword: @escaping VerifyPassword) {
        self.verifyPassword = verifyPassword
    }

}
