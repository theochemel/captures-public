//
//  ClipTrimmerView.swift
//  clipthat-standalone
//
//  Created by Theo Chemel on 12/30/18.
//  Copyright © 2018 Theo Chemel. All rights reserved.
//

import Foundation
import UIKit

class ClipTrimmerView: UIView {
    
    weak var delegate: ClipTrimmerViewDelegate?
    
    var timelineContainerView: UIView!
    var timelineImageViews: [UIImageView]!
    var leftHandleView: HandleView!
    var rightHandleView: HandleView! 
    var topLineView: UIView!
    var bottomLineView: UIView!
    var leftTransparencyView: UIView!
    var rightTransparencyView: UIView!
    
    init(forClip clip: URL, frame: CGRect) {
        super.init(frame: frame)
        
        let numberOfThumbnails = 6
        
        translatesAutoresizingMaskIntoConstraints = false
        
        accessibilityIdentifier = "Clip Trimmer"
        
        timelineContainerView = {
            let view = UIView()
            view.backgroundColor = .clear
            view.frame = CGRect(x: 32.0, y: bounds.midY - 32.0, width: bounds.width - 64.0, height: 64.0)
//            view.layer.cornerRadius = 10.0
            view.layer.masksToBounds = true
            return view
        }()
        addSubview(timelineContainerView)
        
        timelineImageViews = []
        
        let thumbnailWidth = timelineContainerView.bounds.width / CGFloat(numberOfThumbnails)
        
        for x in 0 ..< 6 {
            let imageView = UIImageView()
            imageView.frame = CGRect(x: CGFloat(x) * thumbnailWidth, y: 2.0, width: thumbnailWidth, height: 60.0)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            timelineContainerView.addSubview(imageView)
            timelineImageViews.append(imageView)
        }
        
        generateThumbnails(forClip: clip, numberOfThumbnails: numberOfThumbnails).onSuccess { thumbnails in
            for (index, thumbnail) in thumbnails.enumerated() {
                UIView.transition(with: self.timelineImageViews[index], duration: 0.3, options: [], animations: {
                    self.timelineImageViews[index].image = thumbnail
                }, completion: nil)
            }
        }
        
        leftTransparencyView = {
            let view = UIView()
            view.frame = CGRect(x: timelineContainerView.frame.minX - 20.0, y: timelineContainerView.frame.minY, width: 20.0, height: timelineContainerView.frame.height)
            view.backgroundColor = UIColor.white.withAlphaComponent(0.5)
            return view
        }()
        addSubview(leftTransparencyView)
        
        rightTransparencyView = {
            let view = UIView()
            view.frame = CGRect(x: timelineContainerView.frame.maxX, y: timelineContainerView.frame.minY, width: 20.0, height: timelineContainerView.frame.height)
            view.backgroundColor = UIColor.white.withAlphaComponent(0.5)
            return view
        }()
        addSubview(rightTransparencyView)
        
        leftHandleView = {
            let view = HandleView()
            view.frame = CGRect(x: timelineContainerView.frame.minX - 20.0, y: timelineContainerView.frame.minY - 2.0, width: 20.0, height: timelineContainerView.frame.height + 4.0)
            view.backgroundColor = .buttonBlue
            view.layer.cornerRadius = 5.0
            view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: 10.0, y: 20.0))
            linePath.addLine(to: CGPoint(x: 10.0, y: view.bounds.height - 20.0))

            let lineLayer = CAShapeLayer()
            lineLayer.path = linePath.cgPath
            lineLayer.strokeColor = UIColor.white.cgColor
            lineLayer.lineWidth = 2.0
            lineLayer.lineCap = .round
            
            view.layer.addSublayer(lineLayer)
            
            view.isUserInteractionEnabled = true
            
            view.accessibilityIdentifier = "Left Handle"
            
            let panGestureRecognizer = UIPanGestureRecognizer()
            panGestureRecognizer.addTarget(self, action: #selector(leftHandlePan(_:)))
            view.addGestureRecognizer(panGestureRecognizer)
            
            
            return view
        }()
        addSubview(leftHandleView)
        
