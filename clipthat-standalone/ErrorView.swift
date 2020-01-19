//
//  ErrorView.swift
//  clipthat-standalone
//
//  Created by Theo Chemel on 12/26/18.
//  Copyright © 2018 Theo Chemel. All rights reserved.
//

import Foundation
import UIKit

class ErrorView: UIView {
    
    weak var delegate: ErrorViewDelegate?
    
    var okButton: UIButton!
    var titleLabel: UILabel!
    var messageLabel: UILabel!
    
    init(message: String) {
        super.init(frame: .zero)
        
        backgroundColor = .errorRed
        layer.cornerRadius = 10.0
        layer.masksToBounds = true
        
        translatesAutoresizingMaskIntoConstraints = false
        
        okButton = {
            let button = UIButton()
            button.layer.cornerRadius = 10.0
            button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            button.setTitleColor(.white, for: .normal)
            button.setTitle("Ok", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 24.0)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(okPressed(_:)), for: .touchUpInside)
            return button
        }()

        addSubview(okButton)

        NSLayoutConstraint.activate([
            okButton.widthAnchor.constraint(equalToConstant: 60.0),
            okButton.heightAnchor.constraint(equalToConstant: 34.0),
            okButton.trailingAnchor.constraint(equalTo: super.trailingAnchor, constant: -16.0),
            okButton.centerYAnchor.constraint(equalTo: super.centerYAnchor),
        ])
        
        titleLabel = {
            let label = UILabel()
            label.text = "Oops!"
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 24.0)
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: super.leadingAnchor, constant: 16.0),
            titleLabel.trailingAnchor.constraint(equalTo: okButton.leadingAnchor, constant: -16.0),
            titleLabel.heightAnchor.constraint(equalToConstant: 30.0),
            titleLabel.bottomAnchor.constraint(equalTo: super.centerYAnchor, constant: -6.0)
        ])
        
        messageLabel = {
            let label = UILabel()
            label.text = message
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 16.0, weight: .light)
            label.numberOfLines = 2
            label.minimumScaleFactor = 0.75
            label.adjustsFontSizeToFitWidth = true
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: super.leadingAnchor, constant: 16.0),
            messageLabel.trailingAnchor.constraint(equalTo: okButton.leadingAnchor, constant: -16.0),
            messageLabel.topAnchor.constraint(equalTo: super.centerYAnchor, constant: -5.0),
            messageLabel.bottomAnchor.constraint(equalTo: super.bottomAnchor, constant: -12.0),
        ])
    }
    
    @objc func okPressed(_ sender: UIButton) {
        delegate?.errorViewDidPressOk(self)
    }
    
    override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

extension UIViewController {
    
    func displayErrorMessage(message: String) {
        let errorView = ErrorView(message: message)
        errorView.delegate = (self as! ErrorViewDelegate)
        
        self.view.addSubview(errorView)
        
        let verticalPositionConstraint = errorView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: -150.0)
        
        NSLayoutConstraint.activate([
            errorView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16.0),
            errorView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16.0),
            verticalPositionConstraint,
            errorView.heightAnchor.constraint(equalToConstant: 100.0),
            ])
        
        self.view.layoutIfNeeded()
        
        verticalPositionConstraint.constant = 0.0
        
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        })
    }
}

protocol ErrorViewDelegate: class {
    func errorViewDidPressOk(_ sender: ErrorView)
}
