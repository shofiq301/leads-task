//
//  File.swift
//  
//
//  Created by Silver Wolfe on 5/6/23.
//

import Foundation
import Combine

final class ProductDetailsViewModel: ObservableObject{
    
    private(set) var specialInstructionMaxLimit: Int = 200
    @Published var viewState: ViewState = .idle
    @Published var productDetails: ProductDetailsModel?
    @Published var deliveryStatus: ServiceStatus = .delivery
    private let maxRetryTries: Int = 3
    private var cancellables: Set<AnyCancellable> = .init()
    private var productID: Int = 0
    var specialInstruction: String = ""
    var productCount = 0
    var buyNow = false
    
    init(productId: Int, status: ServiceStatus = .delivery) {
        self.productID = productId
        self.deliveryStatus = status
        self.requestProductDetails(productID: self.productID)
        self.setupBindings()
    }
    
    private func setupBindings() {
        self.$productDetails
            .filter{ $0 != nil }
            .receive(on: DispatchQueue.global())
            .sink(receiveValue: { [weak self] updatedValue in
                guard let productDetails = updatedValue else { return }
                if self?.productCount == 0 {
                    self?.productCount = productDetails.minimumQuantity
                }
                self?.viewState = .reload
            })
            .store(in: &cancellables)
    }
}
//MARK: - view model and api service interections
extension ProductDetailsViewModel {
    func requestProductDetails(productID: Int) {
        Task{ [weak self] in
            guard let self = self else { return }
            await self.fetchProductDetails(productID: productID)
        }
    }
    func requestAddToCart(instrction: String) {
        Task{ [weak self] in
            guard let self = self else { return }
            await self.fetchAddToCart(instrction: instrction)
        }
    }
    
    func requestProductToFav() {
        Task{ [weak self] in
            guard let self = self else { return }
            await self.fetchAddToFav()
        }
    }
}

// MARK: Set Data from API Calls
extension ProductDetailsViewModel {
    private func fetchProductDetails(productID: Int) async {
        let result = await self.fetchProductDetailsApiData(productID: productID).publisher
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
                    self.productDetails = updatedValue
                }
                
            })
            .store(in: &cancellables)
    }
    private func fetchAddToCart(instrction: String) async {
        let result = await self.addToCart(instrction: instrction).publisher
            .retry(self.maxRetryTries)
        
        result.receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        print("Added into cart successfully")
                    case .failure(let error):
                        self.viewState = .error(message: error.localizedDescription)
                }
            }, receiveValue: { updatedValue in
                Task { @MainActor in
                    if !updatedValue.status {
                        self.viewState = .error(message: updatedValue.message)
                    } else {
                        self.viewState = .success(message: updatedValue.message, state: self.buyNow == true ? .buy: .addToCart)
                    }
                }
                
            })
            .store(in: &cancellables)
    }
    
    private func fetchAddToFav() async {
        let result = await self.addProductToFavorites().publisher
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
                        self.viewState = .success(message: updatedValue.message, state: .addToProductFav)
                    }
                }
                
            })
            .store(in: &cancellables)
    }
}
extension ProductDetailsViewModel {
    private func fetchProductDetailsApiData(productID: Int) async -> Result<ProductDetailsModel?, Error> {
        let requesrtModel = APIModel.ShopProductDetailstRequestModel(productID: productID, shopID: nil)
        let reply = await hrdAPIService.fetchProductDetails(data: requesrtModel)
        
        switch reply {
            case .success(let data):
                return .success(data)
            case .failure(let error):
                debugPrint(error)
                return .failure(error)
        }
    }
    
    func addToCart(instrction: String) async -> Result<(status: Bool, message: String), Error> {
        let model = APIModel.AddToCartRequestModel(productID: self.productID, pickupStatus: self.deliveryStatus.rawValue, quantity: self.productCount, specialInstructtion: instrction)
        let reply = await hrdAPIService.addToCart(model)
        switch reply {
            case .success(let data):
                return .success(data)
            case .failure(let error):
                return .failure(error)
        }
    }
    
    func addProductToFavorites() async -> Result<(success: Bool, message: String), Error> {
        let reply = await hrdAPIService.addProductToWishlist(productID: productID)
        
        switch reply {
            case .success(let data):
                return .success(data)
            case .failure(let error):
                return .failure(error)
        }
    }
}
