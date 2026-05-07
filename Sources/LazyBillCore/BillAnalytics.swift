import Foundation

public struct BillAnalytics: Sendable {
    public init() {}

    public func categorySummaries(for transactions: [BillTransaction], kind: TransactionKind) -> [CategorySummary] {
        let filtered = transactions.filter { $0.kind == kind }
        let total = filtered.reduce(Decimal.zero) { $0 + $1.amount }
        guard total > 0 else { return [] }

        let grouped = Dictionary(grouping: filtered) { transaction -> String in
            switch kind {
            case .expense:
                return transaction.expenseCategory?.rawValue ?? ExpenseCategory.other.rawValue
            case .income:
                return transaction.incomeCategory?.rawValue ?? IncomeCategory.other.rawValue
            }
        }

        return grouped.map { category, items in
            let amount = items.reduce(Decimal.zero) { $0 + $1.amount }
            return CategorySummary(category: category, amount: amount, percent: amount.doubleValue / total.doubleValue)
        }
        .sorted { $0.amount > $1.amount }
    }

    public func monthlyComparisons(
        for transactions: [BillTransaction],
        months: Set<String>? = nil,
        year: Int? = nil,
        calendar: Calendar = .gregorianUTC
    ) -> [MonthlyComparison] {
        let filtered = transactions.filter { transaction in
            let monthKey = calendar.monthKey(for: transaction.date)
            if let months { return months.contains(monthKey) }
            if let year { return calendar.component(.year, from: transaction.date) == year }
            return true
        }

        let grouped = Dictionary(grouping: filtered) { calendar.monthKey(for: $0.date) }
        return grouped.map { monthKey, items in
            MonthlyComparison(
                monthKey: monthKey,
                expense: items.filter { $0.kind == .expense }.reduce(Decimal.zero) { $0 + $1.amount },
                income: items.filter { $0.kind == .income }.reduce(Decimal.zero) { $0 + $1.amount }
            )
        }
        .sorted { $0.monthKey < $1.monthKey }
    }
}

public enum CategoryClassifier {
    private static let rules: [CategoryRule] = [
        CategoryRule(keywords: ["饭", "餐", "咖啡", "奶茶", "美团", "饿了么"], expenseCategory: .dining),
        CategoryRule(keywords: ["地铁", "公交", "滴滴", "打车", "铁路", "机票"], expenseCategory: .transport),
        CategoryRule(keywords: ["淘宝", "京东", "拼多多", "商场", "超市"], expenseCategory: .shopping),
        CategoryRule(keywords: ["房租", "物业", "水费", "电费", "燃气"], expenseCategory: .housing),
        CategoryRule(keywords: ["医院", "药", "体检", "门诊"], expenseCategory: .healthcare),
        CategoryRule(keywords: ["课程", "书", "培训", "学费"], expenseCategory: .education),
        CategoryRule(keywords: ["电影", "游戏", "会员", "旅游", "酒店"], expenseCategory: .entertainment),
        CategoryRule(keywords: ["红包", "转账"], expenseCategory: .transfer)
    ]

    public static func expenseCategory(for title: String) -> ExpenseCategory {
        let normalized = title.lowercased()
        return rules.first { rule in
            rule.keywords.contains { normalized.contains($0.lowercased()) }
        }?.expenseCategory ?? .other
    }

    public static func incomeCategory(for title: String) -> IncomeCategory {
        if title.contains("工资") || title.contains("薪") { return .salary }
        if title.contains("奖金") || title.contains("补贴") { return .bonus }
        if title.contains("理财") || title.contains("基金") || title.contains("股票") { return .investment }
        if title.contains("退款") || title.contains("报销") { return .refund }
        if title.contains("转账") || title.contains("红包") { return .transfer }
        return .other
    }
}

public extension Calendar {
    static var gregorianUTC: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func monthKey(for date: Date) -> String {
        let components = dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }
}

private extension Decimal {
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
