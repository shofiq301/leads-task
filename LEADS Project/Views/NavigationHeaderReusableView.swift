//
//  File.swift
//  
//
//  Created by Silver Wolfe on 5/6/23.
//

import Foundation
import UIKit
protocol NavigationBarDelegate: AnyObject {
    func onCartPressed()
    func onProfilePressed()
}


class NavigationHeaderReusableView: UICollectionReusableView {
    
    // MARK: - Components
    
    
    lazy var componentsBaseView:UIView = {
        let componentsView = UIView()
        componentsView.translatesAutoresizingMaskIntoConstraints = false
        return componentsView
    }()
    
    lazy var cartButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "cart")?.withRenderingMode(.alwaysTemplate).withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 16), scale: .medium)), for: .normal)
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return button
    }()
    
    
    var profileButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "person")?.withRenderingMode(.alwaysTemplate).withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 16), scale: .medium)), for: .normal)
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return button
    }()
    
    lazy var navigationTitleLablel:UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "My Tesing Project"
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()
    
    lazy var baseStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [navigationTitleLablel, cartButton, profileButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 5
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()
  
    
    
    //MARK: - Conditional Variables
    static let identifier = "NavigationHeaderReusableView"
    weak var delegate: NavigationBarDelegate?
    
    // MARK: - Life Cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}




//MARK: - SetupUI
extension NavigationHeaderReusableView {
    
    func setUI(){
        addSubViews()
        setConstraints()
        setButtonAction()
    }
    
    func addSubViews(){
        self.addSubview(componentsBaseView)
        componentsBaseView.addSubview(baseStack)
    }
    
    func setConstraints(){
        
        NSLayoutConstraint.activate([
            componentsBaseView.topAnchor.constraint(equalTo: self.topAnchor),
            componentsBaseView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            componentsBaseView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            componentsBaseView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            baseStack.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 20),
            baseStack.leadingAnchor.constraint(equalTo: componentsBaseView.leadingAnchor, constant: 20),
            baseStack.bottomAnchor.constraint(equalTo: componentsBaseView.bottomAnchor, constant: 20),
            baseStack.trailingAnchor.constraint(equalTo: componentsBaseView.trailingAnchor, constant: -20),
        ])
    }
    
    
    func setButtonAction(){
        cartButton.addTarget(self, action: #selector(cartAction), for: .touchUpInside)
        profileButton.addTarget(self, action: #selector(profileAction), for: .touchUpInside)
    }
    
    
    @objc func cartAction() {
        self.delegate?.onCartPressed()
    }
    
    @objc func profileAction() {
        self.delegate?.onProfilePressed()
    }
}
extension NavigationHeaderReusableView {
    func setTitle(title:String){
        navigationTitleLablel.text = title
    }
}
