//
//  SHNUrlRouter.swift
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

private typealias PatternRoutePair = (CompiledPattern, SHNUrlRoute)
private typealias CompiledPattern = (NSRegularExpression, [String])

private func regexReplace(expression: NSRegularExpression, replacement: String, target: NSMutableString) {
	expression.replaceMatchesInString(target, options: nil, range: NSMakeRange(0, target.length), withTemplate: replacement)
}

public class SHNUrlRouter {
	private var patterns = Array<PatternRoutePair>()
	private var aliases = Dictionary<String, String>()
	private let unescapePattern = NSRegularExpression(pattern: "\\\\([\\{\\}\\?])", options: nil, error: nil)!
	private let parameterPattern = NSRegularExpression(pattern: "\\{([a-zA-Z0-9_\\-]+)\\}", options: nil, error: nil)!
	private let optionalParameterPattern = NSRegularExpression(pattern: "(\\\\\\/)?\\{([a-zA-Z0-9_\\-]+)\\?\\}", options: nil, error: nil)!
	private let slashCharacterSet = NSCharacterSet(charactersInString: "/")

	public init() { }

	/**
	Add an parameter alias

	:param: alias Name of the parameter
	:param: pattern Regex pattern to match on
	*/
	public func add(alias: String, pattern: String) {
		self.aliases[alias] = pattern
	}

	/**
	Register a route pattern

	:param: pattern Route pattern
	:param: handler Quick handler to call when route is dispatched

	:returns: New route instance for the pattern
	*/
	public func register(routePattern: String, handler: SHNUrlRouteQuickHandler) -> SHNUrlRoute {
		return self.register([routePattern], handler: handler)
	}

	/**
	Register route patterns

	:param: pattern Route patterns
	:param: handler Quick handler to call when route is dispatched

	:returns: New route instance for the patterns
	*/
	public func register(routePatterns: [String], handler: SHNUrlRouteQuickHandler) -> SHNUrlRoute {
		return self.registerFull(routePatterns) { (url, route, parameters) in
			handler(parameters)
		}
	}

	/**
	Register a route pattern with full handler

	:param: pattern Route pattern
	:param: handler Full handler to call when route is dispatched

	:returns: New route instance for the pattern
	*/
	public func registerFull(routePattern: String, handler: SHNUrlRouteHandler) -> SHNUrlRoute {
		return self.registerFull([routePattern], handler: handler)
	}

	/**
	Register route patterns with full handler

	:param: pattern Route patterns
	:param: handler Full handler to call when route is dispatched

	:returns: New route instance for the patterns
	*/
	public func registerFull(routePatterns: [String], handler: SHNUrlRouteHandler) -> SHNUrlRoute {
		assert(routePatterns.count > 0, "Route patterns must contain at least one pattern")

		let route = SHNUrlRoute(router: self, pattern: routePatterns.first!, handler: handler)
		self.register(routePatterns, route: route)
		return route
	}

	internal func register(routePatterns: [String], route: SHNUrlRoute) {
		for routePattern in routePatterns {
			self.patterns.append(PatternRoutePair(self.compilePattern(routePattern), route))
		}
	}

	private func normalizePath(path: String?) -> String {
		if let path = path?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) where count(path) > 0 {
			return "/" + path.stringByTrimmingCharactersInSet(self.slashCharacterSet)
		} else {
			return "/"
		}
	}

	private func compilePattern(pattern: String) -> CompiledPattern {
		// Escape pattern
		var compiled = NSMutableString(string: NSRegularExpression.escapedPatternForString(self.normalizePath(pattern)))

		// Unescape path parameters
		regexReplace(self.unescapePattern, "$1", compiled)

		// Extract out optional parameters so we have just {parameter} instead of {parameter?}
		regexReplace(self.optionalParameterPattern, "(?:$1{$2})?", compiled)

		// Compile captures since unfortunately Foundation doesnt’t support named groups
		var captures = Array<String>()

		self.parameterPattern.enumerateMatchesInString(String(compiled), options: nil, range: NSMakeRange(0, compiled.length)) { (match, _, _) in
			if match.numberOfRanges > 1 {
				let range = match.rangeAtIndex(1)

				if range.location != NSNotFound {
					captures.append(compiled.substringWithRange(range))
				}
			}
		}

		for alias in self.aliases {
			compiled.replaceOccurrencesOfString("{\(alias.0)}", withString: "(\(alias.1))", options: nil, range: NSMakeRange(0, compiled.length))
		}

		regexReplace(self.parameterPattern, "([^\\/]+)", compiled)
		compiled.insertString("^", atIndex: 0)
		compiled.appendString("$")

		var error: NSError?

		if let expression = NSRegularExpression(pattern: String(compiled), options: nil, error: &error) {
			return CompiledPattern(expression, captures)
		} else {
			fatalError("Error compiling pattern: \(compiled), error: \(error)")
		}
	}

	/**
	Route a URL and get the routed instance back

	:param: url URL string to route

	:returns: Instance of SHNUrlRouted with binded parameters
	if matched, nil if route isn’t supported
	*/
	public func route(url: String) -> SHNUrlRouted? {
		if let url = NSURL(string: url) {
			return self.route(url)
		} else {
			return nil
		}
	}

	/**
	Route a URL and get the routed instance back

	:param: url URL to route

	:returns: Instance of SHNUrlRouted with binded parameters
	if matched, nil if route isn’t supported
	*/
	public func route(url: NSURL) -> SHNUrlRouted? {
		let path = self.normalizePath(url.path)
		let range = NSMakeRange(0, count(path))

		for pattern in patterns {
			if let match = pattern.0.0.firstMatchInString(path, options: nil, range: range) {
				var parameters = Dictionary<String, String>()
				let parameterKeys = pattern.0.1

				if parameterKeys.count > 0 {
					for var i = 1; i < match.numberOfRanges; i++ {
						let range = match.rangeAtIndex(i)

						if range.location != NSNotFound {
							let value = (path as NSString).substringWithRange(range)

							if i <= parameterKeys.count {
								parameters[parameterKeys[i - 1]] = value
							}
						}
					}
				}

				return SHNUrlRouted(route: pattern.1, parameters: parameters)
			}
		}

		return nil
	}

	/**
	Dispatch a url

	:param: url URL string to dispatch

	:returns: True if dispatched, false if unable to dispatch which
	occurs if url isn’t routable
	*/
	public func dispatch(url: String) -> Bool {
		if let url = NSURL(string: url) {
			return self.dispatch(url)
		} else {
			return false
		}
	}

	/**
	Dispatch a url

	:param: url URL to dispatch

	:returns: True if dispatched, false if unable to dispatch which
	occurs if url isn’t routable
	*/
	public func dispatch(url: NSURL) -> Bool {
		if let routed = self.route(url) {
			routed.route.handler(url, routed.route, routed.parameters)
			return true
		} else {
			return false
		}
	}

}
