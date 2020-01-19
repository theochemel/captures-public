//
//  CapturesTableViewCell.swift
//  clipthat-standalone
//
//  Created by Theo Chemel on 11/25/18.
//  Copyright © 2018 Theo Chemel. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import SkeletonView

class CapturesTableViewCell: UITableViewCell {
    weak var delegate: CapturesTableViewCellDelegate?
    
    var index: Int!

    var shadowView: UIView!
    var containerView: UIView!
    var thumbnailView: UIButton!
    var progressView: UIProgressView!
    var dateLabel: UILabel!
    var captureTypeLabel: UILabel!
    var shareButton: UIButton!
    
    init(frame: CGRect, capture: Capture) {
        index = capture.index
        
        super.init(style: UITableViewCell.CellStyle.default, reuseIdentifier: "")
        
        selectionStyle = .none
        backgroundColor = .clear
        
        shadowView = {
            let view = UIView(frame: CGRect(x: 16.0, y: 16.0, width: frame.width - 32, height: frame.height - 32))
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.backgroundColor = UIColor.clear.cgColor
            view.layer.shadowOffset = CGSize(width: 0, height: 4)
            view.layer.shadowOpacity = 0.75
            view.layer.shadowRadius = 12
            return view
        }()
        addSubview(shadowView)
        
        containerView = {
            let view = UIView(frame: shadowView.bounds)
            view.backgroundColor = UIColor(red: 237/255, green: 237/255, blue: 237/255, alpha: 1.0)
            view.layer.masksToBounds = true
            view.layer.cornerRadius = 10.0
            view.isUserInteractionEnabled = true
            return view
        }()
        
        thumbnailView = {
            let view = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: containerView.bounds.width, height: containerView.bounds.width * (9.0 / 16.0)))
            view.kf.setImage(with: capture.thumbnailURL, for: .normal, placeholder: UIImage(named: "image_loading"), options: [.transition(.fade(0.2))])
            view.addTarget(self, action: #selector(thumbnailPressed(_:)), for: .touchUpInside)
            view.isUserInteractionEnabled = true
            view.adjustsImageWhenDisabled = false
            return view
        }()
        containerView.addSubview(thumbnailView)
        
        if capture.isVideo {
            let playView = UIImageView(frame: CGRect(x: thumbnailView.bounds.midX - 20, y: thumbnailView.bounds.midY - 20, width: 40.0, height: 40.0))
            playView.image = UIImage(named: "play_icon")
            playView.contentMode = .scaleAspectFit
            thumbnailView.addSubview(playView)
        }
        
        progressView = {
           let view = UIProgressView(frame: CGRect(x: 0.0, y: thumbnailView.frame.maxY, width: containerView.bounds.width, height: 10.0))
            view.alpha = 0.0
            view.transform = CGAffineTransform(scaleX: 1, y: 2)
            return view
        }()
        containerView.addSubview(progressView)
        
        dateLabel = {
            let view = UILabel(frame: CGRect(x: 16.0, y: thumbnailView.frame.maxY + 6, width: containerView.bounds.width - 32, height: 27))
            //            TODO: not returning right date.
            view.text = capture.dateRecorded.timeAgoSinceNow
            view.font = view.font.withSize(16.0)
            view.textColor = UIColor(red: 74/255, green: 74/255, blue: 74/255, alpha: 1.0)
            return view
        }()
        containerView.addSubview(dateLabel)
        
        captureTypeLabel = {
            let view = UILabel(frame: CGRect(x: 16.0, y: thumbnailView.frame.maxY + 32, width: containerView.bounds.width - 32, height: 16))
            view.text = (capture.isVideo ? "Game Clip" : "Screenshot")
            view.font = view.font.withSize(13.0)
            view.textColor = UIColor(red: 114/255, green: 114/255, blue: 114/255, alpha: 1.0)
            return view
        }()
        containerView.addSubview(captureTypeLabel)
        
        shareButton = {
            let view = UIButton(frame: CGRect(x: containerView.bounds.width - 40, y: thumbnailView.frame.maxY + 17, width: 28.0, height: 25))
            view.setImage(UIImage(named: "share_enabled"), for: .normal)
            view.addTarget(self, action: #selector(sharePressed(_:)), for: .touchUpInside)
            view.accessibilityIdentifier = "Share"
            return view
        }()
        containerView.addSubview(shareButton)
        
        shadowView.addSubview(containerView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @objc func sharePressed(_ sender: UIButton) {
        delegate?.capturesTableViewCellDidPressShare(self)
    }
    
    @objc func thumbnailPressed(_ sender: UIButton) {
        delegate?.capturesTableViewCellDidPressThumbnail(self)
    }
}

protocol CapturesTableViewCellDelegate: class {
    func capturesTableViewCellDidPressShare(_ sender: CapturesTableViewCell)
    func capturesTableViewCellDidPressThumbnail(_ sender: CapturesTableViewCell)
}
