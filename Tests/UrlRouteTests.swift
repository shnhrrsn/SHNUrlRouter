//
//  UrlRouterTests.swift
//  SHNUrlRouter
//
//	Copyright (c) 2018 Shaun Harrison
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

class UrlRouteTests: XCTestCase {

    func testDotDoesNotMatchEverything() {
		let route = UrlRoute(pattern: "images/{id}.{ext}")

		guard let match = route.route(for: "images/1.png") else {
			return XCTFail()
		}

		XCTAssertTrue(match.contains("id"))
		XCTAssertFalse(match.contains("foo"))
		XCTAssertEqual(match["id"], "1")
		XCTAssertEqual(match["ext"], "png")

		guard let match2 = route.route(for: "images/12.png") else {
			return XCTFail()
		}

		XCTAssertEqual(match2["id"], "12")
		XCTAssertEqual(match2["ext"], "png")

		// Test parameter() default value
		let route2 = UrlRoute(pattern: "foo/{foo?}")

		guard let match3 = route2.route(for: "foo") else {
			return XCTFail()
		}

		XCTAssertEqual(match3.get("foo", default: "bar"), "bar")
	}

	func testWherePatternsProperlyFilter() {
		var route = UrlRoute(pattern: "foo/{bar}", aliases: [ "bar": "[0-9]+" ])
		XCTAssertNotNil(route.route(for: "foo/123"))
		XCTAssertNil(route.route(for: "foo/123abc"))

		// Optionals
		route = UrlRoute(pattern: "foo/{bar?}", aliases: [ "bar": "[0-9]+" ])
		XCTAssertNotNil(route.route(for: "foo/123"))
		XCTAssertNil(route.route(for: "foo/123abc"))

		route = UrlRoute(pattern: "foo/{bar}/{baz?}", aliases: [ "bar": "[0-9]+" ])
		XCTAssertNotNil(route.route(for: "foo/123"))
		XCTAssertNotNil(route.route(for: "foo/123/abc"))
		XCTAssertNil(route.route(for: "foo/123abc"))
	}

}
