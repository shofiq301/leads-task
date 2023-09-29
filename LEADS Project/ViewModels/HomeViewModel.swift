//
//  File.swift
//  
//
//  Created by Silver Wolfe on 5/6/23.
//

import Foundation
import Combine

enum ViewState: Hashable {
    case loading
    case loaded
    case reload
    case append(items: [AnyHashable])
    case idle
    case empty
    case removed(item: AnyHashable)
    case error(message: String)
    case success(message: String)
}


final class HomeViewModel:ObservableObject{
    
    private(set) var sections: [_Sections<AnyHashable>] = []
    private let maxRetryTries: Int = 3
    private var cancellables: Set<AnyCancellable> = .init()
    @Published var viewState: ViewState = .idle
    
    let itemPerPage: Int = 10
    var endOfPage: Bool = false
    @Published var currentPage: Int = 1
    
    init() {
        sections.append(.init(sectionItem: .category, items: ["A","B","C"]))
        sections.append(.init(sectionItem: .product, items: Array(1...10)))
        viewState = .loaded
    }
}



//MARK: - view model and api service interections

// MARK: Set Data from API Calls

extension HomeViewModel {
   
}

// MARK: API Calls


extension HomeViewModel {
    struct _Sections<I: Hashable>: Hashable {
        let sectionItem: HomeSection
        var items: [I]
    }
}
enum HomeSection{
    case category
    case product
}
