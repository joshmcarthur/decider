import SwiftUI

struct AnimatedSelectionView: View {
    let items: [String]
    let onComplete: (String) -> Void

    @State private var currentIndex = 0
    @State private var showingConfetti = false
    @State private var isSpinning = false
    @State private var scale = 1.0
    @State private var opacity = 1.0
    @State private var selectedItem: String?
    @State private var errorMessage: String?

    private let spinDuration = 2.0
    private let spinItems = 20 // Number of items to show during spin

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                if let selected = selectedItem {
                    // Show selected item
                    Text(selected)
                        .font(.title)
                        .fontWeight(.bold)
                        .scaleEffect(scale)
                        .opacity(opacity)

                    Button("Try again") {
                        withAnimation {
                            selectedItem = nil
                            errorMessage = nil
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.tint)
                } else {
                    // Show spinning text and button
                    Text(isSpinning ? items[currentIndex] : "Ready!")
                        .font(.title)
                        .fontWeight(.bold)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .animation(.easeInOut(duration: 0.15), value: currentIndex)

                    if let error = errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        if items.count < 2 {
                            errorMessage = "Add one more item to make a decision"
                            return
                        }
                        startSpinning()
                    } label: {
                        Image(systemName: "dice")
                            .font(.system(size: 50))
                            .symbolEffect(.bounce.down, options: .repeating, value: isSpinning)
                            .foregroundStyle(items.count < 2 ? Color.secondary : Color.accentColor)
                    }
                    .disabled(isSpinning || items.count < 2)
                }
            }

            if showingConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
    }

    private func startSpinning() {
        isSpinning = true
        showingConfetti = false
        selectedItem = nil

        // Start with fast spinning
        spinThroughItems(interval: 0.05, count: spinItems) {
            // Slow down
            spinThroughItems(interval: 0.1, count: 8) {
                // Final slowdown
                spinThroughItems(interval: 0.2, count: 4) {
                    // Pick final item
                    let finalItem = items.randomElement() ?? items[0]
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        scale = 1.3
                        showingConfetti = true
                        selectedItem = finalItem
                    }

                    // Reset scale
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            scale = 1.0
                        }
                    }

                    // Hide confetti after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            showingConfetti = false
                        }
                    }

                    isSpinning = false
                    onComplete(finalItem)
                }
            }
        }
    }

    private func spinThroughItems(interval: TimeInterval, count: Int, completion: @escaping () -> Void) {
        var remainingSpins = count

        func spin() {
            guard remainingSpins > 0 else {
                completion()
                return
            }

            currentIndex = Int.random(in: 0..<items.count)
            remainingSpins -= 1

            DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                spin()
            }
        }

        spin()
    }
}

struct ConfettiView: View {
    @State private var isVisible = false

    let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange]

    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<50, id: \.self) { _ in
                ConfettiParticle(
                    color: colors.randomElement() ?? .red,
                    size: CGFloat.random(in: 5...10),
                    position: CGPoint(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: geometry.size.height
                    ),
                    duration: Double.random(in: 1.5...2.5)
                )
            }
        }
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                isVisible = true
            }
        }
    }
}

struct ConfettiParticle: View {
    let color: Color
    let size: CGFloat
    let position: CGPoint
    let duration: Double

    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .position(position)
            .offset(y: isAnimating ? -500 : 0)
            .opacity(isAnimating ? 0 : 1)
            .onAppear {
                withAnimation(
                    .easeOut(duration: duration)
                    .delay(Double.random(in: 0...0.5))
                ) {
                    isAnimating = true
                }
            }
    }
}

#Preview {
    AnimatedSelectionView(
        items: ["Pizza", "Sushi", "Burgers"],
        onComplete: { _ in }
    )
}
