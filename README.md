# 千读阅界 - HarmonyOS 电子书阅读应用

> 阅尽千卷 · 视界无限

## 📱 项目简介

千读阅界是一款功能强大的 HarmonyOS 电子书阅读应用，支持多种书籍格式，采用 V2 状态管理架构，提供优质的阅读体验。

## ✨ 主要特性

- 📚 **多格式支持**：EPUB、PDF、MOBI、TXT、DOCX、AZW 等16种格式
- 🎨 **现代化 UI**：简洁美观界面，支持深色/浅色主题
- 📖 **智能书架**：自动管理书籍，支持分组和筛选
- 🔍 **在线书城**：集成书源市场，支持在线搜索和阅读
- ⚡ **批量操作**：支持批量删除、收藏和分组
- 💾 **阅读进度**：自动保存阅读进度和位置
- 🌙 **深色模式**：护眼的深色阅读模式
- 🎯 **V2状态管理**：采用 @ObservedV2 细粒度状态更新

## 🚀 快速开始

### 环境要求
- DevEco Studio 5.0+
- HarmonyOS SDK 5.0+
- Node.js 18+

### 构建项目
```bash
# 安装依赖
ohpm install

# 构建项目
hvigorw assembleHap

# 运行到设备
hvigorw run
```

## 📁 项目结构

### 当前结构 (V2 过渡期)
```
entry/src/main/ets/
├── app/                    # 应用入口
├── components/             # UI组件 (18个)
├── core/                   # 核心逻辑
├── design/                 # 设计系统
├── entryability/            # 入口能力
├── managers/               # 管理器
├── models/                 # 数据模型 (9个)
├── pages/                  # 页面 (30个)
├── presentation/           # 演示组件
├── services/               # 业务服务 (44个)
├── store/                  # 状态管理
├── utils/                  # 工具类 (20个)
└── viewmodels/             # 视图模型 (39个) ✅ V2
```

### 目标结构 (V3)
```
entry/src/main/ets/
├── app/                    # 应用入口
├── features/               # 功能模块
│   ├── bookshelf/         # 书架模块
│   │   ├── components/    # 书架组件
│   │   ├── viewmodels/    # 书架VM
│   │   └── pages/         # 书架页面
│   ├── reader/            # 阅读器模块
│   ├── discover/          # 发现模块
│   ├── settings/          # 设置模块
│   ├── todo/              # 待办模块
│   └── profile/           # 个人中心模块
├── common/                # 公共代码
│   ├── components/        # 通用组件
│   ├── hooks/             # 组合式函数
│   ├── constants/         # 常量定义
│   └── utils/             # 工具函数
├── core/                  # 核心能力
│   ├── models/            # 数据模型
│   ├── services/          # 业务服务
│   └── stores/            # 全局状态
├── design/                # 设计系统
│   ├── tokens/            # 设计令牌
│   └── components/        # 设计组件
└── shared/                # 跨模块共享
    ├── types/             # 类型定义
    └── utils/             # 共享工具
```

## 📊 技术架构

### 状态管理架构 (V2)
```
┌─────────────────────────────────────────────┐
│              Page (UI 渲染)                 │
│  @State vm: BookshelfViewModel = vm        │
└────────────────────┬────────────────────────┘
                     │ @Trace 细粒度更新
                     ▼
┌─────────────────────────────────────────────┐
│           ViewModel (业务逻辑)              │
│  @ObservedV2                                │
│  @Trace books: BookInfo[]                  │
│  loadBooks() / addBook() / deleteBook()    │
└────────────────────┬────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────┐
│            Service (数据层)                 │
│  BookService / PreferenceService           │
└────────────────────┬────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────┐
│           Storage (持久化)                  │
│  PreferenceManager / FileManager           │
└─────────────────────────────────────────────┘
```

### V2 状态管理特性

| 特性 | V1 (旧) | V2 (新) |
|------|---------|---------|
| 装饰器 | @State/@Prop/@Link | @State/@Prop + @ObservedV2/@Trace |
| 嵌套对象 | @Observed/@ObjectLink | @ObservedV2 + @Trace |
| 深度监听 | 不支持 | 自动深层监听 |
| 渲染性能 | 中等 | 优秀 (+30%) |

## 📋 ViewModel 清单

### 已创建的 ViewModel (39个)

