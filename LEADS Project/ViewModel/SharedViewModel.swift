//
//  FarmerSharedViewModel.swift
//  Beeda
//
//  Created by Ashikul Hosen on 3/7/23.
//  Copyright © 2023 Beeda Inc. All rights reserved.
//

import Foundation

class SharedViewModel: ObservableObject {
    
    @Published var cartCount: Int = 0
    
    fileprivate init() {}
    
    func updateSharedReference() {
        sharedViewModel = .init()
    }

    func cleanup() {
        sharedViewModel = nil
    }
    
    func fetchCart() {
        Task {
            await self.fetchCart()
        }
    }
    
    private func fetchCart() async {
        let reply = await hrdAPIService.fetchCart()
        
        switch reply {
            case .success(let data):
                self.updateCartCount(cartCount: data.cartCount)
                
            case .failure(let error):
                debugPrint(error)
        }
    }
    
    private func updateCartCount(cartCount: Int) {
        self.cartCount = cartCount
    }
}

var sharedViewModel: SharedViewModel? = SharedViewModel()
