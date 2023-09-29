//
//  BeedaHRDCategoryCollectionCell.swift
//  
//
//  Created by Md Shofiulla on 4/7/23.
//

import UIKit

class CategoryCollectionCell: UICollectionViewCell {
    
    //MARK: - Components
    lazy var baseView:UIView = {
        var view = UIView()
        return view
    }()
    
    lazy var categoryImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "img_category")
        return imageView
    }()
    lazy var categoryLabel: UILabel = {
        let label = UILabel()
        label.text = "Category"
        label.textAlignment = .center
        label.numberOfLines = 1
        label.textColor = UIColor(hexString: "#2E3A59")
        label.font = .systemFont(ofSize: 12)
        return label
    }()
    
    static let identifier = "CategoryCollectionCell"
    
    //MARK: - Components
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension CategoryCollectionCell {
    private func setUI(){
        addSubViews()
        setConstrains()
    }
    
    private func addSubViews(){
        self.addSubview(baseView)
        
        baseView.addSubview(categoryImageView)
        baseView.addSubview(categoryLabel)
    }
    private func setConstrains(){
        
        NSLayoutConstraint.activate([
            baseView.topAnchor.constraint(equalTo: self.topAnchor),
            baseView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            baseView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            baseView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            categoryImageView.topAnchor.constraint(equalTo: baseView.topAnchor),
            categoryImageView.leadingAnchor.constraint(equalTo: baseView.leadingAnchor),
            categoryImageView.trailingAnchor.constraint(equalTo: baseView.trailingAnchor),
            
            categoryImageView.heightAnchor.constraint(equalToConstant: 40.0),
            categoryImageView.widthAnchor.constraint(equalToConstant: 40.0),
            
            categoryLabel.topAnchor.constraint(equalTo: categoryImageView.topAnchor),
            categoryLabel.leadingAnchor.constraint(equalTo: baseView.leadingAnchor),
            categoryLabel.trailingAnchor.constraint(equalTo: baseView.trailingAnchor),
            categoryLabel.bottomAnchor.constraint(equalTo: baseView.bottomAnchor)
        ])
    }
}
extension CategoryCollectionCell {
    func setupView(categoryName: String, categoryImage: URL?){
        self.categoryLabel.text = categoryName
    }
}
