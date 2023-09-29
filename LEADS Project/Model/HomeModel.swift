//
//  File.swift
//  
//
//  Created by Md Shofiulla on 20/8/23.
//

import Foundation
struct HomeModel: Hashable {
    let allCategories: [CategoryModel]
    init?(_ data: APIModel.HomeResponseModel?) {
        self.allCategories = data?.allCategories?.compactMap{ CategoryModel($0)} ?? []
    }
}
