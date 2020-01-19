//
//  SignInViewController.swift
//  clipthat-standalone
//
//  Created by Theo Chemel on 8/10/18.
//  Copyright © 2018 Theo Chemel. All rights reserved.
//

import Foundation
import UIKit
import TransitionButton

class SignInViewController: UIViewController {
    
    var gamertagTextField: UITextField!
    
    var signInButton: TransitionButton!
    
    var isSigningIn = false
    
    var isSignInCallbackValid = true
    
    override func viewDidLoad() {
        
        let containerView: UIView = {
            let containerView = UIView()
            containerView.backgroundColor = .white
            containerView.translatesAutoresizingMaskIntoConstraints = false
            return containerView
        }()
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12.0),
            containerView.heightAnchor.constraint(equalToConstant: 244.0),
        ])
        
        view.layoutSubviews()
        
        let capturesLabel: UILabel = {
            let label = UILabel(frame: CGRect(x: 20.0, y: 16.0, width: containerView.bounds.width - 40, height: 64.0))
            label.text = "Captures"
            label.textColor = UIColor.buttonBlue
            label.font = UIFont.systemFont(ofSize: 60.0, weight: .light)
            label.accessibilityIdentifier = "Captures"
            return label
        }()
        containerView.addSubview(capturesLabel)
        
