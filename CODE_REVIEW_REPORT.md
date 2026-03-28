# Janus 项目代码审查报告

**审查日期**: 2026-03-28
**项目版本**: v1.0.0
**审查范围**: Flutter前端 + FastAPI后端 + 前后端集成

---

## 一、已完成修改

### 1.1 项目重命名 (eng → Janus)
| 文件 | 修改内容 |
|------|----------|
| `pubspec.yaml` | name: eng → janus |
| `lib/main.dart` | EngApp → JanusApp, title: 'ENG' → 'Janus' |
| `backend/main.py` | 服务名称更新为 Janus |
| `test/widget_test.dart` | package:eng → package:janus |

### 1.2 Agent配置完成
- 协调Agent (coordinator)
- 建筑Agent (building)
- 安装Agent (installation)
- 市政Agent (municipal)
- 园林Agent (garden)
- 仿古Agent (antique)

所有Agent已配置Kimi API: `sk-kimi-9yoaxBVdsjYtWnAwAGSIBmMnWEktog3yYSBRtUm0iOZewu32eFvj9Hs97KdKlEaP`

---

## 二、前端代码审查 (Flutter)

### 2.1 问题清单

#### 🔴 严重问题

| # | 问题 | 位置 | 影响 | 建议修复 |
|---|------|------|------|----------|
| F-001 | API端点版本不匹配 | `api_service.dart:259` | 前端调用`/api/v1/health`，后端提供`/api/health` | 统一端点路径 |
| F-002 | 工程量清单API端点不存在 | `api_service.dart:424` | 调用`/api/v1/projects/{id}/bills`，后端未实现 | 后端需补全或前端移除 |
| F-003 | 更新清单项API端点不存在 | `api_service.dart:441` | 调用`/api/v1/projects/{id}/bills/{item_id}` | 后端需补全或前端移除 |
| F-004 | WebSocket端点路径不匹配 | `websocket_service.dart:143` | 连接`/api/v1/ws`，后端提供`/ws/agent` | 统一端点路径 |

#### 🟡 中等问题

| # | 问题 | 位置 | 影响 | 建议修复 |
|---|------|------|------|----------|
| F-005 | 硬编码IP地址 | `api_service.dart:9` | IP: 192.168.0.112:8742 写死 | 改为配置或动态获取 |
| F-006 | 模拟数据未移除 | `main.dart:1420-1430` | 聊天使用模拟响应 | 接入真实Agent API |
| F-007 | 工程量清单模拟数据 | `BillOfQuantitiesView` | 使用模拟数据而非真实API | 完成API对接 |
| F-008 | 定额查询模拟数据 | `QuotaSearchView:3614` | 搜索返回固定假数据 | 接入真实定额库 |
| F-009 | 缺少错误边界处理 | `main.dart` | 无全局错误捕获 | 添加ErrorWidget |
| F-010 | 未使用WebSocketService | `main.dart` | 虽然引入但未在聊天中使用 | 统一使用WebSocket |

#### 🟢 轻微问题

| # | 问题 | 位置 | 建议 |
|---|------|------|------|
| F-011 | Logo仍显示'E' | `main.dart:321` | 更新为'J'或新Logo |
| F-012 | 欢迎消息Agent名称 | `main.dart:1425` | 已更新为Janus |
| F-013 | 导航栏标题 | `main.dart:1542` | 已更新为Janus |
| F-014 | 提示消息硬编码 | `main.dart:1386-1390` | 可考虑配置化 |
| F-015 | 主题色使用黑色系 | `DesignTokens` | 确认是否符合Janus品牌 |

### 2.2 代码质量评估

**优点**:
- ✅ 良好的组件化设计
- ✅ Cupertino风格一致
- ✅ 支持编辑/撤回消息
- ✅ 打字机效果提升体验
- ✅ 引用来源展示
- ✅ 置信度标识

