//
//  Color.swift
//  GrainChainTest
//
//  Created by Jorge Chavez on 06/10/21.
//

import Foundation
import UIKit

extension UIColor {
  /// - Parameter hexString: A 6 or 8 hexadecimal string.
  convenience init(hex hexString: String) {
    let r, g, b, a: CGFloat
    let offset = hexString.hasPrefix("#") ? 1 : 0
    let start = hexString.index(hexString.startIndex, offsetBy: offset)
    var hexColor = String(hexString[start...])
    hexColor = hexColor.count == 6 ? hexColor.appending("FF") : hexColor
    let scanner = Scanner(string: hexColor)
    var rgba: UInt32 = 0
    if scanner.scanHexInt32(&rgba) {
      r = CGFloat((rgba & 0xFF000000) >> 24) / 255
      g = CGFloat((rgba & 0x00FF0000) >> 16) / 255
      b = CGFloat((rgba & 0x0000FF00) >> 8)  / 255
      a = CGFloat(rgba & 0x000000FF) / 255
      self.init(red: r, green: g, blue: b, alpha: a)
      return
    }
    self.init(red: 0, green: 0, blue: 0, alpha: 0)
  }
}
