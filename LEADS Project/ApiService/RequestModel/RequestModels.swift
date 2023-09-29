//
//  CoffeeHomeRequestModel.swift
//  Beeda
//
//  Created by Ashikul Hosen on 3/15/23.
//  Copyright © 2023 Beeda Inc. All rights reserved.
//

import Foundation

extension APIModel {
    
    struct PopularRequestModel {
        let limit: Int = 10
        let skip: Int = 10
        var select: String
    }
}