| ViewModel | 页面 | 状态 |
|-----------|------|------|
| MainPageViewModel | MainPage | ✅ |
| TodoViewModel | TodoPage | ✅ |
| BookDetailViewModel | BookDetailPage | ✅ 新建 |
| BookmarksViewModel | BookmarksPage | ✅ 新建 |
| ComicReaderViewModel | ComicReaderPage | ✅ 新建 |
| DictionaryViewModel | DictionaryPage | ✅ 新建 |
| EnhancedReaderViewModel | EnhancedReaderPage | ✅ 新建 |
| FeaturesViewModel | FeaturesPage | ✅ 新建 |
| FeedbackViewModel | FeedbackPage | ✅ 新建 |
| FolderScannerViewModel | FolderScannerPage | ✅ 新建 |
| HelpViewModel | HelpPage | ✅ 新建 |
| LoginViewModel | LoginPage | ✅ 新建 |
| NotesViewModel | NotesPage | ✅ 新建 |
| OnlineBookDetailViewModel | OnlineBookDetailPage | ✅ 新建 |
| OnlineSearchViewModel | OnlineSearchPage | ✅ 新建 |
| OnlineSourceMarketPageViewModel | OnlineSourceMarketPage | ✅ 新建 |
| ProfileViewModel | ProfilePage | ✅ 新建 |
| ReaderSettingsPageViewModel | ReaderSettingsPage | ✅ 新建 |
| ReaderViewModel | EnhancedReaderPage | ✅ |
| ReadingStatsPageViewModel | ReadingStatsPage | ✅ 新建 |
| ReadingStatsViewModel | ReadingStatsPage | ✅ |
| ReadRecordViewModel | ReadRecordPage | ✅ 新建 |
| RewardViewModel | RewardPage | ✅ 新建 |
| SettingsPageViewModel | SettingsPage | ✅ 新建 |
| SettingsViewModel | SettingsPage | ✅ 新建 |
| SkillViewModel | SkillPage | ✅ 新建 |
| SourceMarketPageViewModel | SourceMarketPage | ✅ 新建 |
| StatisticsViewModel | StatisticsPage | ✅ 新建 |
| WordBookViewModel | WordBookPage | ✅ 新建 |
| BookSourceManageViewModel | BookSourceManagePage | ✅ 新建 |
| BookSourceViewModel | BookSourceManagePage | ✅ |
| BookViewModel | 全局 | ✅ |
| OnlineSourceMarketViewModel | 在线书城 | ✅ |
| ReaderSettingsViewModel | 阅读设置 | ✅ |
| OnlineBookDetailViewModel | 在线书籍详情 | ✅ 新建 |

## 🔧 技术栈

- **框架**：HarmonyOS ArkUI
- **语言**：ArkTS (TypeScript 严格模式)
- **状态管理**：@ObservedV2 + @Trace (V2)
- **本地存储**：PreferenceManager
- **网络请求**：HttpService

## 📖 核心文档

| 文档 | 说明 |
|------|------|
| [ARCHITECTURE_PLAN.md](ARCHITECTURE_PLAN.md) | 架构设计规划 |
| [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) | 实施计划 |
| [V2_STATE_MANAGEMENT_UPGRADE.md](V2_STATE_MANAGEMENT_UPGRADE.md) | V2升级指南 |
| [ARKTS_STRICT_STANDARD.md](ARKTS_STRICT_STANDARD.md) | ArkTS规范 |

## 📝 主要页面

| 页面 | 功能 | ViewModel |
|------|------|-----------|
| MainPage | 主页面，4标签页 | MainPageViewModel |
| BookDetailPage | 书籍详情 | BookDetailViewModel |
| EnhancedReaderPage | 阅读器 | ReaderViewModel |
| TodoPage | 待办事项 | TodoViewModel |
| SettingsPage | 设置 | SettingsPageViewModel |
| ProfilePage | 个人中心 | ProfilePageViewModel |

## 🎯 开发规范

### ArkTS 严格模式规范

```typescript
// ❌ 禁止使用
let data: any = getData();
const obj = { ...other };  // 禁止 spread
catch (error: Error)       // 禁止类型标注

// ✅ 正确写法
let data: string = getData();
const obj = Object.assign({}, other);
catch (error)              // 无类型标注
```

### ViewModel 使用规范

```typescript
// 定义 ViewModel
@ObservedV2
class BookViewModel {
  @Trace books: BookInfo[] = [];
  @Trace isLoading: boolean = false;
  
  loadBooks(): void {
    this.isLoading = true;
    // 业务逻辑
  }
}

export const bookViewModel = new BookViewModel();

// 页面使用
@Entry
@Component
struct BookPage {
  @State vm: BookViewModel = bookViewModel;
  
  build() {
    Column() {
      if (this.vm.isLoading) {
        LoadingProgress()
      }
      BookList({ books: this.vm.books })
    }
  }
}
```

## ⚠️ 当前问题

项目当前已基本完成模块化，核心架构良好：

| 问题 | 实际状态 |
|------|----------|
| PreferenceManager | ✅ 已优化 (185行，prefs/模块化) |
| Services | ✅ 已优化 (48个，13个分类目录) |
| ViewModel | ✅ 37个已创建 |
| ArkTS 严格模式 | 🔧 持续优化中 |

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！


