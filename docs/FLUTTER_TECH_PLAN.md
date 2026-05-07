# Lazy Bill Flutter 记账软件项目结构与技术方案

> 方向调整：后续建议改为 **Flutter 跨端开发，Android 优先**。Flutter 也可以兼顾 iOS，适合先快速做出漂亮界面、图表和本地账本能力。

## 1. 产品范围

Lazy Bill 的 Flutter 版本目标是做一个本地优先的个人记账 App：

1. 记录收入，收入有独立分类。
2. 记录支出，支出有独立分类。
3. 每条记录包含金额、类别、具体项目/备注、日期。
4. 支持账单记录增删查改。
5. 支持项目类别手动新增、编辑、删除、排序、启用/停用。
6. 支持账单图表展示，包括折线图、饼状图。
7. 折线图支持当周、当月、当年，并支持“累计消费”和“周期消费”两种展示。
8. 支持导入支付宝和微信账单。
9. 界面要现代、清爽、好看，适合日常高频使用。

## 2. 推荐技术栈

| 模块 | 推荐方案 | 原因 |
| --- | --- | --- |
| App 框架 | Flutter 3.x + Dart | Android 优先，同时可扩展 iOS |
| 状态管理 | Riverpod | 易测试、结构清晰，适合中小型到中大型 App |
| 路由 | go_router | 声明式路由，适合底部导航和详情页 |
| 本地数据库 | Drift + SQLite | 类型安全、查询能力强，适合账单聚合统计 |
| 图表 | fl_chart | 支持折线图、饼图、柱状图，自定义能力强 |
| 文件选择 | file_picker | 从手机文件中选择微信/支付宝 CSV/Excel 导出文件 |
| CSV 解析 | csv | 解析常见 CSV 文本 |
| 日期/金额格式化 | intl | 中文日期、人民币格式化 |
| ID 生成 | uuid | 离线生成记录 ID |
| 数据类 | freezed + json_serializable | 不可变模型、复制、序列化更省心 |
| 权限 | permission_handler | Android 文件访问/通知等权限预留 |

## 3. 推荐项目结构

```text
lazy_bill_flutter/
├── android/                              # Android 原生工程
├── ios/                                  # 可选，Flutter 默认生成
├── assets/
│   ├── icons/                            # 分类图标、App 图标素材
│   └── illustrations/                    # 空状态插画
├── lib/
│   ├── main.dart                         # App 入口
│   ├── app.dart                          # MaterialApp/router/theme 组装
│   ├── core/
│   │   ├── constants/                    # 常量：金额精度、默认分类、颜色
│   │   ├── database/                     # Drift 数据库、表定义、DAO
│   │   ├── errors/                       # Failure、异常类型
│   │   ├── routing/                      # go_router 路由配置
│   │   ├── theme/                        # 主题、颜色、字体、圆角、阴影
│   │   ├── utils/                        # 日期、金额、CSV 工具
│   │   └── widgets/                      # 通用组件：金额文本、空状态、卡片
│   ├── features/
│   │   ├── records/                      # 账单记录 CRUD
│   │   │   ├── data/                     # record DAO/repository 实现
│   │   │   ├── domain/                   # BillRecord 实体、用例
│   │   │   └── presentation/             # 列表页、编辑页、筛选器
│   │   ├── categories/                   # 收入/支出分类管理
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── analytics/                    # 图表统计
│   │   │   ├── data/                     # 聚合查询、统计 repository
│   │   │   ├── domain/                   # ChartPoint、PieSlice、PeriodMode
│   │   │   └── presentation/             # 折线图、饼图、维度选择器
│   │   ├── imports/                      # 微信/支付宝账单导入
│   │   │   ├── data/                     # CSV parser、字段映射、去重
│   │   │   ├── domain/                   # ImportPreview、ImportResult
│   │   │   └── presentation/             # 导入页、预览页、错误修正页
│   │   └── home/                         # 首页仪表盘、底部导航
│   └── l10n/                             # 后续多语言预留
├── test/                                 # 单元测试
├── integration_test/                     # 集成测试
└── pubspec.yaml                          # Flutter 依赖和资产配置
```

## 4. 数据模型设计

### 4.1 账单记录 BillRecord