        rightHandleView = {
            let view = HandleView()
            view.frame = CGRect(x: timelineContainerView.frame.maxX, y: timelineContainerView.frame.minY - 2.0, width: 20.0, height: timelineContainerView.frame.height + 4.0)
            view.backgroundColor = .buttonBlue
            view.layer.cornerRadius = 5.0
            view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: 10.0, y: 20.0))
            linePath.addLine(to: CGPoint(x: 10.0, y: view.bounds.height - 20.0))
            
            let lineLayer = CAShapeLayer()
            lineLayer.path = linePath.cgPath
            lineLayer.strokeColor = UIColor.white.cgColor
            lineLayer.lineWidth = 2.0
            lineLayer.lineCap = .round
            
            view.layer.addSublayer(lineLayer)
            
            view.isUserInteractionEnabled = true
            
            view.accessibilityIdentifier = "Right Handle"
            
            let panGestureRecognizer = UIPanGestureRecognizer()
            panGestureRecognizer.addTarget(self, action: #selector(rightHandlePan(_:)))
            view.addGestureRecognizer(panGestureRecognizer)
            
            return view
        }()
        addSubview(rightHandleView)
        
        topLineView = {
            let view = UIView()
            view.frame = CGRect(x: leftHandleView.frame.maxX, y: leftHandleView.frame.minY, width: rightHandleView.frame.minX - leftHandleView.frame.maxX, height: 4.0)
            view.backgroundColor = .buttonBlue
            return view
        }()
        addSubview(topLineView)
        
        bottomLineView = {
            let view = UIView()
            view.frame = CGRect(x: leftHandleView.frame.maxX, y: leftHandleView.frame.maxY - 4.0, width: rightHandleView.frame.minX - leftHandleView.frame.maxX, height: 4.0)
            view.backgroundColor = .buttonBlue
            return view
        }()
        addSubview(bottomLineView)
    }
    
    @objc func leftHandlePan(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: timelineContainerView)
        
        guard recognizer.state != UIGestureRecognizer.State.ended else {
            delegate?.clipTrimmerViewLeftHandleDidFinishMoving()
            recognizer.setTranslation(.zero, in: timelineContainerView)
            return
        }
        
        defer {
            recognizer.setTranslation(.zero, in: timelineContainerView)
            delegate?.clipTrimmerViewLeftHandleDidMove(to: Double((leftHandleView.frame.maxX - timelineContainerView.frame.minX) / timelineContainerView.frame.width))
        }
        
        guard let view = recognizer.view else {
            recognizer.setTranslation(.zero, in: timelineContainerView)
            delegate?.clipTrimmerViewLeftHandleDidMove(to: Double((leftHandleView.frame.maxX - timelineContainerView.frame.minX) / timelineContainerView.frame.width))
            return
        }
        
        if (view.frame.origin.x + translation.x) > (timelineContainerView.frame.minX - 20.0) && (view.frame.origin.x + translation.x + 20.0) < rightHandleView.frame.minX {
            view.frame.origin.x += translation.x
            
            topLineView.frame.origin.x = leftHandleView.frame.maxX
            topLineView.frame.size = CGSize(width: rightHandleView.frame.minX - leftHandleView.frame.maxX, height: topLineView.frame.size.height)
            
            bottomLineView.frame.origin.x = leftHandleView.frame.maxX
            bottomLineView.frame.size = CGSize(width: rightHandleView.frame.minX - leftHandleView.frame.maxX, height: topLineView.frame.size.height)
        
            leftTransparencyView.frame.size.width = leftHandleView.frame.minX
        }
        recognizer.setTranslation(.zero, in: timelineContainerView)
        delegate?.clipTrimmerViewLeftHandleDidMove(to: Double((leftHandleView.frame.maxX - timelineContainerView.frame.minX) / timelineContainerView.frame.width))
    }
    
    @objc func rightHandlePan(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: timelineContainerView)
    
        guard recognizer.state != UIGestureRecognizer.State.ended else {
            delegate?.clipTrimmerViewRightHandleDidFinishMoving()
            recognizer.setTranslation(.zero, in: timelineContainerView)
            return
        }
        
        guard let view = recognizer.view else {
            recognizer.setTranslation(.zero, in: timelineContainerView)
            delegate?.clipTrimmerViewRightHandleDidMove(to: Double((rightHandleView.frame.minX - timelineContainerView.frame.minX) / timelineContainerView.frame.width))
            return
        }
        
        if (view.frame.origin.x + translation.x) < (timelineContainerView.frame.maxX) && (view.frame.origin.x + translation.x) > leftHandleView.frame.maxX {
            view.frame.origin.x += translation.x
            
            topLineView.frame.origin.x = leftHandleView.frame.maxX
            topLineView.frame.size = CGSize(width: rightHandleView.frame.minX - leftHandleView.frame.maxX, height: topLineView.frame.size.height)
            
            bottomLineView.frame.origin.x = leftHandleView.frame.maxX
            bottomLineView.frame.size = CGSize(width: rightHandleView.frame.minX - leftHandleView.frame.maxX, height: topLineView.frame.size.height)
            
            rightTransparencyView.frame.size.width = timelineContainerView.frame.maxX - rightHandleView.frame.maxX + 20.0
            rightTransparencyView.frame.origin.x = rightHandleView.frame.minX
        }
        
        recognizer.setTranslation(.zero, in: timelineContainerView)
        delegate?.clipTrimmerViewRightHandleDidMove(to: Double((rightHandleView.frame.minX - timelineContainerView.frame.minX) / timelineContainerView.frame.width))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol ClipTrimmerViewDelegate: class {
    func clipTrimmerViewLeftHandleDidMove(to position: Double)
    func clipTrimmerViewRightHandleDidMove(to position: Double)
    func clipTrimmerViewLeftHandleDidFinishMoving()
    func clipTrimmerViewRightHandleDidFinishMoving()
}

class HandleView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let frame = self.bounds.insetBy(dx: -10.0, dy: -40);
        return frame.contains(point) ? self : nil;
    }
}
