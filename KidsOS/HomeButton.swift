//
//  HomeButton.swift
//  KidsOS
//
//  Created by Tobias Bleckert on 2026-02-03.
//

import SwiftUI

struct HomeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.45))
                    .frame(width: 52, height: 52)

                Image(systemName: "house.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .accessibilityLabel(Text("Hem"))
    }
}

#Preview {
    HomeButton(action: {})
}
