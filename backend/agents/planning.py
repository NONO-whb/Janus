"""
任务规划Agent (Layer 2)
职责: 任务分解、Agent编排、执行计划生成
"""
from typing import Dict, Any, List
import uuid
from .models import ExecutionPlan, SubTask, DomainType


class PlanningAgent:
    """任务规划Agent - 系统大脑"""

    def __init__(self):
        self.system_prompt = """你是Janus造价助手的任务规划Agent。

职责:
1. 分析用户请求,识别涉及哪些执行域
2. 将复杂任务拆分为可并行/串行的子任务
3. 为每个子任务指定执行域和参数
4. 确定任务依赖关系

执行域说明:
- quota(定额域): 工程量清单、定额套取、造价计算
- query(查询域): 招标信息、价格行情、历史数据查询
- document(资料域): 报告生成、文档制作、资料整理

输出要求:
- 每个子任务必须明确domain类型
- 标注任务间的依赖关系
- 预估执行步骤数
"""

    async def create_plan(self, task_description: str, domains: List[str]) -> ExecutionPlan:
        """创建执行计划"""
        subtasks = []

        # 根据涉及的域创建子任务
        if "quota" in domains:
            quota_tasks = self._create_quota_tasks(task_description)
            subtasks.extend(quota_tasks)

        if "query" in domains:
            query_tasks = self._create_query_tasks(task_description)
            subtasks.extend(query_tasks)

        if "document" in domains:
            document_tasks = self._create_document_tasks(task_description)
            subtasks.extend(document_tasks)

        # 如果没有明确域,默认为定额域
        if not subtasks:
            subtasks = self._create_quota_tasks(task_description)

        return ExecutionPlan(
            plan_id=str(uuid.uuid4())[:8],
            original_request=task_description,
            subtasks=subtasks,
            estimated_steps=len(subtasks),
            domains_involved=list(set(t.domain for t in subtasks))
        )

    def _create_quota_tasks(self, description: str) -> List[SubTask]:
        """创建定额域子任务"""
        tasks = []

        # 解析专业类型
        specialties = self._extract_specialties(description)

        for specialty in specialties:
            task_id = f"quota_{specialty}_{str(uuid.uuid4())[:4]}"
            tasks.append(SubTask(
                id=task_id,
                domain=DomainType.QUOTA,
                description=f"{specialty}专业定额套取",
                parameters={
                    "specialty": specialty,
                    "description": description,
                    "steps": ["step1", "step2", "step3", "step4"]
                }
            ))

        return tasks

    def _create_query_tasks(self, description: str) -> List[SubTask]:
        """创建查询域子任务"""
        tasks = []

        # 判断查询类型
        if "招标" in description or "中标" in description:
            tasks.append(SubTask(
                id=f"query_tender_{str(uuid.uuid4())[:4]}",
                domain=DomainType.QUERY,
                description="招标信息查询",
                parameters={"query_type": "tender", "keywords": description}
            ))

        if "价格" in description or "行情" in description or "多少钱" in description:
            tasks.append(SubTask(
                id=f"query_price_{str(uuid.uuid4())[:4]}",
                domain=DomainType.QUERY,
                description="价格行情查询",
                parameters={"query_type": "price", "keywords": description}
            ))

        if not tasks:
            tasks.append(SubTask(
                id=f"query_general_{str(uuid.uuid4())[:4]}",
                domain=DomainType.QUERY,
                description="通用信息查询",
                parameters={"query_type": "general", "keywords": description}
            ))

        return tasks

    def _create_document_tasks(self, description: str) -> List[SubTask]:
        """创建资料域子任务"""
        tasks = []

        # 判断文档类型
        if "报告" in description:
            tasks.append(SubTask(
                id=f"doc_report_{str(uuid.uuid4())[:4]}",
                domain=DomainType.DOCUMENT,
                description="生成造价分析报告",
                parameters={"doc_type": "report"},
                dependencies=[]  # 依赖定额域和查询域结果
            ))
        else:
            tasks.append(SubTask(
                id=f"doc_general_{str(uuid.uuid4())[:4]}",
                domain=DomainType.DOCUMENT,
                description="文档处理",
                parameters={"doc_type": "general"}
            ))

        return tasks

    def _extract_specialties(self, description: str) -> List[str]:
        """从描述中提取专业类型"""
        specialties = []
        desc = description.lower()

        specialty_keywords = {
            "建筑": ["土建", "建筑", "混凝土", "钢筋", "砌筑", "装饰"],
            "安装": ["安装", "电气", "给排水", "暖通", "消防", "空调"],
            "市政": ["市政", "道路", "桥涵", "管网"],
            "园林": ["园林", "绿化", "景观"],
            "仿古": ["仿古", "古建", "斗拱"]
        }

        for specialty, keywords in specialty_keywords.items():
            if any(kw in desc for kw in keywords):
                specialties.append(specialty)

        if not specialties:
            specialties = ["建筑"]  # 默认建筑专业

        return specialties
