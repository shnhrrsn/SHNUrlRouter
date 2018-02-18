//
//  UrlRouterTests.swift
//  SHNUrlRouter
//
//	Copyright (c) 2015-2018 Shaun Harrison
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.
//

import XCTest
@testable import SHNUrlRouter

class UrlRouterTests: XCTestCase {

	func testReadMeExample() {
		var router = UrlRouter()
		var selectedIndex = -1
		var id = -1
		var section: String?

		router.add("id", pattern: "[0-9]+")
		router.add("section", pattern: "profile|activity")

		router.register("feed") { (parameters) in
			selectedIndex = 0
		}

		router.register("user/{id}/{section?}") { (parameters) in
			guard let stringId = parameters["id"], let intId = Int(stringId) else {
				return
			}

			selectedIndex = 1
			id = intId
			section = parameters["section"] ?? "default"
		}

		XCTAssertTrue(router.dispatch(for: "http://example.com/feed"))
		XCTAssertEqual(selectedIndex, 0)

		XCTAssertFalse(router.dispatch(for: "http://example.com/user"))

		XCTAssertTrue(router.dispatch(for: "http://example.com/user/5"))
		XCTAssertEqual(id, 5)
		XCTAssertEqual(section, "default")

		XCTAssertTrue(router.dispatch(for: "http://example.com/user/5/profile"))
		XCTAssertEqual(id, 5)
		XCTAssertEqual(section, "profile")
	}

	func testBasicDispatchingOfRoutes() {
		var router = UrlRouter()
		var dispatched = false

		router.register("foo/bar") { _ in
			dispatched = true
		}

		XCTAssertTrue(router.dispatch(for: "http://example.com/foo/bar"))
		XCTAssertTrue(dispatched)
	}

	func testBasicDispatchingOfRoutesWithParameter() {
		var router = UrlRouter()
		var dispatched = false

		router.register("foo/{bar}") { parameters in
			XCTAssertEqual(parameters["bar"], "swift")
			dispatched = true
		}

		XCTAssertTrue(router.dispatch(for: "http://example.com/foo/swift"))
		XCTAssertTrue(dispatched)
	}

	func testBasicDispatchingOfRoutesWithOptionalParameter() {
		var router = UrlRouter()
		var dispatched: String? = nil

		router.register("foo/{bar}/{baz?}") { parameters in
			dispatched = "\(parameters["bar"] ?? "").\(parameters["baz"] ?? "1")"
		}

		XCTAssertTrue(router.dispatch(for: "http://example.com/foo/swift/4"))
		XCTAssertEqual(dispatched, "swift.4")

		XCTAssertTrue(router.dispatch(for: "http://example.com/foo/swift"))
		XCTAssertEqual(dispatched, "swift.1")
	}

	func testBasicDispatchingOfRoutesWithOptionalParameters() {
		var router = UrlRouter()
		var dispatched: String? = nil

		router.register("foo/{name}/boom/{age?}/{location?}") { parameters in
			dispatched = "\(parameters["name"] ?? "").\(parameters["age"] ?? "56").\(parameters["location"] ?? "ca")"
		}

		XCTAssertTrue(router.dispatch(for: "http://example.com/foo/steve/boom"))
		XCTAssertEqual(dispatched, "steve.56.ca")

		XCTAssertTrue(router.dispatch(for: "http://example.com/foo/swift/boom/4"))
		XCTAssertEqual(dispatched, "swift.4.ca")

		XCTAssertTrue(router.dispatch(for: "http://example.com/foo/swift/boom/4/org"))
		XCTAssertEqual(dispatched, "swift.4.org")
	}

}
