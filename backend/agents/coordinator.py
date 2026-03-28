"""
跨域知识协调Agent (全局)
职责: 汇总各域结果、处理域间冲突、全局置信度评估、触发人工介入
"""
from typing import Dict, Any, List
from .models import TaskResult, ConfidenceLevel, DomainType


class CrossDomainCoordinator:
    """跨域知识协调Agent - 全局协调"""

    def __init__(self):
        self.domain_agents = {}

    def register_domain_agent(self, domain: DomainType, agent):
        """注册域Agent"""
        self.domain_agents[domain] = agent

    async def coordinate(self, plan, context: Dict[str, Any] = None) -> Dict[str, Any]:
        """协调执行计划"""
        results = {}
        low_confidence_tasks = []

        # 按域分组执行任务
        domain_tasks = self._group_by_domain(plan.subtasks)

        for domain, tasks in domain_tasks.items():
            if domain not in self.domain_agents:
                continue

            agent = self.domain_agents[domain]

            for task in tasks:
                # 执行子任务
                result = await agent.process(task.parameters)
                results[task.id] = result

                # 记录低置信度任务
                if result.confidence < 70:
                    low_confidence_tasks.append({
                        "task_id": task.id,
                        "domain": domain,
                        "confidence": result.confidence,
                        "reason": "置信度低于阈值"
                    })

        # 全局置信度评估
        global_confidence = self._calculate_global_confidence(results)

        # 判断是否触发人工介入
        requires_human = len(low_confidence_tasks) > 0 or global_confidence < 70

        return {
            "success": True,
            "results": results,
            "global_confidence": global_confidence,
            "low_confidence_tasks": low_confidence_tasks,
            "requires_human_review": requires_human,
            "summary": self._generate_summary(results)
        }

    def _group_by_domain(self, subtasks):
        """按域分组任务"""
        groups = {}
        for task in subtasks:
            domain = task.domain
            if domain not in groups:
                groups[domain] = []
            groups[domain].append(task)
        return groups

    def _calculate_global_confidence(self, results: Dict[str, TaskResult]) -> float:
        """计算全局置信度"""
        if not results:
            return 0.0

        total_confidence = sum(r.confidence for r in results.values())
        return total_confidence / len(results)

    def _generate_summary(self, results: Dict[str, TaskResult]) -> str:
        """生成执行摘要"""
        domain_results = {}

        for task_id, result in results.items():
            domain = result.agent_name
            if domain not in domain_results:
                domain_results[domain] = []
            domain_results[domain].append(result)

        summary_parts = ["执行摘要:"]
        for domain, domain_result_list in domain_results.items():
            avg_confidence = sum(r.confidence for r in domain_result_list) / len(domain_result_list)
            summary_parts.append(f"- {domain}: {len(domain_result_list)}项任务, 平均置信度{avg_confidence:.1f}%")

        return "\n".join(summary_parts)

    def check_human_intervention(self, confidence: float, threshold: float = 70.0) -> bool:
        """检查是否需要人工介入"""
        return confidence < threshold
