import Foundation

public enum BillImportError: Error, Equatable {
    case emptyFile
    case unsupportedHeader
}

public struct BillImportParser: Sendable {
    public init() {}

    public func parse(csvText: String, platform: PaymentPlatform) throws -> [BillTransaction] {
        let rows = CSVReader.parse(csvText)
        guard let header = rows.first else { throw BillImportError.emptyFile }
        let dataRows = rows.dropFirst().filter { row in row.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } }

        switch platform {
        case .weChat:
            return dataRows.compactMap { parseWeChat(row: $0, header: header) }
        case .alipay:
            return dataRows.compactMap { parseAlipay(row: $0, header: header) }
        case .manual:
            throw BillImportError.unsupportedHeader
        }
    }

    private func parseWeChat(row: [String], header: [String]) -> BillTransaction? {
        let lookup = RowLookup(header: header, row: row)
        guard let date = DateParsers.parse(lookup.value(forAny: ["交易时间", "时间"])),
              let amount = DecimalParsers.parseSignedAmount(
                lookup.value(forAny: ["金额(元)", "金额"]),
                incomeHints: [lookup.value(forAny: ["收/支", "交易类型"])]
              ) else { return nil }

        let kind: TransactionKind = amount >= 0 ? .income : .expense
        let title = lookup.value(forAny: ["商品", "交易对方", "交易说明"]) ?? "微信账单"
        return BillTransaction(
            date: date,
            title: title,
            amount: abs(amount),
            kind: kind,
            expenseCategory: kind == .expense ? CategoryClassifier.expenseCategory(for: title) : nil,
            incomeCategory: kind == .income ? CategoryClassifier.incomeCategory(for: title) : nil,
            platform: .weChat,
            note: lookup.value(forAny: ["当前状态", "备注"]) ?? ""
        )
    }

    private func parseAlipay(row: [String], header: [String]) -> BillTransaction? {
        let lookup = RowLookup(header: header, row: row)
        guard let date = DateParsers.parse(lookup.value(forAny: ["交易创建时间", "付款时间", "时间"])),
              let rawAmount = DecimalParsers.parse(lookup.value(forAny: ["金额（元）", "金额(元)", "金额"])),
              rawAmount != 0 else { return nil }

        let direction = lookup.value(forAny: ["收/支", "收入/支出"])
        let kind = DecimalParsers.kind(from: direction) ?? (rawAmount >= 0 ? .expense : .income)
        let title = lookup.value(forAny: ["商品名称", "交易对方", "交易说明"]) ?? "支付宝账单"
        return BillTransaction(
            date: date,
            title: title,
            amount: abs(rawAmount),
            kind: kind,
            expenseCategory: kind == .expense ? CategoryClassifier.expenseCategory(for: title) : nil,
            incomeCategory: kind == .income ? CategoryClassifier.incomeCategory(for: title) : nil,
            platform: .alipay,
            note: lookup.value(forAny: ["交易状态", "备注"]) ?? ""
        )
    }
}

private struct RowLookup {
    private let pairs: [String: String]

    init(header: [String], row: [String]) {
        var pairs: [String: String] = [:]
        for (index, key) in header.enumerated() where index < row.count {
            pairs[key.normalizedHeader] = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        self.pairs = pairs
    }

    func value(forAny names: [String]) -> String? {
        for name in names {
            if let value = pairs[name.normalizedHeader], !value.isEmpty { return value }
        }
        return nil
    }
}

private extension String {
    var normalizedHeader: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
    }
}

private enum DateParsers {
    static func parse(_ text: String?) -> Date? {
        guard let text else { return nil }
        for formatter in formatters {
            if let date = formatter.date(from: text) { return date }
        }
        return nil
    }

    private static let formatters: [DateFormatter] = [
        "yyyy-MM-dd HH:mm:ss",
        "yyyy/MM/dd HH:mm:ss",
        "yyyy-MM-dd HH:mm",
        "yyyy/MM/dd HH:mm",
        "yyyy-MM-dd"
    ].map { format in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = format
        return formatter
    }
}

private enum DecimalParsers {
    static func parse(_ text: String?) -> Decimal? {
        guard let text else { return nil }
        let cleaned = text
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "元", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX"))
    }

    static func parseSignedAmount(_ text: String?, incomeHints: [String?]) -> Decimal? {
        guard let amount = parse(text) else { return nil }
        if amount < 0 { return amount }
        if let kind = incomeHints.compactMap(kind(from:)).first {
            return kind == .income ? amount : -amount
        }
        return -amount
    }

    static func kind(from text: String?) -> TransactionKind? {
        guard let text else { return nil }
        if text.contains("收入") || text.contains("收") { return .income }
        if text.contains("支出") || text.contains("支") { return .expense }
        return nil
    }
}

private enum CSVReader {
    static func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var insideQuotes = false
        var iterator = text.makeIterator()

        while let character = iterator.next() {
            switch character {
            case "\"":
                if insideQuotes, let next = iterator.next() {
                    if next == "\"" {
                        field.append(next)
                    } else {
                        insideQuotes = false
                        process(next, field: &field, row: &row, rows: &rows, insideQuotes: &insideQuotes)
                    }
                } else {
                    insideQuotes.toggle()
                }
            default:
                process(character, field: &field, row: &row, rows: &rows, insideQuotes: &insideQuotes)
            }
        }
        row.append(field)
        if !row.isEmpty { rows.append(row) }
        return rows
    }

    private static func process(_ character: Character, field: inout String, row: inout [String], rows: inout [[String]], insideQuotes: inout Bool) {
        if character == ",", !insideQuotes {
            row.append(field)
            field = ""
        } else if character == "\n", !insideQuotes {
            row.append(field.trimmingCharacters(in: CharacterSet(charactersIn: "\r")))
            rows.append(row)
            row = []
            field = ""
        } else {
            field.append(character)
        }
    }
}
