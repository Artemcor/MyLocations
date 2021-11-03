//
//  String+AddText.swift
//  MyLocations
//
//  Created by Стожок Артём on 28.10.2021.
//

import Foundation

extension String {
    mutating func add(text: String?, separatedBy separator: String = "") {
        if let text = text {
            if !isEmpty {
                self += separator
            }
            self += text
        }
    }
}
