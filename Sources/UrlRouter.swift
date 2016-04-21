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

private typealias PatternRoutePair = (CompiledPattern, UrlRoute)
private typealias CompiledPattern = (NSRegularExpression, [String])

private func regexReplace(expression: NSRegularExpression, replacement: String, target: NSMutableString) {
	expression.replaceMatches(in: target, options: [], range: NSMakeRange(0, target.length), withTemplate: replacement)
}

#if !swift(>=3.0)
	@available(*, deprecated=1.2, renamed="UrlRouter", message="Use non-prefixed UrlRouter instead")
	public typealias SHNUrlRouter = UrlRouter
#endif

public class UrlRouter {
	private var patterns = Array<PatternRoutePair>()
	private var aliases = Dictionary<String, String>()
	private let unescapePattern = try! NSRegularExpression(pattern: "\\\\([\\{\\}\\?])", options: [])
	private let parameterPattern = try! NSRegularExpression(pattern: "\\{([a-zA-Z0-9_\\-]+)\\}", options: [])
	private let optionalParameterPattern = try! NSRegularExpression(pattern: "(\\\\\\/)?\\{([a-zA-Z0-9_\\-]+)\\?\\}", options: [])
	private let slashCharacterSet = NSCharacterSet(charactersIn: "/")

	public init() { }

	/**
	Add an parameter alias

	- parameter alias: Name of the parameter
	- parameter pattern: Regex pattern to match on
	*/
	public func add(alias: String, pattern: String) {
		self.aliases[alias] = pattern
	}

	/**
	Register a route pattern

	- parameter pattern: Route pattern
	- parameter handler: Quick handler to call when route is dispatched

	- returns: New route instance for the pattern
	*/
	public func register(routePattern: String, handler: UrlRouteQuickHandler) -> UrlRoute {
		return self.register([routePattern], handler: handler)
	}

	/**
	Register route patterns

	- parameter pattern: Route patterns
	- parameter handler: Quick handler to call when route is dispatched

	- returns: New route instance for the patterns
	*/
	public func register(routePatterns: [String], handler: UrlRouteQuickHandler) -> UrlRoute {
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
	public func registerFull(routePattern: String, handler: UrlRouteHandler) -> UrlRoute {
		return self.registerFull([routePattern], handler: handler)
	}

	/**
	Register route patterns with full handler

	- parameter pattern: Route patterns
	- parameter handler: Full handler to call when route is dispatched

	- returns: New route instance for the patterns
	*/
	public func registerFull(routePatterns: [String], handler: UrlRouteHandler) -> UrlRoute {
		assert(routePatterns.count > 0, "Route patterns must contain at least one pattern")

		let route = UrlRoute(router: self, pattern: routePatterns.first!, handler: handler)
		self.register(routePatterns, route: route)
		return route
	}

	internal func register(routePatterns: [String], route: UrlRoute) {
		for routePattern in routePatterns {
			self.patterns.append(PatternRoutePair(self.compilePattern(routePattern), route))
		}
	}

	private func normalizePath(path: String?) -> String {
		if let path = path?.trimmingCharacters(in: NSCharacterSet.whitespaceAndNewline()) where path.characters.count > 0 {
			return "/" + path.trimmingCharacters(in: self.slashCharacterSet)
		} else {
			return "/"
		}
	}

	private func compilePattern(pattern: String) -> CompiledPattern {
		// Escape pattern
		let compiled = NSMutableString(string: NSRegularExpression.escapedPattern(for: self.normalizePath(pattern)))

		// Unescape path parameters
		regexReplace(self.unescapePattern, replacement: "$1", target: compiled)

		// Extract out optional parameters so we have just {parameter} instead of {parameter?}
		regexReplace(self.optionalParameterPattern, replacement: "(?:$1{$2})?", target: compiled)

		// Compile captures since unfortunately Foundation doesnt’t support named groups
		var captures = Array<String>()

		self.parameterPattern.enumerateMatches(in: compiled as String, options: [], range: NSMakeRange(0, compiled.length)) { (match, _, _) in
			if let match = match where match.numberOfRanges > 1 {
				let range = match.range(at: 1)

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
			let expression = try NSRegularExpression(pattern: compiled as String, options: [])
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
	public func route(url: String) -> UrlRouted? {
		if let url = NSURL(string: url) {
			return self.route(url)
		} else {
			return nil
		}
	}

	/**
	Route a URL and get the routed instance back

	- parameter url: URL to route

	- returns: Instance of SHNUrlRouted with binded parameters if matched, nil if route isn’t supported
	*/
	public func route(url: NSURL) -> UrlRouted? {
		let path = self.normalizePath(url.path)
		let range = NSMakeRange(0, path.characters.count)

		for pattern in patterns {
			if let match = pattern.0.0.firstMatch(in: path, options: [], range: range) {
				var parameters = Dictionary<String, String>()
				let parameterKeys = pattern.0.1

				if parameterKeys.count > 0 {
					for i in 1..<match.numberOfRanges {
						let range = match.range(at: i)

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
	public func dispatch(url: String) -> Bool {
		if let url = NSURL(string: url) {
			return self.dispatch(url)
		} else {
			return false
		}
	}

	/**
	Dispatch a url

	- parameter url: URL to dispatch

	- returns: True if dispatched, false if unable to dispatch which occurs if url isn’t routable
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

#if !swift(>=3.0)

	extension String {

		func trimmingCharacters(in set: NSCharacterSet) -> String {
			return self.stringByTrimmingCharactersInSet(set)
		}

	}

	extension NSString {

		func substring(with range: NSRange) -> String {
			return self.substringWithRange(range)
		}

	}

	extension NSMutableString {

		func insert(string: String, at loc: Int) {
			self.insertString(string, atIndex: loc)
		}

		func append(string: String) {
			self.appendString(string)
		}

		func replaceOccurrences(of string: String, with replacement: String, options: NSStringCompareOptions, range searchRange: NSRange) -> Int {
			return self.replaceOccurrencesOfString(string, withString: replacement, options: options, range: searchRange)
		}

	}

	extension NSCharacterSet {

		convenience init(charactersIn string: String) {
			self.init(charactersInString: string)
		}

		class func whitespaceAndNewline() -> NSCharacterSet {
			return self.whitespaceAndNewlineCharacterSet()
		}

	}

	extension NSRegularExpression {

		class func escapedPattern(for string: String) -> String {
			return self.escapedPatternForString(string)
		}

		func enumerateMatches(in string: String, options: NSMatchingOptions, range: NSRange, usingBlock block: (NSTextCheckingResult?, NSMatchingFlags, UnsafeMutablePointer<ObjCBool>) -> Void) {
			return self.enumerateMatchesInString(string, options: options, range: range, usingBlock: block)
		}

		func firstMatch(in string: String, options: NSMatchingOptions, range: NSRange) -> NSTextCheckingResult? {
			return self.firstMatchInString(string, options: options, range: range)
		}

		func replaceMatches(in string: NSMutableString, options: NSMatchingOptions, range: NSRange, withTemplate templ: String) -> Int {
			return self.replaceMatchesInString(string, options: options, range: range, withTemplate: templ)
		}

	}

	extension NSTextCheckingResult {

		func range(at idx: Int) -> NSRange {
			return self.rangeAtIndex(idx)
		}

	}

#endif
