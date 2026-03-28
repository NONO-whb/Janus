"""
信息部经理 (Layer 3)
职责: 查信息、审文件
"""
from typing import Dict, Any, List
from datetime import datetime


class XinxibuManager:
    """信息部经理 - 查询域大脑"""

    def __init__(self):
        # 信息源配置
        self.query_sources = {
            "tender": ["政府采购网", "公共资源交易中心", "招标网"],
            "price": ["造价信息", "市场价", "信息价"],
            "historical": ["历史项目库"]
        }

    async def process(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """处理信息部任务"""

        request = task.get("request", "")

        # 判断任务类型
        if any(kw in request for kw in ["审查", "审", "合同", "招标文件", "投标"]):
            # 文件审查任务
            return await self._handle_file_review(request)
        else:
            # 信息查询任务
            return await self._handle_info_query(request)

    async def _handle_info_query(self, request: str) -> Dict[str, Any]:
        """处理信息查询"""

        # 判断查询类型
        if "招标" in request or "中标" in request:
            return await self._query_tender(request)
        elif "价格" in request or "行情" in request:
            return await self._query_price(request)
        else:
            return await self._query_general(request)

    async def _query_tender(self, request: str) -> Dict[str, Any]:
        """查询招标信息"""
        # 模拟查询结果
        content = """招标信息：
- XX学校综合楼招标公告（3天前）预算500万
- XX医院项目中标公示（1周前）中标480万
- XX办公楼招标变更（2天前）"""

        return {
            "success": True,
            "content": content,
            "confidence": 80,
            "metadata": {"query_type": "tender", "count": 3}
        }

    async def _query_price(self, request: str) -> Dict[str, Any]:
        """查询价格行情"""
        content = """价格行情（2026年3月）：
- 人工：120-150元/工日
- C30混凝土：450-500元/m³
- 钢筋：3800-4200元/吨"""

        return {
            "success": True,
            "content": content,
            "confidence": 85,
            "metadata": {"query_type": "price"}
        }

    async def _query_general(self, request: str) -> Dict[str, Any]:
        """通用查询"""
        return {
            "success": True,
            "content": f"查询结果: {request}",
            "confidence": 70,
            "metadata": {"query_type": "general"}
        }

    async def _handle_file_review(self, request: str) -> Dict[str, Any]:
        """处理文件审查"""

        # 模拟审查报告
        content = """《文件审查报告》

一、合同审查
【风险1】付款条款
- 条款内容：预付款仅10%
- 风险等级：高
- 建议：建议协商提高至15-20%

【风险2】变更时限
- 条款内容：变更发生后14天内必须提出
- 风险等级：中
- 建议：安排专人跟踪

二、总体评估
风险等级：中
重点关注：付款条款、变更时限"""

        return {
            "success": True,
            "content": content,
            "confidence": 85,
            "metadata": {"review_type": "contract", "risk_count": 2}
        }
