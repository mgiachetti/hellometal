//
//  ViewController.swift
//  HellowMetal
//
//  Created by Martin Giachetti on 5/25/17.
//  Copyright © 2017 Tactivos. All rights reserved.
//

import UIKit
import Metal
import simd
import MetalKit

extension float2 {
    init(_ point: CGPoint) {
        self.init(x: Float(point.x), y: Float(point.y))
    }
}

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var device: MTLDevice!
    var metalLayer: CAMetalLayer!
    var widgets: Array<Node>!
    var pipelineState: MTLRenderPipelineState!
    var texturePipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var timer: CADisplayLink!
    var scene: MTLBuffer!
    var offset: float2!
    var vel: float2!
    var scale: Float = 1.0
    var prevScale: Float = 0.0
    var oriScale: Float = 0.0
    var draggingNode: Node? = nil
    var prevDragPos: float2!
    var clearColor: MTLClearColor!
    
    var panRecognizer: UIPanGestureRecognizer!
    var pinchRecognizer: UIPinchGestureRecognizer!
    var longPressRecognizer: UILongPressGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // touch events
        self.panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(scenePan))
        self.pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(scenePinch))
        self.longPressRecognizer  = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        longPressRecognizer.minimumPressDuration = 0.1;

        panRecognizer.delegate = self
        pinchRecognizer.delegate = self
        self.view.addGestureRecognizer(panRecognizer)
        self.view.addGestureRecognizer(pinchRecognizer)
        self.view.addGestureRecognizer(longPressRecognizer)
        
        
        // initialize touch events
        device = MTLCreateSystemDefaultDevice()
        
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer.frame
        view.layer.addSublayer(metalLayer)
        
        let mural = MuralLoader.load(device: device, url: "https://api.mural.ly/api/murals/murally-org/1495051098202", with: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6Im1hcnRpbjc0MDYiLCJzb3VyY2UiOiJpbnRlcm5hbC1zc28iLCJpYXQiOjE0OTY3NTM3MDAsImV4cCI6MTQ5Njc3NTMwMH0.yseU3U4CTYhBY59e9ZoeqA_0BRFbgNNhPm-KjxdcPhU")
        widgets = mural.widgets
        clearColor = MTLClearColor(red: Double(mural.background.r), green: Double(mural.background.g), blue: Double(mural.background.b), alpha: Double(mural.background.a))
        
//        widgets = Array<Node>()
//        widgets.append(Sticky(text: "Texto", x: 100, y: 100, width: 128, height: 128, r: 0.988, g: 0.996, b: 0.49, a: 1))
//        widgets.append(Sticky(text: "Texto", x: 300, y: 500, width: 128, height: 128, r: 0.988, g: 0.996, b: 0.49, a: 1))
        
//        var sceneData = Array<Float>()
//        for i in 0...100000 {
//            let y = Float((4*i) / 1024)
//            let x =  Float((4*i) % 1024 + (Int(y) % 2))
//            widgets.append(Sticky(text: "Texto", x: x, y: y, width: 1, height: 1, r: 0.988, g: 0.996, b: 0.49, a: 1))
//            sceneData += widgets[i].vertexData;
//        }
//        scene = device.makeBuffer(bytes: &sceneData, length: widgets.count * widgets[0].dataSize, options: [])
        
        
        let defaultLibrary = device.newDefaultLibrary()!
        let colorFragmentProgram = defaultLibrary.makeFunction(name: "color_fragment")
        let textureFragmentProgram = defaultLibrary.makeFunction(name: "texture_fragment")
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
        
        let colorPipelineStateDescriptor = MTLRenderPipelineDescriptor()
        colorPipelineStateDescriptor.vertexFunction = vertexProgram
        colorPipelineStateDescriptor.fragmentFunction = colorFragmentProgram
        colorPipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: colorPipelineStateDescriptor)
        
        let texturePipelineStateDescriptor = MTLRenderPipelineDescriptor()
        texturePipelineStateDescriptor.vertexFunction = vertexProgram
        texturePipelineStateDescriptor.fragmentFunction = textureFragmentProgram
        texturePipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        texturePipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        texturePipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add;
        texturePipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add;
        texturePipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one;
        texturePipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one;
        texturePipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha;
        texturePipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha;
        
        
        texturePipelineState = try! device.makeRenderPipelineState(descriptor: texturePipelineStateDescriptor)
        
        commandQueue = device.makeCommandQueue()
        
        timer = CADisplayLink(target: self, selector: #selector(ViewController.gameloop))
        timer.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
        
        vel = float2(x: 0, y: 0)
        offset = float2(x: 0, y: 0)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func render() {
        guard let drawable = metalLayer?.nextDrawable() else { return }
        
        //init frame
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder.setRenderPipelineState(pipelineState)
        
        let width = Float(view.frame.width)
        let height = Float(view.frame.height)
        let friction = Float(0.5) / self.scale
        
        self.offset.x += vel.x
        self.offset.y += vel.y
        
        if length(vel) > friction {
            let dir = normalize(vel)
            self.vel = vel - dir * friction
        } else {
            self.vel.x = 0.0
            self.vel.y = 0.0
        }
        
        
        let viewMatrix = float4x4.init([
            [    scale,       0, 0, 0],
            [        0,   scale, 0, 0],
            [        0,       0, 1, 0],
            [  offset.x*scale, offset.y*scale, 0, 1]
        ])
        let projMatrix = float4x4.init([
            [ 2/width,         0, 0, 0],
            [       0, -2/height, 0, 0],
            [       0,         0, 1, 0],
            [      -1,         1, 0, 1]
        ])
        
        var matrix = projMatrix * viewMatrix;
        renderEncoder.setVertexBytes(&matrix, length: MemoryLayout.size(ofValue: matrix), at: 1)
        
        // draw objects
        for widget in widgets {
            if widget as? Image != nil {
                renderEncoder.setRenderPipelineState(texturePipelineState)
                widget.render(renderEncoder: renderEncoder)
            } else {
                renderEncoder.setRenderPipelineState(pipelineState)
                widget.render(renderEncoder: renderEncoder)
            }
            
        }
        
        // render n times more
//        let muralWidth:Float =  35000
//        let muralHeight:Float =  18000
//        let n = 4
//        
//        for i in 1..<n {
//            let col = Float(i % Int(sqrt(Double(n))))
//            let row = Float(i / Int(sqrt(Double(n))))
//            let translate = float4x4.init([
//                [ 1.0, 0.0, 0.0, 0.0],
//                [ 0.0, 1.0, 0.0, 0.0],
//                [ 0.0, 0.0, 1.0, 0.0],
//                [ col * muralWidth, row * muralHeight, 0.0, 1.0]
//            ])
//        
//            var imgMatrix = matrix * translate;
//            renderEncoder.setVertexBytes(&imgMatrix, length: MemoryLayout.size(ofValue: matrix), at: 1)
//            for widget in widgets {
//                if widget as? Image != nil {
//                    renderEncoder.setRenderPipelineState(texturePipelineState)
//                    widget.render(renderEncoder: renderEncoder)
//                } else {
//                    renderEncoder.setRenderPipelineState(pipelineState)
//                    widget.render(renderEncoder: renderEncoder)
//                }
//                
//            }
//        }
        
        
//        renderEncoder.setVertexBuffer(scene, offset: 0, at: 0)
//        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: widgets.count * 6)
        
        // render debug triangle
//        var debugData:[Float] = [
//            -offsetX, -offsetY, 0.0, 1.0, 0.0, 0.0, 1.0,
//            -offsetX-10, -offsetY+10, 0.0, 1.0, 0.0, 0.0, 1.0,
//            -offsetX+10, -offsetY+10, 0.0, 1.0, 0.0, 0.0, 1.0,
//        ]
//        let debugSize = debugData.count * MemoryLayout.size(ofValue: debugData[0])
//        renderEncoder.setVertexBytes(&debugData, length: debugSize, at: 0)
//        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        
        
//        for i in 0...1000 {
//            let col = Float(i % 10)
//            let row = Float(i / 10)
//            let translate = float4x4.init([
//                [ 1.0, 0.0, 0.0, 0.0],
//                [ 0.0, 1.0, 0.0, 0.0],
//                [ 0.0, 0.0, 1.0, 0.0],
//                [ col * 300.0, row * 300.0, 0.0, 1.0]
//            ])
//            
//            var imgMatrix = matrix * translate;
//            renderEncoder.setVertexBytes(&imgMatrix, length: MemoryLayout.size(ofValue: matrix), at: 1)
//        
//            image.render(renderEncoder: renderEncoder);
//        }
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func gameloop() {
        autoreleasepool {
            self.render()
        }
    }
    
    // touch events
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.vel.x = 0
        self.vel.y = 0
    }
    
    func inverseTransform(position: float2) -> float2 {
        return float2(x: position.x / scale - offset.x, y: position.y / scale - offset.y)
    }
    
    func inverseTransform(magnitud: float2) -> float2 {
        return float2(x: magnitud.x / scale, y: magnitud.y / scale)
    }
    
    func transform(position: float2) -> float2 {
        return float2(x: (position.x + offset.x) * scale, y: (position.y + offset.y) * scale)
    }
    
    func getNode(position screen: float2) -> Node? {
        let pos = inverseTransform(position: screen)
        for widget in self.widgets {
            if widget.bound.isInside(x: pos.x, y: pos.y) {
                return widget
            }
        }
        return nil;
    }
    
    func longPress(sender: UILongPressGestureRecognizer) {
        let position = float2(sender.location(in: self.view))
        if (sender.state == .began) {
            let node = getNode(position: position)
            self.draggingNode = node
            if node == nil {
                longPressRecognizer.isEnabled = false
                longPressRecognizer.isEnabled = true
                return;
            } else {
                panRecognizer.isEnabled = false
                pinchRecognizer.isEnabled = false
                panRecognizer.isEnabled = true
                pinchRecognizer.isEnabled = true
            }
            self.prevDragPos = position
        }
        
        if self.draggingNode == nil {
            return;
        }
        
        let delta = inverseTransform(magnitud: position - self.prevDragPos)
        self.draggingNode!.move(delta: delta)
        self.prevDragPos = position
    }
    
    func scenePan(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self.view)
        offset.x += Float(translation.x) / self.scale;
        offset.y += Float(translation.y) / self.scale;
        
        sender.setTranslation(CGPoint.zero, in: self.view)
        
        if sender.state == .ended {
            let velocity = sender.velocity(in: self.view);
            self.vel.x = Float(velocity.x) / (self.scale * 60)
            self.vel.y = Float(velocity.y) / (self.scale * 60)
        }
    }
    
    func scenePinch(sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            self.oriScale = Float(self.scale)
            self.prevScale = 1.0
            
        }
        let newScale = Float(sender.scale)
        self.scale = self.oriScale * Float(sender.scale)
        
        
        let location = sender.location(in: self.view)
        let x = Float(location.x)
        let y = Float(location.y)
        let diff = (1/newScale) - (1/prevScale)
        self.offset.x += x * diff / oriScale
        self.offset.y += y * diff / oriScale
        
        self.prevScale = newScale
        
    }
}

