# Kitura Credentials Local

A [Kitura Credentials](https://github.com/IBM-Swift/Kitura-Credentials) plug-in for local authentication (e.g. checking for credentials in a local database) using a web page form.

This plug-in is only compatible with Kitura 2 and Swift 4.

## Usage

Usage is similar to [Kitura-CredentialsHTTP](https://github.com/IBM-Swift/Kitura-CredentialsHTTP) in that you pass a closure that verifies the credentials when instantiating the plug-in.

Here’s a sample main.swift that should show you all you need to do.

```swift

import Kitura
import Credentials
import CredentialsLocal
import KituraSession

let r = Router()

// Initialize Session; have it work on all requests
let session = Session(secret: "Some Unique Secret String")
r.all(middleware: session)

// Parse the request body on all POST requests.
r.post(middleware: BodyParser())

// Initialize Credentials with some paths to redirect the user to on success and
// failure
let creds = Credentials(options: [
    "failureRedirect": "/log-in",
    "successRedirect": "/admin",
])

// Initialize CredentialsLocal with a closure called to validate the posted
// username and password
let local = CredentialsLocal() { username, password, callback in
    // Check to see if the username is "name" and the password is "pass". In
    // real use you'd probably be doing something like hashing the password and
    // checking for the credentials in a database.
    if username == "user", password == "pass" {
        // On success, pass a UserProfile object to the callback.
        let userProfile = UserProfile(id: username, displayName: username, provider: "Local")
        callback(userProfile)
    }
    else {
        // On failure, pass nil to the callback.
        callback(nil)
    }
}

// The plug-in by default assumes the username and password fields on your
// credentials form will be named "username" and "password" respectively. If you
// wish to name something different, you can do so as below:
// local.usernamePostField = "user-id"
// local.passwordPostField = "passphrase"

// Have Credentials use our new CredentialsLocal object as a plugin.
creds.register(plugin: local)

// We want all actions under the "admin" path to require valid credentials.
r.all("/admin", middleware: creds)

// Show a sample restricted page at "/admin". If the user tries to get here when
// not logged in, they will be redirected to "/log-in".
r.get("/admin") { _, response, next in
    response.send("You are logged in!")
    next()
}

// Show a credentials form at the "/log-in" path.
r.get("/log-in") { request, response, next in
    // Render a log in form wtih "username" and "password" fields that POSTs to
    // "/log-in". In real use you probably want to use a templating engine like
    // Stencil to do this.
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

// Have Credentials test for valid credentials on a POST to "/log-in".
r.post("/log-in", handler: creds.authenticate(credentialsType: local.name))

// Kick off Kitura
Kitura.addHTTPServer(onPort: 8080, with: r)
Kitura.run()

```

## Troubleshooting

This code has not yet been extensively tested, and I must confess I really had to grind my brain against the inner workings of Credentials and KituraSession to figure out how it should work. I highly recommend you test extensively before using on production projects.

If you have any problems, please hit me up at ”nocturnal” on the IBM-Swift Slack server, ”_Nocturnal” on Freenode, or one of the other contact methods outlined on [my web site](http://nocturnal.solutions/).
