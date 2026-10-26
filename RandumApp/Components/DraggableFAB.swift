//
//  DraggableFAB.swift
//  RandumApp
//
//  Created by dannyduy on 6/10/26.
//

import SwiftUI

struct DraggableFAB: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var onSelectMode: (TransactionCreationMode) -> Void
    
    private let buttonSize: CGFloat = 58
    
    @State private var dragOffset: CGSize = .zero
    @State private var currentTranslation: CGSize = .zero
    @State private var isPressed: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let safeArea = geometry.safeAreaInsets
            
            let maxLeftOffset = -(screenWidth - buttonSize - 40)
            let maxTopOffset = -(screenHeight - buttonSize - safeArea.top - safeArea.bottom - 40)
            
            Menu {
                // 1. Quét hóa đơn
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onSelectMode(.scan)
                } label: {
                    Label("Scan Receipt", systemImage: "doc.viewfinder")
                }
                
                // 2. Nhập giọng nói
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onSelectMode(.voice)
                } label: {
                    Label("Voice Input", systemImage: "mic.fill")
                }
                
                // 3. Nhập thủ công
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onSelectMode(.manual)
                } label: {
                    Label("Manual Input", systemImage: "square.and.pencil")
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(themeManager.currentAccent.primaryColor)
                        .frame(width: buttonSize, height: buttonSize)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
                .opacity(isPressed ? 0.85 : 1.0)
                .scaleEffect(isPressed ? 0.94 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isPressed)
            }
            .contentShape(Circle())
            .offset(
                x: dragOffset.width + currentTranslation.width,
                y: dragOffset.height + currentTranslation.height
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        if !isPressed {
                            isPressed = true
                        }
                        currentTranslation = value.translation
                    }
                    .onEnded { value in
                        isPressed = false
                        
                        var finalX = dragOffset.width + value.translation.width
                        var finalY = dragOffset.height + value.translation.height
                        
                        // Giới hạn trong khung màn hình
                        finalX = min(max(finalX, maxLeftOffset), 0)
                        finalY = min(max(finalY, maxTopOffset), 0)
                        
                        // Hít vào cạnh trái/phải gần nhất
                        let midX = maxLeftOffset / 2
                        let targetX: CGFloat = finalX < midX ? maxLeftOffset : 0
                        
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            dragOffset = CGSize(width: targetX, height: finalY)
                            currentTranslation = .zero
                        }
                    }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 20)
            .padding(.bottom, 55)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        DraggableFAB { mode in
            print("Tapped FAB")
        }
    }
}
