//
//  ClipEditorViewController.swift
//  clipthat-standalone
//
//  Created by Theo Chemel on 12/29/18.
//  Copyright © 2018 Theo Chemel. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class ClipEditorViewController: UIViewController, ErrorViewDelegate, ClipTrimmerViewDelegate, AVPlayerViewControllerDelegate {
    
    var clipURLToEdit: URL!
    var clipAsset: AVAsset!
    
    var leftHandlePosition: Double!
    var rightHandlePosition: Double!
    
    var player: AVPlayer!
    var playerViewController: AVPlayerViewController!
    
    var doneButton: UIButton!
    
    var shareButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        view.accessibilityIdentifier = "Clip Editor"
        
        doneButton = {
            let button = UIButton()
            button.setTitle("Done", for: .normal)
            button.setTitleColor(.buttonBlue, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.accessibilityIdentifier = "Done"
            button.layer.cornerRadius = 14.0
            button.layer.borderColor = UIColor.buttonBlue.cgColor
            button.layer.borderWidth = 1.0
            
            button.addTarget(self, action: #selector(didPressDoneButton(_:)), for: .touchUpInside)
            
            return button
        }()
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16.0),
            doneButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16.0),
            doneButton.widthAnchor.constraint(equalToConstant: 100.0),
            doneButton.heightAnchor.constraint(equalToConstant: 28.0),
        ])
        
        shareButton = {
            let button = UIButton()
            button.setTitle("Share", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = .buttonBlue
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.accessibilityIdentifier = "Share Clip"
            button.layer.cornerRadius = 14.0
            
            button.addTarget(self, action: #selector(didPressShareButton(_:)), for: .touchUpInside)
            
            return button
        }()
        view.addSubview(shareButton)
        
        NSLayoutConstraint.activate([
            shareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16.0),
            shareButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16.0),
            shareButton.widthAnchor.constraint(equalToConstant: 100.0),
            shareButton.heightAnchor.constraint(equalToConstant: 28.0),
        ])
        
        let playerContainerView: UIView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .clear
            view.layer.cornerRadius = 10.0
            view.layer.masksToBounds = true
            return view
        }()
        view.addSubview(playerContainerView)
        
        NSLayoutConstraint.activate([
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16.0),
            playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16.0),
            playerContainerView.topAnchor.constraint(equalTo: doneButton.bottomAnchor, constant: 16.0),
            playerContainerView.heightAnchor.constraint(equalTo: playerContainerView.widthAnchor, multiplier: (9.0 / 16.0), constant: 0.0),
        ])
        
        view.layoutSubviews()
        
        leftHandlePosition = 0.0
        rightHandlePosition = 1.0
        
        clipAsset = AVAsset(url: clipURLToEdit)
        
        player = AVPlayer(url: clipURLToEdit)
        playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.delegate = self
        
        player.play()
        
        playerContainerView.addSubview(playerViewController.view)
        playerViewController.view.frame = playerContainerView.bounds
        addChild(playerViewController)
        
        playerViewController.showsPlaybackControls = false
        playerViewController.setValue(true, forKey: "requiresLinearPlayback")
        
        let clipTrimmerView = ClipTrimmerView(forClip: clipURLToEdit, frame: CGRect(x: 4.0, y: playerContainerView.frame.maxY + 50.0, width: view.bounds.width - 8.0, height: 92.0))
        clipTrimmerView.delegate = self
        view.addSubview(clipTrimmerView)
        
        player.addBoundaryTimeObserver(forTimes: [(clipAsset.duration.seconds * rightHandlePosition) as NSValue], queue: nil) { [weak self] in
            guard self != nil else { return }
            self!.player.seek(to: CMTime(seconds: self!.clipAsset.duration.seconds * self!.leftHandlePosition, preferredTimescale: CMTimeScale(1.0)))
            self!.player.play()
        }
    }
    
    @objc func didPressShareButton(_ sender: UIButton) {
        print("share")
        
        exportVideo(fromURL: clipURLToEdit, startTime: clipAsset.duration.seconds * leftHandlePosition, endTime: clipAsset.duration.seconds * rightHandlePosition).onSuccess { exportURL in
            let shareViewController = UIActivityViewController(activityItems: [exportURL], applicationActivities: nil)
            self.present(shareViewController, animated: true)
            }.onFailure { error in
                print("error")
                self.displayErrorMessage(message: "Couldn't export the video.")
        }
    }
    
    @objc func didPressDoneButton(_ sender: UIButton) {
        player.pause()
        player.replaceCurrentItem(with: nil)
        player = nil
        playerViewController = nil
        dismiss(animated: true, completion: {
            self.removeFromParent()
        })
    }
    
    func clipTrimmerViewLeftHandleDidMove(to position: Double) {
        leftHandlePosition = position
        
        player.pause()
        player.seek(to: CMTime(seconds: clipAsset.duration.seconds * position, preferredTimescale: CMTimeScale(1.0)))
    }
    
    func clipTrimmerViewRightHandleDidMove(to position: Double) {
        rightHandlePosition = position
        
        player.pause()
        player.seek(to: CMTime(seconds: clipAsset.duration.seconds * position, preferredTimescale: CMTimeScale(1.0)))
    }
    
    func clipTrimmerViewLeftHandleDidFinishMoving() {
        player.play()
    }
    
    func clipTrimmerViewRightHandleDidFinishMoving() {
        self.player.seek(to: CMTime(seconds: self.clipAsset.duration.seconds * self.leftHandlePosition, preferredTimescale: CMTimeScale(1.0)))
        self.player.play()
        
        player.addBoundaryTimeObserver(forTimes: [(clipAsset.duration.seconds * rightHandlePosition) as NSValue], queue: nil) {
            self.player.seek(to: CMTime(seconds: self.clipAsset.duration.seconds * self.leftHandlePosition, preferredTimescale: CMTimeScale(1.0)))
            self.player.play()
        }
    }
    
    func errorViewDidPressOk(_ sender: ErrorView) {
        dismiss(animated: true)
        //        TODO: Check this
    }
}



