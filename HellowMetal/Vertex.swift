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
    var color: Color
    var u, v: Float
    
    func floatBuffer() -> [Float] {
        return [x,y,z,color.r,color.g,color.b,color.a,u,v]
    }
}
