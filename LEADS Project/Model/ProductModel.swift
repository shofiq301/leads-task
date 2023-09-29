//
//  File.swift
//  
//
//  Created by Md Shofiulla on 20/8/23.
//

import Foundation
struct ProductModel: Hashable {
    let id: Int
    let name, unit: String
    let thumbnailImage: URL?
    let video: Bool?
    let priceLower, priceHigher: Double?
    let discountedPrice: Double?
    let currentStock, minimumQuantity, discount: Int?
    let discountType: DiscountType?
    let shippingType: ShippingType?
    let shippingCost, pickupStatus, categoryID: Int
    let shop: ProductShopModel?
    let shopName: String?
    let pickupAvailable: Bool
    let batch: Int
    let uuid = UUID().uuidString
    let discountedText: String
    
    
    init?(_ data: APIModel.ProductRespnseModel?) {
        self.id = data?.id ?? -1
        self.name = data?.name ?? ""
        self.unit = data?.unit ?? ""
        self.thumbnailImage = buildImageURL(fileName: data?.thumbnailImage ?? "")
        self.video = data?.video ?? false
        self.priceLower = data?.priceLower ?? 0.0
        self.priceHigher = data?.priceHigher ?? 0.0
        self.currentStock = data?.currentStock ?? 0
        self.minimumQuantity = data?.minimumQuantity ?? 0
        self.discount = data?.discount ?? 0
        self.discountType = data?.discountType
        self.discountedPrice = CalculationHelper.calculateDiscountPrice(discountType: discountType, discount: Double(data?.discount ?? 0), unitPrice: data?.priceHigher ?? 0.0)
        self.shippingType = data?.shippingType
        self.shippingCost = data?.shippingCost ?? 0
        self.pickupStatus = data?.pickupStatus ?? 0
        self.categoryID = data?.categoryID ?? 0
        self.shop = ProductShopModel(data?.shop)
        self.shopName = data?.shop?.shopName ?? ""
        self.countCart = data?.countCart?.compactMap{ CountCartModel($0)} ?? []
        self.wishlists = data?.wishlists?.compactMap{ ProductWishListModel($0)} ?? []
        self.pickupAvailable = data?.pickupAvailable ?? false
        self.batch = data?.batch ?? 0
        self.discountedText = CalculationHelper.calculateDiscountPriceStr(discountType: discountType, discount: Double(data?.discount ?? 0), unitPrice: data?.priceHigher ?? 0.0)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

struct ProductShopModel: Hashable {
    let shopID: Int
    let shopName: String
    let pickupStatus: Int
    let pickupTime: String
    let logo: URL?
    let address: String
    let shopDistance: Double
    
    init?(_ data: APIModel.ProductShopResponseModel?) {
        self.shopID = data?.shopID ?? -1
        self.shopName = data?.shopName ?? ""
        self.pickupStatus = data?.pickupStatus ?? 0
        self.pickupTime = data?.pickupTime ?? ""
        self.logo = buildImageURL(fileName: data?.logo ?? "")
        self.address = data?.address ?? ""
        self.shopDistance = data?.shopDistance ?? 0.0
    }
}
