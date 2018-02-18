//
//  SHNUrlRouted.swift
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

public struct UrlRouted: CustomDebugStringConvertible {

	let route: UrlRoute
	let parameters: [String: String]

	public func contains(_ parameter: String) -> Bool {
		return self.parameters[parameter] != nil
	}

	public func get(_ parameter: String, default: String? = nil) -> String? {
		return self.parameters[parameter] ?? `default`
	}

	public subscript(parameter: String) -> String? {
		return self.parameters[parameter]
	}

	public var debugDescription: String {
		guard self.parameters.count > 0 else {
			return "\(self.route): (no parameters)"
		}

		return "\(self.route): \(self.parameters)"
	}

}
