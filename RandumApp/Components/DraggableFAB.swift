//
//  DraggableFAB.swift
//  RandumApp
//
//  Created by dannyduy on 6/10/26.
//

import SwiftUI

struct DraggableFAB: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var onTap: () -> Void
    
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
            
            ZStack {
                Circle()
                    .fill(themeManager.currentAccent.primaryColor)
                    .frame(width: buttonSize, height: buttonSize)
                    .shadow(
                        color: themeManager.currentAccent.primaryColor.opacity(isPressed ? 0.2 : 0.4),
                        radius: isPressed ? 4 : 8,
                        x: 0,
                        y: isPressed ? 2 : 4
                    )
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            .opacity(isPressed ? 0.82 : 1.0)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .contentShape(Circle())
            .offset(
                x: dragOffset.width + currentTranslation.width,
                y: dragOffset.height + currentTranslation.height
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isPressed {
                            isPressed = true
                        }
                        currentTranslation = value.translation
                    }
                    .onEnded { value in
                        isPressed = false
                        
                        let dragDistance = hypot(value.translation.width, value.translation.height)
                        
                        // 1. Click / Tap
                        if dragDistance < 2 {
                            currentTranslation = .zero
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            onTap()
                            return
                        }
                        
                        // 2. Drag
                        var finalX = dragOffset.width + value.translation.width
                        var finalY = dragOffset.height + value.translation.height
                        
                        // Limitation prevent out of screen
                        finalX = min(max(finalX, maxLeftOffset), 0)
                        finalY = min(max(finalY, maxTopOffset), 0)
                        
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
        DraggableFAB {
            print("Tapped FAB")
        }
    }
}
