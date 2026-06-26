import Foundation

/// Pure logic layer that adds safety and handling guidance to a classification result.
/// No UI, no network, no state — evaluate once per result and pass the advisory to the view.
struct WasteSafetyPolicy {

    /// Safety and handling guidance for a single classified waste item.
    struct SafetyAdvisory: Equatable {
        /// Short bilingual warnings (e.g. "Do not puncture / 请勿刺破"). Empty when no special risk.
        let warnings: [String]
        /// Step-by-step safe-handling instructions.
        let handlingTips: [String]
        /// True when the item must go to a dedicated special-disposal point.
        let requiresSpecialDisposal: Bool
    }

    /// Evaluates the safety policy for a classified item and returns an advisory.
    /// - Parameters:
    ///   - category: The resolved WasteCategory from the Interpreter Agent.
    ///   - objectLabel: The Core ML output label (e.g. "battery", "food_waste").
    /// - Returns: A `SafetyAdvisory` with applicable warnings and tips.
    func evaluate(category: WasteCategory, objectLabel: String) -> SafetyAdvisory {
        let label = objectLabel.lowercased()
        switch category {
        case .hazardous:
            return hazardousAdvisory(for: label)
        case .recyclable:
            return recyclableAdvisory(for: label)
        case .kitchen:
            return kitchenAdvisory(for: label)
        case .other:
            return otherAdvisory(for: label)
        }
    }

    // MARK: – Category handlers

    private func hazardousAdvisory(for label: String) -> SafetyAdvisory {
        var warnings: [String] = []
        var tips: [String] = [
            "Keep in original packaging until disposal / 保留原包装直至丢弃",
            "Take to a dedicated hazardous-waste drop-off point / 送至专用有害垃圾回收点",
        ]

        if label.contains("battery") || label.contains("batteries") {
            warnings.append("Do not puncture, crush, or incinerate / 请勿刺破、挤压或焚烧")
            warnings.append("Risk of fire or toxic leak if damaged / 损坏可能引起起火或有毒泄漏")
            tips.append("Many supermarkets have battery drop-off boxes / 许多超市设有废电池回收箱")
        } else if label.contains("bulb") || label.contains("lamp") || label.contains("light") || label.contains("mercury") {
            warnings.append("Handle carefully — do not break / 小心轻放，请勿打碎")
            warnings.append("Broken bulbs release toxic mercury vapour / 碎裂灯管会释放有毒汞蒸气")
            tips.append("Place in a rigid box before depositing / 放入硬盒后再投放")
        } else if label.contains("medicine") || label.contains("drug") || label.contains("pill") || label.contains("pharmaceutical") {
            warnings.append("Do not crush or dissolve down the drain / 请勿研碎或冲入下水道")
            warnings.append("Expired medicine can contaminate groundwater / 过期药品可能污染地下水")
            tips.append("Return to a pharmacy for safe disposal / 请交回药店进行安全处理")
        } else if label.contains("paint") || label.contains("solvent") || label.contains("chemical") {
            warnings.append("Keep tightly sealed to prevent vapour release / 请密封防止挥发")
            warnings.append("Do not pour down drains / 请勿倒入下水道")
        }

        return SafetyAdvisory(
            warnings: warnings,
            handlingTips: tips,
            requiresSpecialDisposal: true
        )
    }

    private func recyclableAdvisory(for label: String) -> SafetyAdvisory {
        var warnings: [String] = []
        var tips: [String] = [
            "Rinse out any food residue before placing in the bin / 放入桶前请清洗残留食物",
            "Remove caps and lids — sort them separately if different material / 取下瓶盖，如材质不同请分开投放",
        ]

        if label.contains("glass") {
            warnings.append("Glass can break and cause injury — handle with care / 玻璃易碎，请小心操作")
            tips.append("Place in the recycling bin gently to avoid breakage / 轻放入桶避免破碎")
        } else if label.contains("metal") || label.contains("can") {
            tips.append("Crush cans to save space in the bin / 压扁金属罐以节省空间")
        } else if label.contains("paper") || label.contains("cardboard") {
            tips.append("Keep dry — wet paper cannot be recycled / 保持干燥，湿纸无法回收")
        }

        return SafetyAdvisory(
            warnings: warnings,
            handlingTips: tips,
            requiresSpecialDisposal: false
        )
    }

    private func kitchenAdvisory(for label: String) -> SafetyAdvisory {
        var warnings: [String] = []
        let tips: [String] = [
            "Drain excess liquid before disposal / 丢弃前请沥干多余水分",
            "Remove non-food packaging before placing in the kitchen-waste bin / 去除非食品包装再投入厨余桶",
            "Large hard bones (pork/beef) belong in Other Trash, not Kitchen Waste / 大骨头（猪骨/牛骨）属其他垃圾，非厨余",
        ]

        if label.contains("bone") {
            warnings.append("Large hard bones → Other Trash, not Kitchen Waste / 大骨头属其他垃圾，非厨余垃圾")
        }

        return SafetyAdvisory(
            warnings: warnings,
            handlingTips: tips,
            requiresSpecialDisposal: false
        )
    }

    private func otherAdvisory(for label: String) -> SafetyAdvisory {
        var warnings: [String] = []
        let tips: [String] = [
            "Bag securely to contain odour and prevent litter / 装入袋中防止异味和散落",
            "Tie the bag before placing in the bin / 投放前请扎紧袋口",
        ]

        if label.contains("glass") || label.contains("ceramic") || label.contains("porcelain") || label.contains("broken") {
            warnings.append("Wrap broken items in newspaper before disposal to prevent injury / 丢弃前请用报纸包好破损物以防割伤")
        }

        return SafetyAdvisory(
            warnings: warnings,
            handlingTips: tips,
            requiresSpecialDisposal: false
        )
    }
}
