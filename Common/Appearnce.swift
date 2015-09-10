//
//  Appearnce.swift
//  PartyPlay
//
//  Created by BAN Jun on 8/15/15.
//  Copyright © 2015 banjun. All rights reserved.
//

#if os(iOS) || os(tvOS)
    import UIKit
    
    private func rgb(r: Int, _ g: Int, _ b: Int) -> UIColor {
        return UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(1))
    }
    
    private func gray(y: Int) -> UIColor {
        return rgb(y, y, y)
    }
    
    private func hsb(h: Int, _ s: Int, _ b: Int) -> UIColor {
        return UIColor(hue: CGFloat(h) / 360, saturation: CGFloat(s) / 100, brightness: CGFloat(b) / 100, alpha: CGFloat(1))
    }
#elseif os(OSX)
    import AppKit
    
    private func rgb(r: Int, _ g: Int, _ b: Int) -> NSColor {
        return NSColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(1))
    }
    
    private func gray(y: Int) -> NSColor {
        return rgb(y, y, y)
    }
    
    private func hsb(h: Int, _ s: Int, _ b: Int) -> NSColor {
        return NSColor(hue: CGFloat(h) / 360, saturation: CGFloat(s) / 100, brightness: CGFloat(b) / 100, alpha: CGFloat(1))
    }
#endif


struct Appearance {
    private static let honokaOrange = hsb(30, 84, 100)
    private static let honokaOrangeBlack = hsb(30, 84, 25)

    static let tintColor = honokaOrange
    static let darkTextColor = honokaOrangeBlack
    static let whiteColor = gray(255)
    static let lightTextColor = whiteColor
    static let backgroundColor = whiteColor

    static let cornderRadius = CGFloat(4)
    
    static func install() {
        #if os(iOS)
            UINavigationBar.appearance().tintColor = darkTextColor
            UINavigationBar.appearance().barTintColor = honokaOrange
            UINavigationBar.appearance().translucent = false
        #elseif os(OSX)
        #endif
    }
    
    #if os(iOS)
    static func createButton() -> UIButton {
        let b = UIButton(type: .System)
        b.setTitleColor(lightTextColor, forState: .Normal)
        b.backgroundColor = tintColor
        b.layer.cornerRadius = cornderRadius
        b.layer.masksToBounds = true
        return b
    }
    #endif
}