# Janus v4.0 Agent 能力边界确认文档

> 文档版本: v1.0
> 生成日期: 2026-03-28
> 对应架构: 三层架构 + 三执行域

---

## 1. InteractionAgent (L1 交互层)

### 1.1 职责范围
| 维度 | 说明 |
|------|------|
| **核心职责** | 用户对话接口、意图识别、结果格式化展示 |
| **处理层级** | Layer 1 (输入处理 + 输出格式化) |
| **无状态** | 不保存对话历史，每次请求独立处理 |

### 1.2 输入/输出接口
```python
# 输入
async def process_input(
    user_message: str,
    context: List[AgentMessage] = None
) -> Dict[str, Any]

# 输出
{
    "intent": "quota|query|document|multi_domain",
    "task_description": str,
    "domains": List[str],
    "original_message": str
}

# 格式化输出
async def format_output(results: Dict[str, Any]) -> str
```

### 1.3 意图识别规则
| 执行域 | 触发关键词 | 优先级 |
|--------|-----------|--------|
| quota | 定额、造价、工程量、套取、清单、土建、安装、市政、园林、仿古、混凝土、钢筋、砌筑 | 默认 |
| query | 查询、招标、中标、价格、行情、多少钱、信息价、市场价、历史、类似项目 | 中 |
| document | 报告、文档、生成、导出、打印、PDF、Word、整理、归档、资料 | 低 |

### 1.4 异常处理策略
| 场景 | 处理方式 |
|------|---------|
| 无法识别意图 | 默认路由到 quota 域 |
| 多域触发 | 返回 multi_domain，由 PlanningAgent 拆解 |
| 空输入 | 返回友好提示，请求重新输入 |

### 1.5 置信度评估
- **不涉及** - 本Agent只负责意图分类，置信度评估由下游Agent负责

---

## 2. PlanningAgent (L2 规划层)

### 2.1 职责范围
| 维度 | 说明 |
|------|------|
| **核心职责** | 任务分解、Agent编排、执行计划生成、依赖关系识别 |
| **处理层级** | Layer 2 (任务规划) |
| **关键能力** | 专业识别、子任务生成、依赖标注 |

### 2.2 输入/输出接口
```python
# 输入
async def create_plan(
    task_description: str,
    domains: List[str]
) -> ExecutionPlan

# 输出
ExecutionPlan(
    plan_id: str,              # 8位UUID
    original_request: str,     # 原始请求
    subtasks: List[SubTask],   # 子任务列表
    estimated_steps: int,      # 预估步骤数
    domains_involved: List[DomainType]
)

# 子任务结构
SubTask(
    id: str,                   # 任务ID
    domain: DomainType,        # 执行域
    description: str,          # 任务描述
    parameters: Dict,          # 执行参数
    dependencies: List[str]    # 依赖任务ID列表
)
```

### 2.3 专业识别规则
| 专业 | 关键词 |
|------|--------|
| 建筑 | 土建、建筑、混凝土、钢筋、砌筑、装饰 |
| 安装 | 安装、电气、给排水、暖通、消防、空调 |
| 市政 | 市政、道路、桥涵、管网 |
| 园林 | 园林、绿化、景观 |
| 仿古 | 仿古、古建、斗拱 |

### 2.4 任务分解策略
```
quota 域任务:
  - 每个专业生成独立子任务
  - task_id: quota_{specialty}_{uuid}
  - 参数: {specialty, description, steps: [1,2,3,4]}

query 域任务:
  - tender: 招标/中标关键词
  - price: 价格/行情关键词
  - general: 默认通用查询

document 域任务:
  - report: 报告生成，可依赖 quota/query 结果
  - general: 通用文档处理
```

### 2.5 边界限制
| 限制项 | 说明 |
|--------|------|
| 不执行实际任务 | 只生成计划，不调用LLM/工具 |
| 不评估可行性 | 假设所有子任务都可执行 |
| 不处理循环依赖 | 依赖关系必须是DAG |

---

## 3. QuotaDomainKnowledgeAgent (L3 定额域)

### 3.1 职责范围
| 维度 | 说明 |
|------|------|
| **核心职责** | 定额套取全流程执行（4步流水线） |
| **处理层级** | Layer 3 执行域 |
| **专业覆盖** | 建筑、安装、市政、园林、仿古 |

### 3.2 输入/输出接口
```python
# 输入
async def process(parameters: Dict[str, Any]) -> TaskResult

# 参数
{
    "specialty": str,          # 专业类型
    "description": str,        # 用户原始描述
    "steps": List[str]         # 执行步骤标识
}

# 输出
TaskResult(
    success: bool,
    content: str,               # 格式化结果
    confidence: float,          # 四步平均置信度
    confidence_level: ConfidenceLevel,
    agent_name: "quota_domain",
    metadata: {
        "specialty": str,
        "step_results": {      # 每步详细结果
            "step1": TaskResult,
            "step2": TaskResult,
            "step3": TaskResult,
            "step4": TaskResult
        }
    }
)
```

