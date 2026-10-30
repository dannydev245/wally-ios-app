//
//  Extensions.swift
//  RandumApp
//
//  Created by dannyduy on 1/10/26.
//

import Foundation
import SwiftUI

extension UserDefaults {
    var savedUser: User? {
        get {
            guard let data = data(forKey: AppStorageKeys.currentUser) else { return nil }
            return try? JSONDecoder().decode(User.self, from: data)
        }
        set {
            if let newValue = newValue, let encoded = try? JSONEncoder().encode(newValue) {
                set(encoded, forKey: AppStorageKeys.currentUser)
            } else {
                removeObject(forKey: AppStorageKeys.currentUser)
            }
        }
    }
    
    var savedTransactions: [TransactionItem] {
        get {
            guard let data = data(forKey: AppStorageKeys.userTransaction) else { return [] }
            return (try? JSONDecoder().decode([TransactionItem].self, from: data)) ?? []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                set(encoded, forKey: AppStorageKeys.userTransaction)
            } else {
                removeObject(forKey: AppStorageKeys.userTransaction)
            }
        }
    }
}

extension Double {
    func toCurrencyString() -> String {
        ThemeManager.shared.currentCurrency.format(amount: self)
    }
    
    func toCompactCurrencyString() -> String {
        ThemeManager.shared.currentCurrency.formatCompact(amount: self)
    }
}

extension UIImage {
    /// Chuẩn hóa orientation của ảnh về .up để tọa độ Vision luôn nhất quán
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? self
    }
}
