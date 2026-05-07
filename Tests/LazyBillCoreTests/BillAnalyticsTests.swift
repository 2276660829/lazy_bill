import Foundation
import Testing
@testable import LazyBillCore

@Suite("账本统计分析")
struct BillAnalyticsTests {
    @Test("生成分类饼图数据")
    func categorySummaries() {
        let transactions = sampleTransactions()
        let summaries = BillAnalytics().categorySummaries(for: transactions, kind: .expense)

        #expect(summaries.first?.category == ExpenseCategory.dining.rawValue)
        #expect(summaries.first?.amount == Decimal(300))
        #expect(summaries.reduce(0.0) { $0 + $1.percent } > 0.99)
    }

    @Test("支持按年份生成月消费对比数据")
    func monthlyComparisonsByYear() {
        let comparisons = BillAnalytics().monthlyComparisons(for: sampleTransactions(), year: 2026)

        #expect(comparisons.map(\.monthKey) == ["2026-01", "2026-02"])
        #expect(comparisons[0].expense == Decimal(300))
        #expect(comparisons[1].income == Decimal(1000))
    }

    @Test("支持选择任意几个月进行累计消费对比")
    func selectedMonthComparisons() {
        let comparisons = BillAnalytics().monthlyComparisons(
            for: sampleTransactions(),
            months: ["2026-02"]
        )

        #expect(comparisons.count == 1)
        #expect(comparisons[0].monthKey == "2026-02")
        #expect(comparisons[0].expense == Decimal(200))
    }

    private func sampleTransactions() -> [BillTransaction] {
        [
            BillTransaction(date: Date(timeIntervalSince1970: 1_767_225_600), title: "餐饮", amount: 300, kind: .expense, expenseCategory: .dining, platform: .weChat),
            BillTransaction(date: Date(timeIntervalSince1970: 1_769_904_000), title: "购物", amount: 200, kind: .expense, expenseCategory: .shopping, platform: .alipay),
            BillTransaction(date: Date(timeIntervalSince1970: 1_769_904_000), title: "工资", amount: 1000, kind: .income, incomeCategory: .salary, platform: .alipay)
        ]
    }
}
