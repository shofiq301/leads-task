//
//  BeedaHRDCategoryCollectionCell.swift
//  
//
//  Created by Md Shofiulla on 4/7/23.
//

import UIKit

protocol AddCardDelegate {
    func cartAction(indexPath: IndexPath)
}

extension AddCardDelegate {
    func cartAction(indexPath: IndexPath){}
}



class ProductCollectionCell: UICollectionViewCell {
    
    //MARK: - Components
    lazy var baseView: UIView = {
        var view = UIView()
        return view
    }()
    
    lazy var productImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        return imageView
    }()
    lazy var productNameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UIColor(hexString: "#2E3A59")
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    lazy var mainStatView: UIStackView = {
        let stactView = UIStackView(arrangedSubviews: [productNameLabel, shopNameLabel, productPriceLabel])
        stactView.distribution = .fillEqually
        stactView.axis = .vertical
        stactView.spacing = 0
        return stactView
    }()
    
    lazy var shopNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(hexString: "#979797")
        label.font = .systemFont(ofSize: 12)
        return label
    }()
    
    lazy var productPriceLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    lazy var productUnitLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(hexString: "#8F9BB3")
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    lazy var productAddToCartButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "ic_add", in: .main, with: nil), for: .normal)
        button.addTarget(self, action: #selector(tappedAddToCart(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var discountLabel: UILabelWithPadding = {
        let label = UILabelWithPadding()
        label.padding = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.font = .systemFont(ofSize: 12)
        label.backgroundColor = UIColor(hexString: "#163BDE")
        label.textColor = UIColor(hexString: "#FFEF04")
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    
    //MARK: - Components
    static let identifier = "ProductCollectionCell"
    //MARK: - Conditional variable
    private var delegate: AddCardDelegate?
    private var indexPath: IndexPath?
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension ProductCollectionCell {
    private func setUI(){
        addSubViews()
        setConstrains()
    }
    
    private func addSubViews(){
        self.addSubview(baseView)
        baseView.addSubview(productImageView)
        baseView.addSubview(mainStatView)
        baseView.addSubview(productUnitLabel)
        baseView.addSubview(productAddToCartButton)
        baseView.addSubview(discountLabel)
        
    }
    private func setConstrains(){
        NSLayoutConstraint.activate([
            baseView.topAnchor.constraint(equalTo: self.topAnchor),
            baseView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            baseView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            baseView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            productImageView.topAnchor.constraint(equalTo: baseView.topAnchor),
            productImageView.leadingAnchor.constraint(equalTo: baseView.leadingAnchor),
            productImageView.trailingAnchor.constraint(equalTo: baseView.trailingAnchor),
            
            productImageView.heightAnchor.constraint(equalToConstant: 158),
            
            mainStatView.topAnchor.constraint(equalTo: productImageView.topAnchor),
            mainStatView.leadingAnchor.constraint(equalTo: baseView.leadingAnchor),
            mainStatView.trailingAnchor.constraint(equalTo: baseView.trailingAnchor),
            mainStatView.bottomAnchor.constraint(equalTo: baseView.bottomAnchor),
            discountLabel.topAnchor.constraint(equalTo: productImageView.topAnchor, constant: 12),
            discountLabel.leadingAnchor.constraint(equalTo: productImageView.leadingAnchor)
        ])
    }
}
extension ProductCollectionCell {
    
    @objc func tappedAddToCart(_ sender: UIButton) {
        delegate?.cartAction(indexPath: indexPath ?? IndexPath(row: 0, section: 0))
    }
}