```dart
enum RecordType { income, expense }

class BillRecord {
  final String id;
  final RecordType type;
  final int amountInCents;       // 用分存储，避免浮点误差
  final String categoryId;
  final String title;            // 具体项目，例如“午饭”“工资”“地铁”
  final String? note;
  final DateTime happenedAt;     // 用户选择的账单日期
  final String? source;          // manual / wechat / alipay
  final String? sourceRecordId;  // 导入时用于去重
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 4.2 分类 Category

```dart
class Category {
  final String id;
  final RecordType type;         // income 或 expense
  final String name;             // 餐饮、交通、工资等
  final String iconName;
  final int colorValue;
  final int sortOrder;
  final bool isDefault;
  final bool isArchived;         // 删除默认建议用归档，避免历史账单失去分类
}
```

### 4.3 导入批次 ImportBatch

```dart
class ImportBatch {
  final String id;
  final String source;           // wechat / alipay
  final String fileName;
  final int importedCount;
  final int skippedDuplicateCount;
  final DateTime importedAt;
}
```

## 5. 核心功能方案

### 5.1 收入/支出记录

记录页字段：

- 类型：收入 / 支出。
- 金额：数字键盘输入，建议突出显示。
- 类别：根据类型过滤分类；支出只显示支出分类，收入只显示收入分类。
- 具体项目：例如“午饭”“地铁”“工资”“奖金”。
- 日期：日期选择器，默认今天。
- 备注：可选。

交互建议：

- 首页底部中间放一个醒目的 “+” 按钮。
- 添加页默认选中“支出”，但可以一键切换为“收入”。
- 编辑记录时复用同一个页面。
- 删除记录时弹确认框，避免误删。

### 5.2 增删查改

推荐页面：

- 首页：展示今日/本月支出、收入、结余、快捷入口。
- 账单列表页：按日期分组，支持月份切换、关键词搜索、分类筛选、收入/支出筛选。
- 账单编辑页：新增/编辑同页。
- 账单详情页：显示完整信息、来源、导入批次，支持编辑/删除。

查询能力：

- 按时间范围查询：日、周、月、年、自定义。
- 按类型查询：收入/支出/全部。
- 按类别查询。
- 按关键词查询具体项目和备注。

### 5.3 分类管理

分类页分成两个 Tab：

- 支出分类：餐饮、交通、购物、居住、医疗、娱乐、学习、其他。
- 收入分类：工资、奖金、兼职、投资、报销、红包、其他。

分类操作：

- 新增分类：名称、图标、颜色、类型。
- 编辑分类：改名、换图标、换颜色、排序。
- 删除分类：如果没有账单可直接删除；如果已有账单，建议改为归档或提示迁移到其他分类。
- 排序：长按拖动排序。

## 6. 图表方案

### 6.1 饼状图

用途：展示某个时间范围内，不同分类的占比。

筛选项：

- 时间：本周、本月、本年、自定义。
- 类型：支出 / 收入。
- 分类：默认全部。

展示内容：

- 饼图显示分类占比。
- 下方列表显示分类名称、金额、百分比。
- 点击某个扇区可跳到账单列表，并自动筛选该分类。

### 6.2 折线图

折线图需要支持两个维度：

1. 时间粒度：周 / 月 / 年。
2. 统计方式：累计消费 / 周期消费。

#### A. 当周视图

- X 轴：周一到周日。
- “累计消费”：周一到当天逐日累计。
- “周期消费”：每天单独消费金额。
- 可选择第 1 周到第 52/53 周。

#### B. 当月视图

- X 轴：1 号到 28/29/30/31 号。
- “累计消费”：1 号到当天逐日累计，效果类似你给的参考图。
- “周期消费”：每天单独消费金额。
- 支持选择 1 月到 12 月，也支持多个月对比，例如同时展示 1 月、2 月、3 月的累计消费曲线。

#### C. 当年视图

- X 轴：1 月到 12 月，或者第 1 周到第 52/53 周。
- “累计消费”：从 1 月/第 1 周累计到当前月/周。
- “周期消费”：每月/每周单独消费金额。
- 支持选择年份，例如 2024、2025、2026。

### 6.3 对比图参考实现

你给的图属于“月度累计消费曲线”：

- 标题：月度累计消费曲线。
- X 轴：日期号，1 到 31。
- Y 轴：累计支出金额。
- 图例：1 月、2 月、3 月、4 月、5 月。
- 每条线代表某个月从 1 号开始的累计支出。
- 可以加“今天”竖线，例如 5 月 7 日。

Flutter 中可用 `fl_chart` 的 `LineChart` 实现：

- 每个月一组 `LineChartBarData`。
- 每条线的数据点是 `FlSpot(day, cumulativeAmount)`。
- 用 `ExtraLinesData` 画“今天”竖线。
- 自定义 tooltip 显示日期和人民币金额。

## 7. 微信/支付宝账单导入方案

### 7.1 导入流程

1. 用户点击“导入账单”。
2. 选择来源：微信 / 支付宝。
3. 使用文件选择器选择 CSV 文件。
4. App 解析文件，进入“导入预览页”。
5. 预览页展示：总记录数、可导入数、重复数、异常数。
6. 用户可修改异常记录的分类、类型、金额或日期。
7. 确认导入后写入数据库。
8. 保存导入批次，方便后续查看或回滚。

### 7.2 字段映射

微信常见字段：

```text
交易时间, 交易类型, 交易对方, 商品, 收/支, 金额(元), 当前状态
```

支付宝常见字段：

```text
交易创建时间, 商品名称, 交易对方, 收/支, 金额（元）, 交易状态
```

实际导出的表头可能会随地区、版本、导出入口略有差异，因此解析器要支持字段别名配置。

### 7.3 自动分类规则

可以先用关键词规则：

- 餐饮：饭、餐、咖啡、奶茶、美团、饿了么。
- 交通：地铁、公交、滴滴、打车、铁路、机票。
- 购物：淘宝、京东、拼多多、超市、商场。
- 居住：房租、物业、水费、电费、燃气。
- 收入：工资、薪资、奖金、补贴、报销、退款。

后续可以把规则做成可编辑配置，用户可以自己添加关键词。

### 7.4 去重策略

导入时建议生成 `sourceRecordId`：

```text
来源 + 交易时间 + 金额 + 交易对方 + 商品名称
```

如果数据库中已经存在相同 `sourceRecordId`，则标记为重复并跳过。

## 8. 界面设计建议

### 8.1 视觉风格

推荐风格：轻量、现代、卡片式、低饱和配色。

- 主色：绿色或蓝绿色，表示财务健康。
- 支出：红/橙色。
- 收入：绿色。
- 背景：浅灰或米白。
- 卡片：白色，圆角 16-24，轻阴影。
- 图表：使用柔和但区分度高的颜色。

### 8.2 页面结构

底部导航建议 4 个 Tab：

1. 首页：本月概览、快捷记账、最近记录。
2. 明细：账单列表、搜索筛选。
3. 图表：饼图、折线图、时间维度切换。
4. 我的：分类管理、导入账单、设置、备份。

### 8.3 首页卡片

首页建议包含：

- 本月支出。
- 本月收入。
- 本月结余。
- 预算剩余，后续可加。
- 快速记一笔按钮。
- 最近 5 条账单。

## 9. 数据库表建议

```text
categories
- id TEXT PRIMARY KEY
- type TEXT
- name TEXT
- icon_name TEXT
- color_value INTEGER
- sort_order INTEGER
- is_default INTEGER
- is_archived INTEGER
- created_at INTEGER
- updated_at INTEGER

