import Foundation

// MARK: – Model

/// A single entry in BinWise's local China waste-sorting knowledge base.
struct WasteKnowledgeItem: Identifiable {
    /// Stable identifier used for navigation and quiz lookup.
    let id: String
    /// English name shown in UI.
    let nameEN: String
    /// Chinese name (simplified).
    let nameCN: String
    /// China 4-bin category.
    let category: WasteCategory
    /// Why this item belongs in the given category (1-2 sentences).
    let explanation: String
    /// A common incorrect assumption people make about this item, if any.
    let commonMistake: String?
    /// Practical disposal tip.
    let tips: String
    /// True for items with China-specific edge-case rules that differ from intuition.
    let isTricky: Bool
}

// MARK: – Static data

/// Complete 60-item China waste-sorting knowledge base.
/// Covers all 4 bins with representative items, famous tricky cases, and bilingual names.
enum WasteKnowledgeBase {

    // MARK: – Recyclable (可回收物)

    private static let recyclable: [WasteKnowledgeItem] = [
        WasteKnowledgeItem(
            id: "REC-001", nameEN: "Plastic Bottle", nameCN: "塑料瓶",
            category: .recyclable,
            explanation: "Clean plastic bottles are valuable recyclables. Rinse before recycling.",
            commonMistake: "Throwing away without rinsing — contamination lowers recycling value.",
            tips: "Crush flat to save space. Remove cap separately.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "REC-002", nameEN: "Cardboard Box", nameCN: "纸箱",
            category: .recyclable,
            explanation: "Dry cardboard is one of the most recyclable materials.",
            commonMistake: "Leaving tape and stickers on — remove them first.",
            tips: "Break down flat. Keep dry — wet cardboard is Other waste.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "REC-003", nameEN: "Newspaper", nameCN: "报纸",
            category: .recyclable,
            explanation: "Clean paper is highly recyclable.",
            commonMistake: nil,
            tips: "Bundle with string or put in paper bag.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "REC-004", nameEN: "Glass Bottle", nameCN: "玻璃瓶",
            category: .recyclable,
            explanation: "Intact glass bottles are recyclable. Note: broken glass goes to Other.",
            commonMistake: "Broken glass pieces — those go to Other waste, not Recyclable.",
            tips: "Rinse clean. Whole bottles only.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "REC-005", nameEN: "Metal Can", nameCN: "金属罐",
            category: .recyclable,
            explanation: "Aluminum and steel cans are highly recyclable metals.",
            commonMistake: nil,
            tips: "Rinse clean. Crush flat to save space.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "REC-006", nameEN: "Rinsed Milk Carton", nameCN: "洗净的牛奶盒",
            category: .recyclable,
            explanation: "A rinsed milk carton is clean paper — fully recyclable.",
            commonMistake: "Unrinsed milk cartons go to Other waste due to food contamination.",
            tips: "Rinse, fold flat, then recycle. Key: it must be clean.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "REC-007", nameEN: "Books & Magazines", nameCN: "书本/杂志",
            category: .recyclable,
            explanation: "Paper publications are clean recyclables.",
            commonMistake: nil,
            tips: "Remove plastic covers if present.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "REC-008", nameEN: "Metal Coat Hanger", nameCN: "金属衣架",
            category: .recyclable,
            explanation: "Metal hangers are scrap metal — recyclable.",
            commonMistake: "Mixing with plastic hangers — only metal ones are recyclable.",
            tips: "Bring to recycling point or sell to scrap collector.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "REC-009", nameEN: "Old Clothes & Fabric", nameCN: "旧衣物",
            category: .recyclable,
            explanation: "China's system includes clothing as recyclable for reuse/donation programs.",
            commonMistake: "Throwing away wearable clothes — they can be donated.",
            tips: "Donate wearable items. Place in designated clothing recycling bins.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "REC-010", nameEN: "Clean Plastic Bag", nameCN: "干净的塑料袋",
            category: .recyclable,
            explanation: "Clean, dry plastic bags can be recycled.",
            commonMistake: "Dirty or greasy bags must go to Other waste.",
            tips: "Must be visibly clean and dry. Bundle several together.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "REC-011", nameEN: "Rinsed Yogurt Cup", nameCN: "洗净的酸奶杯",
            category: .recyclable,
            explanation: "Rinsed plastic food containers are recyclable.",
            commonMistake: "Unrinsed containers with food residue go to Other waste.",
            tips: "Rinse thoroughly. Check for recycling symbol.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "REC-012", nameEN: "Aluminum Foil (clean)", nameCN: "干净的铝箔纸",
            category: .recyclable,
            explanation: "Clean aluminum foil is a recyclable metal.",
            commonMistake: "Dirty or greasy foil must go to Other waste.",
            tips: "Only if visibly clean with no food residue.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "REC-013", nameEN: "Laptop / Tablet", nameCN: "笔记本电脑/平板",
            category: .recyclable,
            explanation: "Electronics contain recyclable metals and materials. Bring to e-waste point.",
            commonMistake: nil,
            tips: "Factory reset before recycling. Use designated e-waste collection points.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "REC-014", nameEN: "Printer Paper (clean)", nameCN: "打印纸(干净)",
            category: .recyclable,
            explanation: "Clean office paper is recyclable.",
            commonMistake: "Shredded paper is hard to recycle — check local rules.",
            tips: "Keep dry. Can include staples — sorters remove them.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "REC-015", nameEN: "Cardboard Egg Tray", nameCN: "纸质蛋托",
            category: .recyclable,
            explanation: "Clean cardboard egg trays are recyclable paper.",
            commonMistake: "Foam/styrofoam egg trays go to Other waste.",
            tips: "Must be clean and dry, no egg residue.",
            isTricky: true
        ),
    ]

