//
//  Color.swift
//  HellowMetal
//
//  Created by Martin Giachetti on 6/4/17.
//  Copyright © 2017 Tactivos. All rights reserved.
//

import Foundation

struct Color {
    var r: Float
    var g: Float
    var b: Float
    var a: Float
}

let HEXRegex = try! NSRegularExpression(pattern: "^#[0-9a-f]{6}$", options: [.caseInsensitive])
let RGBRegex = try! NSRegularExpression(pattern: "^rgb", options: [.caseInsensitive])
func match(string: String, regex: NSRegularExpression) -> Bool {
    return regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.characters.count)).count > 0
}

extension Color {
    init(string: String) {
        if match(string: string, regex: HEXRegex) {
            var color: UInt32 = 0;
            Scanner(string: string.substring(from: string.index(string.startIndex, offsetBy: 1))).scanHexInt32(&color)
            self.r = Float((color >> 16) & 0xFF) / 255.0
            self.g = Float((color >> 8) & 0xFF) / 255.0
            self.b = Float(color & 0xFF) / 255.0
            self.a = 1.0
        } else if match(string: string, regex: RGBRegex) {
            var array = string.components(separatedBy: CharacterSet(charactersIn: "(,)"))
            self.r = Float(array[1])!/255.0
            self.g = Float(array[2])!/255.0
            self.b = Float(array[3])!/255.0
            self.a = array.count == 6 ? Float(array[4])! : 1.0
        } else {
            print(string)
            self.r = 0.0
            self.g = 0.0
            self.b = 0.0
            self.a = 1.0
        }
    }
}

extension Color {
    static let BLACK       = Color(r: 0.0, g: 0.0, b: 0.0, a: 1.0)
    static let BLUE        = Color(r: 0.0, g: 0.0, b: 1.0, a: 1.0)
    static let GREEN       = Color(r: 0.0, g: 1.0, b: 0.0, a: 1.0)
    static let RED         = Color(r: 1.0, g: 0.0, b: 0.0, a: 1.0)
    static let TRANSPARENT = Color(r: 0.0, g: 0.0, b: 0.0, a: 0.0)
    static let WHITE       = Color(r: 1.0, g: 1.0, b: 1.0, a: 1.0)
}
