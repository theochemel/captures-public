//
//  CapturesTableViewController.swift
//  clipthat-standalone
//
//  Created by Theo Chemel on 11/25/18.
//  Copyright © 2018 Theo Chemel. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import AVKit
import Digger
import Hero
import GoogleMobileAds

class CapturesTableViewController: UITableViewController, CapturesTableViewCellDelegate, GADInterstitialDelegate, ErrorViewDelegate, UserViewDelegate {
    
    var user: User!
    
    var captures: [Capture]!
    
    var friends: [User]!
    
    var tableHeaderView: UIView!
    
    var tableHeaderContainerView: UIView!
    
    var tableHeaderViewIsExpanded = false
    
    var tableHeaderContainerViewHeightConstraint: NSLayoutConstraint!
    
    var currentUserView: UserView!
    
    var currentlyDownloadingIndex: Int!
    
    var currentlyPlayingIndex: Int!
    
    var playerViewController: AVPlayerViewController!
    
    var mediaURLToShare: URL!
    
    var interstitial: GADInterstitial!
    
    var isDisplayingInterstitial: Bool = false
    
    var isLoadingNewUser: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DiggerCache.cleanDownloadFiles()
        
        interstitial = createAndLoadInterstitial()
        
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        
        
        let backgroundView: UIView = {
            let view = UIView()
            view.backgroundColor = .white
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()
        
        tableView.backgroundView = backgroundView
        
        for (index, capture) in captures.prefix(4).enumerated() {
            let imageView = UIImageView()
            imageView.frame = CGRect(x: 0.0, y: CGFloat(index) * (9.0 / 16.0) * view.bounds.width, width: view.bounds.width, height: (9.0 / 16.0) * view.bounds.width)
            imageView.contentMode = .scaleAspectFill
            imageView.kf.setImage(with: capture.thumbnailURL)
            backgroundView.addSubview(imageView)
        }
        
        let backgroundBlurView: UIVisualEffectView = {
            let blurView = UIVisualEffectView()
            
            blurView.frame = UIScreen.main.bounds
            
            let blurEffect = UIBlurEffect(style: .light)
            
            blurView.effect = blurEffect
            
            return blurView
        }()
        
        backgroundView.addSubview(backgroundBlurView)
        
        updateUserView(user: user, friends: friends)
        
        let refreshControl: UIRefreshControl = {
            let refreshControl = UIRefreshControl()
            
            refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
            refreshControl.tintColor = .white
            
            return refreshControl
        }()
        tableView.refreshControl = refreshControl
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard captures != nil else { fatalError("No captures") }
        
        let capture = captures[indexPath.row]
        
        let height = (view.frame.width - 32) * (9.0 / 16.0) + 88
        
        let cell = CapturesTableViewCell(frame: CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: height), capture: capture)
        
        if let index = currentlyDownloadingIndex {
            if indexPath.row == index {
                cell.shareButton.isEnabled = false
                cell.progressView.alpha = 1.0
            }
        }
        
        if let index = currentlyPlayingIndex {
            if indexPath.row == index, self.playerViewController != nil {
                cell.thumbnailView.addSubview(self.playerViewController.view)
                self.playerViewController.view.frame = cell.thumbnailView.bounds
            }
        }
        
