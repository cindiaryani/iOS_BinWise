import Foundation

// MARK: – Model

/// A single waste-sorting quiz question.
struct QuizItem: Identifiable {
    let id = UUID()
    /// English item name shown on the quiz card.
    let name: String
    /// Chinese name shown below the English name.
    let chineseName: String
    /// The correct China 4-bin category for this item.
    let correctCategory: WasteCategory
    /// Short bilingual explanation shown after the user answers.
    let explanation: String
}

// MARK: – Item bank (18 items incl. China's famous tricky cases)

/// Static item bank shuffled by QuizViewModel. Includes edge-cases tested in
/// China's mandatory 垃圾分类 inspections (greasy paper, bone size, used tissues, etc.).
let quizItemBank: [QuizItem] = [
    QuizItem(
        name: "Rinsed plastic bottle",
        chineseName: "洗净的塑料瓶",
        correctCategory: .recyclable,
        explanation: "Rinsed bottles are clean recyclables. / 洗净的瓶子属可回收物。"
    ),
    QuizItem(
        name: "Greasy pizza box",
        chineseName: "油腻披萨盒",
        correctCategory: .other,
        explanation: "Grease contaminates paper recycling — bin it as Other Trash. / 油腻纸盒无法回收，归入其他垃圾。"
    ),
    QuizItem(
        name: "Fruit peel",
        chineseName: "果皮",
        correctCategory: .kitchen,
        explanation: "Fruit peel is organic kitchen waste. / 果皮属于厨余垃圾。"
    ),
    QuizItem(
        name: "Small chicken bone",
        chineseName: "小鸡骨头",
        correctCategory: .kitchen,
        explanation: "Small soft bones decompose — they count as kitchen waste. / 小骨头可降解，属厨余垃圾。"
    ),
    QuizItem(
        name: "Large pork bone",
        chineseName: "大猪骨",
        correctCategory: .other,
        explanation: "Large hard bones cannot be processed at kitchen-waste facilities. / 大骨头坚硬，归入其他垃圾。"
    ),
    QuizItem(
        name: "Used tissue paper",
        chineseName: "用过的纸巾",
        correctCategory: .other,
        explanation: "Used tissues are contaminated and cannot be recycled. / 用过的纸巾已污染，属其他垃圾。"
    ),
    QuizItem(
        name: "Rinsed milk carton",
        chineseName: "洗净的牛奶盒",
        correctCategory: .recyclable,
        explanation: "A clean, dry carton is recyclable paper. / 洗净的纸盒属可回收物。"
    ),
    QuizItem(
        name: "Dead battery",
        chineseName: "废旧电池",
        correctCategory: .hazardous,
        explanation: "Batteries contain heavy metals — always hazardous waste. / 电池含重金属，属有害垃圾。"
    ),
    QuizItem(
        name: "Broken ceramic mug",
        chineseName: "破陶瓷杯",
        correctCategory: .other,
        explanation: "Ceramics cannot be melted down and recycled. / 陶瓷不可回收，归入其他垃圾。"
    ),
    QuizItem(
        name: "Expired medicine",
        chineseName: "过期药品",
        correctCategory: .hazardous,
        explanation: "Expired medicine is pharmaceutical hazardous waste. / 过期药品属有害垃圾。"
    ),
    QuizItem(
        name: "Styrofoam packaging",
        chineseName: "泡沫塑料",
        correctCategory: .other,
        explanation: "Most cities in China don't accept expanded polystyrene for recycling. / 大多数城市不回收泡沫塑料，归入其他垃圾。"
    ),
    QuizItem(
        name: "Newspaper",
        chineseName: "报纸",
        correctCategory: .recyclable,
        explanation: "Clean, dry newspaper is recyclable paper. / 干净的报纸属可回收物。"
    ),
    QuizItem(
        name: "Old paint can",
        chineseName: "旧油漆桶",
        correctCategory: .hazardous,
        explanation: "Paint and solvents are chemical hazardous waste. / 油漆含有害化学物质，属有害垃圾。"
    ),
    QuizItem(
        name: "Leftover cooked rice",
        chineseName: "剩米饭",
        correctCategory: .kitchen,
        explanation: "Cooked food scraps are organic kitchen waste. / 剩饭属于厨余垃圾。"
    ),
    QuizItem(
        name: "Aluminium drinks can",
        chineseName: "铝制饮料罐",
        correctCategory: .recyclable,
        explanation: "Metal cans are among the most recyclable materials. / 金属罐属可回收物。"
    ),
    QuizItem(
        name: "Mercury thermometer (broken)",
        chineseName: "碎水银温度计",
        correctCategory: .hazardous,
        explanation: "Mercury is highly toxic — always hazardous. / 汞有剧毒，属有害垃圾，需专门处置。"
    ),
    QuizItem(
        name: "Clean cardboard box",
        chineseName: "干净纸板箱",
        correctCategory: .recyclable,
        explanation: "Clean, flat cardboard is recyclable. / 干净纸板属可回收物。"
    ),
    QuizItem(
        name: "Tea leaves",
        chineseName: "茶叶渣",
        correctCategory: .kitchen,
        explanation: "Tea leaves are organic and belong in kitchen waste. / 茶叶渣属于厨余垃圾。"
    ),
]
