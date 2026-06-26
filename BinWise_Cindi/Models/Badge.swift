import Foundation

/// A gamification milestone badge awarded at key usage milestones.
struct Badge: Identifiable {
    /// Stable string identifier used by GamificationService.
    let id: String
    /// Bilingual badge title shown in the UI.
    let title: String
    /// Short description of what the user did to earn it.
    let description: String
    /// SF Symbol name for the badge icon.
    let icon: String
    /// True when the user has met the unlock criteria.
    let unlocked: Bool
}
