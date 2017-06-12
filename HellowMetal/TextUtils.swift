//
//  TextUtils.swift
//  HellowMetal
//
//  Created by Martin Giachetti on 6/7/17.
//  Copyright © 2017 Tactivos. All rights reserved.
//

import UIKit
import Foundation
import Metal
import MetalKit

func getText(string: String) -> String {
    let regex = try! NSRegularExpression(pattern: ">([^<>]+)<", options: [.caseInsensitive])
    
    let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.characters.count))
    
    var val = ""
    let nsStr = string as NSString
    
    for match in matches {
        val += nsStr.substring(with: NSRange(location: match.range.location + 1, length: match.range.length - 2))
    }
    
    return val.characters.count > 0 ? val : string
}

class TextUtils {
    class func imageFrom(text: String, color: Color, width: Int) -> UIImage? {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: min(width, 1000), height: 30))
        label.text = getText(string: text)
        label.textAlignment = .center
        label.font = UIFont(name: "Helvetica", size: 18)
        label.textColor = UIColor.init(red: CGFloat(color.r), green: CGFloat(color.g), blue: CGFloat(color.b), alpha: CGFloat(color.a)) //UIColor.black
        label.numberOfLines = 0 //will wrap text in new line
//        label.sizeToFit()
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0.0)
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        
        let img = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext();
        
        return img
    }
    
    class func textureFrom(device: MTLDevice, text: String, color: Color, width: Int) -> MTLTexture? {
        let image = imageFrom(text: text, color: color, width: width)
//        UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)

        let textureLoader = MTKTextureLoader(device: device)
        let options = [MTKTextureLoaderOptionGenerateMipmaps: true] as [String : NSObject]
        let texture = try? textureLoader.newTexture(with: image!.cgImage!, options: options)
//        let texture = createTexture(device: device, from: image!)
        return texture
    }
    
    class func createTexture(device: MTLDevice, from image: UIImage) -> MTLTexture {
    
        guard let cgImage = image.cgImage else {
            fatalError("Can't open image \(image)")
        }
    
        let textureLoader = MTKTextureLoader(device: device)
        do {
            let textureOut = try textureLoader.newTexture(with: cgImage)
            return textureOut
        }
        catch {
            fatalError("Can't load texture")
        }
    }
}
