//
// Copyright (c) 2021 Muukii <muukii.app@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import PixelEngine

extension CropView {
  final class _InteractiveCropGuideView: PixelEditorCodeBasedView, UIGestureRecognizerDelegate {
    var willChange: () -> Void = {}
    var didChange: () -> Void = {}

    private let topLeftControlPointView = UIView()
    private let topRightControlPointView = UIView()
    private let bottomLeftControlPointView = UIView()
    private let bottomRightControlPointView = UIView()

    private let topControlPointView = UIView()
    private let rightControlPointView = UIView()
    private let leftControlPointView = UIView()
    private let bottomControlPointView = UIView()

    private weak var cropInsideOverlay: CropInsideOverlayBase?
    private weak var cropOutsideOverlay: CropOutsideOverlayBase?

    private unowned let containerView: CropView
    private unowned let imageView: UIView

    private lazy var invertedMaskShapeLayerView = MaskView()

    private var maximumRect: CGRect?

    private(set) var lockedAspectRatio: PixelAspectRatio?

    private let minimumSize = CGSize(width: 120, height: 120)
    
    private let insetOfGuideFlexibility: UIEdgeInsets

    init(
      containerView: CropView,
      imageView: UIView,
      insetOfGuideFlexibility: UIEdgeInsets
    ) {
      self.containerView = containerView
      self.imageView = imageView
      self.insetOfGuideFlexibility = insetOfGuideFlexibility

      super.init(frame: .zero)

      [
        topLeftControlPointView,
        topRightControlPointView,
        bottomLeftControlPointView,
        bottomRightControlPointView,

        topControlPointView,
        rightControlPointView,
        leftControlPointView,
        bottomControlPointView,
      ].forEach { view in
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
      }

      cornerGestures: do {
        do {
          let panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePanGestureInTopLeft(gesture:))
          )
          topLeftControlPointView.addGestureRecognizer(panGesture)
        }