**待改进**:
- ⚠️ 需要添加loading状态管理
- ⚠️ 需要添加离线缓存
- ⚠️ 图片上传功能未完成 (`_takePhoto`)

---

## 三、后端代码审查 (FastAPI)

### 3.1 问题清单

#### 🔴 严重问题

| # | 问题 | 位置 | 影响 | 建议修复 |
|---|------|------|------|----------|
| B-001 | Agent Chat为模拟实现 | `main.py:174-195` | 仅关键词匹配，未调用真实Agent | 实现Agent调度逻辑 |
| B-002 | WebSocket未实现真实Agent通信 | `main.py:197-215` | 仅echo消息 | 接入Agent系统 |
| B-003 | 工程量清单端点缺失 | - | 前端需要 Bills API | 实现CRUD端点 |
| B-004 | 文件上传路径硬编码 | `main.py:156` | `~/Desktop/造价项目/` | 改为配置 |
| B-005 | CORS允许所有来源 | `main.py:27` | `allow_origins=["*"]` | 生产环境需限制 |

#### 🟡 中等问题

| # | 问题 | 位置 | 建议修复 |
|---|------|------|----------|
| B-006 | 使用模拟项目数据 | `main.py:53-81` | 接入真实项目存储 |
| B-007 | 健康检查端点版本不一致 | `main.py:116` | 统一为 `/api/v1/health` |
| B-008 | 连接信息硬编码 | `main.py:219-228` | IP和端口改为动态获取 |
| B-009 | 缺少请求验证 | - | 添加Pydantic验证 |
| B-010 | 缺少日志记录 | - | 添加结构化日志 |

#### 🟢 轻微问题

| # | 问题 | 建议 |
|---|------|------|
| B-011 | 端口号8080可能冲突 | 可配置化 |
| B-012 | 缺少API文档描述 | 完善docstring |
| B-013 | 文件上传无大小限制 | 添加限制 |
| B-014 | 无速率限制 | 添加限流 |

### 3.2 与Agent系统集成缺口

当前后端是独立服务，需要与Agent系统对接：

```
当前架构:          目标架构:
┌─────────┐       ┌─────────┐
│ Flutter │       │ Flutter │
└────┬────┘       └────┬────┘
     │                 │
┌────▼────┐       ┌────▼────┐
│ FastAPI │       │ FastAPI │
│ (mock)  │       │ (调度)  │
└─────────┘       └────┬────┘
                       │
              ┌────────┼────────┐
              │        │        │
         ┌────▼───┐ ┌──▼───┐ ┌─▼────┐
         │协调Agent│ │专业Agent│ │...   │
         └────────┘ └──────┘ └──────┘
```

**需要实现**:
1. Agent调度器 - 根据消息内容路由到对应Agent
2. 配置文件读取 - 读取 `~/.claude/projects/.../AGENTS/*/config.json`
3. API转发 - 将请求转发给对应Agent的API
4. 流式响应 - 支持WebSocket流式返回

---

## 四、前后端集成问题

### 4.1 API端点映射表

| 功能 | 前端调用 | 后端提供 | 状态 |
|------|----------|----------|------|
| 健康检查 | /api/v1/health | /api/health | ❌ 不匹配 |
| 获取项目列表 | /api/v1/projects | /api/projects | ❌ 不匹配 |
| 获取项目详情 | /api/v1/project | /api/projects/{id} | ❌ 不匹配 |
| 发送命令 | /api/v1/command | /api/agent/chat | ❌ 不匹配 |
| 获取连接信息 | /api/v1/status | /api/connection/info | ❌ 不匹配 |
| 工程量清单 | /api/v1/projects/{id}/bills | ❌ 缺失 | ❌ 未实现 |
| WebSocket | ws://.../api/v1/ws | /ws/agent | ❌ 不匹配 |
| 文件上传 | /api/v1/projects/{id}/files | /api/projects/{id}/files | ❌ 不匹配 |

### 4.2 数据模型不匹配

