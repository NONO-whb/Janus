"""
查询域Agent (Layer 3)
包含: 查询域知识Agent + 执行Agent
"""
from typing import Dict, Any, List
from .models import TaskResult, ConfidenceLevel


class QueryDomainAgent:
    """查询域Agent - 招标信息、价格行情、历史数据查询"""

    def __init__(self):
        self.knowledge_base = {
            "tender_sources": ["政府采购网", "公共资源交易中心", "招标网"],
            "price_sources": ["造价信息", "市场价", "信息价"],
            "historical_projects": []
        }

    async def process(self, parameters: Dict[str, Any]) -> TaskResult:
        """处理查询任务"""
        query_type = parameters.get("query_type", "general")
        keywords = parameters.get("keywords", "")

        if query_type == "tender":
            return await self._query_tender(keywords)
        elif query_type == "price":
            return await self._query_price(keywords)
        elif query_type == "historical":
            return await self._query_historical(keywords)
        else:
            return await self._general_query(keywords)

    async def _query_tender(self, keywords: str) -> TaskResult:
        """招标信息查询"""
        # 模拟招标信息查询
        mock_results = [
            {"title": f"{keywords}招标公告", "date": "2026-03-20", "budget": "500万"},
            {"title": f"{keywords}中标公示", "date": "2026-03-15", "budget": "480万"}
        ]

        confidence = 80.0  # 查询类置信度相对较高

        return TaskResult(
            success=True,
            content=f"招标信息查询结果:\n" + "\n".join([f"- {r['title']} ({r['date']}) 预算:{r['budget']}" for r in mock_results]),
            confidence=confidence,
            confidence_level=self._calculate_level(confidence),
            agent_name="query_domain",
            metadata={"query_type": "tender", "results": mock_results}
        )

    async def _query_price(self, keywords: str) -> TaskResult:
        """价格行情查询"""
        # 模拟价格查询
        price_data = {
            "人工": "120-150元/工日",
            "混凝土": "450-500元/m³",
            "钢筋": "3800-4200元/吨"
        }

        confidence = 85.0

        return TaskResult(
            success=True,
            content=f"价格行情:\n" + "\n".join([f"- {k}: {v}" for k, v in price_data.items()]),
            confidence=confidence,
            confidence_level=self._calculate_level(confidence),
            agent_name="query_domain",
            metadata={"query_type": "price", "data": price_data}
        )

    async def _query_historical(self, keywords: str) -> TaskResult:
        """历史数据查询"""
        confidence = 75.0

        return TaskResult(
            success=True,
            content=f"历史项目查询: 找到3个类似项目",
            confidence=confidence,
            confidence_level=self._calculate_level(confidence),
            agent_name="query_domain",
            metadata={"query_type": "historical", "count": 3}
        )

    async def _general_query(self, keywords: str) -> TaskResult:
        """通用查询"""
        confidence = 70.0

        return TaskResult(
            success=True,
            content=f"通用查询结果: {keywords}",
            confidence=confidence,
            confidence_level=self._calculate_level(confidence),
            agent_name="query_domain",
            metadata={"query_type": "general"}
        )

    def _calculate_level(self, confidence: float) -> ConfidenceLevel:
        if confidence >= 90:
            return ConfidenceLevel.HIGH
        elif confidence >= 70:
            return ConfidenceLevel.MEDIUM
        else:
            return ConfidenceLevel.LOW
