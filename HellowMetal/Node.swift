//
//  Node.swift
//  HellowMetal
//
//  Created by Martin Giachetti on 5/26/17.
//  Copyright © 2017 Tactivos. All rights reserved.
//

import Foundation
import Metal
import QuartzCore
import MetalKit

struct Bound {
    var x: Float
    var y: Float
    var width: Float
    var height: Float
    
    init(vertices: [Vertex]) {
        var minX = Float.greatestFiniteMagnitude
        var minY = Float.greatestFiniteMagnitude
        var maxX = Float.leastNormalMagnitude
        var maxY = Float.leastNormalMagnitude
        
        for vertex in vertices {
            minX = Float.minimum(vertex.x, minX)
            minY = Float.minimum(vertex.y, minX)
            maxX = Float.maximum(vertex.x, maxX)
            maxY = Float.maximum(vertex.y, maxY)
        }
        
        self.x = minX
        self.y = minY
        self.width = maxX - minX
        self.height = maxY - minY
    }
    
    func isInside(x: Float, y: Float) -> Bool {
        return (
            x >= self.x && x <= (self.x + self.width) &&
            y >= self.y && y <= (self.y + self.height)
        )
    }
}

class Node {
    let name: String
    let vertexCount: Int
    var vertexData: Array<Float>
    let dataSize: Int
    var bound: Bound
    
    init(name: String, vertices: Array<Vertex>) {
        self.vertexData = Array<Float>()
        
        for vertex in vertices {
            self.vertexData += vertex.floatBuffer()
        }
        
        self.bound = Bound(vertices: vertices)
        
        self.dataSize = self.vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        
        self.name = name
        vertexCount = vertices.count
    }
    
    func render(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setVertexBytes(self.vertexData, length: dataSize, at: 0)

        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount / 3)
        
    }
    
    func move(delta: float2) {
        let vertexSize = vertexData.count / vertexCount
        for i in 0..<vertexCount {
            vertexData[i * vertexSize + 0] += delta.x
            vertexData[i * vertexSize + 1] += delta.y
        }
        bound.x += delta.x
        bound.y += delta.y
    }
}
