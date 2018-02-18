//
//  SHNUrlRouter.swift
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

import Foundation

public struct UrlRouter {
	private var routes = [UrlRoute]()
	internal fileprivate(set) var aliases = [String: String]()

	public init() { }

	/**
	Add an parameter alias

	- parameter alias: Name of the parameter
	- parameter pattern: Regex pattern to match on
	*/
	public mutating func add(_ alias: String, pattern: String) {
		self.aliases[alias] = pattern
	}

	/**
	Register a route pattern

	- parameter pattern: Route pattern
	- parameter handler: Quick handler to call when route is dispatched

	- returns: New route instance for the pattern
	*/
	@discardableResult public mutating func register(_ routePattern: String, handler: @escaping UrlRouteQuickHandler) -> UrlRoute {
		return self.register([ routePattern ], handler: handler)
	}

	/**
	Register route patterns

	- parameter pattern: Route patterns
	- parameter handler: Quick handler to call when route is dispatched

	- returns: New route instance for the patterns
	*/
	@discardableResult public mutating func register(_ routePatterns: [String], handler: @escaping UrlRouteQuickHandler) -> UrlRoute {
		return self.registerFull(routePatterns) { (url, route, parameters) in
			handler(parameters)
		}
	}

	/**
	Register a route pattern with full handler

	- parameter pattern: Route pattern
	- parameter handler: Full handler to call when route is dispatched

	- returns: New route instance for the pattern
	*/
	@discardableResult public mutating func registerFull(_ routePattern: String, handler: @escaping UrlRouteHandler) -> UrlRoute {
		return self.registerFull([ routePattern ], handler: handler)
	}

	/**
	Register route patterns with full handler

	- parameter pattern: Route patterns
	- parameter handler: Full handler to call when route is dispatched

	- returns: New route instance for the patterns
	*/
	@discardableResult public mutating func registerFull(_ routePatterns: [String], handler: @escaping UrlRouteHandler) -> UrlRoute {
		assert(routePatterns.count > 0, "Route patterns must contain at least one pattern")

		let route = UrlRoute(patterns: routePatterns, aliases: self.aliases, handler: handler)
		self.routes.append(route)
		return route
	}

	/**
	Route a URL and get the routed instance back

	- parameter url: URL string to route

	- returns: Instance of SHNUrlRouted with binded parameters if matched, nil if route isn’t supported
	*/
	public func route(for url: String) -> UrlRouted? {
		guard let url = URL(string: url) else {
			return nil
		}

		return self.route(for: url)
	}

	/**
	Route a URL and get the routed instance back

	- parameter url: URL to route

	- returns: Instance of SHNUrlRouted with binded parameters if matched, nil if route isn’t supported
	*/
	public func route(for url: URL) -> UrlRouted? {
		let path = url.path.normalizedPath()

		for route in self.routes {
			guard let routed = route.route(normalizedPath: path) else {
				continue
			}


			return routed
		}

		return nil
	}

	/**
	Dispatch a url

	- parameter url: URL string to dispatch

	- returns: True if dispatched, false if unable to dispatch which occurs if url isn’t routable
	*/
	public func dispatch(for url: String) -> Bool {
		guard let url = URL(string: url) else {
			return false
		}

		return self.dispatch(for: url)
	}

	/**
	Dispatch a url

	- parameter url: URL to dispatch

	- returns: True if dispatched, false if unable to dispatch which occurs if url isn’t routable
	*/
	public func dispatch(for url: URL) -> Bool {
		guard let routed = self.route(for: url) else {
			return false
		}

		routed.route.handler(url, routed.route, routed.parameters)
		return true
	}

}
