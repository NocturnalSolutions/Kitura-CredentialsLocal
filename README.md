# Kitura Credentials Local

A [Kitura Credentials](https://github.com/IBM-Swift/Kitura-Credentials) plug-in for local authentication (e.g. checking for credentials in a local database) using a web page form.

This plug-in is only compatible with Kitura 2 and Swift 4.

## Usage

Usage is similar to [Kitura-CredentialsHTTP](https://github.com/IBM-Swift/Kitura-CredentialsHTTP) in that you pass a closure that verifies the credentials when instantiating the plug-in. There are two approaches to this.

The simpler approach is closest to how Kitura-CredentialsHTTP works. You pass a closure that takes a username, password, and callback method. The username and password will have been extracted from a URL-encoded POST body with "username" and "password" named values; if you want these fields to have different names in the form's HTML, override these by setting the `usernamePostField` and `passwordPostField` parameters, respectively.

```swift
let local = CredentialsLocal() { username, password, callback in
    // Check to see if the username is "admin@example.com" and the password is
    // "swordfish". In real use you'd probably be doing something like hashing
    // the password and checking for the credentials in a database.
    if username == "admin@example.com", password == "swordfish" {
        // On success, pass a UserProfile object to the callback.
        let userProfile = UserProfile(id: username, displayName: username, provider: "Local")
        callback(userProfile)
    }
    else {
        // On failure, pass nil to the callback.
        callback(nil)
    }
}

// Override the names of the respective fields.
local.usernamePostField = "emailAddress"
local.passwordPostField = "passphrase"
```

The second approach will need to be used if you need to validate more fields besides just a username and password field, or are using a form where the POST body will be encoded another way (such as "multipart/form-data"). In this case, the callback is passed the entire RouterRequest object. Here's an example where we validate a "captcha" field on the form alongside username and password fields.

```swift
let local = CredentialsLocal() { request, callback in
    guard let body = request.body?.asURLEncoded, let userId = body["username"], let pass = body["password"], let cap = body["captchaVal"] else {
        callback(nil)
        return
    }
    if userId != "admin", pass != "swordfish", cap != "123456" {
        callback(nil)
        return
    }
    let userProfile = UserProfile(id: userId, displayName: userId, provider: "Local")
    callback(userProfile)
}
```

After instantiating CredentialsLocal, you should add it as a plug-in to a Credentials instance, then assign the latter instance to a router handler that handles the logging in action of your application. For example, if you have a form which posts to `/log-in`:

```swift
let simpleCredents = Credentials()
let simpleCallbackLocal = CredentialsLocal() { userId, password, callback in
    // …
}
simpleCredents.register(plugin: simpleCallbackLocal)
router.post("/log-in", middleware: simpleCredents)
```

### Access Restriction

Note that if blocking access to certain pages to those who are not authenticated is your goal, you’ll need to write the code for that yourself. A simple example would be [writing a RouterMiddleware](https://nocturnalsolutions.gitbooks.io/kitura-book/4-middleware.html) class which looks something like:

```swift
public class Restrictor: RouterMiddleware {
    public func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        guard let _ = request.userProfile else {
            try! response.send("Access denied.").status(.forbidden).end()
            return
        }
        next()
    }
}
```

And then attaching that as middleware to, say, an `/admin` path in your application.

### Full Example

Here’s a sample main.swift with a more complete implementation example with a log-in form. It also uses the “Restrictor” middleware as demonstrated above. (If you're not already well familiar with how to use forms with Kitura, I suggest reading the [relevant chapter](https://nocturnalsolutions.gitbooks.io/kitura-book/content/8-forms.html) in [Kitura Until Dawn](https://nocturnalsolutions.gitbooks.io/kitura-book/content/), my free Kitura e-book.)

```swift

import Kitura
import Credentials
import CredentialsLocal
import KituraSession

let router = Router()

let session = Session(secret: "I like turtles.")
router.all(middleware: session)

router.post(middleware: BodyParser())

let simpleCredents = Credentials()
let simpleCallbackLocal = CredentialsLocal() { userId, password, callback in
    let users = ["John" : "12345", "Mary" : "qwerasdf"]
    if let storedPassword = users[userId] {
        if (storedPassword == password) {
            callback(UserProfile(id: userId, displayName: userId, provider: "Local"))
            return
        }
    }
    // else if userId or password doesnt match
    callback(nil)
}
simpleCredents.register(plugin: simpleCallbackLocal)

router.all("/admin", middleware: Restrictor())

router.all("/admin") { request, response, next in
    if let profile = request.userProfile  {
        response.send("\(profile.displayName) is logged in with \(profile.provider)")
    }
    else {
        response.send("This shouldn't have happened.").status(.unauthorized)
    }
    next()
}

router.post("/log-in", middleware: simpleCredents)
router.get("/log-in") { request, response, next in
    let page = """
<!DOCTYPE html>
<html><body>
    <form method="post" action="/log-in">
        Username: <input type="text" name="username" /><br />
        Password: <input type="password" name="password" /><br />
        <input type="submit" />
    </form>
</body></html>
"""
    response.send(page)
    next()
}

router.post("/log-in") { request, response, next in
    if let _ = request.userProfile {
        try response.redirect("/admin").end()
    }
    else {
        response.send("Access denied.").status(.unauthorized)
    }
    next()
}

// Kick off Kitura
Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
```

## Upgrading

Version 1.0 of this Credentials plug-in was a redirecting plug-in, which basically means that it would try to redirect unauthorized users to a log in form page. I decided that wasn’t a great idea since often it is more desirable to just show the user an “access denied” message rather than redirecting them, so I refactored the plug-in as a non-redirecting one. In real world terms, this means that you need to be aware that this redirection will no longer happen after upgrading the module and you will need to implement your own code to do any sort of access restriction and/or redirection.

## Troubleshooting

This code has so far only been lightly tested. As security is a major concern on the web, I highly recommend you test extensively before using on production projects.

If you have any problems, please contact me via GitHub, as ”nocturnal” on the IBM-Swift Slack server, or as ”_Nocturnal” on Freenode. Other contact methods are outlined on [my web site](http://nocturnal.solutions/).
