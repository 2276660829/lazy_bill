# Lazy Bill 使用指南

这份指南说明如何把当前仓库里的账本原型跑起来，以及如何导入微信、支付宝账单。

## 你现在拿到的是什么？

当前仓库是一个 **Swift Package + SwiftUI 页面原型**：

- `LazyBillCore`：已经可以运行和测试的核心逻辑，负责账单解析、分类、统计。
- `Sources/LazyBillApp`：SwiftUI + Apple Charts 的界面代码，适合放进 Xcode 的 iOS App Target 中运行。

也就是说：当前仓库还不是一个可以直接双击安装的 iPhone App，需要用 Xcode 建一个 iOS App 壳，把这里的核心库和界面代码接进去。

## 方式一：先验证核心功能

如果你只是想确认导入、分类和统计逻辑能不能跑，执行：

```bash
swift test
```

看到测试通过后，说明微信/支付宝 CSV 示例解析、分类饼图数据、月度对比数据都能正常工作。

## 方式二：在 Xcode 里跑 iPhone App 原型

### 1. 准备环境

- 一台 Mac。
- Xcode 15 或更高版本，建议使用较新的 Xcode，因为界面使用了 SwiftUI 和 Apple Charts。
- iOS 17 或更高版本的模拟器/真机。

### 2. 新建 iOS App

1. 打开 Xcode。
2. 选择 **File > New > Project...**。
3. 选择 **iOS > App**。
4. Product Name 可以填 `LazyBill`。
5. Interface 选择 **SwiftUI**。
6. Language 选择 **Swift**。
7. Minimum Deployments 选择 **iOS 17.0** 或更高。

### 3. 加入本地 Swift Package

1. 在 Xcode 左侧项目导航中选中项目。
2. 进入 **Package Dependencies**。
3. 点击 **+**。
4. 选择 **Add Local...**。
5. 选择本仓库根目录，也就是包含 `Package.swift` 的目录。
6. 添加 `LazyBillCore` 到你的 App Target。

### 4. 加入界面文件

把仓库里的这 3 个文件拖进 Xcode 的 App Target：

- `Sources/LazyBillApp/LazyBillApp.swift`
- `Sources/LazyBillApp/BillStore.swift`
- `Sources/LazyBillApp/DashboardView.swift`

拖入时注意勾选你的 App Target。

如果你新建项目时 Xcode 已经生成了一个 `LazyBillApp.swift`，请保留一个 `@main` 入口即可：

- 简单做法：删除 Xcode 自动生成的 `LazyBillApp.swift`，使用本仓库的 `Sources/LazyBillApp/LazyBillApp.swift`。
- 或者把自动生成入口里的 `ContentView()` 改成 `DashboardView().environmentObject(BillStore.preview)`。

### 5. 运行

选择一个 iPhone 模拟器，然后点击 Xcode 左上角运行按钮。

启动后你会看到：

- “导入微信 / 支付宝账单”卡片。
- 分类占比饼图。
- 累计消费对比图。
- 月份筛选按钮。
- 最近记录列表。

当前页面里的“导入微信示例”和“导入支付宝示例”按钮会导入内置示例数据，方便你先看效果。

## 如何导入真实微信账单？

1. 打开微信。
2. 进入 **我 > 服务 > 钱包 > 账单**。
3. 找到账单导出入口，按微信提示申请导出。
4. 获取账单文件后，确保是 CSV 或可转换为 CSV 的表格。
5. 当前解析器优先识别这些字段：

```text
交易时间, 交易类型, 交易对方, 商品, 收/支, 金额(元), 当前状态
```

如果你的文件表头略有不同，可以在 `Sources/LazyBillCore/BillImportParser.swift` 中给 `parseWeChat` 增加字段别名。

## 如何导入真实支付宝账单？

1. 打开支付宝。
2. 进入账单页面。
3. 按支付宝提供的方式导出账单。
4. 获取账单文件后，确保是 CSV 或可转换为 CSV 的表格。
5. 当前解析器优先识别这些字段：

```text
交易创建时间, 商品名称, 收/支, 金额（元）, 交易状态
```

如果支付宝导出的字段名称和这里不同，可以在 `Sources/LazyBillCore/BillImportParser.swift` 中给 `parseAlipay` 增加字段别名。

## 当前原型还缺什么？

为了尽快让你看到“能导入、能分类、能画图”的核心效果，目前还没有做这些完整 App 功能：

- 文件选择器：还没有直接从 iPhone 文件 App 选择 CSV。
- 本地持久化：导入的数据暂时在内存里，重启 App 会恢复示例数据。
- 分类编辑：分类规则目前写在代码里，还没有做用户自定义页面。
- Xcode 工程文件：当前是 Swift Package，需要按上面步骤接入 iOS App Target。

## 下一步建议

如果要把它做成真正可日常使用的 App，建议按这个顺序继续：

1. 增加文件选择器，支持从“文件”App 选择微信/支付宝 CSV。
2. 增加 SwiftData 或 Core Data，把交易记录保存到本地。
3. 增加分类管理页面，允许手动修改分类和关键词规则。
4. 增加导入预览页，导入前确认重复记录和异常记录。
5. 创建正式 Xcode iOS App 工程并配置图标、名称、权限和发布设置。
