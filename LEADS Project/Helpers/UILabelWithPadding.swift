//
//  File.swift
//  
//
//  Created by Md Shofiulla on 4/7/23.
//

import UIKit
class UILabelWithPadding: UILabel {
    
    var padding = UIEdgeInsets(top: 9, left: 34, bottom: 9, right: 34)
    
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }
    
    override var intrinsicContentSize : CGSize {
        let superContentSize = super.intrinsicContentSize
        let width = superContentSize.width + padding.left + padding.right
        let heigth = superContentSize.height + padding.top + padding.bottom
        return CGSize(width: width, height: heigth)
    }
    
}