        do {
          let panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePanGestureInTopRight(gesture:))
          )
          topRightControlPointView.addGestureRecognizer(panGesture)
        }

        do {
          let panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePanGestureInBottomLeft(gesture:))
          )
          bottomLeftControlPointView.addGestureRecognizer(panGesture)
        }

        do {
          let panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePanGestureInBottomRight(gesture:))
          )
          bottomRightControlPointView.addGestureRecognizer(panGesture)
        }
      }

      edgeGestures: do {
        do {
          let panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePanGestureInTop(gesture:))
          )
          topControlPointView.addGestureRecognizer(panGesture)
        }

        do {
          let panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePanGestureInRight(gesture:))
          )
          rightControlPointView.addGestureRecognizer(panGesture)
        }

        do {
          let panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePanGestureInLeft(gesture:))
          )
          leftControlPointView.addGestureRecognizer(panGesture)
        }

        do {
          let panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePanGestureInBottom(gesture:))
          )
          bottomControlPointView.addGestureRecognizer(panGesture)
        }
      }

      let length: CGFloat = 30

      topLeftControlPointView&>.do {
        NSLayoutConstraint.activate([
          $0.leftAnchor.constraint(equalTo: leftAnchor),
          $0.topAnchor.constraint(equalTo: topAnchor),
          $0.heightAnchor.constraint(equalToConstant: length),
          $0.widthAnchor.constraint(equalToConstant: length),
        ])
      }

      topRightControlPointView&>.do {
        NSLayoutConstraint.activate([
          $0.rightAnchor.constraint(equalTo: rightAnchor),
          $0.topAnchor.constraint(equalTo: topAnchor),
          $0.heightAnchor.constraint(equalToConstant: length),
          $0.widthAnchor.constraint(equalToConstant: length),
        ])
      }

      bottomLeftControlPointView&>.do {
        NSLayoutConstraint.activate([
          $0.leftAnchor.constraint(equalTo: leftAnchor),
          $0.bottomAnchor.constraint(equalTo: bottomAnchor),
          $0.heightAnchor.constraint(equalToConstant: length),
          $0.widthAnchor.constraint(equalToConstant: length),
        ])
      }

      bottomRightControlPointView&>.do {
        NSLayoutConstraint.activate([
          $0.rightAnchor.constraint(equalTo: rightAnchor),
          $0.bottomAnchor.constraint(equalTo: bottomAnchor),
          $0.heightAnchor.constraint(equalToConstant: length),
          $0.widthAnchor.constraint(equalToConstant: length),
        ])
      }

      topControlPointView&>.do {
        NSLayoutConstraint.activate([
          $0.topAnchor.constraint(equalTo: topAnchor, constant: 0),
          $0.leftAnchor.constraint(equalTo: topLeftControlPointView.rightAnchor),
          $0.rightAnchor.constraint(equalTo: topRightControlPointView.leftAnchor),
          $0.heightAnchor.constraint(equalToConstant: length),
        ])
      }

      rightControlPointView&>.do {
        NSLayoutConstraint.activate([
          $0.topAnchor.constraint(equalTo: topRightControlPointView.bottomAnchor),
          $0.bottomAnchor.constraint(equalTo: bottomRightControlPointView.topAnchor),
          $0.rightAnchor.constraint(equalTo: rightAnchor),
          $0.widthAnchor.constraint(equalToConstant: length),
        ])
      }

      bottomControlPointView&>.do {
        NSLayoutConstraint.activate([
          $0.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
          $0.leftAnchor.constraint(equalTo: bottomLeftControlPointView.rightAnchor),
          $0.rightAnchor.constraint(equalTo: bottomRightControlPointView.leftAnchor),
          $0.heightAnchor.constraint(equalToConstant: length),
        ])
      }

      leftControlPointView&>.do {
        NSLayoutConstraint.activate([
          $0.topAnchor.constraint(equalTo: topLeftControlPointView.bottomAnchor),
          $0.bottomAnchor.constraint(equalTo: bottomLeftControlPointView.topAnchor),
          $0.leftAnchor.constraint(equalTo: leftAnchor),
          $0.widthAnchor.constraint(equalToConstant: length),
        ])
      }
    }

    // MARK: - Functions

    /**
     Displays a view as an overlay.
     e.g. grid view
     */
    func setCropInsideOverlay(_ newOverlay: CropInsideOverlayBase?) {
      cropInsideOverlay?.removeFromSuperview()

      if let overlay = newOverlay {
        overlay.isUserInteractionEnabled = false
        addSubview(overlay)
        cropInsideOverlay = overlay
      }
    }

    func setCropOutsideOverlay(_ view: CropOutsideOverlayBase?) {
      defer {
        setNeedsLayout()
        layoutIfNeeded()
      }
      
      guard let view = view else {
        cropOutsideOverlay = nil
        return
      }
      
      assert(view.superview != nil)
      assert(view.superview is CropView)

      cropOutsideOverlay = view
   
    }

    func setLockedAspectRatio(_ aspectRatio: PixelAspectRatio?) {
      lockedAspectRatio = aspectRatio
    }

    override func layoutSubviews() {
      super.layoutSubviews()

      cropInsideOverlay?.frame = bounds

      if let outOfBoundsOverlayView = cropOutsideOverlay {
        let frame = convert(bounds, to: outOfBoundsOverlayView)

        invertedMaskShapeLayerView.frame = outOfBoundsOverlayView.bounds
        invertedMaskShapeLayerView.setUnmaskRect(frame)

        if outOfBoundsOverlayView.mask == nil {
          outOfBoundsOverlayView.mask = invertedMaskShapeLayerView
        }
      }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
      let view = super.hitTest(point, with: event)

      if view == self {
        return nil
      }

      return view
    }

    func willBeginScrollViewAdjustment() {
      cropInsideOverlay?.didBeginAdjustment(kind: .scrollView)
      cropOutsideOverlay?.didBeginAdjustment(kind: .scrollView)
    }

    func didEndScrollViewAdjustment() {
      cropInsideOverlay?.didEndAdjustment(kind: .scrollView)
      cropOutsideOverlay?.didEndAdjustment(kind: .scrollView)
    }

    @inline(__always)
    private func updateMaximumRect() {
      maximumRect = imageView.convert(imageView.bounds, to: containerView)
        .intersection(containerView.bounds.inset(by: insetOfGuideFlexibility))
    }

    private func onGestureTrackingStarted() {
      translatesAutoresizingMaskIntoConstraints = false

      updateMaximumRect()
      willChange()
      cropInsideOverlay?.didBeginAdjustment(kind: .guide)
      cropOutsideOverlay?.didBeginAdjustment(kind: .guide)
    }

    private func onGestureTrackingEnded() {
      deactivateAllConstraints()
      didChange()
      cropInsideOverlay?.didEndAdjustment(kind: .guide)
      cropOutsideOverlay?.didEndAdjustment(kind: .guide)
    }

    private var widthConstraint: NSLayoutConstraint!
    private var heightConstraint: NSLayoutConstraint!

    private var activeConstraints: [NSLayoutConstraint] = []

    private func activateRightConstraint() {
      translatesAutoresizingMaskIntoConstraints = false

      activeConstraints.append(
        rightAnchor.constraint(
          equalTo: superview!.rightAnchor,
          constant: frame.maxX - superview!.bounds.maxX
        )&>.do {
          $0.isActive = true
        }
      )
    }

    private func activateLeftMaxConstraint() {
      translatesAutoresizingMaskIntoConstraints = false

      activeConstraints.append(
        leftAnchor.constraint(
          greaterThanOrEqualTo: superview!.leftAnchor,
          constant: maximumRect!.minX
        )&>.do {
          $0.isActive = true
        }
      )
    }

    private func activateRightMaxConstraint() {
      translatesAutoresizingMaskIntoConstraints = false

      activeConstraints.append(
        rightAnchor.constraint(
          lessThanOrEqualTo: superview!.rightAnchor,
          constant: maximumRect!.maxX - superview!.bounds.maxX
        )&>.do {
          $0.isActive = true
        }
      )
    }

    private func activateTopMaxConstraint() {
      translatesAutoresizingMaskIntoConstraints = false

      activeConstraints.append(
        topAnchor.constraint(
          greaterThanOrEqualTo: superview!.topAnchor,
          constant: maximumRect!.minY
        )&>.do {
          $0.isActive = true
        }
      )
    }

    private func activateBottomMaxConstraint() {
      translatesAutoresizingMaskIntoConstraints = false

      activeConstraints.append(
        bottomAnchor.constraint(
          lessThanOrEqualTo: superview!.bottomAnchor,
          constant: maximumRect!.maxY - superview!.bounds.maxY
        )&>.do {
          $0.isActive = true
        })
    }

    private func activateLeftConstraint() {
      translatesAutoresizingMaskIntoConstraints = false

      activeConstraints.append(
        leftAnchor.constraint(
          equalTo: superview!.leftAnchor,
          constant: frame.minX - superview!.bounds.minX
        )&>.do {
          $0.isActive = true
        }
      )
    }

    private func activateBottomConstraint() {
      translatesAutoresizingMaskIntoConstraints = false

      activeConstraints.append(
        bottomAnchor.constraint(
          equalTo: superview!.bottomAnchor,
          constant: frame.maxY - superview!.bounds.maxY
        )&>.do {
          $0.isActive = true
        }
      )
    }

    private func activateTopConstraint() {
      translatesAutoresizingMaskIntoConstraints = false

      activeConstraints.append(
        topAnchor.constraint(
          equalTo: superview!.topAnchor,
          constant: frame.minY - superview!.bounds.minY
        )&>.do {
          $0.isActive = true
        }
      )
    }

    private func activateCenterXConstraint() {
      activeConstraints.append(
        centerXAnchor.constraint(
          equalTo: superview!.centerXAnchor,
          constant: frame.midX - superview!.bounds.midX
        )&>.do {
          $0.priority = .defaultLow
          $0.isActive = true
        }
      )
    }

    private func activateCenterYConstraint() {
      activeConstraints.append(
        centerYAnchor.constraint(
          equalTo: superview!.centerYAnchor,
          constant: frame.midY - superview!.bounds.midY
        )&>.do {
          $0.priority = .defaultLow
          $0.isActive = true
        }
      )
    }

    private func activateWidthConstraint() {
      translatesAutoresizingMaskIntoConstraints = false

      widthConstraint = widthAnchor.constraint(equalToConstant: bounds.width)&>.do {
        $0.priority = .defaultLow
        $0.isActive = true
      }

      activeConstraints.append(
        widthAnchor.constraint(greaterThanOrEqualToConstant: minimumSize.width)&>.do {
          $0.isActive = true
        }
      )
    }

    private func activateHeightConstraint() {
      translatesAutoresizingMaskIntoConstraints = false

      heightConstraint = heightAnchor.constraint(equalToConstant: bounds.height)&>.do {
        $0.priority = .defaultLow
        $0.isActive = true
      }

      activeConstraints.append(
        heightAnchor.constraint(greaterThanOrEqualToConstant: minimumSize.height)&>.do {
          $0.isActive = true
        }
      )
    }
    
    
    private func activateAspectRatioConstraint() {
      if let aspectRatio = lockedAspectRatio {
        activeConstraints.append(widthAnchor.constraint(
          equalTo: heightAnchor,
          multiplier: aspectRatio.width / aspectRatio.height,
          constant: 1
        )&>.do {
          $0.isActive = true
        })
      }
    }


    private func deactivateAllConstraints() {
      translatesAutoresizingMaskIntoConstraints = true

      NSLayoutConstraint.deactivate([
        widthConstraint,
        heightConstraint,

      ].compactMap { $0 } + activeConstraints)
      
      layoutIfNeeded()
    }

    @objc
    private func handlePanGestureInTopLeft(gesture: UIPanGestureRecognizer) {
      assert(containerView == superview)

      switch gesture.state {
      case .began:
        onGestureTrackingStarted()

        activateConstraints: do {
          activateAspectRatioConstraint()

          activateTopMaxConstraint()
          activateLeftMaxConstraint()

          activateBottomConstraint()
          activateRightConstraint()
          activateWidthConstraint()
          activateHeightConstraint()
        }

        fallthrough
      case .changed:
        defer {
          gesture.setTranslation(.zero, in: self)
        }

        let translation = gesture.translation(in: self)

        widthConstraint.constant -= translation.x
        heightConstraint.constant -= translation.y

      case .cancelled,
           .ended,
           .failed:

        onGestureTrackingEnded()
      default:
        break
      }
    }

    @objc
    private func handlePanGestureInTopRight(gesture: UIPanGestureRecognizer) {
      assert(containerView == superview)

      switch gesture.state {
      case .began:
        onGestureTrackingStarted()

        activateConstraints: do {
          activateAspectRatioConstraint()

          activateTopMaxConstraint()
          activateRightMaxConstraint()

          activateBottomConstraint()
          activateLeftConstraint()

          activateWidthConstraint()
          activateHeightConstraint()
        }

        fallthrough
      case .changed:
        defer {
          gesture.setTranslation(.zero, in: self)
        }
        let translation = gesture.translation(in: self)

        widthConstraint.constant += translation.x
        heightConstraint.constant -= translation.y

      case .cancelled,
           .ended,
           .failed:
        onGestureTrackingEnded()

      default:
        break
      }
    }

    @objc
    private func handlePanGestureInBottomLeft(gesture: UIPanGestureRecognizer) {
      assert(containerView == superview)

      switch gesture.state {
      case .began:
        onGestureTrackingStarted()

        activateConstraints: do {
          activateAspectRatioConstraint()

          activateBottomMaxConstraint()
          activateLeftMaxConstraint()

          activateTopConstraint()
          activateRightConstraint()

          activateWidthConstraint()
          activateHeightConstraint()
        }

        fallthrough
      case .changed:
        defer {
          gesture.setTranslation(.zero, in: self)
        }

        let translation = gesture.translation(in: self)

        widthConstraint.constant -= translation.x
        heightConstraint.constant += translation.y

      case .cancelled,
           .ended,
           .failed:
        onGestureTrackingEnded()
      default:
        break
      }
    }

    @objc
    private func handlePanGestureInBottomRight(gesture: UIPanGestureRecognizer) {
      assert(containerView == superview)

      switch gesture.state {
      case .began:
        onGestureTrackingStarted()

        activateConstraints: do {
          activateAspectRatioConstraint()

          activateBottomMaxConstraint()
          activateRightMaxConstraint()

          activateTopConstraint()
          activateLeftConstraint()

          activateWidthConstraint()
          activateHeightConstraint()
        }

        fallthrough
      case .changed:
        defer {
          gesture.setTranslation(.zero, in: self)
        }

        let translation = gesture.translation(in: self)

        widthConstraint.constant += translation.x
        heightConstraint.constant += translation.y

      case .cancelled,
           .ended,
           .failed:
        onGestureTrackingEnded()
      default:
        break
      }
    }

    @objc
    private func handlePanGestureInTop(gesture: UIPanGestureRecognizer) {
      assert(containerView == superview)

      switch gesture.state {
      case .began:
        onGestureTrackingStarted()

        activateConstraints: do {
          activateAspectRatioConstraint()

          activateTopMaxConstraint()
          activateCenterXConstraint()
          
          activateRightMaxConstraint()
          activateLeftMaxConstraint()
          
          activateBottomConstraint()

          if lockedAspectRatio == nil {
            activateWidthConstraint()
          }
          activateHeightConstraint()
        }

        fallthrough
      case .changed:

        defer {
          gesture.setTranslation(.zero, in: self)
        }

        let translation = gesture.translation(in: self)

        heightConstraint.constant -= translation.y

      case .cancelled,
           .ended,
           .failed:
        onGestureTrackingEnded()
      default:
        break
      }
    }

    @objc
    private func handlePanGestureInRight(gesture: UIPanGestureRecognizer) {
      assert(containerView == superview)

      switch gesture.state {
      case .began:
        onGestureTrackingStarted()

        activateConstraints: do {
          activateAspectRatioConstraint()
          
          activateRightMaxConstraint()
          activateCenterYConstraint()
          
          activateTopMaxConstraint()
          activateBottomMaxConstraint()
          
          activateLeftConstraint()
          
          activateWidthConstraint()
          if lockedAspectRatio == nil {
            activateHeightConstraint()
          }
        }

        fallthrough
      case .changed:
        defer {
          gesture.setTranslation(.zero, in: self)
        }

        let translation = gesture.translation(in: self)

        widthConstraint.constant += translation.x

      case .cancelled,
           .ended,
           .failed:
        onGestureTrackingEnded()
      default:
        break
      }
    }

    @objc
    private func handlePanGestureInLeft(gesture: UIPanGestureRecognizer) {
      assert(containerView == superview)

      switch gesture.state {
      case .began:
        onGestureTrackingStarted()

        activateConstraints: do {
          activateAspectRatioConstraint()
          
          activateLeftMaxConstraint()
          activateCenterYConstraint()
          
          activateTopMaxConstraint()
          activateBottomMaxConstraint()
          
          activateRightConstraint()
          
          activateWidthConstraint()
          if lockedAspectRatio == nil {
            activateHeightConstraint()
          }
        }

        fallthrough
      case .changed:

        defer {
          gesture.setTranslation(.zero, in: self)
        }

        let translation = gesture.translation(in: self)

        widthConstraint.constant -= translation.x

      case .cancelled,
           .ended,
           .failed:
        onGestureTrackingEnded()
      default:
        break
      }
    }

    @objc
    private func handlePanGestureInBottom(gesture: UIPanGestureRecognizer) {
      assert(containerView == superview)

      switch gesture.state {
      case .began:
        onGestureTrackingStarted()

        activateConstraints: do {
          activateAspectRatioConstraint()
          
          activateBottomMaxConstraint()
          activateCenterXConstraint()
          
          activateRightMaxConstraint()
          activateLeftMaxConstraint()
          
          activateTopConstraint()
          
          if lockedAspectRatio == nil {
            activateWidthConstraint()
          }
          activateHeightConstraint()
        }

        fallthrough
      case .changed:
        defer {
          gesture.setTranslation(.zero, in: self)
        }

        let translation = gesture.translation(in: self)

        heightConstraint.constant += translation.y

      case .cancelled,
           .ended,
           .failed:
        onGestureTrackingEnded()
      default:
        break
      }
    }
  }
}

private final class MaskView: PixelEditorCodeBasedView {
  private let topView = UIView()
  private let rightView = UIView()
  private let leftView = UIView()
  private let bottomView = UIView()

  init() {
    super.init(frame: .zero)

    backgroundColor = .clear
    [
      topView,
      rightView,
      leftView,
      bottomView,
    ].forEach {
      addSubview($0)
      $0.backgroundColor = .white
    }
  }

  func setUnmaskRect(_ rect: CGRect) {
    topView.frame = .init(origin: .zero, size: .init(width: bounds.width, height: rect.minY))
    rightView.frame = .init(
      origin: .init(x: rect.maxX, y: rect.minY),
      size: .init(width: bounds.width - rect.maxX, height: rect.height)
    )
    leftView.frame = .init(
      origin: .init(x: 0, y: rect.minY),
      size: .init(width: rect.minX, height: rect.height)
    )
    bottomView.frame = .init(
      origin: .init(x: 0, y: rect.maxY),
      size: .init(width: bounds.width, height: bounds.height - rect.maxY)
    )
  }
}
