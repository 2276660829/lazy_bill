import Foundation
import Testing
@testable import LazyBillCore

@Suite("账单导入解析")
struct BillImportParserTests {
    @Test("解析微信账单并自动识别收支与分类")
    func parseWeChatBill() throws {
        let csv = """
        交易时间,交易类型,交易对方,商品,收/支,金额(元),当前状态
        2026-01-03 08:10:00,商户消费,咖啡店,早餐咖啡,支出,18.50,支付成功
        2026-01-05 10:00:00,转账,朋友,红包,收入,88.00,已收钱
        """

        let transactions = try BillImportParser().parse(csvText: csv, platform: .weChat)

        #expect(transactions.count == 2)
        #expect(transactions[0].kind == .expense)
        #expect(transactions[0].expenseCategory == .dining)
        #expect(transactions[1].kind == .income)
        #expect(transactions[1].incomeCategory == .transfer)
    }

    @Test("解析支付宝账单并保留商品名称")
    func parseAlipayBill() throws {
        let csv = """
        交易创建时间,商品名称,收/支,金额（元）,交易状态
        2026/02/01 12:00:00,地铁通勤,支出,6.00,交易成功
        2026/02/28 09:00:00,工资,收入,12000.00,交易成功
        """

        let transactions = try BillImportParser().parse(csvText: csv, platform: .alipay)

        #expect(transactions.map(\.title) == ["地铁通勤", "工资"])
        #expect(transactions[0].expenseCategory == .transport)
        #expect(transactions[1].incomeCategory == .salary)
    }
}
