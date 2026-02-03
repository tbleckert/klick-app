//
//  AlphabetView.swift
//  Klick
//
//  Created by Tobias Bleckert on 2026-02-03.
//

import SwiftUI

struct AlphabetEntry: Identifiable {
    let id = UUID()
    let letterUpper: String
    let letterLower: String
    let word: String
    let emoji: String
}

struct AlphabetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var isAdvancing = false

    private let entries: [AlphabetEntry] = [
        AlphabetEntry(letterUpper: "A", letterLower: "a", word: "apelsin", emoji: "🍊"),
        AlphabetEntry(letterUpper: "B", letterLower: "b", word: "boll", emoji: "⚽️"),
        AlphabetEntry(letterUpper: "C", letterLower: "c", word: "cykel", emoji: "🚲"),
        AlphabetEntry(letterUpper: "D", letterLower: "d", word: "drake", emoji: "🐉"),
        AlphabetEntry(letterUpper: "E", letterLower: "e", word: "elefant", emoji: "🐘"),
        AlphabetEntry(letterUpper: "F", letterLower: "f", word: "fisk", emoji: "🐟"),
        AlphabetEntry(letterUpper: "G", letterLower: "g", word: "glass", emoji: "🍦"),
        AlphabetEntry(letterUpper: "H", letterLower: "h", word: "hund", emoji: "🐶"),
        AlphabetEntry(letterUpper: "I", letterLower: "i", word: "igelkott", emoji: "🦔"),
        AlphabetEntry(letterUpper: "J", letterLower: "j", word: "jordgubbe", emoji: "🍓"),
        AlphabetEntry(letterUpper: "K", letterLower: "k", word: "katt", emoji: "🐱"),
        AlphabetEntry(letterUpper: "L", letterLower: "l", word: "lampa", emoji: "💡"),
        AlphabetEntry(letterUpper: "M", letterLower: "m", word: "måne", emoji: "🌙"),
        AlphabetEntry(letterUpper: "N", letterLower: "n", word: "nalle", emoji: "🧸"),
        AlphabetEntry(letterUpper: "O", letterLower: "o", word: "orm", emoji: "🐍"),
        AlphabetEntry(letterUpper: "P", letterLower: "p", word: "pizza", emoji: "🍕"),
        AlphabetEntry(letterUpper: "Q", letterLower: "q", word: "quiz", emoji: "❓"),
        AlphabetEntry(letterUpper: "R", letterLower: "r", word: "robot", emoji: "🤖"),
        AlphabetEntry(letterUpper: "S", letterLower: "s", word: "sol", emoji: "☀️"),
        AlphabetEntry(letterUpper: "T", letterLower: "t", word: "tåg", emoji: "🚂"),
        AlphabetEntry(letterUpper: "U", letterLower: "u", word: "uggla", emoji: "🦉"),
        AlphabetEntry(letterUpper: "V", letterLower: "v", word: "val", emoji: "🐋"),
        AlphabetEntry(letterUpper: "W", letterLower: "w", word: "wok", emoji: "🍜"),
        AlphabetEntry(letterUpper: "X", letterLower: "x", word: "xylofon", emoji: "🎶"),
        AlphabetEntry(letterUpper: "Y", letterLower: "y", word: "yxa", emoji: "🪓"),
        AlphabetEntry(letterUpper: "Z", letterLower: "z", word: "zebra", emoji: "🦓"),
        AlphabetEntry(letterUpper: "Å", letterLower: "å", word: "ål", emoji: "🐟"),
        AlphabetEntry(letterUpper: "Ä", letterLower: "ä", word: "äpple", emoji: "🍎"),
        AlphabetEntry(letterUpper: "Ö", letterLower: "ö", word: "ö", emoji: "🏝️")
    ]

    var body: some View {
        let entry = entries[index]

        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.78, blue: 0.49),
                    Color(red: 0.70, green: 0.90, blue: 0.63)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 280, height: 280)
                .offset(x: -150, y: -220)

            VStack {
                HStack {
                    HomeButton(action: {
                        dismiss()
                    })
                    .padding(.leading, 20)
                    .padding(.top, 60)

                    Spacer()
                }

                Spacer()
            }

            VStack(spacing: 18) {
                Text("\(entry.letterUpper) \(entry.letterLower)")
                    .font(.custom("Chalkboard SE", size: 120))
                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.14))
                    .shadow(color: Color.white.opacity(0.7), radius: 4, x: 0, y: 2)

                Text(entry.word)
                    .font(.custom("Chalkboard SE", size: 48))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.22))

                Text(entry.emoji)
                    .font(.system(size: 80))

                Spacer()

                Button(action: {
                    advance()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.42, green: 0.72, blue: 0.98),
                                        Color(red: 0.18, green: 0.46, blue: 0.88)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 220, height: 90)

                        Text("Nästa")
                            .font(.custom("Chalkboard SE", size: 34))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Nästa"))
                .disabled(isAdvancing)
                .padding(.bottom, 40)
            }
            .padding(.top, 80)
            .multilineTextAlignment(.center)
        }
        .onAppear {
            index = 0
        }
    }

    private func advance() {
        guard !isAdvancing else { return }
        isAdvancing = true
        index = (index + 1) % entries.count
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isAdvancing = false
        }
    }
}

#Preview {
    AlphabetView()
}
