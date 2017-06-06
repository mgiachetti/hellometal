//
//  MuralLoader.swift
//  HellowMetal
//
//  Created by Martin Giachetti on 6/4/17.
//  Copyright © 2017 Tactivos. All rights reserved.
//

import Metal
import Foundation

enum WidgetType: String {
    case arrow = "murally.widget.arrow"
    case cluster = "murally.widget.ClusterWidget"
    case draw = "murally.widget.DrawWidget"
    case file = "murally.widget.FileWidget"
    case photo = "murally.widget.PhotoWidget"
    case shape = "murally.widget.ShapeWidget"
    case sticker = "murally.widget.StickerWidget"
    case text = "murally.widget.TextWidget"
    case thread = "murally.widget.ThreadWidget"
}

func getImage(url: String, token: String) -> String {
    if url.characters.first != "/" {
        if url.range(of:"https//api.mural.ly") != nil{
            return "\(url)?jwt=\(token)"
        }
        return url;
    }
    return "https://api.mural.ly\(url)?jwt=\(token)"
}

struct Point {
    var x: Float
    var y: Float
}

func getOffset(widgets: inout [String: [String: Any]], id: String?) -> Point {
    if id == nil {
        return Point(x: 0.0, y: 0.0)
    }
    let parent = widgets[id!]!
    return Point(x: parent["x"] as! Float, y: parent["y"] as! Float)
}

struct Mural {
    var background: Color
    var widgets: [Node]
}

func getStackingOrder(widgets: inout [String: [String: Any]], id: String) -> Int {
    let widget = widgets[id]!
    let properties = widget["properties"] as! [String: Any]
    let parentId = properties["parentId"] as? String ?? nil
    let stackingOrder = widget["stackingOrder"] as! Int
    
    return parentId == nil || parentId!.isEmpty ? stackingOrder * 1000000 : getStackingOrder(widgets: &widgets, id: parentId!) + stackingOrder
}

class MuralLoader {
    
    static func loadJson(url: URL) -> [String: Any] {
        let data = try! Data(contentsOf: url)
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        return json as! [String: Any]
    }
    
    static func load(device: MTLDevice, url: String, with token: String) -> Mural {
        let json = loadJson(url: URL(string: "\(url)?jwt=\(token)")!)
        var widgetsData = json["widgets"] as! [String: [String: Any]]

        var widgets = Array<Node>();
        
        let values = widgetsData.values.sorted(by: { getStackingOrder(widgets: &widgetsData, id:$0["id"] as! String) < getStackingOrder(widgets: &widgetsData, id: $1["id"] as! String) })
        
        for widget in values {
            let type = WidgetType(rawValue: widget["type"] as! String)!
            let properties = widget["properties"] as! [String: Any]
            let offset = getOffset(widgets: &widgetsData, id: properties["parentId"] as? String)
            switch type {
            case .text:
                widgets.append(Sticky(
                    text: properties["text"] as! String,
                    x: widget["x"] as! Float + offset.x,
                    y: widget["y"] as! Float + offset.y,
                    width: widget["width"] as! Float!,
                    height: widget["height"] as! Float,
                    color: Color(string: properties["backgroundColor"] as! String)
                ))
            case .photo:
                let url = (properties["photoURL"] ?? properties["thumbURL"]) as? String
                if url == nil || url!.isEmpty {
                    continue
                }
                widgets.append(Image(
                    device: device,
                    url: getImage(url: url!, token: token),
                    x: widget["x"] as! Float + offset.x,
                    y: widget["y"] as! Float + offset.y,
                    width: widget["width"] as! Float,
                    height: widget["height"] as! Float
                ))
            case .shape:
                widgets.append(Shape(
                    type: ShapeType(rawValue: properties["shapeType"] as! String)!,
                    x: widget["x"] as! Float + offset.x,
                    y: widget["y"] as! Float + offset.y,
                    width: widget["width"] as! Float,
                    height: widget["height"] as! Float,
                    color: Color(string: (properties["background"] as? String) ?? "rgba(0,0,0,0)"),
                    rotation: (widget["rotation"] as? Float) ?? Float(0.0)
                ))
            default: break
            }
        }
        
        return Mural(background: Color(string: json["background"] as! String), widgets: widgets)
    }
}