//        let xboxLabel: UILabel = {
//            let label = UILabel(frame: CGRect(x: 24.0, y: capturesLabel.frame.maxY + 2, width: containerView.bounds.width - 48, height: 30))
//            label.text = "for Xbox"
//            label.textColor = UIColor.darkGray
//            label.font = UIFont.systemFont(ofSize: 24.0, weight: .light)
//            label.accessibilityIdentifier = "For Xbox"
//            return label
//        }()
//        containerView.addSubview(xboxLabel)
        
        gamertagTextField = {
            let textField = UITextField(frame: CGRect(x: 18.0, y: capturesLabel.frame.maxY + 14.0, width: containerView.bounds.width - 36, height: 44))
            textField.layer.cornerRadius = 10.0
            textField.layer.borderWidth = 2.0
            textField.layer.borderColor = UIColor.buttonBlue.withAlphaComponent(0.5).cgColor
            textField.font = textField.font?.withSize(24)
            textField.attributedPlaceholder = NSAttributedString(string: "Gamertag", attributes: [NSAttributedString.Key.foregroundColor : UIColor.buttonBlue.withAlphaComponent(0.5)])
            textField.textColor = UIColor.buttonBlue.withAlphaComponent(1.0)
            textField.textAlignment = .center
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.accessibilityIdentifier = "Gamertag"
            textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            return textField
        }()
        containerView.addSubview(gamertagTextField)
        
        signInButton = {
            let button = TransitionButton(frame: CGRect(x: 18.0, y: gamertagTextField.frame.maxY + 16.0, width: containerView.bounds.width - 36, height: 44))
            button.setTitle("Sign In", for: .normal)
            button.titleLabel?.font = button.titleLabel?.font.withSize(24.0)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = UIColor.buttonBlue
            button.cornerRadius = 10.0
            button.addTarget(self, action: #selector(signInButtonTouchUpInside(_:)), for: .touchUpInside)
            button.accessibilityIdentifier = "Sign In"
            return button
        }()
        containerView.addSubview(signInButton)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(textFieldEndEditing(_:)))
        tapGestureRecognizer.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        isSigningIn = false
        isSignInCallbackValid = true
        
        if let gamertag = UserDefaults.standard.string(forKey: "gamerTag"), let xuid = UserDefaults.standard.string(forKey: "xuid") {
            
            let user = User()
            user.gamerTag = gamertag
            user.xuid = xuid
            
            let loadScreenViewController = LoadScreenViewController()
            loadScreenViewController.user = user
            self.present(loadScreenViewController, animated: false)
        }
    }
    
    @objc func textFieldEndEditing(_ sender: UITapGestureRecognizer) {
        gamertagTextField.resignFirstResponder()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        if isSigningIn {
            signInButton.stopAnimation(animationStyle: .normal, revertAfterDelay: 0.0, completion: nil)
            isSignInCallbackValid = false
            isSigningIn = false
        }
        
        guard let text = textField.text else { return }
        
        if text.count > 0, textField.layer.borderColor != UIColor.buttonBlue.cgColor, textField.layer.animation(forKey: "toBlue") == nil {
            let toBlueAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.borderColor))
            toBlueAnimation.fromValue = UIColor.buttonBlue.withAlphaComponent(0.5).cgColor
            toBlueAnimation.toValue = UIColor.buttonBlue.cgColor
            toBlueAnimation.duration = 0.4
            toBlueAnimation.beginTime = CACurrentMediaTime()
            toBlueAnimation.fillMode = .forwards
            toBlueAnimation.isRemovedOnCompletion = false
            textField.layer.add(toBlueAnimation, forKey: "toBlue")
            textField.layer.removeAnimation(forKey: "toTranslucentBlue")
        } else if text.count == 0 {
            let toTranslucentBlueAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.borderColor))
            toTranslucentBlueAnimation.fromValue = UIColor.buttonBlue.cgColor
            toTranslucentBlueAnimation.toValue = UIColor.buttonBlue.withAlphaComponent(0.5).cgColor
            toTranslucentBlueAnimation.duration = 0.4
            toTranslucentBlueAnimation.beginTime = CACurrentMediaTime()
            toTranslucentBlueAnimation.fillMode = .forwards
            toTranslucentBlueAnimation.isRemovedOnCompletion = false
            textField.layer.add(toTranslucentBlueAnimation, forKey: "toTranslucentBlue")
            textField.layer.removeAnimation(forKey: "toBlue")
        }
    }
    
    @objc func signInButtonTouchUpInside(_ sender: TransitionButton) {
        
        guard !isSigningIn else { return }
        
        view.endEditing(true)
        
        guard let gamerTag = gamertagTextField.text else {
            blinkTextFieldRed(delay: 0.0)
            return
        }
        
        guard gamerTag.count > 1 else {
            blinkTextFieldRed(delay: 0.0)
            return
        }
        
        let user = User()
        user.gamerTag = gamerTag
        
        sender.startAnimation()
        
        isSigningIn = true
        
        getXUID(ofUser: user).onSuccess { signedInUser in
            
            guard self.isSignInCallbackValid else { return }
            
            self.gamertagTextField.resignFirstResponder()
            
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            
            UserDefaults.standard.set(signedInUser.gamerTag, forKey: "gamerTag")
            UserDefaults.standard.set(signedInUser.xuid, forKey: "xuid")
            
            sender.stopAnimation(animationStyle: .expand) {
                let loadScreenViewController = LoadScreenViewController()
                loadScreenViewController.user = signedInUser
                self.present(loadScreenViewController, animated: true)
            }
            
        }.onFailure { error in
            self.blinkTextFieldRed(delay: 0.8)
            sender.stopAnimation(animationStyle: .shake)
        }.onComplete { _ in
            self.isSigningIn = false
            self.isSignInCallbackValid = true
        }
    }
    
    func blinkTextFieldRed(delay: Double) {
        
        let toRedAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.borderColor))
        toRedAnimation.fromValue = UIColor.buttonBlue.withAlphaComponent(0.5).cgColor
        toRedAnimation.toValue = UIColor.errorRed.cgColor
        toRedAnimation.duration = 0.4
        toRedAnimation.beginTime = CACurrentMediaTime() + delay
        toRedAnimation.fillMode = .forwards
        toRedAnimation.isRemovedOnCompletion = false
        gamertagTextField.layer.add(toRedAnimation, forKey: nil)
        
        let toBlueAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.borderColor))
        toBlueAnimation.fromValue = UIColor.errorRed.cgColor
        toBlueAnimation.toValue = UIColor.buttonBlue.cgColor
        toBlueAnimation.duration = 0.4
        toBlueAnimation.beginTime = CACurrentMediaTime() + 1.0 + delay
        toBlueAnimation.fillMode = .forwards
        toBlueAnimation.isRemovedOnCompletion = false
        gamertagTextField.layer.add(toBlueAnimation, forKey: nil)
    }
}
