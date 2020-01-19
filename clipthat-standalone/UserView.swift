//
//  UserView.swift
//  clipthat-standalone
//
//  Created by Theo Chemel on 12/26/18.
//  Copyright © 2018 Theo Chemel. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

class UserView: UIView {
    
    weak var delegate: UserViewDelegate?
    
    var isRootUser: Bool!
    
    var containerView: UIView!
    var thumbnailImageView: UIImageView!
    var gamerTagLabel: UILabel!
    var actionButton: UIButton!
    var expansionIndicator: UIView!
    var loadingIndicator: UIImageView!
    var tapGestureRecognizer: UITapGestureRecognizer!
    
    var relatedUser: User!
    
    init(user: User, isRootUser: Bool) {
        super.init(frame: .zero)
        
        self.isRootUser = isRootUser
        
        backgroundColor = .clear
        
        translatesAutoresizingMaskIntoConstraints = false
        
        relatedUser = user

        containerView = {
            let view = UIView(frame: .zero)
            view.backgroundColor = .white
            view.layer.masksToBounds = true
            view.isUserInteractionEnabled = true
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()
        addSubview(containerView)
        
        tapGestureRecognizer = {
            let gestureRecognizer = UITapGestureRecognizer()
            gestureRecognizer.addTarget(self, action: #selector(didTap(_:)))
            return gestureRecognizer
        }()
        containerView.addGestureRecognizer(tapGestureRecognizer)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: super.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: super.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: super.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: super.bottomAnchor),
        ])
        
        thumbnailImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 12.0
            imageView.image = UIImage(named: "user")
            imageView.layer.masksToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }()
        containerView.addSubview(thumbnailImageView)
        
        getUserThumbnail(ofUser: user).onSuccess { thumbnailUser in
            self.thumbnailImageView.kf.setImage(with: thumbnailUser.thumbnailURL, options: [.transition(.fade(0.2))])
        }
        
        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12.0),
            thumbnailImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 24.0),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 24.0),
        ])
        
        if isRootUser {
            
            expansionIndicator = {
                let view = UIView()
                view.backgroundColor = .clear
                view.translatesAutoresizingMaskIntoConstraints = false
                
                let indicatorShapeLayer = CAShapeLayer()
                let indicatorPath = UIBezierPath()
                indicatorPath.move(to: CGPoint(x: 4.0, y: 18.0))
                indicatorPath.addLine(to: CGPoint(x: 14.0, y: 10.0))
                indicatorPath.addLine(to: CGPoint(x: 24.0, y: 18.0))
                
                indicatorShapeLayer.path = indicatorPath.cgPath
                indicatorShapeLayer.strokeColor = UIColor.buttonBlue.cgColor
                indicatorShapeLayer.fillColor = UIColor.clear.cgColor
                indicatorShapeLayer.lineWidth = 2.0
                
                view.layer.addSublayer(indicatorShapeLayer)
                return view
            }()
            
            containerView.addSubview(expansionIndicator)
            
            NSLayoutConstraint.activate([
                expansionIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12.0),
                expansionIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                expansionIndicator.widthAnchor.constraint(equalToConstant: 28.0),
                expansionIndicator.heightAnchor.constraint(equalToConstant: 28.0),
            ])
            
            actionButton = {
                let button = UIButton()
                button.setTitle("Sign Out", for: .normal)
                button.backgroundColor = .buttonBlue
                button.layer.cornerRadius = 14.0
                button.titleLabel?.textColor = .white
                button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
                button.titleLabel?.minimumScaleFactor = 0.75
                button.translatesAutoresizingMaskIntoConstraints = false
                return button
            }()
            containerView.addSubview(actionButton)
            
            NSLayoutConstraint.activate([
                actionButton.trailingAnchor.constraint(equalTo: expansionIndicator.leadingAnchor, constant: -8.0),
                actionButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                actionButton.heightAnchor.constraint(equalToConstant: 28.0),
                actionButton.widthAnchor.constraint(equalToConstant: 90.0),
            ])
        }
        
        gamerTagLabel = {
            let label = UILabel()
            label.text = user.gamerTag
            label.textColor = .darkGray
            label.font = UIFont.systemFont(ofSize: 18.0)
            label.textAlignment = .left
            label.minimumScaleFactor = 0.5
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        containerView.addSubview(gamerTagLabel)
        
        let labelTrailingConstraint = (actionButton != nil ? gamerTagLabel.trailingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: -16.0) : gamerTagLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16.0))
        
        NSLayoutConstraint.activate([
            gamerTagLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12.0),
            labelTrailingConstraint,
            gamerTagLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 1.0),
            gamerTagLabel.heightAnchor.constraint(equalToConstant: 24.0),
        ])
        
        if !isRootUser {
            let dividingLineView: UIView = {
                let view = UIView()
                view.backgroundColor = UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1.0)
                view.translatesAutoresizingMaskIntoConstraints = false
                return view
            }()
            containerView.addSubview(dividingLineView)
            
            NSLayoutConstraint.activate([
                dividingLineView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                dividingLineView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                dividingLineView.topAnchor.constraint(equalTo: containerView.topAnchor),
                dividingLineView.heightAnchor.constraint(equalToConstant: 1.0),
            ])
            
            loadingIndicator = {
                let imageView = UIImageView()
                imageView.image = UIImage(named: "loading_spinner_blue")
                imageView.isHidden = true
                imageView.translatesAutoresizingMaskIntoConstraints = false
                return imageView
            }()
            
            containerView.addSubview(loadingIndicator)
            
            NSLayoutConstraint.activate([
                loadingIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12.0),
                loadingIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                loadingIndicator.widthAnchor.constraint(equalToConstant: 28.0),
                loadingIndicator.heightAnchor.constraint(equalToConstant: 28.0),
            ])
        }
    }
    
    func startLoadingAnimation() {
        
        guard loadingIndicator != nil else { return }
        
        loadingIndicator.isHidden = false
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = Double.pi * 2.0
        rotationAnimation.duration = 0.5
        rotationAnimation.isCumulative = true
        rotationAnimation.repeatCount = Float.greatestFiniteMagnitude
        
        loadingIndicator.layer.add(rotationAnimation, forKey: "rotationAnimation")
    }
    
    func stopLoadingAnimation() {
        
        guard loadingIndicator != nil else { return }
        
        loadingIndicator.isHidden = true
        
        loadingIndicator.layer.removeAnimation(forKey: "rotationAnimation")
    }
    
    @objc func didTap(_ sender: UITapGestureRecognizer) {
        delegate?.userViewDidTap(sender.view?.superview as! UserView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol UserViewDelegate: class {
    func userViewDidTap(_ sender: UserView)
}
