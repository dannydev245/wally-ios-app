//
//  WelcomeScreen.swift
//  RandumApp
//
//  Created by dannyduy on 2/10/26.
//

import SwiftUI

struct WelcomeScreen: View {
    let onGetStarted: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            
            ZStack(alignment: .top) {
                // Banner
                ZStack {
                    AppColors.primary
                        .ignoresSafeArea()
                    
                    VStack() {
                        Spacer()
                        
                        ZStack {
                            // Blur Card Behind
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.12))
                                .frame(width: 320, height: 260)
                                .rotationEffect(.degrees(12))
                            
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.16))
                                .frame(width: 320, height: 260)
                                .rotationEffect(.degrees(6))
                            
                            // Center Card
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.2))
                                .frame(width: 320, height: 260)
                                .overlay(
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Circle()
                                                .fill(.white)
                                                .frame(width: 24, height: 24)
                                            Rectangle()
                                                .fill(.white.opacity(0.8))
                                                .frame(width: 200, height: 8)
                                                .cornerRadius(4)
                                            Spacer()
                                        }
                                        
                                        // Bar Chart
                                        HStack(alignment: .bottom, spacing: 12) {
                                            RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.5)).frame(width: 30, height: 100)
                                            RoundedRectangle(cornerRadius: 4).fill(.white).frame(width: 30, height: 75)
                                            RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.7)).frame(width: 30, height: 160)
                                            RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.4)).frame(width: 30, height: 50)
                                        }
                                        .padding(.top, 4)
                                    }
                                        .padding(24)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, screenHeight * 0.05)
                }
                .frame(width: geometry.size.width, height: screenHeight * 0.7)
                
                // Content
                VStack(alignment: .center, spacing: 14) {
                    Spacer().frame(height: 4)
                    
                    Text("Wally")
                        .font(.system(size: 30, weight: .heavy))
                        .tracking(2)
                        .foregroundStyle(AppColors.primary)
                    
                    Text("Take Control of Your Money")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Track your spending, manage your budget, and build better financial habits.")
                        .font(.system(size: 15))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 12)
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        AppButton(title: "Get Started") {
                            onGetStarted()
                        }
                        
                        Text("Your finances, all in one place.")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 36)
                .frame(width: geometry.size.width, height: screenHeight * 0.42)
                .background(
                    Color(.systemBackground)
                        .cornerRadiusTop(36)
                )
                .offset(y: screenHeight * 0.58)
            }
        }
        .ignoresSafeArea(.all)
    }
}

#Preview {
    WelcomeScreen {
        print("!")
    }
}
