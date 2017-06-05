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
        let uri = URL(string: url)
//        let data = try? Data(contentsOf: uri)
//        
//        if data != nil {
//            self.texture = try? textureLoader.newTexture(with: data!)
//        }
        
        
        let V0 = Vertex(x: x        , y: y         , z: 0.0, color: .WHITE, u: 0.0, v: 0.0)
        let V1 = Vertex(x: x        , y: y + height, z: 0.0, color: .WHITE, u: 0.0, v: 1.0)
        let V2 = Vertex(x: x + width, y: y + height, z: 0.0, color: .WHITE, u: 1.0, v: 1.0)
        let V3 = Vertex(x: x + width, y: y         , z: 0.0, color: .WHITE, u: 1.0, v: 0.0)
        let vertices = [V0, V1, V3, V1, V2, V3]
        
        
        super.init(name: "Image", vertices: vertices)
        
        if uri != nil {
            URLSession.shared.dataTask(with: uri!) { (data, _, _) in
                if data != nil {
                    DispatchQueue.main.async(execute: { () -> Void in
                        let options = [MTKTextureLoaderOptionGenerateMipmaps: true]
                        
                        self.texture = try? textureLoader.newTexture(with: data!, options: options as [String : NSObject])
                        if self.texture != nil {
                            print(self.texture.mipmapLevelCount)
                        }
                    })
                }
            }.resume()
        }
    }
    
    override func render(renderEncoder: MTLRenderCommandEncoder) {
        
        if self.texture == nil {
            return
        }
        
        renderEncoder.setFragmentTexture(texture, at: 0)
        
        renderEncoder.setVertexBytes(self.vertexData, length: dataSize, at: 0)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount / 3)
        
    }
}
