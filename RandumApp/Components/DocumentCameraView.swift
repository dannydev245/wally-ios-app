//
//  DocumentCameraView.swift
//  RandumApp
//
//  Created by dannyduy on 28/10/26.
//

import SwiftUI
import VisionKit

struct DocumentCameraView: UIViewControllerRepresentable {
    var onScan: ([UIImage]) -> Void
    var onCancel: () -> Void
    
    private let maxScanPages = 3
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(maxPages: maxScanPages, onScan: onScan, onCancel: onCancel)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let maxPages: Int
        var onScan: ([UIImage]) -> Void
        var onCancel: () -> Void
        
        init(maxPages: Int, onScan: @escaping ([UIImage]) -> Void, onCancel: @escaping () -> Void) {
            self.maxPages = maxPages
            self.onScan = onScan
            self.onCancel = onCancel
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else {
                onCancel()
                return
            }
            
            let processCount = min(scan.pageCount, maxPages)
            var scannedImages: [UIImage] = []
            
            for index in 0..<processCount {
                scannedImages.append(scan.imageOfPage(at: index))
            }
            
            onScan(scannedImages)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onCancel()
        }
    }
}
