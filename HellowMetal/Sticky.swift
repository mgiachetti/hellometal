//
//  Triangle.swift
//  HellowMetal
//
//  Created by Martin Giachetti on 5/26/17.
//  Copyright © 2017 Tactivos. All rights reserved.
//

import Foundation
import Metal

class Sticky: Node {
    init(text: String, x: Float, y: Float, width: Float, height: Float, r: Float, g: Float, b: Float, a: Float) {
        let V0 = Vertex(x: x        , y: y         , z: 0.0, r: r, g: g, b: b, a: a, u: 0.0, v: 0.0)
        let V1 = Vertex(x: x        , y: y + height, z: 0.0, r: r, g: g, b: b, a: a, u: 0.0, v: 0.0)
        let V2 = Vertex(x: x + width, y: y + height, z: 0.0, r: r, g: g, b: b, a: a, u: 0.0, v: 0.0)
        let V3 = Vertex(x: x + width, y: y         , z: 0.0, r: r, g: g, b: b, a: a, u: 0.0, v: 0.0)
        let vertices = [V0, V1, V3, V1, V2, V3]
        super.init(name: "Sticky", vertices: vertices)
    }
}
