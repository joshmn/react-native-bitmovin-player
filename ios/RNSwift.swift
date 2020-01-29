//
//  RNSwift.swift
//  RNBitmovinPlayer
//
//  Created by HugoDuarte on 29/01/20.
//  Copyright © 2020 Facebook. All rights reserved.
//

import Foundation

@objc(RNSwift)
class RNSwift: NSObject {
  private var count = 0
    
  @objc
  func increment() {
    count += 1
    print("count is \(count)")
  }
}
