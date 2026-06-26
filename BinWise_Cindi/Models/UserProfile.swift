import Foundation

struct UserProfile {
    let uid: String
    let email: String
    let displayName: String?
    let joinDate: Date

    var firstNameOrEmail: String {
        if let name = displayName, !name.isEmpty {
            return name.components(separatedBy: " ").first ?? name
        }
        return email.components(separatedBy: "@").first ?? email
    }

    var initials: String {
        if let name = displayName, !name.isEmpty {
            let parts = name.components(separatedBy: " ").prefix(2)
            return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
        }
        return String(email.prefix(1)).uppercased()
    }
}