bill_records
- id TEXT PRIMARY KEY
- type TEXT
- amount_in_cents INTEGER
- category_id TEXT
- title TEXT
- note TEXT NULL
- happened_at INTEGER
- source TEXT NULL
- source_record_id TEXT NULL UNIQUE
- import_batch_id TEXT NULL
- created_at INTEGER
- updated_at INTEGER

import_batches
- id TEXT PRIMARY KEY
- source TEXT
- file_name TEXT
- imported_count INTEGER
- skipped_duplicate_count INTEGER
- imported_at INTEGER
```

## 10. 开发里程碑

### 第一阶段：基础记账 MVP

- Flutter 项目初始化。
- 首页、明细页、记一笔页面。
- 收入/支出分类默认数据。
- 账单增删查改。
- SQLite 本地保存。

### 第二阶段：分类管理

- 分类列表。
- 新增/编辑/删除/归档分类。
- 分类颜色和图标选择。
- 已使用分类的删除保护或迁移。

### 第三阶段：图表分析

- 饼图：分类占比。
- 折线图：当周/当月/当年。
- 累计消费和周期消费切换。
- 周 1-52、月 1-12、年份选择器。
- 多月累计曲线对比，贴近参考图效果。

### 第四阶段：账单导入

- 文件选择器。
- 微信 CSV 解析。
- 支付宝 CSV 解析。
- 导入预览、异常修正、重复跳过。
- 导入批次记录。

### 第五阶段：体验优化

- 暗色模式。
- 搜索和高级筛选。
- 数据备份/恢复。
- 桌面小组件或快捷记账入口。
- 预算、周期账单、资产账户等高级功能。
