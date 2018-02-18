//
//  SHNUrlRoute.swift
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

public typealias UrlRouteQuickHandler = ([String: String]) -> Void
public typealias UrlRouteHandler = (URL, UrlRoute, [String: String]) -> Void

public struct UrlRoute: CustomDebugStringConvertible {

	/** Original route pattern this route was created with */
	public let pattern: String

	/** Compiled patterns */
	private let patterns: [UrlPattern]

	/** Route handler to use during dispatching */
	public let handler: UrlRouteHandler

	public var debugDescription: String {
		return self.pattern
	}

	public init(pattern: String, aliases: [String: String] = [:], handler: @escaping UrlRouteHandler = { _,_,_ in }) {
		self.init(patterns: [ pattern ], aliases: aliases, handler: handler)
	}

	public init(patterns: [String], aliases: [String: String] = [:], handler: @escaping UrlRouteHandler = { _,_,_ in }) {
		self.pattern = patterns[0]
		self.handler = handler
		self.patterns = patterns.map { UrlPattern.build(pattern: $0, aliases: aliases) }
	}

	public func route(for url: URL) -> UrlRouted? {
		return self.route(normalizedPath: url.path.normalizedPath())
	}

	public func route(for url: String) -> UrlRouted? {
		return self.route(normalizedPath: url.normalizedPath())
	}

	internal func route(normalizedPath path: String) -> UrlRouted? {
		let range = NSMakeRange(0, path.count)

		for pattern in self.patterns {
			guard let match = pattern.expression.firstMatch(in: path, options: [ ], range: range) else {
				continue
			}

			var parameters = [String: String]()
			let parameterKeys = pattern.captures

			if parameterKeys.count > 0 {
				for i in 1..<match.numberOfRanges {
					let range: NSRange

					#if swift(>=4.0)
						range = match.range(at: i)
					#else
						range = match.rangeAt(i)
					#endif

					guard range.location != NSNotFound else {
						continue
					}

					let value = (path as NSString).substring(with: range)

					if i <= parameterKeys.count {
						parameters[parameterKeys[i - 1]] = value
					}
				}
			}

			return UrlRouted(route: self, parameters: parameters)
		}

		return nil
	}

}
