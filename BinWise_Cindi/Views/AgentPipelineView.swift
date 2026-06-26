import SwiftUI

/// The centerpiece UI: a three-step vertical stepper that animates as the pipeline advances.
/// Each step shows pending (gray), active (spinning), or done (green checkmark) state.
struct AgentPipelineView: View {

    let stage: PipelineStage

    // MARK: – Step model

    private enum Step: Int, CaseIterable {
        case vision = 0, interpreter, advisor

        var title: String {
            switch self {
            case .vision:      return "Vision"
            case .interpreter: return "Interpreter Agent"
            case .advisor:     return "Advisor Agent"
            }
        }
        var subtitle: String {
            switch self {
            case .vision:      return "Identifying object"
            case .interpreter: return "Determining category"
            case .advisor:     return "Disposal guidance"
            }
        }
        var icon: String {
            switch self {
            case .vision:      return "camera.metering.center.weighted"
            case .interpreter: return "brain.head.profile"
            case .advisor:     return "text.bubble.fill"
            }
        }
    }

    // MARK: – Stage → active index

    private var activeIndex: Int {
        switch stage {
        case .detecting:    return 0
        case .interpreting: return 1
        case .advising:     return 2
        default:            return -1
        }
    }

    // MARK: – Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Step.allCases, id: \.rawValue) { step in
                stepRow(step)
                if step != .advisor {
                    connectorLine(doneAbove: isDone(step))
                }
            }
        }
        .padding(DS.Spacing.md)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    // MARK: – Row

    private func stepRow(_ step: Step) -> some View {
        HStack(spacing: DS.Spacing.md) {
            indicator(for: step)
            labels(for: step)
            Spacer()
        }
        .padding(.vertical, DS.Spacing.sm)
    }

    // MARK: – Indicator circle

    @ViewBuilder
    private func indicator(for step: Step) -> some View {
        ZStack {
            Circle()
                .fill(circleColor(for: step))
                .frame(width: 36, height: 36)

            if isDone(step) {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            } else if isActive(step) {
                SpinnerView()
            } else {
                Image(systemName: step.icon)
                    .font(.system(size: 14))
                    .foregroundColor(DS.textSecondary)
            }
        }
    }

    private func circleColor(for step: Step) -> Color {
        if isDone(step)   { return DS.success }
        if isActive(step) { return DS.primary }
        return DS.border
    }

    // MARK: – Labels

    private func labels(for step: Step) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(step.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(isActive(step) || isDone(step) ? DS.textPrimary : DS.textSecondary)
                .animation(.easeInOut, value: stage)
            Text(step.subtitle)
                .font(.caption)
                .foregroundColor(DS.textSecondary)
        }
    }

    // MARK: – Connector

    private func connectorLine(doneAbove: Bool) -> some View {
        Rectangle()
            .fill(doneAbove ? DS.success.opacity(0.4) : DS.border)
            .frame(width: 2, height: 14)
            .padding(.leading, 17)
            .animation(.easeInOut, value: doneAbove)
    }

    // MARK: – State helpers

    private func isDone(_ step: Step) -> Bool {
        switch stage {
        case .interpreting: return step.rawValue < 1
        case .advising:     return step.rawValue < 2
        case .complete:     return true
        default:            return false
        }
    }

    private func isActive(_ step: Step) -> Bool {
        step.rawValue == activeIndex
    }
}

// MARK: – Spinner

/// Rotating arrow icon used for the active pipeline step.
struct SpinnerView: View {
    @State private var rotating = false

    var body: some View {
        Image(systemName: "arrow.triangle.2.circlepath")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .rotationEffect(.degrees(rotating ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotating = true
                }
            }
    }
}

// MARK: – Preview

struct AgentPipelineView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DS.Spacing.lg) {
            AgentPipelineView(stage: .detecting)
            AgentPipelineView(stage: .interpreting)
            AgentPipelineView(stage: .complete)
        }
        .padding()
        .background(DS.background)
    }
}
