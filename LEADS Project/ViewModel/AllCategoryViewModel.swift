//
//  File.swift
//  
//
//  Created by Silver Wolfe on 5/6/23.
//

import Foundation
import Combine

final class AllCategoryViewModel: ObservableObject{
    
   
    @Published var error: Error?
    @Published var categoryList: [CategoryModel] = []
    @Published var viewState: ViewState = .idle
    
    private let maxRetryTries: Int = 3
    private var cancellables: Set<AnyCancellable> = .init()
    init() {
        self.requestAllCategoris()
        self.setupBindings()
    }
    private func  setupBindings(){
        $categoryList
            .filter{ !$0.isEmpty }
            .receive(on: DispatchQueue.global())
            .sink { [weak self] _ in
                self?.viewState = .reload
            }.store(in: &cancellables)
    }
}
//MARK: - view model and api service interections
extension AllCategoryViewModel {
    func requestAllCategoris(ignoreCache: Bool = false) {
        Task{ [weak self] in
            guard let self = self else { return }
            await self.fetchAllCategoris(ignoreCache: ignoreCache)
        }
    }
}

// MARK: Set Data from API Calls
extension AllCategoryViewModel {
    private func fetchAllCategoris(ignoreCache: Bool = false) async {
        let result = await self.fetchCategoryData(ignoreCache: ignoreCache).publisher
            .retry(self.maxRetryTries)
        
        result.receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        print("Category data retrieval completed successfully")
                    case .failure(let error):
                        self.error = error
                }
            }, receiveValue: { updatedValue in
                Task { @MainActor in
                    self.categoryList = updatedValue ?? []
                }
                
            })
            .store(in: &cancellables)
    }
}
extension AllCategoryViewModel {
    private func fetchCategoryData(ignoreCache: Bool = false) async -> Result<[CategoryModel]?, Error> {
        let reply = await hrdAPIService.fetchCategoryData()
        
        switch reply {
            case .success(let data):
                return .success(data)
            case .failure(let error):
                debugPrint(error)
                return .failure(error)
        }
    }
}
