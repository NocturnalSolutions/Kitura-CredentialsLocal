/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation
import XCTest

import Kitura
import KituraNet
import KituraSession
import Credentials
import LoggerAPI

@testable import CredentialsLocal

class TestLocal : XCTestCase {
    
    static var allTests : [(String, (TestLocal) -> () throws -> Void)] {
        return [
                   ("testNoCredentials", testNoCredentialsSimple),
                   ("testBadCredentials", testBadCredentialsSimple),
                   ("testGoodCredentials", testGoodCredentialsSimple),
//                   ("testBasic", testBasic),
        ]
    }
    
    override func setUp() {
        doSetUp()
    }
    
    override func tearDown() {
        doTearDown()
    }
    
    let host = "127.0.0.1"
    
    let router = TestLocal.setupRouter()
    
    func testNoCredentialsSimple() {
        performServerTest(router: router) { expectation in
            self.performRequest(method: "post", host: self.host, path: "/log-in", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")
                expectation.fulfill()
            })
        }
    }

    func testNoCredentialsRequest() {
        performServerTest(router: router) { expectation in
            self.performRequest(method: "post", host: self.host, path: "/request-log-in", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")
                expectation.fulfill()
            })
        }
    }

    func testBadCredentialsSimple() {
        // Good username, bad password
        performServerTest(router: router) { expectation in
            self.performRequest(method: "post", path:"/log-in", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")
                expectation.fulfill()
            }, headers: ["Content-Type": "application/x-www-form-urlencoded"], requestModifier: { request in
                request.write(from: "username=John&password=wrongPassword")
            })
        }

        
        // Good password, bad username
        performServerTest(router: router) { expectation in
            self.performRequest(method: "post", path:"/log-in", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")
                expectation.fulfill()
            }, headers: ["Content-Type": "application/x-www-form-urlencoded"], requestModifier: { request in
                request.write(from: "username=Maria&password=qwerasdf")
            })
        }
    }

    func testBadCredentialsRequest() {
        // Good username, bad password
        performServerTest(router: router) { expectation in
            self.performRequest(method: "post", path:"/request-log-in", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")
                expectation.fulfill()
            }, headers: ["Content-Type": "application/x-www-form-urlencoded"], requestModifier: { request in
                request.write(from: "username=John&password=wrongPassword")
            })
        }


        // Good password, bad username
        performServerTest(router: router) { expectation in
            self.performRequest(method: "post", path:"/request-log-in", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")
                expectation.fulfill()
            }, headers: ["Content-Type": "application/x-www-form-urlencoded"], requestModifier: { request in
                request.write(from: "username=Maria&password=qwerasdf")
            })
        }
    }

    func testGoodCredentialsSimple() {
        performServerTest(router: router) { expectation in
            self.performRequest(method: "post", path:"/log-in", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(String(describing: response?.statusCode))")
                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body,"<!DOCTYPE html><html><body><b>Mary is logged in with Local</b></body></html>\n\n")
                }
                catch{
                    XCTFail("No response body")
                }
                expectation.fulfill()
            }, headers: ["Content-Type": "application/x-www-form-urlencoded"], requestModifier: { request in
                request.write(from: "username=Mary&password=qwerasdf")
            })
        }
    }

    func testGoodCredentialsRequest() {
        performServerTest(router: router) { expectation in
            self.performRequest(method: "post", path:"/request-log-in", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(String(describing: response?.statusCode))")
                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body,"<!DOCTYPE html><html><body><b>John is logged in with Local</b></body></html>\n\n")
                }
                catch{
                    XCTFail("No response body")
                }
                expectation.fulfill()
            }, headers: ["Content-Type": "application/x-www-form-urlencoded"], requestModifier: { request in
                request.write(from: "username=John&password=12345&captcha=123456")
            })
        }
    }

    static func setupRouter() -> Router {
        let router = Router()

        // Get Sessions working on all paths
        let session = Session(secret: "I like turtles.")
        router.all(middleware: session)

        // Parse bodies on posts
        router.post(middleware: BodyParser())

        // "User accounts"
        let users = ["John" : "12345", "Mary" : "qwerasdf"]

        // Set up credentials for a simple (username and password) callback
        let simpleCredents = Credentials(options: [
            "failureRedirect": "/failure",
            "successRedirect": "/private/success"
        ])

        // Set up Credentials for a request callback
        let requestCredents = Credentials(options: [
            "failureRedirect": "/failure",
            "successRedirect": "/request-private/success"
        ])

        // Set up simple verification callback
        let simpleCallbackLocal = CredentialsLocal() { userId, password, callback in
            if let storedPassword = users[userId] {
                if (storedPassword == password) {
                    callback(UserProfile(id: userId, displayName: userId, provider: "Local"))
                }
            }
            callback(nil)
        }
        simpleCredents.register(plugin: simpleCallbackLocal)

        // Set up request verification callback
        let requestCallbackLocal = CredentialsLocal() { request, callback in
            guard let body = request.body?.asURLEncoded,
                let userId = body["username"],
                let password = body["password"],
                let captcha = body["captcha"] else {
                callback(nil)
                return
            }
            if let storedPassword = users[userId] {
                if storedPassword == password, captcha == "123456" {
                    callback(UserProfile(id: userId, displayName: userId, provider: "Local"))
                }
            }
            callback(nil)
        }
        requestCredents.register(plugin: requestCallbackLocal)

        // Set up paths that require valid credents
        router.all("/private", middleware: simpleCredents)
        router.all("/request-private", middleware: requestCredents)

        // Set up paths to handle the log in "form" submission
        router.post("/log-in", handler: simpleCredents.authenticate(credentialsType: simpleCallbackLocal.name))
        router.post("/request-log-in", handler: requestCredents.authenticate(credentialsType: requestCallbackLocal.name))

        // Set up a handler for a "successful" log in
        let successHandler: (RouterRequest, RouterResponse, @escaping () -> Void ) -> Void = {request, response, next in
            response.headers["Content-Type"] = "text/html; charset=utf-8"
            do {
                if let profile = request.userProfile  {
                    try response.status(.OK).send("<!DOCTYPE html><html><body><b>\(profile.displayName) is logged in with \(profile.provider)</b></body></html>\n\n").end()
                    next()
                    return
                }
                else {
                    try response.status(.unauthorized).end()
                }
            }
            catch {}
            next()
        }

        // Set up our success page routes
        router.all("/private/success", handler: successHandler)
        router.all("/request-private/success", handler: successHandler)

        // Set up our failure page route
        router.all("/failure") { _, response, next in
            response.status(.unauthorized)
            response.send("You're not authorized.")
            Log.info("/failure handler reached")
            next()
        }
        
        return router
    }
}
