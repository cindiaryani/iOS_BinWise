import SwiftUI

/// China's mandatory 4-bin waste classification categories.
enum WasteCategory: String, Codable, CaseIterable {
    case recyclable
    case hazardous
    case kitchen
    case other

    /// Official Chinese bin name.
    var chineseName: String {
        switch self {
        case .recyclable: return "可回收物"
        case .hazardous:  return "有害垃圾"
        case .kitchen:    return "厨余垃圾"
        case .other:      return "其他垃圾"
        }
    }

    /// English bin name.
    var englishName: String {
        switch self {
        case .recyclable: return "Recyclable"
        case .hazardous:  return "Hazardous"
        case .kitchen:    return "Kitchen Waste"
        case .other:      return "Other Trash"
        }
    }

    /// Brand color from the design system.
    var color: Color {
        switch self {
        case .recyclable: return DS.Category.recyclable
        case .hazardous:  return DS.Category.hazardous
        case .kitchen:    return DS.Category.kitchen
        case .other:      return DS.Category.other
        }
    }

    /// SF Symbol name used in category badges.
    var iconName: String {
        switch self {
        case .recyclable: return "arrow.3.trianglepath"
        case .hazardous:  return "exclamationmark.triangle.fill"
        case .kitchen:    return "leaf.fill"
        case .other:      return "trash.fill"
        }
    }
}
