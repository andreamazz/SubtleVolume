//
//  SubtleVolume.swift
//  SubtleVolume
//
//  Created by Andrea Mazzini on 05/03/16.
//  Copyright © 2016 Fancy Pixel. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

/**
 The style of the volume indicator

 - plain: A plain bar
 - rounded: A plain bar with rounded corners
 */
@objc public enum SubtleVolumeStyle: Int {
  case plain
  case rounded
}

/**
 The entry and exit animation of the volume indicator

 - None: The indicator is always visible
 - SlideDown: The indicator fades in/out and slides from/to the top into position
 - FadeIn: The indicator fades in and out
 */
@objc public enum SubtleVolumeAnimation: Int {
  case none
  case slideDown
  case fadeIn
}

/**
 Errors being thrown by `SubtleError`.

 - unableToChangeVolumeLevel: `SubtleVolume` was unable to change audio level
 */
public enum SubtleVolumeError: Error {
  case unableToChangeVolumeLevel
}

/**
 Delegate protocol fo `SubtleVolume`. 
 Notifies the delegate when a change is about to happen (before the entry animation)
 and when a change occurred (and the exit animation is complete)
 */
@objc public protocol SubtleVolumeDelegate {
  /**
   The volume is about to change. This is fired before performing any entry animation

   - parameter subtleVolume: The current instance of `SubtleVolume`
   - parameter value: The value of the volume (between 0 an 1.0)
   */
  @objc optional func subtleVolume(_ subtleVolume: SubtleVolume, willChange value: Double)

  /**
   The volume did change. This is fired after the exit animation is done

   - parameter subtleVolume: The current instance of `SubtleVolume`
   - parameter value: The value of the volume (between 0 an 1.0)
   */
  @objc optional func subtleVolume(_ subtleVolume: SubtleVolume, didChange value: Double)

  /**
   The volume did change. This is fired after the exit animation is done

   - parameter subtleVolume: The current instance of `SubtleVolume`
   - parameter value: The value of the volume (between 0 an 1.0)
   - returns: An optional UIImage displayed near the bar
   */
  @objc optional func subtleVolume(_ subtleVolume: SubtleVolume, accessoryFor value: Double) -> UIImage?
}

/**
 Replace the system volume popup with a more subtle way to display the volume
 when the user changes it with the volume rocker.
 */
@objc open class SubtleVolume: UIView {

  /**
   The style of the volume indicator
   */
  open fileprivate(set) var style = SubtleVolumeStyle.plain

  /**
   The entry and exit animation of the indicator. The animation is triggered by the volume
   If the animation is set to `.None`, the volume indicator is always visible
   */
  open var animation = SubtleVolumeAnimation.none {
    didSet {
      updateVolume(volumeLevel, animated: false)
    }
  }
    
  open var displayAnimationDuration: TimeInterval = 0.4
  open var hideAnimationDuration: TimeInterval = 0.4

  open var barBackgroundColor = UIColor.clear {
    didSet {
      container.backgroundColor = barBackgroundColor
    }
  }

  open var barTintColor = UIColor.white {
    didSet {
      overlay.backgroundColor = barTintColor
    }
  }

  open weak var delegate: SubtleVolumeDelegate?

  fileprivate let volume = MPVolumeView(frame: .zero)
  fileprivate let overlay = UIView(frame: .zero)
  fileprivate let container = UIView(frame: .zero)
  fileprivate let accessory = UIImageView(frame: .zero)

  /// Returns the current volume. Read-only
  public fileprivate(set) var volumeLevel = Double(0)

  /// Returns the animation state. Read-only
  public fileprivate(set) var isAnimating = false

  /// Returns the default volume bump when you programmatically change the volume
  public static let DefaultVolumeStep: Double = 0.05

  /// Padding for the inner volume bar
  public var padding: CGSize = .zero

  private var audioSessionOutputVolumeObserver: Any?


  /// Initialize with a style and a frame
  ///
  /// - Parameters:
  ///   - style: the SubtleVolumeStyle
  ///   - frame: the view's frame
  @objc convenience public init(style: SubtleVolumeStyle, frame: CGRect) {
    self.init(frame: frame)
    self.style = style
  }

  /// Initialize with a style and a frame
  ///
  /// - Parameters:
  ///   - style: the SubtleVolumeStyle
  @objc convenience public init(style: SubtleVolumeStyle) {
    self.init(style: style, frame: CGRect.zero)
  }

  @objc required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  @objc required public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required public init() {
    fatalError("Please use the convenience initializers instead")
  }


  /// Increase the volume by a given step
  ///
  /// - Parameter delta: the volume increase. The volume goes from 0 to 1, delta must be a Double in that range
  /// - Throws: `SubtleVolumeError.unableToChangeVolumeLevel`
  @objc public func increaseVolume(by step: Double = DefaultVolumeStep, animated: Bool = false) throws {
    try setVolumeLevel(volumeLevel + step, animated: animated)
  }

