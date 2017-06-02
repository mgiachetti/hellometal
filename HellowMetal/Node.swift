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

class Node {
    let name: String
    let vertexCount: Int
    var vertexData: Array<Float>
    let dataSize: Int
    
    init(name: String, vertices: Array<Vertex>) {
        self.vertexData = Array<Float>()
        for vertex in vertices {
            self.vertexData += vertex.floatBuffer()
        }
        
        self.dataSize = self.vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        
        self.name = name
        vertexCount = vertices.count
    }
    
    func render(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setVertexBytes(self.vertexData, length: dataSize, at: 0)

        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount / 3)
        
    }
}
