//
//  File.swift
//  
//
//  Created by Md Shofiulla on 20/8/23.
//

import Foundation
struct CategoryModel: Hashable {
    let id: Int
    let name: String
    let icon: IconMdoel?
    let imageURL: URL?
    let uid = UUID().uuidString
    
    init?(_ data: APIModel.CategoryResponseModel?) {
        self.id = data?.id ?? -1
        self.name = data?.name ?? ""
        self.icon = IconMdoel(data?.icon)
        self.imageURL = buildImageURL(fileName: icon?.fileName ?? "")
    }
   
    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }
    
    init(id: Int, name: String, icon: IconMdoel?, imageUrl: URL?) {
        self.id = id
        self.name = name
        self.icon = icon
        self.imageURL = imageUrl
    }
    
    static let emptyCategory: CategoryModel = .init(id: -1, name: "All", icon: nil, imageUrl: nil)
}
struct IconMdoel: Hashable {
    let id: Int
    let fileName: String
    
    init?(_ data: APIModel.IconResponseModel?) {
        self.id = data?.id ?? -1
        self.fileName = data?.fileName ?? ""
    }
}
