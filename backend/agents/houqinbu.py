"""
后勤部 (跨域)
职责: 统筹协调、处理冲突、喊人帮忙
"""
from typing import Dict, Any, List
from datetime import datetime


class Houqinbu:
    """后勤部 - 全局协调"""

    def __init__(self):
        # 注册的部门经理
        self.departments = {}

    def register_department(self, name: str, manager):
        """注册部门"""
        self.departments[name] = manager

    async def coordinate(self, project_path: str, departments: List[str], task: Dict[str, Any]) -> Dict[str, Any]:
        """协调多部门任务"""

        results = {}
        low_confidence_tasks = []

        # 并行调用各部门（简化版顺序调用）
        for dept_name in departments:
            if dept_name not in self.departments:
                continue

            manager = self.departments[dept_name]

            # 调用部门处理
            result = await manager.process(task)
            results[dept_name] = result

            # 检查置信度
            if result.get("confidence", 100) < 70:
                low_confidence_tasks.append({
                    "department": dept_name,
                    "confidence": result.get("confidence", 0),
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

    def _calculate_global_confidence(self, results: Dict[str, Any]) -> float:
        """计算全局置信度"""
        if not results:
            return 0.0

        total_confidence = sum(r.get("confidence", 0) for r in results.values())
        return total_confidence / len(results)

    def _generate_summary(self, results: Dict[str, Any]) -> str:
        """生成执行摘要"""
        summary_parts = ["执行摘要:"]

        for dept, result in results.items():
            confidence = result.get("confidence", 0)
            summary_parts.append(f"- {dept}: 置信度{confidence:.0f}%")

        return "\n".join(summary_parts)