        cell.delegate = self
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (view.frame.width - 32) * (9.0 / 16.0) + 88
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard captures != nil else { fatalError("No Captures") }
        return captures.count
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if playerViewController != nil {
            playerViewController.view.removeFromSuperview()
            playerViewController.removeFromParent()
            playerViewController = nil
        }
    }
    
    @objc func didPressSignOut() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        view.window!.rootViewController?.dismiss(animated: true)
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        print("Refresh!")
        
        DiggerManager.shared.cancelAllTasks()
        DiggerCache.cleanDownloadFiles()
        
        if playerViewController != nil {
            playerViewController.view.removeFromSuperview()
            playerViewController.removeFromParent()
            playerViewController = nil
        }
        
        currentlyPlayingIndex = nil
        currentlyDownloadingIndex = nil
        
        guard !isLoadingNewUser else {
            refreshControl.endRefreshing()
            return
        }
        getCaptures(user: user).onSuccess { newCaptures in
            self.captures = newCaptures
            self.tableView.reloadSections(IndexSet(integer: 0), with: .fade)
        }.onFailure { error in
            print(error)
        }.onComplete { _ in
            refreshControl.endRefreshing()
        }
    }
    
    func capturesTableViewCellDidPressShare(_ sender: CapturesTableViewCell) {
        print("Share capture \(sender.index!)")
        
        guard currentlyDownloadingIndex == nil, tableView.refreshControl?.isRefreshing == false else { return }
        
        if interstitial.isReady {
            
            if playerViewController != nil {
                playerViewController.view.removeFromSuperview()
                playerViewController.removeFromParent()
                playerViewController = nil
            }
            
            currentlyPlayingIndex = nil
            
            interstitial.present(fromRootViewController: self)
            isDisplayingInterstitial = true
            
        } else {
            isDisplayingInterstitial = false
        }
        
        let captureToShare = captures[sender.index]
        
        guard captureToShare.localMediaURL == nil else {
            mediaURLToShare = captureToShare.localMediaURL
            
            if isDisplayingInterstitial == false {
                displayShareSheet(forURL: mediaURLToShare)
                mediaURLToShare = nil
            }
            
            return
        }
        
        UIView.animate(withDuration: 0.5) {
            sender.progressView.alpha = 1.0
        }
        sender.shareButton.isEnabled = false
        
        currentlyDownloadingIndex = sender.index
        
        Digger.download(captureToShare.mediaURL).progress { (progress) in
            
            guard let cell = self.tableView.cellForRow(at: IndexPath(row: captureToShare.index, section: 0)) as? CapturesTableViewCell else { return }
            
            cell.progressView.setProgress(Float(progress.fractionCompleted), animated: false)
            
            }.completion { (result) in
                
                self.currentlyDownloadingIndex = nil
                
                if let cell = self.tableView.cellForRow(at: IndexPath(row: captureToShare.index, section: 0)) as? CapturesTableViewCell {
                
                    UIView.animate(withDuration: 0.5, animations: {
                        cell.progressView.alpha = 0.0
                    })
                    cell.shareButton.isEnabled = true
                }
                
                switch result {
                    
                case .success(let url):
                    self.captures[captureToShare.index].localMediaURL = url
                    self.mediaURLToShare = url
                    
                    if self.isDisplayingInterstitial == false {
                        self.displayShareSheet(forURL: self.mediaURLToShare)
                        self.mediaURLToShare = nil
                    }
                    
                case .failure(let error):
                    print(error.localizedDescription)
                    //                    TODO: Better error handling
                }
        }
    }
    
    func capturesTableViewCellDidPressThumbnail(_ sender: CapturesTableViewCell) {
        print("Show capture \(sender.index!)")
        
        guard tableView.refreshControl?.isRefreshing == false, captures[sender.index].isVideo == true else { return }
        
        if self.playerViewController != nil {
            self.playerViewController.view.removeFromSuperview()
            self.playerViewController.removeFromParent()
            self.playerViewController = nil
        }
        
        currentlyPlayingIndex = sender.index
        
        let player = AVPlayer(url: captures[sender.index].mediaURL)
        player.play()
        
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        self.playerViewController = playerViewController
        addChild(playerViewController)
        
        if let cell = self.tableView.cellForRow(at: IndexPath(row: sender.index, section: 0)) as? CapturesTableViewCell {
            cell.thumbnailView.addSubview(playerViewController.view)
            playerViewController.view.frame = cell.thumbnailView.bounds
        }
    }
    
    func errorViewDidPressOk(_ sender: ErrorView) {
        self.dismiss(animated: true)
        //        TODO: Is this right? Whole VC needs better error handling.
    }
    
    func createAndLoadInterstitial() -> GADInterstitial {
        let interstitial = GADInterstitial(adUnitID: "ca-app-pub-2766675160977066/5870223254")
        interstitial.delegate = self
        interstitial.load(GADRequest())
        return interstitial
    }
    
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print("Failed to recieve ad: \(error.localizedDescription)")
    }
    
    func interstitialDidFail(toPresentScreen ad: GADInterstitial) {
        
        print("Interstitial failed to present!")
        
        interstitial = createAndLoadInterstitial()
        
        isDisplayingInterstitial = false
        
        
        if let media = mediaURLToShare {
            displayShareSheet(forURL: media)
            self.mediaURLToShare = nil
        }
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        interstitial = createAndLoadInterstitial()
        
        isDisplayingInterstitial = false
        
        if let media = mediaURLToShare {
            displayShareSheet(forURL: media)
            self.mediaURLToShare = nil
        }
    }
    
    func displayShareSheet(forURL url: URL) {
        
        guard url.pathExtension == "MP4" else {
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            present(activityViewController, animated: true)
            return
        }
        
        let clipEditorViewController = ClipEditorViewController()
        clipEditorViewController.clipURLToEdit = url
        
        present(clipEditorViewController, animated: true)
        
    }
    
    func userViewDidTap(_ sender: UserView) {
        if sender.isRootUser {
//            expand user view
            if tableHeaderViewIsExpanded == false {
                UIView.animate(withDuration: 0.3) {
                    self.tableView.beginUpdates()
                    self.tableHeaderContainerViewHeightConstraint.constant = (CGFloat(self.friends.count) + 1) * 40.0
                    self.tableHeaderView.frame = CGRect(x: 0.0, y: 0.0, width: self.tableView.bounds.width, height: (CGFloat(self.friends.count) + 1) * 40.0 + 8.0)
//                    self.tableView.tableHeaderView = self.tableHeaderView
                    self.tableHeaderView.layoutIfNeeded()
                    self.tableView.endUpdates()
                }
                tableHeaderViewIsExpanded = true
                
                let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
                rotationAnimation.fromValue = 0.0
                rotationAnimation.toValue = CGFloat.pi
                rotationAnimation.duration = 0.3
                rotationAnimation.fillMode = .forwards
                rotationAnimation.isRemovedOnCompletion = false
                
                self.currentUserView.expansionIndicator.layer.add(rotationAnimation, forKey: "expanded")
                
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.tableView.beginUpdates()
                    self.tableHeaderContainerViewHeightConstraint.constant = 40.0
                    self.tableHeaderView.frame = CGRect(x: 0.0, y: 0.0, width: self.tableView.bounds.width, height: 48.0)
//                    self.tableView.tableHeaderView = self.tableHeaderView
                    self.tableHeaderView.layoutIfNeeded()
                    self.tableView.endUpdates()
                }
                tableHeaderViewIsExpanded = false
                
                let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
                rotationAnimation.fromValue = CGFloat.pi
                rotationAnimation.toValue = 0.0
                rotationAnimation.duration = 0.3
                rotationAnimation.fillMode = .forwards
                rotationAnimation.isRemovedOnCompletion = false
                
                self.currentUserView.expansionIndicator.layer.add(rotationAnimation, forKey: "default")
            }
        } else {
            
            guard !tableView.refreshControl!.isRefreshing, !isLoadingNewUser else { return }
            
            isLoadingNewUser = true
            
            sender.startLoadingAnimation()
            
            getCaptures(user: sender.relatedUser).onSuccess { friendCaptures in
                
                self.friends.insert(self.user, at: 0)
                self.friends = self.friends.filter { $0.gamerTag != sender.relatedUser.gamerTag }
                
                self.user = sender.relatedUser
                self.captures = friendCaptures
                
                let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
                rotationAnimation.fromValue = CGFloat.pi
                rotationAnimation.toValue = 0.0
                rotationAnimation.duration = 0.3
                rotationAnimation.fillMode = .forwards
                rotationAnimation.isRemovedOnCompletion = false
                
                self.currentUserView.expansionIndicator.layer.add(rotationAnimation, forKey: "default")
                
                DiggerManager.shared.cancelAllTasks()
                DiggerCache.cleanDownloadFiles()
                
                if self.playerViewController != nil {
                    self.playerViewController.view.removeFromSuperview()
                    self.playerViewController.removeFromParent()
                    self.playerViewController = nil
                }
                
                self.currentlyPlayingIndex = nil
                self.currentlyDownloadingIndex = nil
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.tableView.beginUpdates()
                    self.tableHeaderContainerViewHeightConstraint.constant = 40.0
                    self.tableHeaderView.frame = CGRect(x: 0.0, y: 0.0, width: self.tableView.bounds.width, height: 48.0)
                    self.tableHeaderView.layoutIfNeeded()
                    self.tableView.reloadSections(IndexSet(integer: 0), with: .fade)
                    self.tableView.endUpdates()
                }, completion: { _ in
//                    self.tableView.reloadData()
                    self.updateUserView(user: self.user, friends: self.friends)
                    self.tableHeaderViewIsExpanded = false
                })
                
            }.onFailure { error in
                sender.stopLoadingAnimation()
                }.onComplete { _ in
                    self.isLoadingNewUser = false
            }
        }
    }
    
    func updateUserView(user: User, friends: [User]) {
            
        tableHeaderView = {
            let view = UIView()
            view.backgroundColor = .clear
            return view
        }()
        tableView.tableHeaderView = tableHeaderView
        tableHeaderView.frame = CGRect(x: 0.0, y: 0.0, width: tableView.bounds.width, height: 48.0)
        
        tableHeaderContainerView = {
            let view = UIView()
            view.backgroundColor = .white
            view.layer.masksToBounds = true
            view.layer.cornerRadius = 10.0
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()
        tableHeaderView.addSubview(tableHeaderContainerView)
        
        tableHeaderContainerViewHeightConstraint = tableHeaderContainerView.heightAnchor.constraint(equalToConstant: 40.0)
        NSLayoutConstraint.activate([
            tableHeaderContainerView.leadingAnchor.constraint(equalTo: tableHeaderView.leadingAnchor, constant: 16.0),
            tableHeaderContainerView.trailingAnchor.constraint(equalTo: tableHeaderView.trailingAnchor, constant: -16.0),
            tableHeaderContainerView.topAnchor.constraint(equalTo: tableHeaderView.topAnchor, constant: 8.0),
            tableHeaderContainerViewHeightConstraint,
        ])
        
        currentUserView = UserView(user: user, isRootUser: true)
        currentUserView.actionButton.addTarget(self, action: #selector(didPressSignOut), for: .touchUpInside)
        currentUserView.delegate = self
        tableHeaderContainerView.addSubview(currentUserView)
        
        NSLayoutConstraint.activate([
            currentUserView.leadingAnchor.constraint(equalTo: tableHeaderContainerView.leadingAnchor),
            currentUserView.trailingAnchor.constraint(equalTo: tableHeaderContainerView.trailingAnchor),
            currentUserView.topAnchor.constraint(equalTo: tableHeaderContainerView.topAnchor),
            currentUserView.heightAnchor.constraint(equalToConstant: 40.0),
        ])
        
        for (index, friend) in friends.enumerated() {
            let friendUserView = UserView(user: friend, isRootUser: false)
            friendUserView.delegate = self
            tableHeaderContainerView.addSubview(friendUserView)
            
            NSLayoutConstraint.activate([
                friendUserView.leadingAnchor.constraint(equalTo: tableHeaderContainerView.leadingAnchor),
                friendUserView.trailingAnchor.constraint(equalTo: tableHeaderContainerView.trailingAnchor),
                friendUserView.heightAnchor.constraint(equalToConstant: 40.0),
                friendUserView.topAnchor.constraint(equalTo: tableHeaderContainerView.topAnchor, constant: CGFloat(index + 1) * 40.0),
            ])
            tableHeaderView.layoutIfNeeded()
        }
        
        tableView.layoutIfNeeded()
        tableHeaderView.layoutIfNeeded()
        tableHeaderContainerView.layoutIfNeeded()
    }
}