### 3.3 4步流水线详解

#### Step 1: 清单初步整理
| 属性 | 说明 |
|------|------|
| Agent | step1_preliminary |
| 输入 | 用户原始描述 + 专业 |
| 处理 | 正则提取工程量、单位、项目名称 |
| 输出 | BillItem 列表 |
| 置信度 | 85% (有匹配) / 60% (无匹配) |
| 失败条件 | confidence < 70% 时提前返回 |

#### Step 2: 清单标准化
| 属性 | 说明 |
|------|------|
| Agent | step2_standardization |
| 输入 | Step1 输出的 items |
| 处理 | 名称规范化、单位标准化、特征提取 |
| 输出 | 标准化后的 items |
| 置信度 | 90% (规则明确) |
| 失败条件 | confidence < 70% 时提前返回 |

#### Step 3: 定额套取
| 属性 | 说明 |
|------|------|
| Agent | step3_matching |
| 输入 | 标准化后的 items + 专业 |
| 处理 | 定额编码匹配、单价查询、合价计算 |
| 输出 | 带定额编码的 items |
| 置信度 | 75% (AI匹配有不确定性) |
| 失败条件 | confidence < 70% 时提前返回 |

#### Step 4: 复核
| 属性 | 说明 |
|------|------|
| Agent | step4_review |
| 输入 | Step3 输出的 items |
| 处理 | 完整性检查、单价合理性检查、总价计算 |
| 输出 | 最终 items + issues 列表 |
| 置信度 | 85% (无issues) / 70% (有issues) |

### 3.4 知识库
```python
{
    "建筑": {
        "rules": ["定额规范-建筑分册", "工程量计算规则-建筑"],
        "units": {"m3": "立方米", "m2": "平方米", "m": "米"},
        "coefficients": {"人工": 1.0, "材料": 1.0, "机械": 1.0}
    },
    "安装": {
        "rules": ["定额规范-安装分册", "工程量计算规则-安装"],
        "units": {"m": "米", "套": "套", "台": "台"},
        "coefficients": {"人工": 1.05, "材料": 1.02, "机械": 1.0}
    }
}
```

### 3.5 异常处理策略
| 场景 | 处理方式 |
|------|---------|
| 某步置信度<70% | 提前返回，不执行后续步骤 |
| 未匹配定额编码 | 标记为 None，Step4 生成 issue |
| 单价异常(<=0) | Step4 标记 issue，但继续处理 |
| 专业未识别 | 默认使用"建筑"专业 |

---

## 4. QueryDomainAgent (L3 查询域)

### 4.1 职责范围
| 维度 | 说明 |
|------|------|
| **核心职责** | 招标信息、价格行情、历史数据查询 |
| **处理层级** | Layer 3 执行域 |
| **数据源** | 招标网站、价格数据库、历史项目库 |

### 4.2 输入/输出接口
```python
# 输入
async def process(parameters: Dict[str, Any]) -> TaskResult

# 参数
{
    "query_type": "tender|price|historical|general",
    "keywords": str
}

# 输出
TaskResult(
    success: bool,
    content: str,           # 查询结果文本
    confidence: float,      # 固定值: tender(80%), price(85%), historical(75%), general(70%)
    agent_name: "query_domain",
    metadata: {
        "query_type": str,
        "results" | "data" | "count": Any
    }
)
```

### 4.3 查询类型
| 类型 | 置信度 | 数据源 | 输出示例 |
|------|--------|--------|---------|
| tender | 80% | 政府采购网、公共资源交易中心、招标网 | 招标公告列表(标题、日期、预算) |
| price | 85% | 造价信息、市场价、信息价 | 材料价格表(人工、混凝土、钢筋) |
| historical | 75% | 历史项目库 | 类似项目数量、参考案例 |
| general | 70% | 综合查询 | 通用文本结果 |

### 4.4 边界限制
| 限制项 | 说明 |
|--------|------|
| 模拟数据 | 当前使用mock数据，非真实数据源 |
| 实时性 | 不保证价格/招标信息的实时更新 |
| 覆盖范围 | 仅支持预设的关键词匹配 |

---

## 5. DocumentDomainAgent (L3 资料域)

### 5.1 职责范围
| 维度 | 说明 |
|------|------|
| **核心职责** | 报告生成、文档制作、资料整理 |
| **处理层级** | Layer 3 执行域 |
| 模板支持 | 报告模板、预算书模板、结算书模板 |

