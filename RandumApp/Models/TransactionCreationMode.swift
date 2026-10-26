//
//  TransactionCreationMode.swift
//  RandumApp
//
//  Created by dannyduy on 26/10/26.
//


enum TransactionCreationMode: Identifiable {
    case manual
    case voice
    case scan
    
    var id: Self { self }
}