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

class Sticky: Node {
    var textImage: Image
    init(device: MTLDevice, text: String, x: Float, y: Float, width: Float, height: Float, color: Color) {
        let V0 = Vertex(x: x        , y: y         , z: 0.0, color: color, u: 0.0, v: 0.0)
        let V1 = Vertex(x: x        , y: y + height, z: 0.0, color: color, u: 0.0, v: 0.0)
        let V2 = Vertex(x: x + width, y: y + height, z: 0.0, color: color, u: 0.0, v: 0.0)
        let V3 = Vertex(x: x + width, y: y         , z: 0.0, color: color, u: 0.0, v: 0.0)
        let vertices = [V0, V1, V3, V1, V2, V3]
        
        let fontColor = color.grayScale() < 0.5 ? Color.WHITE : Color.BLACK
        let texture = TextUtils.textureFrom(device: device, text: text, color: fontColor, width: Int(width))!
        let textWidth = width
        let textHeight = Float(30)
        let textX = (width - textWidth) / 2 + x;
        let textY = (height - textHeight) / 2 + y;
        
        textImage = Image(texture: texture, x: textX, y: textY, width: textWidth, height: textHeight)
        
        super.init(name: "Sticky", vertices: vertices)
    }
    
    override func render(renderEncoder: MTLRenderCommandEncoder) {
        super.render(renderEncoder: renderEncoder)
        textImage.render(renderEncoder: renderEncoder)
    }
    
    override func move(delta: float2) {
        super.move(delta: delta)
        textImage.move(delta: delta)
    }
}