    // MARK: – Hazardous (有害垃圾)

    private static let hazardous: [WasteKnowledgeItem] = [
        WasteKnowledgeItem(
            id: "HAZ-001", nameEN: "Battery (AA/AAA)", nameCN: "电池(5号/7号)",
            category: .hazardous,
            explanation: "All batteries contain toxic chemicals harmful to soil and water.",
            commonMistake: "Throwing in regular trash — illegal and harmful.",
            tips: "Use designated battery collection boxes in supermarkets and communities.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "HAZ-002", nameEN: "Fluorescent Light Bulb", nameCN: "荧光灯管",
            category: .hazardous,
            explanation: "Contains mercury — a hazardous heavy metal.",
            commonMistake: "LED bulbs are Other waste; fluorescent bulbs are Hazardous.",
            tips: "Handle carefully, don't break. Use designated disposal points.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "HAZ-003", nameEN: "Medicine / Pills", nameCN: "药品/药片",
            category: .hazardous,
            explanation: "Expired or unused medicine can contaminate water if landfilled.",
            commonMistake: "Flushing down toilet — pollutes water supply.",
            tips: "Return to pharmacy. Never flush or throw in regular trash.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "HAZ-004", nameEN: "Pesticide / Insecticide", nameCN: "杀虫剂",
            category: .hazardous,
            explanation: "Chemical pesticides are toxic — classified Hazardous.",
            commonMistake: nil,
            tips: "Never pour down drain. Use hazardous waste collection points.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "HAZ-005", nameEN: "Paint Can (with residue)", nameCN: "油漆桶(有残留)",
            category: .hazardous,
            explanation: "Paint contains volatile chemicals. Empty dry cans may be recyclable.",
            commonMistake: "Empty dried-out cans are sometimes Other; cans with wet paint are Hazardous.",
            tips: "Let paint dry completely in can if possible before disposal.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "HAZ-006", nameEN: "Thermometer (mercury)", nameCN: "水银温度计",
            category: .hazardous,
            explanation: "Mercury thermometers contain highly toxic mercury.",
            commonMistake: "Digital thermometers are Other waste; mercury ones are Hazardous.",
            tips: "If broken, do NOT touch mercury. Call local environmental authority.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "HAZ-007", nameEN: "Nail Polish / Remover", nameCN: "指甲油/洗甲水",
            category: .hazardous,
            explanation: "Acetone and chemical pigments make these Hazardous.",
            commonMistake: nil,
            tips: "Use designated hazardous waste collection.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "HAZ-008", nameEN: "Printer Ink Cartridge", nameCN: "打印机墨盒",
            category: .hazardous,
            explanation: "Contains chemical inks that are hazardous to environment.",
            commonMistake: nil,
            tips: "Many printer brands offer take-back programs.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "HAZ-009", nameEN: "Smartphone", nameCN: "智能手机",
            category: .hazardous,
            explanation: "Phone batteries contain lithium — classified as Hazardous in China.",
            commonMistake: "Many people treat it as Recyclable — but the battery makes it Hazardous.",
            tips: "Factory reset. Use phone brand's take-back program or e-waste point.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "HAZ-010", nameEN: "Expired Cosmetics", nameCN: "过期化妆品",
            category: .hazardous,
            explanation: "Expired chemical formulas can be hazardous.",
            commonMistake: nil,
            tips: "Return to brand stores that offer take-back, or use hazardous collection.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "HAZ-011", nameEN: "Weed Killer / Herbicide", nameCN: "除草剂",
            category: .hazardous,
            explanation: "Chemical herbicides are toxic to ecosystem.",
            commonMistake: nil,
            tips: "Never pour down drain or in garden soil. Use hazardous disposal.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "HAZ-012", nameEN: "Car Battery", nameCN: "汽车电池",
            category: .hazardous,
            explanation: "Lead-acid batteries are highly toxic.",
            commonMistake: nil,
            tips: "Return to auto shop or gas station — most accept them for recycling.",
            isTricky: false
        ),
    ]

