import Foundation

public enum TransactionKind: String, Codable, CaseIterable, Sendable {
    case expense = "支出"
    case income = "收入"
}

public enum ExpenseCategory: String, Codable, CaseIterable, Sendable {
    case dining = "餐饮"
    case transport = "交通"
    case shopping = "购物"
    case housing = "居住"
    case healthcare = "医疗健康"
    case education = "学习教育"
    case entertainment = "休闲娱乐"
    case transfer = "转账红包"
    case other = "其他支出"
}

public enum IncomeCategory: String, Codable, CaseIterable, Sendable {
    case salary = "工资薪酬"
    case bonus = "奖金补贴"
    case investment = "投资理财"
    case refund = "退款报销"
    case transfer = "转账收款"
    case other = "其他收入"
}

public enum PaymentPlatform: String, Codable, CaseIterable, Sendable {
    case weChat = "微信"
    case alipay = "支付宝"
    case manual = "手动记录"
}

public struct CategoryRule: Codable, Equatable, Sendable {
    public let keywords: [String]
    public let expenseCategory: ExpenseCategory

    public init(keywords: [String], expenseCategory: ExpenseCategory) {
        self.keywords = keywords
        self.expenseCategory = expenseCategory
    }
}

public struct BillTransaction: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var date: Date
    public var title: String
    public var amount: Decimal
    public var kind: TransactionKind
    public var expenseCategory: ExpenseCategory?
    public var incomeCategory: IncomeCategory?
    public var platform: PaymentPlatform
    public var note: String

    public init(
        id: UUID = UUID(),
        date: Date,
        title: String,
        amount: Decimal,
        kind: TransactionKind,
        expenseCategory: ExpenseCategory? = nil,
        incomeCategory: IncomeCategory? = nil,
        platform: PaymentPlatform,
        note: String = ""
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.amount = amount
        self.kind = kind
        self.expenseCategory = expenseCategory
        self.incomeCategory = incomeCategory
        self.platform = platform
        self.note = note
    }
}

public struct CategorySummary: Identifiable, Equatable, Sendable {
    public var id: String { category }
    public let category: String
    public let amount: Decimal
    public let percent: Double

    public init(category: String, amount: Decimal, percent: Double) {
        self.category = category
        self.amount = amount
        self.percent = percent
    }
}

public struct MonthlyComparison: Identifiable, Equatable, Sendable {
    public var id: String { monthKey }
    public let monthKey: String
    public let expense: Decimal
    public let income: Decimal

    public init(monthKey: String, expense: Decimal, income: Decimal) {
        self.monthKey = monthKey
        self.expense = expense
        self.income = income
    }
}
