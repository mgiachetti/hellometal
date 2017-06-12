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
    
    init(x: Float, y: Float, width: Float, height: Float) {
        let V0 = Vertex(x: x        , y: y         , z: 0.0, color: .WHITE, u: 0.0, v: 0.0)
        let V1 = Vertex(x: x        , y: y + height, z: 0.0, color: .WHITE, u: 0.0, v: 1.0)
        let V2 = Vertex(x: x + width, y: y + height, z: 0.0, color: .WHITE, u: 1.0, v: 1.0)
        let V3 = Vertex(x: x + width, y: y         , z: 0.0, color: .WHITE, u: 1.0, v: 0.0)
        let vertices = [V0, V1, V3, V1, V2, V3]
        
        super.init(name: "Image", vertices: vertices)
    }
    
    convenience init(device: MTLDevice, url: String, x: Float, y: Float, width: Float, height: Float) {
        self.init(x: x, y: y, width: width, height: height)
        
        let uri = URL(string: url)
        if uri != nil {
            let textureLoader = MTKTextureLoader(device: device)
            URLSession.shared.dataTask(with: uri!) { (data, _, _) in
                if data != nil {
                    DispatchQueue.main.async(execute: { () -> Void in
                        let options = [MTKTextureLoaderOptionGenerateMipmaps: true] as [String : NSObject]
                        
                        self.texture = try? textureLoader.newTexture(with: data!, options: options )
//                        if self.texture != nil {
//                            print(self.texture.mipmapLevelCount)
//                        }
                    })
                }
            }.resume()
        }
    }
    
    convenience init(texture: MTLTexture, x: Float, y: Float, width: Float, height: Float) {
        self.init(x: x, y: y, width: width, height: height)
        self.texture = texture
    }

    override func render(renderEncoder: MTLRenderCommandEncoder) {
        
        if self.texture == nil {
            return
        }
        
        renderEncoder.setRenderPipelineState(MetalInstance.texturePipelineState!)
        
        renderEncoder.setFragmentTexture(texture, at: 0)
        
        renderEncoder.setVertexBytes(self.vertexData, length: dataSize, at: 0)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: 1)
        
    }
}
