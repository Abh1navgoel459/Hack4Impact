//
//  Item.swift
//  NowApp
//
//  Created by Abhinav Goel on 2/25/24.
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
