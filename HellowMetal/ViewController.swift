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

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var device: MTLDevice!
    var metalLayer: CAMetalLayer!
    var widgets: Array<Node>!
    var pipelineState: MTLRenderPipelineState!
    var texturePipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var timer: CADisplayLink!
    var scene: MTLBuffer!
    var offsetX: Float = 0.0
    var offsetY: Float = 0.0
    var velX: Float = 0
    var velY: Float = 0
    var scale: Float = 1.0
    var prevScale: Float = 0.0
    var oriScale: Float = 0.0
    
    var image: Image!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // touch events
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(scenePan))
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(scenePinch))

        panGesture.delegate = self
        pinchRecognizer.delegate = self
        self.view.addGestureRecognizer(panGesture)
        self.view.addGestureRecognizer(pinchRecognizer)
        
        
        // initialize touch events
        device = MTLCreateSystemDefaultDevice()
        
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer.frame
        view.layer.addSublayer(metalLayer)
        
        widgets = Array<Node>()
//        widgets.append(Sticky(text: "Texto", x: 100, y: 100, width: 128, height: 128, r: 0.988, g: 0.996, b: 0.49, a: 1))
//        widgets.append(Sticky(text: "Texto", x: 300, y: 500, width: 128, height: 128, r: 0.988, g: 0.996, b: 0.49, a: 1))
        
        var sceneData = Array<Float>()
        for i in 0...100000 {
            let y = Float((4*i) / 1024)
            let x =  Float((4*i) % 1024 + (Int(y) % 2))
            widgets.append(Sticky(text: "Texto", x: x, y: y, width: 1, height: 1, r: 0.988, g: 0.996, b: 0.49, a: 1))
            sceneData += widgets[i].vertexData;
        }
        scene = device.makeBuffer(bytes: &sceneData, length: widgets.count * widgets[0].dataSize, options: [])
        
        
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
        
        texturePipelineState = try! device.makeRenderPipelineState(descriptor: texturePipelineStateDescriptor)
        
        commandQueue = device.makeCommandQueue()
        
        timer = CADisplayLink(target: self, selector: #selector(ViewController.gameloop))
        timer.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
        
        
        image = Image(device: device, url: "https://mural.co/public/assets/images/home/English_get-it-from-MS.png", x: 0.0, y: 800.0, width: 200, height: 200)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>,
                      with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.velX = 0
        self.velY = 0
    }
    
    func scenePan(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self.view)
        offsetX += Float(translation.x) / self.scale;
        offsetY += Float(translation.y) / self.scale;
        
        sender.setTranslation(CGPoint.zero, in: self.view)
        
        if sender.state == .ended {
            let velocity = sender.velocity(in: self.view);
            self.velX = Float(velocity.x) / (self.scale * 60)
            self.velY = Float(velocity.y) / (self.scale * 60)
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
        self.offsetX += x * diff / oriScale
        self.offsetY += y * diff / oriScale
        
        self.prevScale = newScale
        
    }
    
    func render() {
        guard let drawable = metalLayer?.nextDrawable() else { return }
        
        //init frame
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor( red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder.setRenderPipelineState(pipelineState)
        
        let width = Float(view.frame.width)
        let height = Float(view.frame.height)
        let friction = Float(0.5) / self.scale
        
        self.offsetX += velX
        self.offsetY += velY
        
        self.velX = copysign(max(abs(velX) - friction, 0.0), velX)
        self.velY = copysign(max(abs(velY) - friction, 0.0), velY)
        
        let viewMatrix = float4x4.init([
            [    scale,       0, 0, 0],
            [        0,   scale, 0, 0],
            [        0,       0, 1, 0],
            [  offsetX*scale, offsetY*scale, 0, 1]
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
//        for widget in widgets {
//            widget.render(renderEncoder: renderEncoder)
//        }
        
        renderEncoder.setVertexBuffer(scene, offset: 0, at: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: widgets.count * 6)
        
        // render debug triangle
//        var debugData:[Float] = [
//            -offsetX, -offsetY, 0.0, 1.0, 0.0, 0.0, 1.0,
//            -offsetX-10, -offsetY+10, 0.0, 1.0, 0.0, 0.0, 1.0,
//            -offsetX+10, -offsetY+10, 0.0, 1.0, 0.0, 0.0, 1.0,
//        ]
//        let debugSize = debugData.count * MemoryLayout.size(ofValue: debugData[0])
//        renderEncoder.setVertexBytes(&debugData, length: debugSize, at: 0)
//        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        renderEncoder.setRenderPipelineState(texturePipelineState)
        
        for i in 0...1000 {
            let col = Float(i % 10)
            let row = Float(i / 10)
            let translate = float4x4.init([
                [ 1.0, 0.0, 0.0, 0.0],
                [ 0.0, 1.0, 0.0, 0.0],
                [ 0.0, 0.0, 1.0, 0.0],
                [ col * 300.0, row * 300.0, 0.0, 1.0]
            ])
            
            var imgMatrix = matrix * translate;
            renderEncoder.setVertexBytes(&imgMatrix, length: MemoryLayout.size(ofValue: matrix), at: 1)
        
            image.render(renderEncoder: renderEncoder);
        }
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func gameloop() {
        autoreleasepool {
            self.render()
        }
    }
}

