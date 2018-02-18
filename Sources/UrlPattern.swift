//
//  UrlPattern.swift
//  SHNUrlRouter
//
//  Created by Shaun Harrison on 2/17/18.
//  Copyright © 2018 Shaun Harrison. All rights reserved.
//

import Foundation

private let parameterPattern = try! NSRegularExpression(pattern: "\\{([a-zA-Z0-9_\\-]+)\\}", options: [])
private let unescapePattern = try! NSRegularExpression(pattern: "\\\\([\\{\\}\\?])", options: [])
private let optionalParameterPattern = try! NSRegularExpression(pattern: "(\\\\\\/)?\\{([a-zA-Z0-9_\\-]+)\\?\\}", options: [])

public struct UrlPattern {

	let expression: NSRegularExpression
	let captures: [String]

	static func build(pattern: String, aliases: [String: String] = [:]) -> UrlPattern {
		// Escape pattern
		let compiled = NSMutableString(string: NSRegularExpression.escapedPattern(for: pattern.normalizedPath()))

		// Unescape path parameters
		regexReplace(unescapePattern, replacement: "$1", target: compiled)

		// Extract out optional parameters so we have just {parameter} instead of {parameter?}
		regexReplace(optionalParameterPattern, replacement: "(?:$1{$2})?", target: compiled)

		// Compile captures since unfortunately Foundation doesnt’t support named groups
		var captures = [String]()

		parameterPattern.enumerateMatches(in: String(compiled), options: [], range: NSMakeRange(0, compiled.length)) { (match, _, _) in
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

		for alias in aliases {
			compiled.replaceOccurrences(of: "{\(alias.0)}", with: "(\(alias.1))", options: [], range: NSMakeRange(0, compiled.length))
		}

		regexReplace(parameterPattern, replacement: "([^\\/]+)", target: compiled)
		compiled.insert("^", at: 0)
		compiled.append("$")

		do {
			let expression = try NSRegularExpression(pattern: String(compiled), options: [])
			return UrlPattern(expression: expression, captures: captures)
		} catch let error as NSError {
			fatalError("Error compiling pattern: \(compiled), error: \(error)")
		}
	}

}

private func regexReplace(_ expression: NSRegularExpression, replacement: String, target: NSMutableString) {
	expression.replaceMatches(in: target, options: [], range: NSMakeRange(0, target.length), withTemplate: replacement)
}
