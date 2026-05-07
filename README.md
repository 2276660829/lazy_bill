# lazy_bill

🧾 个人记账应用 | Personal Expense Tracker — 简洁、高效、一目了然的日常收支管理工具。



- 导入微信、支付宝 CSV 账单。
- 自动区分收入、支出，并按关键词识别常见分类。
- 支出分类与收入分类独立管理。
- 用饼图展示分类占比。
- 用柱状图/折线图展示累计消费和收入对比。
- 支持选择某几个月对比，也支持按年份展示月度消费对比。



```text
Package.swift                         Swift Package 配置，提供 LazyBillCore 库
Sources/LazyBillCore/                 可测试的记账核心能力
Sources/LazyBillApp/                  SwiftUI + Charts 的 iOS/macOS 界面原型
Tests/LazyBillCoreTests/              导入解析与统计分析测试
```

## 核心能力

### 账单导入

`BillImportParser` 支持解析微信和支付宝常见 CSV 字段：

- 微信：`交易时间`、`交易类型`、`交易对方`、`商品`、`收/支`、`金额(元)`、`当前状态`。
- 支付宝：`交易创建时间`、`商品名称`、`收/支`、`金额（元）`、`交易状态`。

解析后会生成统一的 `BillTransaction` 数据模型，便于后续存储、筛选和图表展示。

### 分类体系

支出分类包括：餐饮、交通、购物、居住、医疗健康、学习教育、休闲娱乐、转账红包、其他支出。

收入分类包括：工资薪酬、奖金补贴、投资理财、退款报销、转账收款、其他收入。

`CategoryClassifier` 内置关键词规则，后续可以替换为用户自定义规则或本地机器学习模型。

### 可视化分析

`BillAnalytics` 提供两类图表数据：

- `categorySummaries`：生成饼图使用的分类金额和占比。
- `monthlyComparisons`：生成月度消费/收入对比图，支持传入年份或任意月份集合。

`Sources/LazyBillApp/DashboardView.swift` 使用 SwiftUI 和 Apple Charts 演示：

- 分类占比环形饼图。
- 月度支出柱状图 + 收入折线图。
- 月份多选筛选器。
- 微信/支付宝示例导入按钮。


## 怎么用？

如果你想先验证账单解析、分类和统计逻辑，在仓库根目录执行：

```bash
swift test
```

如果你想在 iPhone 模拟器或真机上看到界面，需要用 Xcode 新建一个 iOS SwiftUI App，把本仓库作为本地 Swift Package 加入，然后把 `Sources/LazyBillApp` 里的 SwiftUI 文件加入 App Target。完整步骤见 [使用指南](docs/USAGE.md)。

## 本地验证

```bash
swift test
```

> 当前仓库提供 Swift Package 和 SwiftUI 原型源码。若要打包为可安装 iOS App，建议下一步在 Xcode 中创建 iOS App Target，并将 `Sources/LazyBillApp` 加入 App Target，将 `LazyBillCore` 作为本地 package 依赖。