  /// Increase the volume by a given step
  ///
  /// - Parameter delta: the volume increase. The volume goes from 0 to 1, delta must be a Double in that range
  /// - Throws: `SubtleVolumeError.unableToChangeVolumeLevel`
  @objc public func decreaseVolume(by step: Double = DefaultVolumeStep, animated: Bool = false) throws {
    try setVolumeLevel(volumeLevel - step, animated: animated)
  }

  /**
   Programatically set the volume level.

   - parameter volumeLevel: The new level of volume (between 0 an 1.0)
   - parameter animated: Indicating whether the change should be animated
   */
  @objc public func setVolumeLevel(_ volumeLevel: Double, animated: Bool = false) throws {
    guard let slider = volume.subviews.compactMap({ $0 as? UISlider }).first else {
      throw SubtleVolumeError.unableToChangeVolumeLevel
    }

    var level = volumeLevel
    if level < 0 {
      level = 0
    }
    if level > 1 {
      level = 1
    }

    let updateVolume = {
      // Trick iOS into thinking that slider value has changed
      slider.value = Float(level)
    }

    // If user opted out of animation, toggle observation for the duration of the change
    if !animated {
      audioSessionOutputVolumeObserver = nil

      updateVolume()

      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) { [weak self] in
        guard let `self` = self else { return }
        self.audioSessionOutputVolumeObserver = AVAudioSession.sharedInstance().observe(\.outputVolume) { [weak self] (audioSession, _) in
          self?.updateVolume(level, animated: true)
        }
      }
    } else {
      updateVolume()
    }
  }

  /// Resume audio session. Call this once the app becomes active after being pushed in background
  @objc public func resume() {
    do {
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("Unable to initialize AVAudioSession")
      return
    }
  }

  fileprivate func setup() {
    resume()
    updateVolume(Double(AVAudioSession.sharedInstance().outputVolume), animated: false)
    self.audioSessionOutputVolumeObserver = AVAudioSession.sharedInstance().observe(\.outputVolume) { [weak self] (audioSession, _) in
      guard let `self` = self else { return }
      self.updateVolume(Double(audioSession.outputVolume), animated: true)
    }

    backgroundColor = .clear
    container.backgroundColor = .clear

    volume.setVolumeThumbImage(UIImage(), for: UIControl.State())
    volume.isUserInteractionEnabled = false
    volume.alpha = 0.0001
    volume.showsRouteButton = false

    addSubview(volume)

    overlay.backgroundColor = .white
    container.addSubview(overlay)

    addSubview(accessory)
    addSubview(container)
  }

  open override func layoutSubviews() {
    super.layoutSubviews()

    switch style {
    case .plain:
      container.layer.cornerRadius = 0
      overlay.layer.cornerRadius = 0
    case .rounded:
      container.layer.cornerRadius = container.frame.height / 2
      overlay.layer.cornerRadius = container.frame.height / 2
    }
  }

  fileprivate func updateVolume(_ value: Double, animated: Bool) {
    delegate?.subtleVolume?(self, willChange: value)
    let previous = volumeLevel
    volumeLevel = value

    let image = delegate?.subtleVolume?(self, accessoryFor: volumeLevel)
    accessory.image = image
    var insets = UIEdgeInsets.zero
    if image != nil {
      insets.left += (frame.height)
      accessory.frame = CGRect(x: 0, y: 0, width: frame.height, height: frame.height)
    }
    insets.left += padding.width
    insets.right += padding.width
    insets.bottom += padding.height
    insets.top += padding.height

    let width = frame.size.width - insets.left - insets.right
    let height = frame.size.height - insets.top - insets.bottom

    overlay.frame = frame
    container.frame = CGRect(x: insets.left, y: insets.top, width: width, height: height)
    overlay.frame = CGRect(x: 0, y: 0, width: container.frame.width * CGFloat(previous), height: height)

    if animated {
      isAnimating = true
    }
    UIView.animate(withDuration: animated ? 0.1 : 0, animations: { () -> Void in
      self.overlay.frame.size.width = self.container.frame.width * CGFloat(self.volumeLevel)
    })

    let totalAnimationTime: TimeInterval = 1.2 + displayAnimationDuration + hideAnimationDuration
    UIView.animateKeyframes(withDuration: animated ? totalAnimationTime : 0, delay: 0, options: .beginFromCurrentState, animations: { () -> Void in
      UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: self.displayAnimationDuration / totalAnimationTime, animations: {
        switch self.animation {
        case .none: break
        case .fadeIn:
          self.alpha = 1
        case .slideDown:
          self.alpha = 1
          self.transform = CGAffineTransform.identity
        }
      })

      UIView.addKeyframe(withRelativeStartTime: 1 - (self.hideAnimationDuration / totalAnimationTime), relativeDuration: (self.hideAnimationDuration / totalAnimationTime), animations: { () -> Void in
        switch self.animation {
        case .none: break
        case .fadeIn:
          self.alpha = 0.0001
        case .slideDown:
          self.alpha = 0.0001
          self.transform = CGAffineTransform(translationX: 0, y: -self.frame.height)
        }
      })

    }) { finished in
      if self.isAnimating {
        self.isAnimating = !finished
      }
      self.delegate?.subtleVolume?(self, didChange: value)
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
