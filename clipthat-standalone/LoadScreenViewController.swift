//
//  LoadScreenViewController.swift
//  clipthat-standalone
//
//  Created by Theo Chemel on 8/10/18.
//  Copyright © 2018 Theo Chemel. All rights reserved.
//

import Foundation
import UIKit
import TransitionButton
import Hero
import Kingfisher

class LoadScreenViewController: UIViewController, ErrorViewDelegate {
    
    var user: User!
    
    var loadingView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ImageCache.default.clearDiskCache()
        ImageCache.default.clearMemoryCache()
        
        hero.isEnabled = true
        hero.modalAnimationType = .fade
        
        view.backgroundColor = .buttonBlue
        
        loadingView = UIImageView(frame: CGRect(x: view.bounds.midX - 40, y: view.bounds.midY - 40, width: 80, height: 80))
        loadingView.image = UIImage(named: "loading_spinner")
        loadingView.alpha = 0.0
        loadingView.accessibilityIdentifier = "Loading"
        
        view.addSubview(loadingView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(startAnimation), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        getCaptures(user: user).onSuccess { captures in
            
            guard captures.count > 0 else {
                self.displayErrorMessage(message: "It doesn't look like you have any captures.")
                return
            }
            
            let dispatchGroup = DispatchGroup()
            
            var friends: [User] = []
            
            dispatchGroup.enter()
            getFriends(ofUser: self.user).onSuccess { loadedFriends in
                friends = loadedFriends
                }.onComplete { _ in
                    dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            cacheThumbnails(ofCaptures: Array(captures.prefix(3))).onComplete { _ in
                dispatchGroup.leave()
            }
            
            dispatchGroup.notify(queue: .main, execute: {
                let capturesTableViewController = CapturesTableViewController()
                capturesTableViewController.user = self.user
                capturesTableViewController.captures = captures
                capturesTableViewController.friends = friends
                self.present(capturesTableViewController, animated: true)
            })

        }.onFailure { error in
            print(error)
            
            self.displayErrorMessage(message: "Check your internet connection and try again.")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startAnimation()
        
        UIView.animate(withDuration: 0.5) {
            self.loadingView.alpha = 1.0
        }
    }
    
    func errorViewDidPressOk(_ sender: ErrorView) {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        self.dismiss(animated: true)
    }
    
    @objc func startAnimation() {
        let rotation: CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = Double.pi * 2
        rotation.duration = 0.5
        rotation.isCumulative = true
        rotation.repeatCount = Float.greatestFiniteMagnitude
        loadingView.layer.add(rotation, forKey: "rotationAnimation")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        loadingView.layer.stopAnimation(forKey: "rotationAnimation")
    }
}