### 5.2 输入/输出接口
```python
# 输入
async def process(parameters: Dict[str, Any]) -> TaskResult

# 参数
{
    "doc_type": "report|budget|settlement|organize|general",
    "quota_result": Dict,      # 可选: 定额域结果
    "query_result": Dict,      # 可选: 查询域结果
    "project_name": str        # 可选: 项目名称
}

# 输出
TaskResult(
    success: bool,
    content: str,              # 生成的文档内容
    confidence: float,         # report(85%), organize(90%), general(80%)
    agent_name: "document_domain",
    metadata: {
        "doc_type": str,
        "pages": int            # 仅report类型
    }
)
```

### 5.3 文档类型
| 类型 | 置信度 | 说明 |
|------|--------|------|
| report | 85% | 造价分析报告，含项目概况、清单、市场参考、结论、建议 |
| organize | 90% | 资料整理归档，按规范分类 |
| general | 80% | 通用文档处理 |

### 5.4 报告模板结构
```markdown
# 造价分析报告

## 一、项目概况
{project_name}

## 二、工程量清单
{quota_result.content}

## 三、市场参考
{query_result.content}

## 四、分析结论
根据定额套取结果和市场价格对比,本项目造价合理。

## 五、建议
1. 建议复核定额套用准确性
2. 关注材料价格波动
3. 参考类似项目经验
```

---

## 6. CrossDomainCoordinator (跨域协调)

### 6.1 职责范围
| 维度 | 说明 |
|------|------|
| **核心职责** | 域Agent注册、任务分发、结果汇总、冲突处理、人工介入判断 |
| **处理层级** | Layer 3 全局协调 |
| **无业务逻辑** | 不处理具体业务，只做协调 |

### 6.2 输入/输出接口
```python
# Agent注册
async def register_domain_agent(domain: DomainType, agent)

# 协调执行
async def coordinate(plan: ExecutionPlan, context: Dict = None) -> Dict[str, Any]

# 输出
{
    "success": bool,
    "results": Dict[str, TaskResult],    # 各任务ID对应的结果
    "global_confidence": float,          # 全局平均置信度
    "low_confidence_tasks": List[Dict],  # 低置信度任务列表
    "requires_human_review": bool,       # 是否需人工介入
    "summary": str                       # 执行摘要
}
```

### 6.3 任务分发逻辑
```python
# 1. 按 domain 分组子任务
domain_tasks = {
    DomainType.QUOTA: [subtask1, subtask2],
    DomainType.QUERY: [subtask3],
    DomainType.DOCUMENT: [subtask4]
}

# 2. 并行执行各域任务
for domain, tasks in domain_tasks.items():
    agent = self.domain_agents[domain]
    for task in tasks:
        result = await agent.process(task.parameters)
```

### 6.4 全局置信度计算
```python
global_confidence = sum(r.confidence for r in results.values()) / len(results)
```

### 6.5 人工介入触发条件
| 条件 | 说明 |
|------|------|
| 存在低置信度任务 | 任一任务 confidence < 70% |
| 全局置信度低 | global_confidence < 70% |
| 结果冲突 | 不同域结果存在矛盾（待实现） |

### 6.6 冲突处理策略（当前版本）
- **TBD** - 当前版本未实现自动冲突解决
- 仅记录低置信度任务，由人工介入处理

---

## 7. Agent协作契约

### 7.1 调用链路
```
用户输入
    ↓
InteractionAgent.process_input() → 意图识别
    ↓
PlanningAgent.create_plan() → 生成执行计划
    ↓
CrossDomainCoordinator.coordinate() → 分发任务
    ↓
├─→ QuotaDomainKnowledgeAgent.process() [可选]
├─→ QueryDomainAgent.process() [可选]
├─→ DocumentDomainAgent.process() [可选]
    ↓
InteractionAgent.format_output() → 格式化展示
    ↓
用户看到结果
```

### 7.2 数据流转
| 阶段 | 数据格式 |
|------|---------|
| L1→L2 | {intent, task_description, domains} |
| L2→L3 | ExecutionPlan (包含 SubTask 列表) |
| L3 内部 | TaskResult (统一结果格式) |
| L3→L1 | Dict[str, TaskResult] |
| L1→用户 | 格式化文本 |

### 7.3 错误处理约定
| 层级 | 错误处理方式 |
|------|-------------|
| L1 | 捕获所有异常，返回友好错误提示 |
| L2 | 不抛异常，返回空计划或降级计划 |
| L3 | 返回 TaskResult(success=False)，不抛异常 |
| Coordinator | 聚合各域错误，标记需人工审核 |

---

## 8. 待确认事项

| 序号 | 事项 | 优先级 |
|------|------|--------|
| 1 | 定额域4步流水线中各Step的详细Prompt设计 | 高 |
| 2 | QueryDomain 真实数据源集成方案 | 中 |
| 3 | DocumentDomain 更多模板类型支持 | 低 |
| 4 | CrossDomainCoordinator 冲突解决策略 | 中 |
| 5 | 人工介入界面设计（HITL） | 高 |

---

*文档生成完成 - Phase 2 结束*
