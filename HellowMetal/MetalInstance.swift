//
//  MetalInstance.swift
//  HellowMetal
//
//  Created by Martin Giachetti on 6/9/17.
//  Copyright © 2017 Tactivos. All rights reserved.
//

import Foundation
import Metal

class MetalInstance {
    static var device: MTLDevice? = nil
    static var colorPipelineState: MTLRenderPipelineState? = nil
    static var texturePipelineState: MTLRenderPipelineState? = nil
}
