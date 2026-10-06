//
//  MonthlyChartData.swift
//  RandumApp
//
//  Created by dannyduy on 5/10/26.
//

import Foundation

struct MonthlyChartData: Identifiable {
    let id = UUID()
    let weekLabel: String
    let amount: Double
    let type: TransactionType
}
