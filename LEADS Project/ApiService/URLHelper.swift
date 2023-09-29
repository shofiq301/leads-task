//
//  URLHelper.swift
//  LEADS Project
//
//  Created by Md Shofiulla on 29/9/23.
//

import Foundation
let BASE_URL = "https://dummyjson.com/"
enum URLHelper{
    enum URLs {
        case categories
        case products(param: APIModel.PopularRequestModel)
        var url: URL? {
            switch self {
            case .categories:
                let url = URL(string: BASE_URL)
                url?.append(path: "products/categories")
                return url
            case .products:
                let queryParams: [URLQueryItem] = [
                    .init(name: "limit", value: String(params.limit)),
                    .init(name: "skip", value: String(params.skip)),
                    .init(name: "select", value: String(params.select))
                ]
                let url = URL(string: BASE_URL)
                url?.append(path: "/products")
                url?.append(queryItems: queryParams)
                return url
            }
        }
    }
}

func buildImageURL(fileName: String) -> URL? {
    return URL(string: fileName)
}
