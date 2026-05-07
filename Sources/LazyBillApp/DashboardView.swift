#if canImport(SwiftUI) && canImport(Charts)
import SwiftUI
import Charts
import LazyBillCore

struct DashboardView: View {
    @EnvironmentObject private var store: BillStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    importCard
                    categoryPieCard
                    monthlyComparisonCard
                    transactionListCard
                }
                .padding()
            }
            .navigationTitle("Lazy Bill 账本")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var importCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("导入微信 / 支付宝账单", systemImage: "square.and.arrow.down")
                .font(.headline)
            Text("选择平台后导入 CSV 文本，系统会根据交易说明自动识别收入、支出和分类。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Button("导入微信示例") { importSample(platform: .weChat) }
                Button("导入支付宝示例") { importSample(platform: .alipay) }
            }
            .buttonStyle(.borderedProminent)
        }
        .cardStyle()
    }

    private var categoryPieCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("分类占比")
                    .font(.headline)
                Spacer()
                Picker("收支", selection: $store.selectedKind) {
                    ForEach(TransactionKind.allCases, id: \.self) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }

            Chart(store.categorySummaries) { item in
                SectorMark(
                    angle: .value("金额", item.amount.doubleValue),
                    innerRadius: .ratio(0.58),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("分类", item.category))
                .annotation(position: .overlay) {
                    Text(item.percent, format: .percent.precision(.fractionLength(0)))
                        .font(.caption2)
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 260)
        }
        .cardStyle()
    }

    private var monthlyComparisonCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("累计消费对比")
                    .font(.headline)
                Spacer()
                Picker("年份", selection: $store.selectedYear) {
                    ForEach([2025, 2026], id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
            }

            MonthSelectionView(selectedMonths: $store.selectedMonths)

            Chart(store.monthlyComparisons) { item in
                BarMark(x: .value("月份", item.monthKey), y: .value("支出", item.expense.doubleValue))
                    .foregroundStyle(.red.gradient)
                LineMark(x: .value("月份", item.monthKey), y: .value("收入", item.income.doubleValue))
                    .foregroundStyle(.green)
                    .symbol(.circle)
            }
            .frame(height: 280)
        }
        .cardStyle()
    }

    private var transactionListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近记录")
                .font(.headline)
            ForEach(store.transactions.prefix(6)) { transaction in
                HStack {
                    VStack(alignment: .leading) {
                        Text(transaction.title)
                            .font(.subheadline.weight(.semibold))
                        Text("\(transaction.platform.rawValue) · \(transaction.kind.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(transaction.amount.doubleValue, format: .currency(code: "CNY"))
                        .foregroundStyle(transaction.kind == .income ? .green : .primary)
                }
            }
        }
        .cardStyle()
    }

    private func importSample(platform: PaymentPlatform) {
        let text: String
        switch platform {
        case .weChat:
            text = """
            交易时间,交易类型,交易对方,商品,收/支,金额(元),当前状态
            2026-04-01 08:00:00,商户消费,咖啡店,早餐咖啡,支出,22.00,支付成功
            """
        case .alipay:
            text = """
            交易创建时间,商品名称,收/支,金额（元）,交易状态
            2026/04/02 09:00:00,工资,收入,15000.00,交易成功
            """
        case .manual:
            return
        }
        try? store.importCSV(text, platform: platform)
    }
}

private struct MonthSelectionView: View {
    @Binding var selectedMonths: Set<String>
    private let months = (1...12).map { String(format: "2026-%02d", $0) }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button("全年") { selectedMonths.removeAll() }
                    .buttonStyle(.bordered)
                ForEach(months, id: \.self) { month in
                    Button(month) {
                        if selectedMonths.contains(month) {
                            selectedMonths.remove(month)
                        } else {
                            selectedMonths.insert(month)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(selectedMonths.contains(month) ? .blue : .gray)
                }
            }
        }
    }
}

private extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }
}

private extension Decimal {
    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
}
#endif
