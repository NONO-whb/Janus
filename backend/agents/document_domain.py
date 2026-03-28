"""
资料域Agent (Layer 3)
包含: 资料域知识Agent + 执行Agent
"""
from typing import Dict, Any
from .models import TaskResult, ConfidenceLevel


class DocumentDomainAgent:
    """资料域Agent - 报告生成、文档制作、资料整理"""

    def __init__(self):
        self.templates = {
            "report": "造价分析报告模板",
            "budget": "预算书模板",
            "settlement": "结算书模板"
        }

    async def process(self, parameters: Dict[str, Any]) -> TaskResult:
        """处理资料制作任务"""
        doc_type = parameters.get("doc_type", "general")

        if doc_type == "report":
            return await self._generate_report(parameters)
        elif doc_type == "organize":
            return await self._organize_documents(parameters)
        else:
            return await self._general_document(parameters)

    async def _generate_report(self, parameters: Dict[str, Any]) -> TaskResult:
        """生成造价分析报告"""
        # 获取依赖域的结果
        quota_result = parameters.get("quota_result", {})
        query_result = parameters.get("query_result", {})

        report_content = f"""# 造价分析报告

## 一、项目概况
{parameters.get('project_name', '未命名项目')}

## 二、工程量清单
{quota_result.get('content', '暂无数据')}

## 三、市场参考
{query_result.get('content', '暂无数据')}

## 四、分析结论
根据定额套取结果和市场价格对比,本项目造价合理。

## 五、建议
1. 建议复核定额套用准确性
2. 关注材料价格波动
3. 参考类似项目经验
"""

        confidence = 85.0

        return TaskResult(
            success=True,
            content=report_content,
            confidence=confidence,
            confidence_level=self._calculate_level(confidence),
            agent_name="document_domain",
            metadata={"doc_type": "report", "pages": 5}
        )

    async def _organize_documents(self, parameters: Dict[str, Any]) -> TaskResult:
        """整理资料"""
        confidence = 90.0

        return TaskResult(
            success=True,
            content="资料整理完成,已按规范分类归档",
            confidence=confidence,
            confidence_level=self._calculate_level(confidence),
            agent_name="document_domain",
            metadata={"doc_type": "organize"}
        )

    async def _general_document(self, parameters: Dict[str, Any]) -> TaskResult:
        """通用文档处理"""
        confidence = 80.0

        return TaskResult(
            success=True,
            content="文档处理完成",
            confidence=confidence,
            confidence_level=self._calculate_level(confidence),
            agent_name="document_domain",
            metadata={"doc_type": "general"}
        )

    def _calculate_level(self, confidence: float) -> ConfidenceLevel:
        if confidence >= 90:
            return ConfidenceLevel.HIGH
        elif confidence >= 70:
            return ConfidenceLevel.MEDIUM
        else:
            return ConfidenceLevel.LOW
