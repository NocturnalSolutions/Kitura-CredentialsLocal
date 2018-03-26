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
    private var verifyRequest: VerifyRequest? = nil

    public func authenticate(request: RouterRequest, response: RouterResponse, options: [String : Any], onSuccess: @escaping (UserProfile) -> Void, onFailure: @escaping (HTTPStatusCode?, [String : String]?) -> Void, onPass: @escaping (HTTPStatusCode?, [String : String]?) -> Void, inProgress: @escaping () -> Void) {
        // Define our closure here to avoid duplication
        let successOrFailure: (UserProfile?) -> Void = { userProfile in
            if let userProfile = userProfile {
                onSuccess(userProfile)
            }
            else {
                onFailure(.forbidden, nil)
            }
        }
        // Are we using a simple password verifier?
        if let verifyPassword = verifyPassword {
            guard let post = request.body?.asURLEncoded, let user = post[usernamePostField], let pass = post[passwordPostField] else {
                onPass(nil, nil)
                return
            }
            verifyPassword(user, pass, successOrFailure)
        }
        // Are we using a verifier for the entire request object?
        else if let verifyRequest = verifyRequest {
            verifyRequest(request, successOrFailure)
        }
        else {
            onPass(nil, nil)
        }
    }

    public init(verifyPassword: @escaping VerifyPassword) {
        self.verifyPassword = verifyPassword
    }

    public init(verifyRequest: @escaping VerifyRequest) {
        self.verifyRequest = verifyRequest
    }


}
