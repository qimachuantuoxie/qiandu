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

### 当前结构 (V3 模块化架构)
```
entry/src/main/ets/
├── app/                    # 应用入口
├── common/                 # 公共代码
│   ├── components/        # 通用组件 (18个)
│   ├── constants/         # 常量定义
│   ├── hooks/             # 组合式函数
│   └── utils/             # 工具函数 (20个)
├── core/                   # 核心能力
│   ├── models/            # 数据模型 (9个)
│   ├── services/          # 业务服务 (48个，13个分类)
│   ├── stores/            # 全局状态管理
│   ├── viewmodels/        # 核心ViewModel (兼容层)
│   └── utils/             # 核心工具类
├── design/                 # 设计系统
│   ├── tokens/            # 设计令牌
│   └── components/        # 设计组件
├── features/               # 功能模块 (V3架构)
│   ├── home/              # 首页模块
│   │   ├── components/    # 首页组件
│   │   ├── viewmodels/    # MainPageViewModel
│   │   └── pages/         # 首页页面
│   ├── bookshelf/         # 书架模块
│   │   ├── components/    # 书架组件
│   │   ├── viewmodels/    # BookDetail/Bookmarks/Notes VM
│   │   └── pages/         # 书架页面
│   ├── reader/            # 阅读器模块
│   │   ├── viewmodels/    # Reader/EnhancedReader/ComicReader VM
│   │   └── pages/         # 阅读器页面
│   ├── discover/          # 发现模块
│   │   ├── viewmodels/    # Todo/Features/Statistics VM
│   │   └── pages/         # 发现页面
│   ├── settings/          # 设置模块
│   │   ├── viewmodels/    # Settings/Help/Feedback VM
│   │   └── pages/         # 设置页面
│   ├── profile/           # 个人中心模块
│   │   ├── viewmodels/    # Profile/Login VM
│   │   └── pages/         # 个人中心页面
│   ├── online-books/      # 在线书城模块
│   │   ├── viewmodels/    # OnlineSearch/OnlineBookDetail VM
│   │   └── pages/         # 在线书城页面
│   ├── source-market/     # 书源市场模块
│   │   ├── viewmodels/    # BookSource/SourceMarket VM
│   │   └── pages/         # 书源市场页面
│   └── tools/             # 工具模块
│       ├── viewmodels/    # FolderScanner/Dictionary VM
│       └── pages/         # 工具页面
└── entryability/          # 入口能力
```

### 目标结构 (已完成迁移)
✅ V3 模块化架构已基本完成，所有 ViewModel 已按功能模块组织

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

### 已创建的 ViewModel (24个)

#### 核心模块 (core/)
| ViewModel | 说明 | 状态 |
|-----------|------|------|
| BookViewModel | 书籍管理 (兼容层，转发到BookStore) | ✅ |

#### 首页模块 (features/home/)
| ViewModel | 页面 | 状态 |
|-----------|------|------|
| MainPageViewModel | MainPage (主页面) | ✅ |

#### 书架模块 (features/bookshelf/)
| ViewModel | 页面 | 状态 |
|-----------|------|------|
| BookDetailViewModel | BookDetailPage (书籍详情) | ✅ |
| BookmarksViewModel | BookmarksPage (书签管理) | ✅ |
| NotesViewModel | NotesPage (笔记管理) | ✅ |

#### 阅读器模块 (features/reader/)
| ViewModel | 页面 | 状态 |
|-----------|------|------|
| ReaderViewModel | EnhancedReaderPage (基础阅读器) | ✅ |
| EnhancedReaderViewModel | EnhancedReaderPage (增强阅读器) | ✅ |
| ComicReaderViewModel | ComicReaderPage (漫画阅读器) | ✅ |
| ReaderSettingsViewModel | ReaderSettingsPage (阅读设置) | ✅ |

#### 发现模块 (features/discover/)
| ViewModel | 页面 | 状态 |
|-----------|------|------|
| TodoViewModel | TodoPage (待办事项) | ✅ |
| FeaturesViewModel | FeaturesPage (功能特性) | ✅ |
| StatisticsViewModel | StatisticsPage (统计信息) | ✅ |
| ReadingStatsViewModel | ReadingStatsPage (阅读统计) | ✅ |
| ReadRecordViewModel | ReadRecordPage (阅读记录) | ✅ |
| WordBookViewModel | WordBookPage (生词本) | ✅ |

#### 设置模块 (features/settings/)
| ViewModel | 页面 | 状态 |
|-----------|------|------|
| SettingsViewModel | SettingsPage (设置管理) | ✅ |
| SettingsPageViewModel | SettingsPage (页面状态) | ✅ |
| HelpViewModel | HelpPage (帮助文档) | ✅ |
| FeedbackViewModel | FeedbackPage (反馈建议) | ✅ |
| RewardViewModel | RewardPage (打赏支持) | ✅ |
| SkillViewModel | SkillPage (技能展示) | ✅ |

#### 个人中心模块 (features/profile/)
| ViewModel | 页面 | 状态 |
|-----------|------|------|
| ProfileViewModel | ProfilePage (个人信息) | ✅ |
| ProfilePageViewModel | ProfilePage (页面状态) | ✅ |
| LoginViewModel | LoginPage (登录注册) | ✅ |

#### 在线书城模块 (features/online-books/)
| ViewModel | 页面 | 状态 |
|-----------|------|------|
| OnlineSearchViewModel | OnlineSearchPage (在线搜索) | ✅ |
| OnlineBookDetailViewModel | OnlineBookDetailPage (在线书籍详情) | ✅ |
| OnlineSourceMarketViewModel | OnlineSourceMarketPage (在线书源市场) | ✅ |

#### 书源市场模块 (features/source-market/)
| ViewModel | 页面 | 状态 |
|-----------|------|------|
| BookSourceViewModel | BookSourceManagePage (书源管理) | ✅ |
| BookSourceManageViewModel | BookSourceManagePage (书源管理页面) | ✅ |
| SourceMarketViewModel | SourceMarketPage (书源市场) | ✅ |

#### 工具模块 (features/tools/)
| ViewModel | 页面 | 状态 |
|-----------|------|------|
| FolderScannerViewModel | FolderScannerPage (文件夹扫描) | ✅ |
| DictionaryViewModel | DictionaryPage (词典查询) | ✅ |

## 🔧 技术栈

- **框架**：HarmonyOS ArkUI (Stage Model)
- **语言**：ArkTS (TypeScript 严格模式)
- **SDK版本**：HarmonyOS 6.1.0(23), API Level 23
- **状态管理**：@ObservedV2 + @Trace (V2细粒度响应式)
- **全局状态**：@hadss/state_store (BookStore等)
- **本地存储**：PreferenceManager (首选项管理)
- **网络请求**：HttpService
- **构建工具**：Hvigor
- **包管理**：ohpm (Open Harmony Package Manager)
- **测试框架**：@ohos/hypium (Mocha风格)

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

## ⚠️ 当前状态

项目已完成V3模块化架构升级，核心架构良好：

| 项目 | 状态 |
|------|------|
| V3模块化架构 | ✅ 已完成 (8个功能模块) |
| ViewModel迁移 | ✅ 24个ViewModel已按模块组织 |
| PreferenceManager | ✅ 已优化 (185行，prefs/模块化) |
| Services | ✅ 已优化 (48个服务，13个分类目录) |
| 状态管理V2 | ✅ 全部使用@ObservedV2 + @Trace |
| ArkTS严格模式 | 🔧 持续优化中 |
| 代码规范 | ✅ 遵循AGENTS.md规范 |

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！


