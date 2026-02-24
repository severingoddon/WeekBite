import SwiftUI

struct TourOverlayView: View {
    @Environment(TourManager.self) private var tourManager

    let anchors: [String: Anchor<CGRect>]
    let proxy: GeometryProxy

    var body: some View {
        if tourManager.isActive, let step = tourManager.currentStep,
           let anchor = anchors[step.anchorID] {
            let frame = proxy[anchor]

            ZStack {
                // Dimming background with spotlight cutout
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .reverseMask {
                        RoundedRectangle(cornerRadius: 8)
                            .frame(width: frame.width + 16, height: frame.height + 16)
                            .position(x: frame.midX, y: frame.midY)
                    }
                    .onTapGesture {
                        tourManager.endTour()
                    }

                // Tooltip
                tooltipView(step: step, targetFrame: frame)
            }
            .animation(.easeInOut(duration: 0.3), value: tourManager.currentIndex)
        }
    }

    @ViewBuilder
    private func tooltipView(step: TourStep, targetFrame: CGRect) -> some View {
        let tooltipWidth: CGFloat = 280

        VStack(alignment: .leading, spacing: 8) {
            Text(step.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(WBColor.textPrimary)

            Text(step.text)
                .font(.system(size: 13))
                .foregroundStyle(WBColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text("\(tourManager.currentIndex + 1) / \(tourManager.totalSteps)")
                    .font(.system(size: 12))
                    .foregroundStyle(WBColor.textMuted)

                Spacer()

                Button("Überspringen") {
                    tourManager.endTour()
                }
                .font(.system(size: 13))
                .foregroundStyle(WBColor.textMuted)

                GradientButton(
                    title: tourManager.currentIndex == tourManager.totalSteps - 1 ? "Fertig" : "Weiter"
                ) {
                    tourManager.nextStep()
                }
            }
        }
        .padding(16)
        .frame(width: tooltipWidth)
        .background(WBColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(WBColor.accentCyan.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: WBColor.accentCyan.opacity(0.15), radius: 15)
        .position(tooltipPosition(step: step, targetFrame: targetFrame, tooltipWidth: tooltipWidth))
    }

    private func tooltipPosition(step: TourStep, targetFrame: CGRect, tooltipWidth: CGFloat) -> CGPoint {
        let tooltipHeight: CGFloat = 160
        let gap: CGFloat = 16
        let screenWidth = UIScreen.main.bounds.width

        switch step.position {
        case .bottom:
            return CGPoint(
                x: clampX(targetFrame.midX, width: tooltipWidth, screenWidth: screenWidth),
                y: targetFrame.maxY + gap + tooltipHeight / 2
            )
        case .top:
            return CGPoint(
                x: clampX(targetFrame.midX, width: tooltipWidth, screenWidth: screenWidth),
                y: targetFrame.minY - gap - tooltipHeight / 2
            )
        case .left:
            return CGPoint(
                x: targetFrame.minX - gap - tooltipWidth / 2,
                y: targetFrame.midY
            )
        case .right:
            return CGPoint(
                x: targetFrame.maxX + gap + tooltipWidth / 2,
                y: targetFrame.midY
            )
        }
    }

    private func clampX(_ x: CGFloat, width: CGFloat, screenWidth: CGFloat) -> CGFloat {
        let padding: CGFloat = 12
        let minX = padding + width / 2
        let maxX = screenWidth - padding - width / 2
        return min(max(x, minX), maxX)
    }
}

extension View {
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask(
            Rectangle()
                .ignoresSafeArea()
                .overlay(
                    mask()
                        .blendMode(.destinationOut)
                )
        )
    }
}
