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

private typealias PatternRoutePair = (CompiledPattern, UrlRoute)
private typealias CompiledPattern = (NSRegularExpression, [String])

private func regexReplace(_ expression: NSRegularExpression, replacement: String, target: NSMutableString) {
	expression.replaceMatches(in: target, options: [], range: NSMakeRange(0, target.length), withTemplate: replacement)
}

@available(*, deprecated: 1.2, renamed: "UrlRouter", message: "Use non-prefixed UrlRouter instead")
public typealias SHNUrlRouter = UrlRouter

open class UrlRouter {
	fileprivate var patterns = [PatternRoutePair]()
	fileprivate var aliases = [String: String]()
	fileprivate let unescapePattern = try! NSRegularExpression(pattern: "\\\\([\\{\\}\\?])", options: [])
	fileprivate let parameterPattern = try! NSRegularExpression(pattern: "\\{([a-zA-Z0-9_\\-]+)\\}", options: [])
	fileprivate let optionalParameterPattern = try! NSRegularExpression(pattern: "(\\\\\\/)?\\{([a-zA-Z0-9_\\-]+)\\?\\}", options: [])
	fileprivate let slashCharacterSet = CharacterSet(charactersIn: "/")

	public init() { }

	/**
	Add an parameter alias

	- parameter alias: Name of the parameter
	- parameter pattern: Regex pattern to match on
	*/
	open func add(_ alias: String, pattern: String) {
		self.aliases[alias] = pattern
	}

	/**
	Register a route pattern

	- parameter pattern: Route pattern
	- parameter handler: Quick handler to call when route is dispatched

	- returns: New route instance for the pattern
	*/
	@discardableResult open func register(_ routePattern: String, handler: @escaping UrlRouteQuickHandler) -> UrlRoute {
		return self.register([routePattern], handler: handler)
	}

	/**
	Register route patterns

	- parameter pattern: Route patterns
	- parameter handler: Quick handler to call when route is dispatched

	- returns: New route instance for the patterns
	*/
	@discardableResult open func register(_ routePatterns: [String], handler: @escaping UrlRouteQuickHandler) -> UrlRoute {
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
	@discardableResult open func registerFull(_ routePattern: String, handler: @escaping UrlRouteHandler) -> UrlRoute {
		return self.registerFull([routePattern], handler: handler)
	}

	/**
	Register route patterns with full handler

	- parameter pattern: Route patterns
	- parameter handler: Full handler to call when route is dispatched

	- returns: New route instance for the patterns
	*/
	@discardableResult open func registerFull(_ routePatterns: [String], handler: @escaping UrlRouteHandler) -> UrlRoute {
		assert(routePatterns.count > 0, "Route patterns must contain at least one pattern")

		let route = UrlRoute(router: self, pattern: routePatterns.first!, handler: handler)
		self.register(routePatterns, route: route)
		return route
	}

	internal func register(_ routePatterns: [String], route: UrlRoute) {
		for routePattern in routePatterns {
			self.patterns.append(PatternRoutePair(self.compilePattern(routePattern), route))
		}
	}

	fileprivate func normalizePath(_ path: String?) -> String {
		if let path = path?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), path.count > 0 {
			return "/" + path.trimmingCharacters(in: self.slashCharacterSet)
		} else {
			return "/"
		}
	}

	fileprivate func compilePattern(_ pattern: String) -> CompiledPattern {
		// Escape pattern
		let compiled = NSMutableString(string: NSRegularExpression.escapedPattern(for: self.normalizePath(pattern)))

		// Unescape path parameters
		regexReplace(self.unescapePattern, replacement: "$1", target: compiled)

		// Extract out optional parameters so we have just {parameter} instead of {parameter?}
		regexReplace(self.optionalParameterPattern, replacement: "(?:$1{$2})?", target: compiled)

		// Compile captures since unfortunately Foundation doesnt’t support named groups
		var captures = Array<String>()

		self.parameterPattern.enumerateMatches(in: String(compiled), options: [], range: NSMakeRange(0, compiled.length)) { (match, _, _) in
			if let match = match , match.numberOfRanges > 1 {
				let range: NSRange

				#if swift(>=4.0)
					range = match.range(at: 1)
				#else
					range = match.rangeAt(1)
				#endif

				if range.location != NSNotFound {
					captures.append(compiled.substring(with: range))
				}
			}
		}

		for alias in self.aliases {
			compiled.replaceOccurrences(of: "{\(alias.0)}", with: "(\(alias.1))", options: [], range: NSMakeRange(0, compiled.length))
		}

		regexReplace(self.parameterPattern, replacement: "([^\\/]+)", target: compiled)
		compiled.insert("^", at: 0)
		compiled.append("$")

		do {
			let expression = try NSRegularExpression(pattern: String(compiled), options: [])
			return CompiledPattern(expression, captures)
		} catch let error as NSError {
			fatalError("Error compiling pattern: \(compiled), error: \(error)")
		}
	}

	/**
	Route a URL and get the routed instance back

	- parameter url: URL string to route

	- returns: Instance of SHNUrlRouted with binded parameters if matched, nil if route isn’t supported
	*/
	open func route(for url: String) -> UrlRouted? {
		if let url = URL(string: url) {
			return self.route(for: url)
		} else {
			return nil
		}
	}

	/**
	Route a URL and get the routed instance back

	- parameter url: URL to route

	- returns: Instance of SHNUrlRouted with binded parameters if matched, nil if route isn’t supported
	*/
	open func route(for url: URL) -> UrlRouted? {
		let path = self.normalizePath(url.path)
		let range = NSMakeRange(0, path.count)

		for pattern in patterns {
			if let match = pattern.0.0.firstMatch(in: path, options: [], range: range) {
				var parameters = [String: String]()
				let parameterKeys = pattern.0.1

				if parameterKeys.count > 0 {
					for i in 1..<match.numberOfRanges {
						let range: NSRange

						#if swift(>=4.0)
							range = match.range(at: 1)
						#else
							range = match.rangeAt(1)
						#endif

						if range.location != NSNotFound {
							let value = (path as NSString).substring(with: range)

							if i <= parameterKeys.count {
								parameters[parameterKeys[i - 1]] = value
							}
						}
					}
				}

				return UrlRouted(route: pattern.1, parameters: parameters)
			}
		}

		return nil
	}

	/**
	Dispatch a url

	- parameter url: URL string to dispatch

	- returns: True if dispatched, false if unable to dispatch which occurs if url isn’t routable
	*/
	open func dispatch(for url: String) -> Bool {
		if let url = URL(string: url) {
			return self.dispatch(for: url)
		} else {
			return false
		}
	}

	/**
	Dispatch a url

	- parameter url: URL to dispatch

	- returns: True if dispatched, false if unable to dispatch which occurs if url isn’t routable
	*/
	open func dispatch(for url: URL) -> Bool {
		if let routed = self.route(for: url) {
			routed.route.handler(url, routed.route, routed.parameters)
			return true
		} else {
			return false
		}
	}

}

private extension String {

	#if swift(>=4.0)
	#else

		var count: Int {
			return self.characters.count
		}

	#endif

}
