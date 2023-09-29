//
//  File.swift
//  
//
//  Created by Silver Wolfe on 5/6/23.
//

import Foundation
import Combine


enum SearchFilterType{
    case search
    case filter
}


final class SearchViewModel: ObservableObject{
    
    @Published var viewState: ViewState = .idle
    private(set) var sections: [SearchSections<AnyHashable>] = []
    @Published private var searchQueriesCacheData: [String: Int] = [: ]
    @Published var searchText: String = ""
    @Published var products: [ProductModel] = []
    private let maxRetryTries: Int = 3
    private var cancellables: Set<AnyCancellable> = .init()
    @Published var currentPage: Int = 1
    @Published var errorMessage: String = ""
    @Published var inShopSearch = false
    let itemPerPage: Int = 10
    var endOfPage: Bool = false
    var shopID: Int?
    private var searchCleared: Bool = false
    
    var searchFilterType: SearchFilterType = .filter
    var selectedFilterItems: [String: String] = [:] {
        didSet {
            Task{
                self.requestFilteredData()
            }
        }
    }
    
    init() {
        self.setupBindings()
    }
    
    private func setupBindings() {
        self.$searchText
            .filter{ !$0.isEmpty }
            .removeDuplicates()
            .debounce(for: .seconds(1) , scheduler: RunLoop.main)
            .receive(on: DispatchQueue.global())
            .sink { [weak self] string in
                self?.endOfPage = false
//                self?.searchQueriesCacheData[string] = Date().unixTimestamp
                let values: [Int] = self?.searchQueriesCacheData.values.sorted(by: { $0 > $1 }).prefix(5).map{ Int($0) } ?? []
                let filteredValue = self?.searchQueriesCacheData.filter{ values.contains($0.value) } ?? [: ]
                self?.searchQueriesCacheData = filteredValue
                self?.resetPageNumber()
                if self?.shopID != nil {
                    self?.requestInShopSearchData()
                } else {
                    self?.requestSearchData()
                }
            }
            .store(in: &cancellables)
        
        self.$currentPage
            .filter{ $0 != 1 }
            .receive(on: DispatchQueue.global())
            .sink { [weak self] updatedValue in
                guard let self = self else { return }
                if !self.selectedFilterItems.isEmpty {
                    Task {
                        await self.filterData()
                    }
                } else {
                    if self.shopID != nil {
                        self.requestInShopSearchData()
                    } else {
                        self.requestSearchData()
                    }
                }
            }
            .store(in: &cancellables)
        
        self.$searchQueriesCacheData
            .removeDuplicates()
            .receive(on: DispatchQueue.global())
            .sink { [weak self] updatedQueries in
                guard let self = self else { return }
                print(updatedQueries)
//                Pref.setRecentSearches(for: .farmer, self.searchQueriesCacheData)
//                let sortedKeys = self.searchQueriesCacheData.keysSortedByValue(isOrderedBefore: >)
//                self.searchQueries = sortedKeys
            }
            .store(in: &cancellables)
        
        
        self.$products
            .receive(on: DispatchQueue.global())
            .filter{ !$0.isEmpty }
            .sink { [weak self] updatedValue in
                self?.viewState = .loaded
                if self?.currentPage != 1 {
                    guard let index = self?.sections.firstIndex(where: { $0.sectionItem == .product }) else { return }
                    self?.sections[index].items.append(contentsOf: updatedValue)
                    self?.viewState = .append(items: updatedValue)
                }
            }
            .store(in: &cancellables)
    }
    func searchIsCleared(_ cleared: Bool) {
        self.searchCleared = cleared
        self.currentPage = 1
        self.endOfPage = false
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
extension SearchViewModel {
    func requestFilteredData(ignoreCache: Bool = false) {
        viewState = .loading
        Task{ [weak self] in
            guard let self = self else { return }
            await self.fetchFilterData(ignoreCache: ignoreCache)
        }
    }
    
    func requestSearchData(ignoreCache: Bool = false) {
        viewState = .loading
        Task{ [weak self] in
            guard let self = self else { return }
            await self.fetchSearchedData(ignoreCache: ignoreCache)
        }
    }
    
    func requestInShopSearchData(ignoreCache: Bool = false) {
        viewState = .loading
        Task{ [weak self] in
            guard let self = self else { return }
            await self.fetchInShopSearchedData(ignoreCache: ignoreCache)
        }
    }
}
extension SearchViewModel {
    private func fetchFilterData(ignoreCache: Bool = false) async {
        let result = await self.filterData().publisher
            .retry(self.maxRetryTries)
        
        result.receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        print("Filter data retrieval completed successfully")
                    case .failure(let error):
                        self.viewState = .error(message: error.localizedDescription)
                        self.viewState = .loaded
                }
            }, receiveValue: { updatedValue in
                Task { @MainActor in
                    self.products = updatedValue.products
                    self.endOfPage = updatedValue.isLastPage
                    if self.currentPage == 1 {
                        self.sections.removeAll()
                        self.updateSectionData(self.products, shops: updatedValue.shops)
                    }
                    
                }
                
            })
            .store(in: &cancellables)
    }
    
    private func fetchSearchedData(ignoreCache: Bool = false) async {
        let result = await self.search().publisher
            .retry(self.maxRetryTries)
        
        result.receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        print("Search data retrieval completed successfully")
                    case .failure(let error):
                        self.viewState = .error(message: error.localizedDescription)
                        self.viewState = .loaded
                }
            }, receiveValue: { updatedValue in
                Task { @MainActor in
                    self.products = updatedValue.products
                    self.endOfPage = updatedValue.isLastPage
                    if self.currentPage == 1 {
                        self.sections.removeAll()
                        self.updateSectionData(self.products, shops: updatedValue.shops)
                    }
                    
                }
                
            })
            .store(in: &cancellables)
    }
    private func fetchInShopSearchedData(ignoreCache: Bool = false) async {
        let result = await self.inShopSearch().publisher
            .retry(self.maxRetryTries)
        
        result.receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        print("Search data retrieval completed successfully")
                    case .failure(let error):
                        self.viewState = .error(message: error.localizedDescription)
                        self.viewState = .loaded
                }
            }, receiveValue: { updatedValue in
                Task { @MainActor in
                    self.products = updatedValue.products
                    self.endOfPage = updatedValue.isLastPage
                    if self.currentPage == 1 {
                        self.sections.removeAll()
                        self.updateSectionData(self.products, shops: [])
                    }
                    
                }
                
            })
            .store(in: &cancellables)
    }
}
extension SearchViewModel {
    func filterData() async -> Result<(products: [ProductModel], shops: [ShopModel], isLastPage: Bool), Error> {
        let data = APIModel.FilterRequestModel(keyword: searchText, currentPage: 1, itemPerPage: 10)
        var dataDictionary = data.dictionary
        let convertedArray: [[String: Any]] = self.selectedFilterItems.map { key, value in
            return [key.replacingOccurrences(of: "\\d", with: "", options: .regularExpression): Int(value) ?? value]
        }
        dataDictionary?["filter"] = convertedArray
        
        guard let dataDictionary = dataDictionary, !dataDictionary.isEmpty else { fatalError("Nothing found") }
        let reply = await hrdAPIService.filter(data: dataDictionary)
        
        switch reply {
            case .success(let data):
                return .success((data))
            case .failure(let error):
                return .failure(error)
        }
    }
    
    func search() async -> Result<(products: [ProductModel], shops: [ShopModel], isLastPage: Bool), Error>{
        let data = APIModel.SearchRequestModel(keyword: searchText, currentPage: currentPage, itemPerPage: itemPerPage, shopID: nil)
        let reply = await hrdAPIService.search(data: data)
        
        switch reply {
            case .success(let data):
                return .success((data))
            case .failure(let error):
                return .failure(error)
        }
    }
    func inShopSearch() async -> Result<(products: [ProductModel], isLastPage: Bool), Error>{
        let data = APIModel.SearchRequestModel(keyword: searchText, currentPage: currentPage, itemPerPage: itemPerPage, shopID: shopID)
        let reply = await hrdAPIService.inShopSearch(data: data)
        
        switch reply {
            case .success(let data):
                return .success((data))
            case .failure(let error):
                return .failure(error)
        }
    }
}



//MARK: - view model and api service interections
extension SearchViewModel {
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
extension SearchViewModel {
    struct SearchSections<I: Hashable>: Hashable {
        let sectionItem: ShopProductSection
        var items: [I]
    }
}
