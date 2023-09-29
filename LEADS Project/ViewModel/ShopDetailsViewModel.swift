//
//  File.swift
//  
//
//  Created by Silver Wolfe on 5/6/23.
//

import Foundation
import Combine

final class ShopDetailsViewModel:ObservableObject{
    
    
    private(set) var sections: [ShopDetailsSections<AnyHashable>] = []
    @Published var viewState: ViewState = .idle
    @Published var shopDetails: ShopDetailsModel?
    @Published var selectedOrderStatus: ServiceStatus = .delivery
    @Published var products: [ProductModel] = []
    @Published var selectedCategoryId: String?
    @Published var currentPage: Int = 1
    
    @Published var categoryList: [CategoryModel] = []
    private let maxRetryTries: Int = 3
    private var cancellables: Set<AnyCancellable> = .init()
    var shopID: Int = 0
    var selectedIndex: Int = 0
    
    
    let itemPerPage: Int = 10
    var endOfPage: Bool = false
    
    
    init(shopId: Int) {
        self.shopID = shopId
        self.requestShopDetails(shopID: self.shopID)
        self.setupBindings()
    }
    private func setupBindings() {
        self.$shopDetails
            .filter{ $0 != nil }
            .receive(on: DispatchQueue.global())
            .sink(receiveValue: { [weak self] updatedValue in
                guard let shopDetails = updatedValue else { return }
                self?.sections.append(.init(sectionItem: .banner, items: [shopDetails]))
                self?.sections.append(.init(sectionItem: .product, items: []))
                self?.viewState = .reload
                self?.categoryList.append(CategoryModel.emptyCategory)
                self?.categoryList.append(contentsOf: shopDetails.shopCategories)
            })
            .store(in: &cancellables)
        
        self.$selectedOrderStatus
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.global())
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.selectedIndex = 0
                self.resetPageNumber()
                self.requestShopProduct()
            }
            .store(in: &cancellables)
        
        self.$selectedCategoryId
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.global())
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.resetPageNumber()
                self.requestShopProduct()
            }
            .store(in: &cancellables)
        
        self.$products
            .receive(on: DispatchQueue.global())
            .filter{ !$0.isEmpty }
            .sink { [weak self] updatedValue in
                if self?.currentPage == 1 {
                    if let index = self?.sections.firstIndex(where: { $0.sectionItem == .product }) {
                        if updatedValue.isEmpty {
                            self?.sections[index].items = [ProductModel.emptyProduct]
                        }else {
                            self?.sections[index].items = updatedValue
                        }
                        self?.viewState = .reload
                    } else{
                        self?.sections.append(.init(sectionItem: .product, items: updatedValue))
                        self?.viewState = .reload
                    }
                }else {
                    if let index = self?.sections.firstIndex(where: { $0.sectionItem == .product }) {
                        self?.sections[index].items.append(contentsOf: updatedValue)
                        self?.viewState = .append(items: updatedValue)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func updatePageNumber() {
        if self.endOfPage { return }
        self.currentPage += 1
    }
    
    func resetPageNumber() {
        self.currentPage = 1
        self.endOfPage = false
    }
}
//MARK: - view model and api service interections
extension ShopDetailsViewModel {
    func requestShopDetails(shopID: Int) {
        Task{ [weak self] in
            guard let self = self else { return }
            await self.fetchProductDetails()
        }
    }
    func requestShopProduct() {
        Task{ [weak self] in
            guard let self = self else { return }
            await self.fetchShopProducts()
        }
    }
    func requestShopToFav() {
        Task{ [weak self] in
            guard let self = self else { return }
            await self.fetchAddToFav()
        }
    }
}


//MARK: - view model and api service interections
//extension ShopDetailsViewModel {
//    private func addSections() {
//        sections.append(.init(sectionItem:.banner, items: ["Item 1"]))
//        sections.append(.init(sectionItem:.product, items: [1.6, 2.6, 3.6, 4.6, 5.6,6.6,7.6,8.6,9.6,10.6]))
//        categoryList = Array(1...10)
//    }
//    
//    
//}


// MARK: Set Data from API Calls
extension ShopDetailsViewModel {
    private func fetchProductDetails() async {
        let result = await self.fetchShopDetailsApiData(shopID: shopID).publisher
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
                    self.shopDetails = updatedValue
                }
                
            })
            .store(in: &cancellables)
    }
    
    
    private func fetchShopProducts(ignoreCache: Bool = false) async {
        let result = await self.fetchShopProductData().publisher
            .retry(self.maxRetryTries)
        
        result.receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        print("Shop Products data retrieval completed successfully")
                    case .failure(let error):
                        self.viewState = .error(message: error.localizedDescription)
                }
            }, receiveValue: { updatedValue in
                Task { @MainActor in
                    self.products = updatedValue.products
                    self.endOfPage = updatedValue.isLastPage
                }
                
            })
            .store(in: &cancellables)
    }
    
    
    
    private func fetchAddToFav() async {
        let result = await self.addShopToFavorites().publisher
            .retry(self.maxRetryTries)

        result.receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        print("product added successfully")
                    case .failure(let error):
                        self.viewState = .error(message: error.localizedDescription)
                }
            }, receiveValue: { updatedValue in
                Task { @MainActor in
                    if !updatedValue.success {
                        self.viewState = .error(message: updatedValue.message)
                    } else {
                        self.viewState = .success(message: updatedValue.message, state: .addToShopFav)
                    }
                }

            })
            .store(in: &cancellables)
    }
}
extension ShopDetailsViewModel {
    private func fetchShopDetailsApiData(shopID: Int) async -> Result<ShopDetailsModel?, Error>{
        let requesrtModel = APIModel.ShopProductDetailstRequestModel(productID: nil, shopID: shopID)
        let reply = await hrdAPIService.fetchShopDetails(data: requesrtModel)
        
        switch reply {
            case .success(let data):
                return .success(data)
            case .failure(let error):
                debugPrint(error)
                return .failure(error)
        }
    }
    
    func addShopToFavorites() async -> Result<(success: Bool, message: String), Error> {
        let reply = await hrdAPIService.addShopToFavorites(shopID: shopID)
        
        switch reply {
            case .success(let data):
                return .success(data)
            case .failure(let error):
                return .failure(error)
        }
    }
    
    private func fetchShopProductData(ignoreCache: Bool = false) async -> Result<(products: [ProductModel], isLastPage: Bool), Error> {
        let requestModel = APIModel.ShopProductRequestModel(shopID: shopID, perPage: itemPerPage, currentPage: currentPage, status: selectedOrderStatus.rawValue, categoryID: selectedCategoryId ?? "all")
        let reply = await hrdAPIService.fetchShopProductData(data: requestModel)
        switch reply {
            case .success(let data):
                return .success(data)
            case .failure(let error):
                debugPrint(error)
                return .failure(error)
        }
    }
}

extension ShopDetailsViewModel {
    struct ShopDetailsSections<I: Hashable>: Hashable {
        let sectionItem: ShopDetailsSection
        var items: [I]
    }
}
