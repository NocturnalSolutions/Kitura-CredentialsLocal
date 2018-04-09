import Foundation
import Kitura
import KituraNet
import KituraSession
import Credentials
import LoggerAPI

public class CredentialsLocal: CredentialsPluginProtocol {
    public let name: String = "Local"

    public var usersCache: NSCache<NSString, BaseCacheElement>?

    public let redirecting: Bool = false

    // POST fields to find the username and password in.
    public var usernamePostField: String = "username"
    public var passwordPostField: String = "password"

    private var verifyPassword: VerifyPassword? = nil
    private var verifyRequest: VerifyRequest? = nil

    public func authenticate(request: RouterRequest, response: RouterResponse, options: [String : Any], onSuccess: @escaping (UserProfile) -> Void, onFailure: @escaping (HTTPStatusCode?, [String : String]?) -> Void, onPass: @escaping (HTTPStatusCode?, [String : String]?) -> Void, inProgress: @escaping () -> Void) {
        // Define our closure here to avoid duplication
        let successOrFailure: (UserProfile?) -> Void = { userProfile in
            if let userProfile = userProfile {
                Log.info("CredentialsLocal: UserProfile created")
                CredentialsLocal.store(userProfile: userProfile, in: request.session!)
                onSuccess(userProfile)
            }
            else {
                Log.warning("CredentialsLocal: UserProfile creation failed")
                onFailure(.forbidden, nil)
            }
        }
        // Are we using a simple password verifier?
        if let verifyPassword = verifyPassword {
            Log.info("CredentialsLocal: Attempting simple verification")
            guard let post = request.body?.asURLEncoded, let user = post[usernamePostField], let pass = post[passwordPostField] else {
                Log.warning("CredentialsLocal: Simple: Credentials not found in post body. (Are my usernamePostField and passwordPostField properties set correctly?)")
                onPass(nil, nil)
                return
            }
            verifyPassword(user, pass, successOrFailure)
        }
        // Are we using a verifier for the entire request object?
        else if let verifyRequest = verifyRequest {
            Log.info("CredentialsLocal: Attempting request verification")
            verifyRequest(request, successOrFailure)
        }
        else {
            Log.error("CredentialsLocal: authenticate method called but no verifier available (this should not be possible)")
            onPass(nil, nil)
        }
    }

    public init(verifyPassword: @escaping VerifyPassword) {
        self.verifyPassword = verifyPassword
    }

    public init(verifyRequest: @escaping VerifyRequest) {
        self.verifyRequest = verifyRequest
    }

    // Store a user profile in a session. This is copied from Credentials.swift
    // where we can't use it since it's static. :(
    private static func store(userProfile: UserProfile, in session: SessionState) {
        var dictionary = [String:Any]()
        dictionary["displayName"] = userProfile.displayName
        dictionary["provider"] = userProfile.provider
        dictionary["id"] = userProfile.id

        if let name = userProfile.name {
            dictionary["familyName"] = name.familyName
            dictionary["givenName"] = name.givenName
            dictionary["middleName"] = name.middleName
        }

        if let emails = userProfile.emails {
            var emailsArray = [String]()
            var emailTypesArray = [String]()
            for email in emails {
                emailsArray.append(email.value)
                emailTypesArray.append(email.type)
            }
            dictionary["emails"] = emailsArray
            dictionary["emailTypes"] = emailTypesArray
        }

        if let photos = userProfile.photos {
            var photosArray = [String]()
            for photo in photos {
                photosArray.append(photo.value)
            }
            dictionary["photos"] = photosArray
        }

        if !userProfile.extendedProperties.isEmpty {
            dictionary["extendedProperties"] = userProfile.extendedProperties
        }

        session["userProfile"] = dictionary
    }


}