    // MARK: – Kitchen / Wet (厨余垃圾)

    private static let kitchen: [WasteKnowledgeItem] = [
        WasteKnowledgeItem(
            id: "KIT-001", nameEN: "Fruit Peel", nameCN: "果皮",
            category: .kitchen,
            explanation: "Fruit peels are organic and compostable.",
            commonMistake: nil,
            tips: "Can include in Kitchen waste with no preparation needed.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "KIT-002", nameEN: "Vegetable Scraps", nameCN: "菜叶菜根",
            category: .kitchen,
            explanation: "Raw vegetable parts are organic kitchen waste.",
            commonMistake: nil,
            tips: "Include stems, roots, leaves — all organic.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "KIT-003", nameEN: "Leftover Rice / Noodles", nameCN: "剩饭剩面",
            category: .kitchen,
            explanation: "Cooked grain leftovers are Kitchen waste.",
            commonMistake: nil,
            tips: "Drain excess liquid before placing in bin.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "KIT-004", nameEN: "Small Chicken Bone", nameCN: "小鸡骨头",
            category: .kitchen,
            explanation: "Small soft bones can be composted — Kitchen waste.",
            commonMistake: "Large hard bones (pork leg, beef) go to Other waste — too hard to compost.",
            tips: "Small bones: Kitchen. Large bones: Other. Size matters!",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "KIT-005", nameEN: "Eggshell", nameCN: "蛋壳",
            category: .kitchen,
            explanation: "Eggshells are organic and compostable — Kitchen waste.",
            commonMistake: "Some think eggshells are hard so they go to Other — wrong, they compost well.",
            tips: "Include egg membrane inside too.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "KIT-006", nameEN: "Tea Leaves / Tea Bag", nameCN: "茶叶渣/茶包",
            category: .kitchen,
            explanation: "Used tea leaves are organic Kitchen waste.",
            commonMistake: "Paper tea bag wrapper: remove and put in Other waste.",
            tips: "Squeeze out excess water first.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "KIT-007", nameEN: "Coffee Grounds", nameCN: "咖啡渣",
            category: .kitchen,
            explanation: "Coffee grounds are organic — excellent Kitchen waste and garden compost.",
            commonMistake: nil,
            tips: "Paper coffee filter goes to Other waste; grounds go to Kitchen.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "KIT-008", nameEN: "Bread / Pastry", nameCN: "面包/糕点",
            category: .kitchen,
            explanation: "Baked goods are food waste — Kitchen category.",
            commonMistake: nil,
            tips: "Include packaging-free bread products. Remove plastic wrapper first.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "KIT-009", nameEN: "Fruit Core / Pit", nameCN: "果核",
            category: .kitchen,
            explanation: "Apple cores, mango pits, peach stones — all Kitchen waste.",
            commonMistake: "Hard pits seem like Other waste but they are organic and go to Kitchen.",
            tips: "Large fruit pits go to Kitchen. They will be processed industrially.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "KIT-010", nameEN: "Tofu", nameCN: "豆腐",
            category: .kitchen,
            explanation: "Tofu and soy products are organic food — Kitchen waste.",
            commonMistake: nil,
            tips: "Drain excess water before putting in bin.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "KIT-011", nameEN: "Seafood Shells (small)", nameCN: "贝壳(小)",
            category: .kitchen,
            explanation: "Small clam and oyster shells can be composted — Kitchen waste in most Chinese cities.",
            commonMistake: "Large shells like conch may go to Other waste in some cities — check local rules.",
            tips: "Rules vary by city. Shanghai/Beijing: small shells → Kitchen.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "KIT-012", nameEN: "Meat Scraps", nameCN: "肉类残渣",
            category: .kitchen,
            explanation: "Raw or cooked meat scraps are organic — Kitchen waste.",
            commonMistake: nil,
            tips: "Drain excess fat/liquid first.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "KIT-013", nameEN: "Expired Food (no packaging)", nameCN: "过期食物(无包装)",
            category: .kitchen,
            explanation: "Food past its expiry is still organic — Kitchen waste without packaging.",
            commonMistake: "Keep packaging separate: recyclable or Other depending on material.",
            tips: "Remove all packaging before placing food in Kitchen bin.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "KIT-014", nameEN: "Flower / Plant Waste", nameCN: "花卉植物残枝",
            category: .kitchen,
            explanation: "Cut flowers and plant trimmings are organic — Kitchen waste in China.",
            commonMistake: nil,
            tips: "Remove plastic wrapping or wire support first.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "KIT-015", nameEN: "Nut Shells (soft)", nameCN: "瓜子壳/软坚果壳",
            category: .kitchen,
            explanation: "Soft nut shells like sunflower seeds, peanut shells — Kitchen waste.",
            commonMistake: "Walnut and hard coconut shells go to Other waste.",
            tips: "Soft shells: Kitchen. Hard coconut shell: Other.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "KIT-016", nameEN: "Ice Cream / Dairy", nameCN: "冰淇淋/乳制品",
            category: .kitchen,
            explanation: "Dairy food waste is organic — Kitchen waste.",
            commonMistake: "Container goes to Other or Recyclable; food content goes to Kitchen.",
            tips: "Always separate food from packaging.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "KIT-017", nameEN: "Pet Food (uneaten)", nameCN: "宠物剩食",
            category: .kitchen,
            explanation: "Uneaten pet food is organic matter — Kitchen waste.",
            commonMistake: nil,
            tips: "Remove from can/bag first. Container is separate (Recyclable or Other).",
            isTricky: false
        ),
    ]

