//
//  Appearnce.swift
//  PartyPlay
//
//  Created by BAN Jun on 8/15/15.
//  Copyright © 2015 banjun. All rights reserved.
//

import UIKit


private func hsb(h: Int, _ s: Int, _ b: Int) -> UIColor {
    return UIColor(hue: CGFloat(h) / 360, saturation: CGFloat(s) / 100, brightness: CGFloat(b) / 100, alpha: CGFloat(1))
}


struct Appearance {
    private static let honokaOrange = hsb(30, 84, 100)
    private static let honokaOrangeBlack = hsb(30, 84, 25)

    static let tintColor = honokaOrange
    static let darkTextColor = honokaOrangeBlack
    static let lightTextColor = UIColor.whiteColor()
    static let backgroundColor = UIColor.whiteColor()
    
    static func install() {
        UINavigationBar.appearance().tintColor = darkTextColor
        UINavigationBar.appearance().barTintColor = honokaOrange
    }
}