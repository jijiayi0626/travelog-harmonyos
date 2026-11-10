# 旅记 Travelog

一个 HarmonyOS NEXT（Stage 模型 / ArkTS / ArkUI 声明式 UI）旅行记录应用。记录旅程、图文时刻、地点足迹、旅行花费与行前清单，并为「多人共享 / 云端同步」预留了可插拔的数据层与接口契约。

## 功能

| 模块 | 能力 |
| --- | --- |
| 行程 | 旅行列表、新建/编辑、封面渐变卡、状态（计划中/进行中/已结束）、行程天数 |
| 时间线 | 按天分组展示图文记录，支持文字 + 相册多图（最多 9 张，图片复制到应用沙箱） |
| 足迹 | 地点打卡：定位取坐标（可手动填写）、城市聚合、点击跳转系统地图 |
| 账本 | 全球/单个旅行记账，金额、分类、备注、日期，分类占比条形统计 |
| 清单 | 行前待办，勾选/删除/进度统计 |
| 旅伴 | 成员列表、添加成员、邀请码复制（本地档案模式） |
| 我的 | 本地账号资料、数据统计、云同步状态、关于 |
| 云同步 | `ISyncService` 契约 + 本地 no-op 实现；后端接入后替换实现即可 |

## 技术要点

- **状态管理 V2**：`@ComponentV2` / `@Local` / `@Param` / `@Event` / `@Computed` / `@Monitor` / `@ObservedV2` + `@Trace`，跨页共享用 `AppStorageV2`。
- **路由**：统一 `Navigation + NavDestination + NavPathStack`（`AppRouter` 集中管理），未使用旧版 Router。
- **数据层**：`ITravelRepository` 接口 + `RdbTravelRepository`（`relationalStore` 本地 SQLite）实现，`RepositoryProvider` 单例注入。
- **刷新机制**：写操作后 `AppRefresh.bump()`，列表页 `@Monitor('refresh.tick')` 自动重拉，避免手动回调。
- **国际化**：中文 base / `zh_CN` / `en_US` 三套字符串资源，颜色走 `color.json`。

## 目录

```
entry/src/main/ets/
├── entryability/EntryAbility.ets      # 入口，初始化数据库
├── pages/Index.ets                    # Navigation 根 + 底部四 Tab + PageMap
├── pages/*.ets                        # 详情/编辑类 NavDestination 页面
├── view/                              # 四个 Tab 内容组件
├── components/                        # 可复用展示组件
├── viewmodel/                         # 页面状态容器（@ObservedV2）
├── model/Entities.ets                 # 领域模型
├── data/                              # RDB、Repository 接口与实现、注入点
├── service/                           # 账号、同步、媒体、定位、地图、刷新信号
├── common/                            # 路由表、Toast
└── utils/                             # 日期、分类工具
```

## 环境要求与构建

- DevEco Studio 5.0 及以上，HarmonyOS SDK **API 12（5.0.0）** 及以上。
- 打开 `TravelDiary` 工程目录 → `File > Project Structure > Signing Configs` 勾选 **Automatically generate signature**（本仓库未内置签名，属于本机凭据）。
- 执行 `hvigorw assembleHap` 或在 DevEco 中直接 Run。

> 说明：本工程在交付环境中没有 DevEco SDK，未执行真机编译；代码按 API 12 的标准 ArkTS/ArkUI 写法编写，建议首次打开后先 Sync 一次依赖再构建。

## 接入真实后端

1. 实现 `ITravelRepository` 的远程版本（如 `RemoteTravelRepository`），在 `RepositoryProvider.use(...)` 处切换。
2. 实现 `ISyncService` 的远程版本（如 `RemoteSyncService`），在 `SyncProvider.use(...)` 处切换。
3. 协议、字段与鉴权约定见 [docs/SYNC_API_CONTRACT.md](docs/SYNC_API_CONTRACT.md)。

## 已知边界

- **地图底图**：应用内嵌地图需要 AGC 开通 Map Kit 并配置 client_id，本工程默认用「足迹列表 + 跳转系统地图」实现，接入点见 `service/MapProvider.ets`。
- **多人共享**：本地模式提供成员档案与邀请码 UI；真正的多人协作依赖后端与账号体系（已留契约）。
- **图片**：从系统相册选择后复制到沙箱（`files/moment_images`），删除记录时会清理。
- **定位**：需用户授权 `ohos.permission.LOCATION` / `APPROXIMATELY_LOCATION`，拒绝授权时可手动填写地点。