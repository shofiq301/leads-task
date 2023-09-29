//
//  File.swift
//  
//
//  Created by Silver Wolfe on 5/6/23.
//

import Foundation
import Combine

final class FilterViewModel: ObservableObject{
    
    
    private(set) var sections: [BeedaHRDFilterSection<AnyHashable>] = []
    @Published var filterValues: [FilterItemDataModel] = []
    @Published var viewState: ViewState = .idle
    
    private var cancellable = Set<AnyCancellable>()
    
    
    var selectedFilterItems: [String: String] = [:] {
        didSet {
            debugPrint(selectedFilterItems)
        }
    }
    
    
    
    init() {
        self.filterData()
        self.setupBindings()
    }
    
    private func setupBindings() {
        $filterValues
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedValue in
                guard let self = self else { return }
                self.sections.removeAll()
                
                for data in updatedValue {
                    self.sections.append(.init(sectionItem: data.itemType, selectionType: data.selectionType, items: data.values))
                }
                self.viewState = .reload
            }
            .store(in: &cancellable)
    }
    func filterData() {
        Task {
            await fetchAllFilterDataCategories()
        }
    }
    func filteredData() {
        Task {
            await filterData()
        }
    }
    
  
    
}
extension FilterViewModel {
   
    func fetchAllFilterDataCategories() async {
        let reply = await hrdAPIService.fetchAllFilterData()
        
        switch reply {
            case .success(let data):
                self.filterValues = data
            case .failure(let error):
                debugPrint(error)
        }
    }
    
}

extension FilterViewModel {
    struct BeedaHRDFilterSection<T: Hashable>: Hashable {
        let sectionItem: String
        var sectionItemKey: String {
            return sectionItem.replacingOccurrences(of: " ", with: "_").lowercased()
        }
        let selectionType: String
        let items: [T]
    }
}
