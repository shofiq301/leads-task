//
//  File.swift
//  
//
//  Created by Silver Wolfe on 5/6/23.
//

import Foundation
import Combine

final class ShopReviewViewModel:ObservableObject{
    
    
    private(set) var sections: [BeedaHRDShopReviewSections<AnyHashable>] = []
    @Published var viewState: ViewState = .idle
    @Published var shopInfo: ShopRatingInfoModel?
    
    private let maxRetryTries: Int = 3
    private var cancellables: Set<AnyCancellable> = .init()
    var shopID: Int = 0
    
    init(shopId: Int) {
        self.shopID = shopId
        self.requestShopRating(shopID: self.shopID)
        self.setupBindings()
    }
    
    private func setupBindings() {
        self.$shopInfo
            .filter{ $0 != nil }
            .receive(on: DispatchQueue.global())
            .sink(receiveValue: { [weak self] updatedValue in
                guard let shopDetails = updatedValue else { return }
                self?.sections.append(.init(sectionItem: .banner, items: [shopDetails]))
                self?.sections.append(.init(sectionItem: .rating, items: [shopDetails.starRating]))
                self?.sections.append(.init(sectionItem: .comment, items: shopDetails.reviews))
                self?.viewState = .reload
            })
            .store(in: &cancellables)
    }
}
extension ShopReviewViewModel {
    func requestShopRating(shopID: Int) {
        Task{ [weak self] in
            guard let self = self else { return }
            await self.fetchProductDetails()
        }
    }
}

extension ShopReviewViewModel {
    private func fetchProductDetails() async {
        let result = await self.fetchShopRatingApiData(shopID: shopID).publisher
            .retry(self.maxRetryTries)
        
        result.receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        print("Product details data retrieval completed successfully")
                    case .failure(let error):
                        self.viewState = .error(message: error.localizedDescription)
                }
            }, receiveValue: { updatedValue in
                Task { @MainActor in
                    self.shopInfo = updatedValue
                }
                
            })
            .store(in: &cancellables)
    }
}
extension ShopReviewViewModel {
    private func fetchShopRatingApiData(shopID: Int) async -> Result<ShopRatingInfoModel?, Error>{
        let requesrtModel = APIModel.ShopProductDetailstRequestModel(productID: nil, shopID: shopID)
        let reply = await hrdAPIService.fetchShopRatingInfo(data: requesrtModel)
        
        switch reply {
            case .success(let data):
                return .success(data)
            case .failure(let error):
                debugPrint(error)
                return .failure(error)
        }
    }
}
extension ShopReviewViewModel {
    struct BeedaHRDShopReviewSections<I: Hashable>: Hashable {
        let sectionItem: ShopReviewSection
        var items: [I]
    }
}
