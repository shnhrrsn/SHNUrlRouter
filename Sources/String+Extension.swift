//
//  String+Extension.swift
//  SHNUrlRouter
//
//  Created by Shaun Harrison on 2/17/18.
//  Copyright © 2018 Shaun Harrison. All rights reserved.
//

private let slashCharacterSet = CharacterSet(charactersIn: "/")

internal extension String {

	func normalizedPath() -> String {
		let path = self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

		guard path.count > 0 else {
			return "/"
		}

		return "/" + path.trimmingCharacters(in: slashCharacterSet)
	}

	#if swift(>=4.0)
	#else
		var count: Int {
			return self.characters.count
		}
	#endif

}
