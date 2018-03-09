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
    public var usernamePostField: String = "user"
    public var passwordPostField: String = "pass"

    private var verifyPassword: VerifyPassword? = nil

    public func authenticate(request: RouterRequest, response: RouterResponse, options: [String : Any], onSuccess: @escaping (UserProfile) -> Void, onFailure: @escaping (HTTPStatusCode?, [String : String]?) -> Void, onPass: @escaping (HTTPStatusCode?, [String : String]?) -> Void, inProgress: @escaping () -> Void) {
        // That this method got called means that a user session was not loaded.
        if let verifyPassword = verifyPassword, let post = request.body?.asURLEncoded, let user = post[usernamePostField], let pass = post[passwordPostField] {
            verifyPassword(user, pass) { userProfile in
                if let userProfile = userProfile {
                    onSuccess(userProfile)
                    return
                }
                else {
                    onFailure(.forbidden, nil)
                    return
                }
            }
        }
        if options.index(forKey: "failureRedirect") != nil {
            // Trigger the redirect.
            inProgress()
        }
        else {
            // Show access denied page.
            onFailure(.forbidden, nil)
        }
    }

    public init(verifyPassword: @escaping VerifyPassword) {
        self.verifyPassword = verifyPassword
    }

}

