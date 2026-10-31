//
//  DraggableFAB.swift
//  RandumApp
//
//  Created by dannyduy on 6/10/26.
//

import SwiftUI

struct DraggableFAB: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var onSelectMode: (TransactionCreationMode) -> Void
    
    private let buttonSize: CGFloat = 58
    private let subButtonSize: CGFloat = 46
    
    @State private var isOpen: Bool = false
    @State private var dragOffset: CGSize = .zero
    @State private var currentTranslation: CGSize = .zero
    @State private var isPressed: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let safeArea = geometry.safeAreaInsets
            
            let maxLeftOffset = -(screenWidth - buttonSize - 40)
            let maxTopOffset = -(screenHeight - buttonSize - safeArea.top - safeArea.bottom - 220)
            
            ZStack {
                if isOpen {
                    Color.black.opacity(0.18)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            closeMenu()
                        }
                        .transition(.opacity)
                }
                
                ZStack {
                    // Sub-button 3: Manual Input
                    subButton(
                        icon: "square.and.pencil",
                        offsetY: -180,
                        delay: 0.08
                    ) {
                        handleSelectMode(.manual)
                    }
                    
                    // Sub-button 2: Voice Input
                    subButton(
                        icon: "mic.fill",
                        offsetY: -120,
                        delay: 0.04
                    ) {
                        handleSelectMode(.voice)
                    }
                    
                    // Sub-button 1: Scan Receipt
                    subButton(
                        icon: "doc.viewfinder",
                        offsetY: -60,
                        delay: 0.0
                    ) {
                        handleSelectMode(.scan)
                    }
                    
                    ZStack {
                        Circle()
                            .fill(themeManager.currentAccent.primaryColor)
                            .frame(width: buttonSize, height: buttonSize)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(isOpen ? 45 : 0))
                    }
                    .frame(width: buttonSize, height: buttonSize)
                    .opacity(isPressed ? 0.82 : 1.0)
                    .scaleEffect(isPressed ? 0.92 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isPressed)
                }
                .offset(
                    x: dragOffset.width + currentTranslation.width,
                    y: dragOffset.height + currentTranslation.height
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard !isOpen else { return }
                            if !isPressed {
                                isPressed = true
                            }
                            currentTranslation = value.translation
                        }
                        .onEnded { value in
                            if isOpen {
                                closeMenu()
                                return
                            }
                            
                            isPressed = false
                            let dragDistance = hypot(value.translation.width, value.translation.height)
                            
                            if dragDistance < 4 {
                                currentTranslation = .zero
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    isOpen = true
                                }
                                return
                            }
                            
                            var finalX = dragOffset.width + value.translation.width
                            var finalY = dragOffset.height + value.translation.height
                            
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
    
    // MARK: - Sub Button
    @ViewBuilder
    private func subButton(
        icon: String,
        offsetY: CGFloat,
        delay: Double,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(themeManager.currentAccent.inputBackgroundColor)
                    .frame(width: subButtonSize, height: subButtonSize)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(themeManager.currentAccent.primaryColor)
            }
            .frame(width: subButtonSize, height: subButtonSize)
            .contentShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
        .offset(y: offsetY)
        .scaleEffect(isOpen ? 1.0 : 0.001)
        .opacity(isOpen ? 1.0 : 0)
        .allowsHitTesting(isOpen)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.7).delay(delay),
            value: isOpen
        )
    }
    
    private func closeMenu() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            isOpen = false
        }
    }
    
    private func handleSelectMode(_ mode: TransactionCreationMode) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        closeMenu()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onSelectMode(mode)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        DraggableFAB { mode in
            print("Tapped FAB", mode)
        }
    }
}
