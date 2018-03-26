import Credentials
import Kitura

// MARK verifyRequest

/// Type alias for a verification callback to which the entire RouterRequest
/// ojbect is passed. This allows for verification when forms more complex than
/// just a username and password are needed; e.g., when a captcha also needed to
/// be validated.

public typealias VerifyRequest = (RouterRequest, @escaping (UserProfile?) -> Void) -> Void
