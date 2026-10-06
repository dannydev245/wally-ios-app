//
//  DraggableFAB.swift
//  RandumApp
//
//  Created by dannyduy on 6/10/26.
//

import SwiftUI

struct DraggableFAB: View {
    var onTap: () -> Void
    
    private let buttonSize: CGFloat = 58
    
    @State private var position: CGPoint = .zero
    @State private var isInitialized: Bool = false
    @State private var dragOffset: CGSize = .zero
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            // MARK: - Floating Circle Body
            ZStack {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: buttonSize, height: buttonSize)
                    .shadow(
                        color: AppColors.primary.opacity(isPressed ? 0.2 : 0.4),
                        radius: isPressed ? 4 : 8,
                        x: 0,
                        y: isPressed ? 2 : 4
                    )
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            // Recover blur and scale animation when tap
            .opacity(isPressed ? 0.82 : 1.0)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .contentShape(Circle())
            .position(
                x: (isInitialized ? position.x : (screenWidth - buttonSize / 2 - 20)) + dragOffset.width,
                y: (isInitialized ? position.y : (screenHeight - buttonSize / 2 - 24)) + dragOffset.height
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isInitialized {
                            position = CGPoint(
                                x: screenWidth - buttonSize / 2 - 20,
                                y: screenHeight - buttonSize / 2 - 24
                            )
                            isInitialized = true
                        }
                        
                        // Active tap animation
                        if !isPressed {
                            isPressed = true
                        }
                        
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        // Release tapp animation
                        isPressed = false
                        
                        let dragDistance = hypot(value.translation.width, value.translation.height)
                        
                        // 1. Recognize Tap operation
                        if dragDistance < 2 {
                            dragOffset = .zero
                            
                            // Produces a slight vibration upon successful press
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            
                            onTap()
                            return
                        }
                        
                        // 2. Recognize Drag operation
                        let newX = position.x + value.translation.width
                        var newY = position.y + value.translation.height
                        
                        let minX = buttonSize / 2 + 16
                        let maxX = screenWidth - buttonSize / 2 - 16
                        let minY = buttonSize / 2 + safeArea.top + 20
                        let maxY = screenHeight - buttonSize / 2 - 24
                        
                        newY = min(max(newY, minY), maxY)
                        let snapX = newX < (screenWidth / 2) ? minX : maxX
                        
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            position = CGPoint(x: snapX, y: newY)
                            dragOffset = .zero
                        }
                    }
            )
            .onAppear {
                if !isInitialized {
                    position = CGPoint(
                        x: screenWidth - buttonSize / 2 - 20,
                        y: screenHeight - buttonSize / 2 - 24
                    )
                    isInitialized = true
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        DraggableFAB {
            print("Tapped FAB123")
        }
    }
}
