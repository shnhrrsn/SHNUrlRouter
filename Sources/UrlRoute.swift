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

public typealias UrlRouteQuickHandler = ([String: String]) -> Void
public typealias UrlRouteHandler = (NSURL, UrlRoute, [String: String]) -> Void

@available(*, deprecated=1.2, renamed="UrlRoute", message="Use non-prefixed UrlRoute instead")
public typealias SHNUrlRoute = UrlRoute

@available(*, deprecated=1.2, renamed="UrlRouteQuickHandler", message="Use non-prefixed UrlRouteQuickHandler instead")
public typealias SHNUrlRouteQuickHandler = UrlRouteQuickHandler

@available(*, deprecated=1.2, renamed="UrlRouteHandler", message="Use non-prefixed UrlRouteHandler instead")
public typealias SHNUrlRouteHandler = UrlRouteHandler

public class UrlRoute: CustomDebugStringConvertible {

	private weak var router: UrlRouter?

	/** Original route pattern this route was created with */
	public let pattern: String

	/** Route handler to use during dispatching */
	public let handler: UrlRouteHandler

	public var debugDescription: String {
		return self.pattern
	}

	public init(router: UrlRouter, pattern: String, handler: UrlRouteHandler) {
		self.pattern = pattern
		self.router = router
		self.handler = handler
	}

	/**
	Add a route pattern alias to this route

	- parameter pattern: Route pattern

	- returns: Current route instance for chaining
	*/
	public func addAlias(pattern: String) -> UrlRoute {
		return self.addAliases([pattern])
	}

	/**
	Add route pattern aliases to this route

	- parameter patterns: Route patterns

	- returns: Current route instance for chaining
	*/
	public func addAliases(patterns: [String]) -> UrlRoute {
		self.router?.register(patterns, route: self)
		return self
	}

}
