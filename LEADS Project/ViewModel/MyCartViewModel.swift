//
//  File.swift
//  
//
//  Created by Silver Wolfe on 5/6/23.
//

import Foundation
import Combine

final class MyCartViewModel:ObservableObject{
    
    @Published var items: [CartItemModel] = []
    @Published var summary: CartSummaryModel?
    @Published var cartTotalCost: Double = 0
    @Published var itemCount: Int = 0
    var hasUnavailableProductInCart: Bool = false
    
    private let maxRetryTries: Int = 3
    private(set) var sections: [CartSections<AnyHashable>] = []
    private var cancellable = Set<AnyCancellable>()
    @Published var viewState: ViewState = .idle
    init() {
        self.requestForCartData()
        self.setupBinding()
    }
    
    @inlinable func calculateCartTotalCost() {
        guard let summary = summary else {
            cartTotalCost = 0
            return
        }
        cartTotalCost = summary.itemTotal
    }
    private func setupBinding() {
        $summary.zip(self.$items)
            .receive(on: DispatchQueue.global())
            .dropFirst()
            .sink {[weak self] data in
                if !data.1.isEmpty {
                    self?.sections.removeAll()
                    self?.sections.append(.init(sectionItem: .product, items: data.1))
                    self?.sections.append(.init(sectionItem: .addMore, items: [1]))
                    self?.sections.append(.init(sectionItem: .total, items: [data.0]))
                    self?.viewState = .reload
                }
                else {
                    self?.viewState = .empty
                }
                
            }
            .store(in: &cancellable)
    }
    
}

extension MyCartViewModel {
    func requestForCartData(ignoreCache: Bool = false) {
        Task{ [weak self] in
            guard let self = self else { return }
            await self.fetchCartData()
        }
    }
    func updateCartQty(cartID: Int, qty: Int) {
        Task{ [weak self] in
            guard let self = self else { return }
            await self.updateCartQuantity(cartID: cartID, qty: qty)
        }
    }
}
extension MyCartViewModel {
    func fetchCartData(ignoreCache: Bool = false) async {
        let result = await self.fetchCart().publisher
            .retry(self.maxRetryTries)
        
        result.receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                    case .finished:
                        debugPrint("Cart data retrieval completed successfully")
                    case .failure(let error):
                        self?.viewState = .error(message: error.localizedDescription)
                }
            }, receiveValue: { updatedValue in
                Task { @MainActor in
                    self.hasUnavailableProductInCart = false
                    self.items = updatedValue.items
                    self.itemCount = updatedValue.count
                    self.items.forEach { item in
                        if (item.pickupAvailable == false && item.pickupStatus == 1) || item.stockAvailable == false {
                            self.hasUnavailableProductInCart = true
                            return
                        }
                    }
                    self.summary = updatedValue.summery
                    self.calculateCartTotalCost()
                }
                
            })
            .store(in: &cancellable)
    }
    
    func updateCartQuantity(cartID: Int, qty: Int) async {
        let result = await self.updateCartItem(cartID, quantity: qty).publisher
            .retry(self.maxRetryTries)
        
        result.receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                    case .finished:
                        debugPrint("Change cart quantity retrieval completed successfully")
                    case .failure(let error):
                        self?.viewState = .error(message: error.localizedDescription)
                }
            }, receiveValue: { updatedValue in
                Task { @MainActor in
                    self.requestForCartData()
                }
                
            })
            .store(in: &cancellable)
    }
}

extension MyCartViewModel{
    
    func fetchCart() async -> Result<(items: [CartItemModel], summery: CartSummaryModel?, count: Int), Error>{
        let reply = await hrdAPIService.fetchCart()
        
        switch reply {
            case .success(let data):
                return .success((items: data.items, summery: data.summery, count: data.cartCount))
            case .failure(let error):
                return .failure(error)
        }
    }
    
    func updateCartItem(_ cartID: Int, quantity: Int) async -> Result<CartSummaryModel?, Error> {
        let data = APIModel.ChangeQtyRequestModel(cartID: cartID, quantity: quantity)
        let reply = await hrdAPIService.changeCartQuantity(data)
        
        switch reply {
            case .success(let data):
                return .success(data)
            case .failure(let error):
                return .failure(error)
        }
    }
    
    func clearCartForUnavailableItems(cartId: Int?) async -> Bool {
        var cartIDs: [Int] = []
        if cartId == nil{
            cartIDs = self.items.compactMap {
                if ($0.pickupAvailable == false && $0.pickupStatus == 1) || $0.stockAvailable == false { return $0.id }
                return nil
            }
        }else {
            cartIDs.append(cartId ?? 0)
        }
        
        let reply  = await hrdAPIService.clearCartForUnavailableItems(cartIDs: cartIDs)
        switch reply {
            case .success(let data):
                return data.status
            case .failure(let error):
                self.viewState = .error(message: error.localizedDescription)
                return false
        }
    }
    
    func clearCart() async -> Bool {
        let reply  = await hrdAPIService.clearCart()
        switch reply {
            case .success(let data):
                return data.status
            case .failure(let error):
                self.viewState = .error(message: error.localizedDescription)
                return false
        }
    }
    
    
}

extension MyCartViewModel {
    struct CartSections<I: Hashable>: Hashable {
        let sectionItem: CartSection
        var items: [I]
    }
}
