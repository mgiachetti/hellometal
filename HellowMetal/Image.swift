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

class Image: Node {
    var texture: MTLTexture!
    
    init(device: MTLDevice, url: String, x: Float, y: Float, width: Float, height: Float) {
        
        let textureLoader = MTKTextureLoader.init(device: device)
        let uri = URL(string: url)!
        let data = try? Data(contentsOf: uri)
        self.texture = try! textureLoader.newTexture(with: data!)
        let imgWidth = Float(texture.width)
        let imgHeight = Float(texture.height)
        
        let V0 = Vertex(x: x        , y: y         , z: 0.0, r: 0, g: 0, b: 0, a: 0, u: 0.0, v: 0.0)
        let V1 = Vertex(x: x        , y: y + imgHeight, z: 0.0, r: 0, g: 0, b: 0, a: 0, u: 0.0, v: 1.0)
        let V2 = Vertex(x: x + imgWidth, y: y + imgHeight, z: 0.0, r: 0, g: 0, b: 0, a: 0, u: 1.0, v: 1.0)
        let V3 = Vertex(x: x + imgWidth, y: y         , z: 0.0, r: 0, g: 0, b: 0, a: 0, u: 1.0, v: 0.0)
        let vertices = [V0, V1, V3, V1, V2, V3]
        
        super.init(name: "Sticky", vertices: vertices)
    }
    
    override func render(renderEncoder: MTLRenderCommandEncoder) {
        
        renderEncoder.setFragmentTexture(texture, at: 0)
        renderEncoder.setVertexBytes(self.vertexData, length: dataSize, at: 0)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount / 3)
        
    }
}
