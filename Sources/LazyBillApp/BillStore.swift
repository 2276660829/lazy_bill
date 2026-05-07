#if canImport(SwiftUI)
import Foundation
import SwiftUI
import LazyBillCore

@MainActor
final class BillStore: ObservableObject {
    @Published var transactions: [BillTransaction]
    @Published var selectedKind: TransactionKind = .expense
    @Published var selectedYear: Int = 2026
    @Published var selectedMonths: Set<String> = []

    private let analytics = BillAnalytics()
    private let parser = BillImportParser()

    init(transactions: [BillTransaction] = []) {
        self.transactions = transactions
    }

    var categorySummaries: [CategorySummary] {
        analytics.categorySummaries(for: transactions, kind: selectedKind)
    }

    var monthlyComparisons: [MonthlyComparison] {
        if selectedMonths.isEmpty {
            return analytics.monthlyComparisons(for: transactions, year: selectedYear)
        }
        return analytics.monthlyComparisons(for: transactions, months: selectedMonths)
    }

    func importCSV(_ text: String, platform: PaymentPlatform) throws {
        transactions.append(contentsOf: try parser.parse(csvText: text, platform: platform))
    }

    static var preview: BillStore {
        BillStore(transactions: [
            BillTransaction(date: .sample("2026-01-03"), title: "早餐咖啡", amount: 18.5, kind: .expense, expenseCategory: .dining, platform: .weChat),
            BillTransaction(date: .sample("2026-01-12"), title: "地铁通勤", amount: 56, kind: .expense, expenseCategory: .transport, platform: .alipay),
            BillTransaction(date: .sample("2026-02-01"), title: "房租", amount: 3200, kind: .expense, expenseCategory: .housing, platform: .weChat),
            BillTransaction(date: .sample("2026-02-28"), title: "工资", amount: 12000, kind: .income, incomeCategory: .salary, platform: .alipay),
            BillTransaction(date: .sample("2026-03-08"), title: "京东购物", amount: 699, kind: .expense, expenseCategory: .shopping, platform: .alipay)
        ])
    }
}

private extension Date {
    static func sample(_ text: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: text) ?? .now
    }
}
#endif
