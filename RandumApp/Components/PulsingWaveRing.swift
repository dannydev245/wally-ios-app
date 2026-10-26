//
//  PulsingWaveRing.swift
//  RandumApp
//
//  Created by dannyduy on 26/10/26.
//

import SwiftUI

struct PulsingWaveRing: View {
    let color: Color
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.35), lineWidth: 3)
                .frame(width: 80, height: 80)
                .scaleEffect(isPulsing ? 1.55 : 1.0)
                .opacity(isPulsing ? 0 : 0.8)
            
            Circle()
                .stroke(color.opacity(0.25), lineWidth: 2)
                .frame(width: 80, height: 80)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0 : 0.6)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}
