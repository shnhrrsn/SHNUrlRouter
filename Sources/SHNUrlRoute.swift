//
//  SHNUrlRoute.swift
//  SHNUrlRouter
//
//	Copyright (c) 2015 Shaun Harrison
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

import Foundation

public typealias SHNUrlRouteQuickHandler = ([String: String]) -> Void
public typealias SHNUrlRouteHandler = (NSURL, SHNUrlRoute, [String: String]) -> Void

public class SHNUrlRoute: CustomDebugStringConvertible {

	private weak var router: SHNUrlRouter?

	/** Original route pattern this route was created with */
	public let pattern: String

	/** Route handler to use during dispatching */
	public let handler: SHNUrlRouteHandler

	public var debugDescription: String {
		return self.pattern
	}

	public init(router: SHNUrlRouter, pattern: String, handler: SHNUrlRouteHandler) {
		self.pattern = pattern
		self.router = router
		self.handler = handler
	}

	/**
	Add a route pattern alias to this route

	- parameter pattern: Route pattern

	- returns: Current route instance for chaining
	*/
	public func addAlias(pattern: String) -> SHNUrlRoute {
		return self.addAliases([pattern])
	}

	/**
	Add route pattern aliases to this route

	- parameter patterns: Route patterns

	- returns: Current route instance for chaining
	*/
	public func addAliases(patterns: [String]) -> SHNUrlRoute {
		self.router?.register(patterns, route: self)
		return self
	}

}
