//
//  YPGuideView.swift
//  YPImagePicker
//
//  Created by Roy on 2021/12/3.
//  Copyright © 2021 Yummypets. All rights reserved.
//

import UIKit

internal class YPGuideView: UIView {
    
    private var bubbleContainer: UIView?
    private var titleLabel: UILabel?
    private var subtitleLabel: UILabel?
    private var confirmButton: UIButton?
    
    private var gradientLayer: CAGradientLayer?
    
    internal static func show(over view: UIView, title: String, subtitle: String) {
        let guide = YPGuideView()
        guide.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        guide.frame = view.bounds
        view.addSubview(guide)
        guide.titleLabel?.text = title
        guide.subtitleLabel?.text = subtitle
    }
    
    // MARK: - Object lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        configure()
    }
    
    func configure() {
        let bubble: UIView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .brown
            view.layer.cornerRadius = 10
            view.layer.masksToBounds = true
            self.addSubview(view)
            view.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
            view.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12).isActive = true
            view.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12).isActive = true
            return view
        }()
        bubbleContainer = bubble
        
        let hstack: UIStackView = {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.distribution = .fill
            stack.translatesAutoresizingMaskIntoConstraints = false
            bubble.addSubview(stack)
            stack.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10).isActive = true
            stack.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10).isActive = true
            stack.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 16).isActive = true
            stack.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -16).isActive = true
            return stack
        }()
        
        let vstack: UIStackView = {
            let stack = UIStackView()
            stack.axis = .vertical
            stack.distribution = .equalSpacing
            hstack.addArrangedSubview(stack)
            return stack
        }()
        
        titleLabel = {
            let label = UILabel()
            label.font = UIFont(name: "PingFangTC-Medium", size: 18)
            label.textColor = .white
            label.text = "Title"
            vstack.addArrangedSubview(label)
            return label
        }()
        
        subtitleLabel = {
            let label = UILabel()
            label.font = UIFont(name: "PingFangTC-Medium", size: 14)
            label.textColor = .white
            label.text = "Subtitle"
            vstack.addArrangedSubview(label)
            return label
        }()
        
        confirmButton = {
            let col = UIView()
            col.backgroundColor = .clear
            let button = UIButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.titleLabel?.font = UIFont(name: "PingFangTC-Medium", size: 14)
            button.setTitleColor(.white, for: .normal)
            button.setTitle("知道了", for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.white.cgColor
            button.layer.cornerRadius = 6
            button.layer.masksToBounds = true
            col.addSubview(button)
            
            button.widthAnchor.constraint(equalToConstant: 68).isActive = true
            button.heightAnchor.constraint(equalToConstant: 34).isActive = true
            button.leadingAnchor.constraint(equalTo: col.leadingAnchor).isActive = true
            button.trailingAnchor.constraint(equalTo: col.trailingAnchor).isActive = true
            button.centerYAnchor.constraint(equalTo: col.centerYAnchor).isActive = true
            button.topAnchor.constraint(greaterThanOrEqualTo: col.topAnchor).isActive = true
            
            hstack.addArrangedSubview(col)
            return button
        }()
        
        createBubbleBackground()
        
        confirmButton?.addTarget(self, action: #selector(clickedConfirm(_:)), for: .touchUpInside)
    }
    
    // MARK: - View lifecycle
    override func layoutSubviews() {
        super.layoutSubviews()
        
        createBubbleBackground()
    }
    
    private func createBubbleBackground() {
        if gradientLayer != nil {
            gradientLayer?.removeFromSuperlayer()
            gradientLayer = nil
        }
        
        guard let container = bubbleContainer else { return }
        
        let glayer = CAGradientLayer()
        glayer.frame = container.bounds
        glayer.colors = [UIColor(r: 228, g: 194, b: 153, a: 230).cgColor,
                         UIColor(r: 129, g: 93, b: 41, a: 230).cgColor]
        glayer.startPoint = CGPoint(x: 0, y: 0.5)
        glayer.endPoint = CGPoint(x: 1, y: 0.5)
        glayer.cornerRadius = 10
        container.layer.insertSublayer(glayer, at: 0)

        gradientLayer = glayer
    }
    
    // MARK: - IB Actions
    @objc func clickedConfirm(_ sender: Any) {
        removeFromSuperview()
    }
}