    // MARK: – Other / Dry (其他垃圾)

    private static let other: [WasteKnowledgeItem] = [
        WasteKnowledgeItem(
            id: "OTH-001", nameEN: "Used Tissue / Napkin", nameCN: "用过的纸巾",
            category: .other,
            explanation: "Used tissues are contaminated — NOT recyclable paper. Other waste.",
            commonMistake: "Thinking it's paper so it's recyclable — wrong! Contamination makes it Other.",
            tips: "This is one of the most common mistakes in China. Used tissue = Other.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "OTH-002", nameEN: "Greasy Pizza Box", nameCN: "油腻的比萨盒",
            category: .other,
            explanation: "Grease contaminates the cardboard fibers — makes it unrecyclable.",
            commonMistake: "Clean cardboard lid part can be torn off and recycled; greasy bottom is Other.",
            tips: "Tear clean top: Recyclable. Greasy bottom: Other. Smart separation!",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "OTH-003", nameEN: "Styrofoam / Polystyrene", nameCN: "泡沫塑料",
            category: .other,
            explanation: "Styrofoam (PS) is not accepted in China's standard recycling system.",
            commonMistake: "Looks like plastic so people assume recyclable — but it's Other in China.",
            tips: "No domestic recycling for styrofoam in most Chinese cities.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "OTH-004", nameEN: "Broken Ceramic / Porcelain", nameCN: "破损陶瓷",
            category: .other,
            explanation: "Ceramics cannot be recycled with glass — different melting points.",
            commonMistake: "Looks like glass, but broken ceramics go to Other, not Recyclable.",
            tips: "Wrap in paper before disposal to prevent injury.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "OTH-005", nameEN: "Large Bone (pork/beef)", nameCN: "大骨头(猪骨/牛骨)",
            category: .other,
            explanation: "Large hard bones are too dense to compost — go to Other waste.",
            commonMistake: "Small chicken bones = Kitchen; large hard bones = Other. Size matters.",
            tips: "If you can snap it easily → Kitchen. If solid/dense → Other.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "OTH-006", nameEN: "Cigarette Butt", nameCN: "烟蒂",
            category: .other,
            explanation: "Cigarette butts contain toxic chemicals and non-recyclable filters.",
            commonMistake: nil,
            tips: "Extinguish fully before disposal.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "OTH-007", nameEN: "Dirty Diaper", nameCN: "脏纸尿裤",
            category: .other,
            explanation: "Contaminated hygiene products go to Other waste.",
            commonMistake: nil,
            tips: "Fold and seal before disposal to reduce odor.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "OTH-008", nameEN: "Dust & Dirt (sweeping)", nameCN: "扫地灰尘",
            category: .other,
            explanation: "Household dust is mixed contaminated material — Other waste.",
            commonMistake: nil,
            tips: "Put dustpan contents directly in Other bin.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "OTH-009", nameEN: "Plastic-Lined Paper Cup", nameCN: "纸杯(内衬塑料)",
            category: .other,
            explanation: "Paper cups have a plastic lining preventing paper recycling.",
            commonMistake: "Looks like paper so people put it in Recyclable — but the lining ruins it.",
            tips: "Standard disposable cups (café/office) → Other waste.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "OTH-010", nameEN: "Broken Glass (pieces)", nameCN: "破碎玻璃",
            category: .other,
            explanation: "Broken glass cannot be recycled safely with intact bottles.",
            commonMistake: "Intact glass bottle = Recyclable; broken glass pieces = Other waste.",
            tips: "Wrap carefully in thick paper/tape before placing in bin for safety.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "OTH-011", nameEN: "Used Tape / Stickers", nameCN: "用过的胶带/贴纸",
            category: .other,
            explanation: "Adhesive materials are mixed composition — not recyclable.",
            commonMistake: nil,
            tips: "Remove stickers from bottles/boxes before recycling the container.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "OTH-012", nameEN: "Plastic Straw", nameCN: "塑料吸管",
            category: .other,
            explanation: "Straws are too small/light to sort in recycling facilities.",
            commonMistake: nil,
            tips: "Avoid single-use straws when possible. If used, Other waste.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "OTH-013", nameEN: "Cat Litter / Pet Waste", nameCN: "猫砂/宠物粪便",
            category: .other,
            explanation: "Pet waste is contaminated organic matter — not suitable for food composting.",
            commonMistake: "Pet waste is NOT the same as Kitchen food waste.",
            tips: "Seal before disposal to prevent odor. Other waste only.",
            isTricky: true
        ),
        WasteKnowledgeItem(
            id: "OTH-014", nameEN: "Cork", nameCN: "软木塞",
            category: .other,
            explanation: "Cork is not commonly recycled in China's standard system.",
            commonMistake: nil,
            tips: "Some specialty cork recycling programs exist — check locally.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "OTH-015", nameEN: "Foam Makeup Sponge", nameCN: "化妆海绵",
            category: .other,
            explanation: "Synthetic foam with cosmetic residue — Other waste.",
            commonMistake: nil,
            tips: "Replace with washable alternatives to reduce waste.",
            isTricky: false
        ),
        WasteKnowledgeItem(
            id: "OTH-016", nameEN: "Dirty Aluminum Foil", nameCN: "脏铝箔纸",
            category: .other,
            explanation: "Food-contaminated foil cannot be recycled.",
            commonMistake: "Clean foil = Recyclable; dirty foil with food = Other waste.",
            tips: "If you can wipe it clean → Recyclable. If food-stained → Other.",
            isTricky: true
        ),
    ]

    // MARK: – Combined

    /// All 60 knowledge items (15 recyclable + 12 hazardous + 17 kitchen + 16 other).
    static let items: [WasteKnowledgeItem] = recyclable + hazardous + kitchen + other
}
