//
//  OCRModels.swift
//  RandumApp
//
//  Created by dannyduy on 30/10/26.
//

import Foundation
import CoreGraphics

// MARK: - Parse Errors
enum ReceiptParseError: LocalizedError {
    case multipleTransactionsDetected
    case noDataDetected
    
    var localizedResource: LocalizedStringResource {
        switch self {
        case .multipleTransactionsDetected:
            return "The image contains multiple transactions. Please select a single transaction detail or invoice."
        case .noDataDetected:
            return "No valid payment information found on the image."
        }
    }
    
    var errorDescription: String? {
        String(localized: localizedResource)
    }
}

// MARK: - Spatial Data Structures
struct OCRTextElement {
    let text: String
    let box: CGRect // Vision coordinates: (0,0) at the bottom-left corner, (1,1) at the top-right corner
    
    var topDownY: CGFloat { 1.0 - box.midY } // 0.0 is the very top, 1.0 is the very bottom
    var leftRightX: CGFloat { box.midX }     // 0.0 is the left margin, 1.0 is the right margin
    var textHeight: CGFloat { box.height }
}

struct OCRTextRow {
    var elements: [OCRTextElement]
    
    var topDownY: CGFloat {
        elements.map { $0.topDownY }.reduce(0, +) / CGFloat(max(1, elements.count))
    }
    
    var text: String {
        elements.map { $0.text }.joined(separator: " ")
    }
}
