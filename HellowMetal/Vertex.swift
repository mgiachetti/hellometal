//
//  Vertex.swift
//  HellowMetal
//
//  Created by Martin Giachetti on 5/26/17.
//  Copyright © 2017 Tactivos. All rights reserved.
//

import Foundation

struct Vertex {
    var x, y, z: Float
    var r, g, b, a: Float
    var u, v: Float
    
    func floatBuffer() -> [Float] {
        return [x,y,z,r,g,b,a,u,v]
    }
}
