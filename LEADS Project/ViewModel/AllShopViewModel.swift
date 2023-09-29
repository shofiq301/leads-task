//
//  File.swift
//  
//
//  Created by Silver Wolfe on 5/6/23.
//

import Foundation
import Combine

final class AllShopViewModel:ObservableObject{
    
    @Published var error: Error?
    @Published var shopList: [ShopModel] = []
    @Published var viewState: ViewState = .idle
    @Published var currentPage: Int = 1
    
    private let maxRetryTries: Int = 3
    private var cancellables: Set<AnyCancellable> = .init()
    
    let itemPerPage: Int = 10
    var endOfPage: Bool = false
    
    init() {
        self.setupBindings()
    }
    
    private func setupBindings() {
        self.$currentPage
            .receive(on: DispatchQueue.global())
            .sink(receiveValue: { [weak self] _ in
                self?.requestForShopData()
            })
            .store(in: &cancellables)
        
        self.$shopList
            .receive(on: DispatchQueue.global())
            .filter{ !$0.isEmpty }
            .sink { [weak self] updatedValue in
                if updatedValue.isEmpty { return }
                self?.viewState = .reload
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
extension AllShopViewModel {
    func requestForShopData(ignoreCache: Bool = false) {
        Task{ [weak self] in
            guard let self = self else { return }
            await self.fetchShopData(ignoreCache: ignoreCache)
        }
    }
}

// MARK: Set Data from API Calls
extension AllShopViewModel {
    private func fetchShopData(ignoreCache: Bool = false) async {
        let result = await self.fetchShoData().publisher
            .retry(self.maxRetryTries)
        
        result.receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        debugPrint("Popular data retrieval completed successfully")
                    case .failure(let error):
                        self.error = error
                }
            }, receiveValue: { updatedValue in
                Task { @MainActor in
                    guard let updatedValue = updatedValue else { return }
                    if self.currentPage == 1 {
                        self.shopList = updatedValue.shops
                    } else {
                        self.shopList.append(contentsOf: updatedValue.shops)
                    }
                    self.endOfPage = updatedValue.isLlastPage
                }
                
            })
            .store(in: &cancellables)
    }
}
extension AllShopViewModel {
    private func fetchShoData(ignoreCache: Bool = false) async -> Result<(shops: [ShopModel], isLlastPage: Bool)?, Error> {
        let requesrtModel = APIModel.PaginateRequestModel(pickupStatus: nil, perPage: self.itemPerPage, page: self.currentPage)
        let reply = await hrdAPIService.fetchAllShopsData(data: requesrtModel)
        
        switch reply {
            case .success(let data):
                return .success((data?.shops ?? [], data?.isLastPage ?? false))
            case .failure(let error):
                debugPrint(error)
                return .failure(error)
        }
    }
}
