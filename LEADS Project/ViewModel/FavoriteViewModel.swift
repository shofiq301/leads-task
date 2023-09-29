//
//  File.swift
//  
//
//  Created by Silver Wolfe on 5/6/23.
//

import Foundation
import Combine

final class FavoriteViewModel: ObservableObject{
    
    
    @Published var viewState: ViewState = .idle
    @Published var currentPage: Int = 1
    @Published var shops: [ShopModel] = []
    @Published var products: [ProductModel] = []
    
    private(set) var sections: [BeedaHRDAllSections<AnyHashable>] = []
    private let maxRetryTries: Int = 3
    private var cancellables: Set<AnyCancellable> = .init()
    
    let itemPerPage: Int = 10
    var endOfPage: Bool = false
    var categoryId: Int = 0
    
    init() {
        self.requestFavData()
        self.setupBindings()
    }
    
    private func setupBindings() {
        
//        self.$shops.zip(self.$products)
//            .receive(on: DispatchQueue.global())
//        //            .filter{ !$0.isEmpty && !$1.isEmpty }
//            .sink { [weak self] updatedData in
//                debugPrint(updatedData)
//                self?.updateSectionData(updatedData.1, shops: updatedData.0)
//            }.store(in: &cancellables)
        
        self.$currentPage
            .filter{ $0 != 1}
            .receive(on: DispatchQueue.global())
            .sink(receiveValue: { [weak self] _ in
                self?.requestFavData()
            })
            .store(in: &cancellables)
        self.$products
            .receive(on: DispatchQueue.global())
            .dropFirst()
            .filter{ !$0.isEmpty }
            .sink { [weak self] updatedValue in
                if updatedValue.isEmpty { return }
                if self?.currentPage != 1 {
                    guard let index = self?.sections.firstIndex(where: { $0.sectionItem == .product }) else { return }
                    self?.sections[index].items.append(contentsOf: updatedValue)
                    self?.viewState = .append(items: updatedValue)
                }
                
            }
            .store(in: &cancellables)
    }
}
//MARK: - view model and api service interections
extension FavoriteViewModel {
    func requestFavData(ignoreCache: Bool = false) {
        Task{ [weak self] in
            guard let self = self else { return }
            await self.fetchFavData(ignoreCache: ignoreCache)
        }
    }
    
    func requestToRemoveShops(shopID: Int) {
        Task{ [weak self] in
            guard let self = self else { return }
            await self.removeFavoriteShop(shopID: shopID)
        }
    }
    func requestToRemoveProduct(productID: Int) {
        Task{ [weak self] in
            guard let self = self else { return }
            await self.removeFavoriteProduct(productID: productID)
        }
    }
}

// MARK: Set Data from API Calls
extension FavoriteViewModel {
    private func fetchFavData(ignoreCache: Bool = false) async {
        let result = await self.fetchFavAPIData(ignoreCache: ignoreCache).publisher
            .retry(self.maxRetryTries)
        
        result.receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        print("Shop data retrieval completed successfully")
                    case .failure(let error):
                        self.viewState = .error(message: error.localizedDescription)
                }
            }, receiveValue: { updatedValue in
                Task { @MainActor in
                    self.shops = updatedValue.shops
                    self.products = updatedValue.products
                    self.endOfPage = updatedValue.isLastPage
                    if self.currentPage == 1 {
                        self.updateSectionData(self.products, shops: updatedValue.shops)
                    }
                }
                
            })
            .store(in: &cancellables)
    }
  
    private func removeFavoriteShop(shopID: Int) async {
        let result = await self.removeShopFromFavorites(shopID: shopID).publisher
            .retry(self.maxRetryTries)
        
        result.receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        print("Shop data retrieval completed successfully")
                    case .failure(let error):
                        self.viewState = .error(message: error.localizedDescription)
                }
            }, receiveValue: { updatedValue in
                Task { @MainActor in
                    self.viewState = .success(message: updatedValue.message, state: .removeShopFromFav)
                }
                
            })
            .store(in: &cancellables)
    }
    private func removeFavoriteProduct(productID: Int) async {
        let result = await self.removeProductFromFavorites(productID: productID).publisher
            .retry(self.maxRetryTries)
        
        result.receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        print("Product data retrieval completed successfully")
                    case .failure(let error):
                        self.viewState = .error(message: error.localizedDescription)
                }
            }, receiveValue: { updatedValue in
                Task { @MainActor in
                    self.viewState = .success(message: updatedValue.message, state: .removeProductFromFav)
                }
                
            })
            .store(in: &cancellables)
    }
    
    
}
extension FavoriteViewModel {
    private func fetchFavAPIData(ignoreCache: Bool = false) async -> Result<(products: [ProductModel], shops: [ShopModel], isLastPage: Bool), Error> {
        let requesrtModel = APIModel.FavoriteRequestModel(perPage: itemPerPage, page: currentPage)
        let reply = await hrdAPIService.fetchFavoriteData(data: requesrtModel)
        switch reply {
            case .success(let data):
                return .success(data)
            case .failure(let error):
                debugPrint(error)
                return .failure(error)
        }
    }
    
    
    private func removeShopFromFavorites(shopID: Int) async -> Result<(success: Bool, message: String), Error>{
        let reply = await hrdAPIService.removeShopFromWishlist(shopID: shopID)
        switch reply {
            case .success(let data):
                return .success(data)
            case .failure(let error):
                return .failure(error)
        }
    }
    
    private func removeProductFromFavorites(productID: Int) async -> Result<(success: Bool, message: String), Error>{
        let reply = await hrdAPIService.removeProductFromWishlist(productID: productID)
        switch reply {
            case .success(let data):
                return .success(data)
            case .failure(let error):
                return .failure(error)
        }
    }
}


extension FavoriteViewModel {
    private func updateSectionData(_ products: [ProductModel], shops: [ShopModel]) {
        if let index = self.sections.firstIndex(where: { $0.sectionItem == .shop }) {
            self.sections[index].items = shops
        } else {
            if !shops.isEmpty {
                self.sections.append(.init(sectionItem:.shop, items: shops))
            }
        }
        if let index = self.sections.firstIndex(where: { $0.sectionItem == .product }) {
            self.sections[index].items = products
        } else {
            if !products.isEmpty {
                self.sections.append(.init(sectionItem:.product, items: products))
            }
        }
        viewState = .reload
        
        if products.isEmpty && shops.isEmpty {
            viewState = .empty
        }
    }
}
extension FavoriteViewModel {
    struct BeedaHRDAllSections<I: Hashable>: Hashable {
        let sectionItem: ShopProductSection
        var items: [I]
    }
}
