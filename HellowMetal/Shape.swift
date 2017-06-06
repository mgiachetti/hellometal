//
//  Triangle.swift
//  HellowMetal
//
//  Created by Martin Giachetti on 5/26/17.
//  Copyright © 2017 Tactivos. All rights reserved.
//

import Foundation
import Metal
import MetalKit

enum ShapeType:String {
    case square = "Square"
    case circle = "Circle"
}

func square(x: Float, y: Float, width: Float, height: Float) -> [float2] {
    let v0 = float2(x: x, y: y)
    let v1 = float2(x: x, y: y + height)
    let v2 = float2(x: x + width, y: y + height)
    let v3 = float2(x: x + width, y: y)
    return [v0, v1, v3, v1, v2, v3];
}

func circle(x: Float, y: Float, width: Float, height: Float) -> [float2] {
    let rx = width / 2;
    let ry = height / 2;
    let center = float2(x: x + rx, y: y + ry)
    let slices = 36
    
    let step = 2 * Float.pi / Float(slices)
    var positions = Array<float2>()
    
    for i in 0..<slices {
        let ang = step * Float(i)
        positions.append(float2(x: center.x + cos(ang) * rx, y: center.y + sin(ang) * ry))
    }
    
    var vertices = Array<float2>()
    
    for i in 0..<slices {
        vertices.append(center)
        vertices.append(positions[i])
        vertices.append(positions[(i + 1) % positions.count])
    }
    
    return vertices
}

class Shape: Node {
    init(type: ShapeType, x: Float, y: Float, width: Float, height: Float, color: Color, rotation: Float) {
        
        
        let positions = type == .square ?
            square(x: x, y: y, width: width, height: height) :
            circle(x: x, y: y, width: width, height: height)
        
        // rotate and convert to Vertex
        let c = cos(rotation * Float.pi / 180.0)
        let s = sin(rotation * Float.pi / 180.0)
        let vertices = positions.map { (pos) -> Vertex in
            return Vertex(x: pos.x, y: pos.y, z: 0.0, color: color, u: 0.0, v: 0.0)
        }.map({ (vertex) -> Vertex in
            let dx = (vertex.x - x)
            let dy = (vertex.y - y)
            var v = vertex
            v.x = x + c*dx - s*dy
            v.y = y + s*dx + c*dy
            return v
        })
        
        super.init(name: "Shape", vertices: vertices)
    }
}