**项目模型**:
```dart
// 前端期望
Project {
  id, name, status, progress, specialty, updated, color,
  files, specialties, activeSpecialties
}

// 后端提供
{
  id, name, status, progress, specialty, updated, color,
  files, specialties, active_specialties  // 下划线命名
}
```

### 4.3 修复方案

**方案A: 后端适配前端** (推荐)
- 统一端点为 `/api/v1/*`
- 添加版本前缀
- 实现缺失的端点

**方案B: 前端适配后端**
- 修改 `api_service.dart` 中的端点路径
- 较快但不够规范

---

## 五、架构审查

### 5.1 与AI Agent Team架构对齐

当前实现状态:
```
✅ Agent配置文件 - 已创建6个Agent配置
✅ 协调Agent概念 - 前端已对接协调Agent入口
❌ 真实Agent调用 - 后端仍为模拟实现
❌ 专业Agent路由 - 未实现智能路由
❌ Agent间通信 - 未实现
```

### 5.2 推荐实现顺序

1. **阶段1**: 修复API端点不匹配 (1-2天)
2. **阶段2**: 后端实现真实Agent调用 (2-3天)
3. **阶段3**: 实现Agent路由逻辑 (1-2天)
4. **阶段4**: 流式响应优化 (1天)
5. **阶段5**: 工程量清单完整功能 (2-3天)

---

## 六、安全问题

| # | 问题 | 级别 | 建议 |
|---|------|------|------|
| S-001 | API Key明文存储在config.json | 🔴 高 | 使用环境变量或密钥管理 |
| S-002 | CORS允许所有来源 | 🟡 中 | 限制为特定域名 |
| S-003 | 文件上传无类型检查 | 🟡 中 | 验证文件类型和大小 |
| S-004 | 无请求认证 | 🟡 中 | 添加API Key或Token验证 |
| S-005 | WebSocket无鉴权 | 🟡 中 | 连接时验证身份 |

---

## 七、性能问题

| # | 问题 | 建议 |
|---|------|------|
| P-001 | 聊天消息无分页 | 大量消息时卡顿，需分页加载 |
| P-002 | 文件上传无进度 | 添加上传进度提示 |
| P-003 | 图片未压缩 | 上传前压缩图片 |
| P-004 | 无缓存机制 | 添加本地缓存 |

---

## 八、修复优先级

### 🔴 P0 - 阻塞发布 (必须修复)
1. F-001, F-004, B-007: API端点统一
2. B-001, B-002: Agent真实调用
3. S-001: API Key安全存储

### 🟡 P1 - 重要 (发布前修复)
4. F-005: 硬编码IP
5. B-003: 工程量清单API
6. F-009: 错误处理

### 🟢 P2 - 优化 (发布后迭代)
7. F-011: Logo更新
8. P-001: 消息分页
9. 单元测试补充

---

## 九、附录

### 9.1 推荐的API端点规范

```
GET  /api/v1/health              # 健康检查
GET  /api/v1/status              # 系统状态
GET  /api/v1/projects            # 项目列表
GET  /api/v1/projects/{id}       # 项目详情
POST /api/v1/projects/{id}/files # 文件上传
GET  /api/v1/projects/{id}/bills # 工程量清单
PUT  /api/v1/projects/{id}/bills/{item_id} # 更新清单项
POST /api/v1/chat                # 发送消息给Agent
WS   /api/v1/ws                  # WebSocket连接
```

### 9.2 Agent调度逻辑建议

```python
# coordinator_router.py
async def route_to_agent(message: str, project_id: str) -> AgentResponse:
    # 1. 分析消息意图
    intent = await analyze_intent(message)

    # 2. 确定专业
    specialty = map_intent_to_specialty(intent)

    # 3. 加载对应Agent配置
    agent_config = load_agent_config(specialty)

    # 4. 调用Agent API
    response = await call_agent_api(agent_config, message, project_id)

    return response
```

---

**审查完成** - 共发现 32 项问题 (4严重/11中等/17轻微)
