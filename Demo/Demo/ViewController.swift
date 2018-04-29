//
//  ViewController.swift
//  Demo
//
//  Created by Andrea Mazzini on 05/03/16.
//  Modified by Sev Gerk 04/29/2018
//  Copyright © 2016 Fancy Pixel. All rights reserved.
//

import UIKit
import SubtleVolume

class ViewController: UIViewController {
  
  let volume = SubtleVolume(style: .roundedLine)
  let volumeHeight: CGFloat = 3
  
  var safeAreaInsets: UIEdgeInsets {
    if #available(iOS 11.0, tvOS 11.0, *) {
      return view.safeAreaInsets
    } else {
      return UIEdgeInsets.zero
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    volume.barTintColor = .white
    volume.barBackgroundColor = UIColor.white.withAlphaComponent(0.3)
    volume.animation = .slideDown
    view.addSubview(volume)
    
    NotificationCenter.default.addObserver(volume, selector: #selector(SubtleVolume.resume), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
  }
  
  override func viewDidLayoutSubviews() {
    layoutVolume()
  }
  
  func layoutVolume() {
    let volumeYPadding: CGFloat = 10
    let volumeXPadding = UIScreen.main.bounds.width * 0.4 / 2
    volume.superview?.bringSubview(toFront: volume)
    volume.frame = CGRect(x: safeAreaInsets.left + volumeXPadding, y: safeAreaInsets.top + volumeYPadding, width: UIScreen.main.bounds.width - (volumeXPadding * 2) - safeAreaInsets.left - safeAreaInsets.right, height: volumeHeight)
  }
  
  @IBAction func minusAction() {
    do {
      try volume.decreaseVolume(animated: true)
    } catch {
      print("The demo must run on a real device, not the simulator")
    }
  }
  
  @IBAction func plusAction() {
    do {
      try volume.setVolumeLevel(volume.volumeLevel + 0.15, animated: true)
    } catch {
      print("The demo must run on a real device, not the simulator")
    }
  }
  
}
