//
//  File.swift
//  
//
//  Created by Silver Wolfe on 5/6/23.
//

import Foundation
import Combine

final class CategoryDetailsViewModel: ObservableObject{
    
    
    @Published var viewState: ViewState = .idle
    @Published var currentPage: Int = 1
    @Published var products: [ProductModel] = []
    
    private(set) var sections: [BeedaHRDAllSections<AnyHashable>] = []
    private let maxRetryTries: Int = 3
    private var cancellables: Set<AnyCancellable> = .init()
    
    let itemPerPage: Int = 10
    var endOfPage: Bool = false
    var categoryId: Int = 0
    
    init(categoryId: Int) {
        self.categoryId = categoryId
        self.requestProductShopData()
        self.setupBindings()
    }
    
    func updatePageNumber() {
        if self.endOfPage { return }
        self.currentPage += 1
    }
    
    
    
    private func setupBindings() {
        self.$currentPage
            .filter{ $0 != 1}
            .receive(on: DispatchQueue.global())
            .sink(receiveValue: { [weak self] _ in
                self?.requestProductShopData()
            })
            .store(in: &cancellables)
        self.$products
            .receive(on: DispatchQueue.global())
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
extension CategoryDetailsViewModel {
    func requestProductShopData(ignoreCache: Bool = false) {
        Task{ [weak self] in
            guard let self = self else { return }
            await self.fetchCategoryDetailsData(ignoreCache: ignoreCache)
        }
    }
}

// MARK: Set Data from API Calls
extension CategoryDetailsViewModel {
    private func fetchCategoryDetailsData(ignoreCache: Bool = false) async {
        let result = await self.fetchCategoryProductData(ignoreCache: ignoreCache).publisher
            .retry(self.maxRetryTries)
        
        result.receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        print("Category data retrieval completed successfully")
                    case .failure(let error):
                        self.viewState = .error(message: error.localizedDescription)
                }
            }, receiveValue: { updatedValue in
                Task { @MainActor in
                    self.products = updatedValue.products
                    self.endOfPage = updatedValue.isLastPage
                    if self.currentPage == 1 {
                        self.updateSectionData(self.products, shops: updatedValue.shops)
                    }
                    
                }
                
            })
            .store(in: &cancellables)
    }
}
extension CategoryDetailsViewModel {
    private func fetchCategoryProductData(ignoreCache: Bool = false) async -> Result<(products: [ProductModel], shops: [ShopModel], isLastPage: Bool), Error> {
        let requesrtModel = APIModel.CategoryProductShopRequestModel(perPage: itemPerPage, page: currentPage, categoryID: self.categoryId)
        let reply = await hrdAPIService.fetchCategoryShopProducts(data: requesrtModel)
        
        switch reply {
            case .success(let data):
                return .success(data)
            case .failure(let error):
                debugPrint(error)
                return .failure(error)
        }
    }
}


extension CategoryDetailsViewModel {
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
extension CategoryDetailsViewModel {
    struct BeedaHRDAllSections<I: Hashable>: Hashable {
        let sectionItem: ShopProductSection
        var items: [I]
    }
}
