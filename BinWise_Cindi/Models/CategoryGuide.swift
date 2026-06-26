import SwiftUI

/// One animated step in a category's sorting preparation sequence.
struct SortingStep: Identifiable {
    let id: Int
    let iconName: String     // SF Symbol
    let titleEN: String
    let titleCN: String
}

/// Static guide for one of China's 4 waste categories.
struct CategoryGuide: Identifiable {
    let id: WasteCategory
    let titleEN: String
    let titleCN: String
    let subtitleEN: String
    let subtitleCN: String
    let binColor: Color
    let examples: [String]   // bilingual example item names
    let steps: [SortingStep]

    // MARK: – Static data set

    static let all: [CategoryGuide] = [recyclable, hazardous, kitchen, other]

    static let recyclable = CategoryGuide(
        id: .recyclable,
        titleEN: "Recyclable",
        titleCN: "可回收物",
        subtitleEN: "Clean, reusable materials",
        subtitleCN: "可重复利用的干净材料",
        binColor: DS.Category.recyclable,
        examples: ["Plastic bottle / 塑料瓶", "Cardboard / 纸板", "Metal can / 金属罐", "Glass jar / 玻璃瓶"],
        steps: [
            SortingStep(id: 0, iconName: "trash",               titleEN: "Empty it",      titleCN: "清空内容"),
            SortingStep(id: 1, iconName: "drop",                titleEN: "Rinse clean",   titleCN: "清洗干净"),
            SortingStep(id: 2, iconName: "arrow.down.to.line",  titleEN: "Flatten/fold",  titleCN: "压扁折叠"),
            SortingStep(id: 3, iconName: "archivebox.fill",     titleEN: "Blue bin",      titleCN: "投入蓝色桶"),
        ]
    )

    static let hazardous = CategoryGuide(
        id: .hazardous,
        titleEN: "Hazardous",
        titleCN: "有害垃圾",
        subtitleEN: "Items that need special disposal",
        subtitleCN: "需要特殊处理的有害物品",
        binColor: DS.Category.hazardous,
        examples: ["Battery / 电池", "Fluorescent bulb / 荧光灯管", "Medicine / 过期药品", "Paint / 油漆"],
        steps: [
            SortingStep(id: 0, iconName: "exclamationmark.shield.fill", titleEN: "Don't break/puncture", titleCN: "请勿打碎或刺破"),
            SortingStep(id: 1, iconName: "bag.fill",                    titleEN: "Seal in original bag",  titleCN: "放入原包装袋密封"),
            SortingStep(id: 2, iconName: "exclamationmark.triangle.fill", titleEN: "Special red bin",     titleCN: "投入红色有害垃圾桶"),
        ]
    )

    static let kitchen = CategoryGuide(
        id: .kitchen,
        titleEN: "Kitchen Waste",
        titleCN: "厨余垃圾",
        subtitleEN: "Food scraps and organic matter",
        subtitleCN: "厨余食物及有机物",
        binColor: DS.Category.kitchen,
        examples: ["Food scraps / 剩菜剩饭", "Fruit peel / 果皮", "Small bones / 小骨头", "Tea leaves / 茶叶"],
        steps: [
            SortingStep(id: 0, iconName: "drop.triangle",       titleEN: "Drain excess liquid", titleCN: "沥干多余水分"),
            SortingStep(id: 1, iconName: "fork.knife",          titleEN: "Remove packaging",    titleCN: "去除食品包装"),
            SortingStep(id: 2, iconName: "leaf.fill",           titleEN: "Green bin",           titleCN: "投入绿色厨余桶"),
        ]
    )

    static let other = CategoryGuide(
        id: .other,
        titleEN: "Other Trash",
        titleCN: "其他垃圾",
        subtitleEN: "Non-recyclable dry waste",
        subtitleCN: "不可回收的干性废弃物",
        binColor: DS.Category.other,
        examples: ["Tissue paper / 纸巾", "Broken ceramics / 破碎陶瓷", "Disposable cup / 一次性杯子", "Straw / 吸管"],
        steps: [
            SortingStep(id: 0, iconName: "shield",              titleEN: "Wrap sharp items",   titleCN: "包裹尖锐物品"),
            SortingStep(id: 1, iconName: "bag",                 titleEN: "Bag it up",          titleCN: "装入袋中"),
            SortingStep(id: 2, iconName: "trash.fill",          titleEN: "Grey/black bin",     titleCN: "投入灰色其他垃圾桶"),
        ]
    )

    /// Returns the guide for a given WasteCategory, or `.other` as fallback.
    static func guide(for category: WasteCategory) -> CategoryGuide {
        all.first { $0.id == category } ?? other
    }
}
