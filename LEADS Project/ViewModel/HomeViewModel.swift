//
//  File.swift
//  
//
//  Created by Silver Wolfe on 5/6/23.
//

import Foundation
import Combine




final class HomeViewModel:ObservableObject{
    
    @Published var selectedOrderStatus: ServiceStatus = .delivery
    @Published var address: DefaultAddressModel?
    private(set) var sections: [HomeSections<AnyHashable>] = []
    @Published var popularList: [ProductModel] = []
    private let maxRetryTries: Int = 3
    private var cancellables: Set<AnyCancellable> = .init()
    @Published var viewState: ViewState = .idle
    
    let itemPerPage: Int = 10
    var endOfPage: Bool = false
    @Published var currentPage: Int = 1
    
    init() {
        self.requestForHomeData()
        self.setupBindings()
    }
    
    private func setupBindings() {
        self.$currentPage
            .filter{ $0 != 1 }
            .receive(on: DispatchQueue.global())
            .sink(receiveValue: { [weak self] _ in
                self?.requestPopularProduct()
            })
            .store(in: &cancellables)
        
        self.$selectedOrderStatus
            .dropFirst()
            .debounce(for: 1, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.global())
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.sections.removeAll()
                self.resetPageNumber()
                self.requestForHomeData()
                self.viewState = .reload
            }
            .store(in: &cancellables)
        
        self.$popularList
            .receive(on: DispatchQueue.global())
            .filter{ !$0.isEmpty }
            .sink { [weak self] updatedValue in
                if updatedValue.isEmpty { return }
                guard let index = self?.sections.firstIndex(where: { $0.sectionItem == .popularItems }) else { return }
                self?.sections[index].items.append(contentsOf: updatedValue)
                if self?.currentPage == 1 {
                    self?.viewState = .reload
                } else {
                    self?.viewState = .append(items: updatedValue)
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
extension HomeViewModel {
    func requestForHomeData(ignoreCache: Bool = false) {
        Task{ [weak self] in
            guard let self = self else { return }
            await self.fetchHomeDataForAPI(ignoreCache: ignoreCache)
            await self.fetchPopularProducts(ignoreCache: ignoreCache)
        }
    }
    func requestPopularProduct(ignoreCache: Bool = false) {
        Task{ [weak self] in
            guard let self = self else { return }
            await self.fetchPopularProducts(ignoreCache: ignoreCache)
        }
    }
}

// MARK: Set Data from API Calls
extension HomeViewModel {
    private func fetchHomeDataForAPI(ignoreCache: Bool = false) async {
        let result = await self.fetchHomeData(ignoreCache: ignoreCache).publisher
            .retry(self.maxRetryTries)
        
        result.receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        debugPrint("Home data retrieval completed successfully")
                    case .failure(let error):
                        self.viewState = .error(message: error.localizedDescription)
                }
            }, receiveValue: { updatedValue in
                Task { @MainActor in
                    guard let defAddress = updatedValue?.defaultAddress else { return }
                    self.address = defAddress
                    self.updateSectionData(updatedValue)
                }
                
            })
            .store(in: &cancellables)
    }
    private func fetchPopularProducts(ignoreCache: Bool = false) async {
        let result = await self.fetchPopularData().publisher
            .retry(self.maxRetryTries)
        
        result.receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        debugPrint("Popular data retrieval completed successfully")
                    case .failure(let error):
                        self.viewState = .error(message: error.localizedDescription)
                }
            }, receiveValue: { updatedValue in
                Task { @MainActor in
                    self.popularList = updatedValue.products
                    self.endOfPage = updatedValue.isLlastPage
                }
                
            })
            .store(in: &cancellables)
    }
}

extension HomeViewModel {
    private func updateSectionData(_ data: HomeModel?) {
        guard let data = data else { return }
        if let index = self.sections.firstIndex(where: { $0.sectionItem == .categories }) {
            self.sections[index].items = [data.allCategories]
        } else {
            if !data.allCategories.isEmpty {
                self.sections.append(.init(sectionItem: .categories, items: data.allCategories))
            }
        }
        if let index = self.sections.firstIndex(where: { $0.sectionItem == .nearby }) {
            self.sections[index].items = data.nearByShops
        } else {
            if !data.nearByShops.isEmpty {
                self.sections.append(.init(sectionItem: .nearby, items: data.nearByShops))
            }
        }
        if let index = self.sections.firstIndex(where: { $0.sectionItem == .featuredItems }) {
            self.sections[index].items = data.featuredItems
        } else {
            if !data.featuredItems.isEmpty {
                self.sections.append(.init(sectionItem: .featuredItems, items: data.featuredItems))
            }
        }
        
        if let index = self.sections.firstIndex(where: { $0.sectionItem == .banners }) {
            self.sections[index].items = data.banners
        } else {
            if !data.banners.isEmpty {
                self.sections.append(.init(sectionItem: .banners, items: data.banners))
            }
        }
        
        if let index = self.sections.firstIndex(where: { $0.sectionItem == .featuredShops }) {
            self.sections[index].items = data.featuredShops
        } else {
            if !data.featuredShops.isEmpty {
                self.sections.append(.init(sectionItem: .featuredShops, items: data.featuredShops))
            }
        }
        self.sections.append(.init(sectionItem: .popularItems, items: []))
        viewState = .reload
    }
}

// MARK: API Calls
extension HomeViewModel {
    private func fetchHomeData(ignoreCache: Bool = false) async -> Result<HomeModel?, Error> {
        let requesrtModel = APIModel.HomeRequestModel(pickupStatus: selectedOrderStatus.rawValue)
        let reply = await hrdAPIService.fetchHomeData(data: requesrtModel)
        
        switch reply {
            case .success(let data):
                return .success(data)
            case .failure(let error):
                debugPrint(error)
                return .failure(error)
        }
    }
    private func fetchPopularData(ignoreCache: Bool = false) async -> Result<(products: [ProductModel], isLlastPage: Bool), Error> {
        let requesrtModel = APIModel.PaginateRequestModel(pickupStatus: selectedOrderStatus.rawValue, perPage: self.itemPerPage, page: self.currentPage)
        let reply = await hrdAPIService.fetchPopularData(data: requesrtModel)
        
        switch reply {
            case .success(let data):
                return .success((products: data?.products ?? [], isLlastPage: data?.isLastPage ?? false))
            case .failure(let error):
                debugPrint(error)
                return .failure(error)
        }
    }
    
    
}


extension HomeViewModel {
    struct HomeSections<I: Hashable>: Hashable {
        let sectionItem: HomeSection
        var items: [I]
    }
}
