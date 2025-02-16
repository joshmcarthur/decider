//
//  Item.swift
//  Decider
//
//  Created by Josh McArthur on 17/02/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
