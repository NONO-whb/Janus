"""
资料部经理 (Layer 3)
职责: 管资料、记开竣工
"""
from typing import Dict, Any, List
from datetime import datetime


class ZiliaobuManager:
    """资料部经理 - 资料域大脑"""

    def __init__(self):
        # 模板库
        self.templates = {
            "材料报验": "材料进场报验单模板",
            "竣工": "竣工验收报告模板",
            "签证": "现场签证单模板",
            "联系单": "工作联系单模板"
        }

        # 项目时间记录
        self.project_dates = {}  # project_name -> {开工, 竣工}

    async def process(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """处理资料部任务"""

        request = task.get("request", "")
        project_name = task.get("project_name", "")

        # 判断任务类型
        if "开工" in request:
            return self._record_start_date(project_name)
        elif "竣工" in request:
            return self._record_end_date(project_name)
        elif "报验" in request:
            return await self._handle_baoyan(request)
        elif "签证" in request or "联系单" in request:
            return await self._handle_qianzheng(request)
        else:
            return await self._handle_general(request)

    def _record_start_date(self, project_name: str) -> Dict[str, Any]:
        """记录开工日期"""
        self.project_dates[project_name] = {
            "开工": datetime.now().strftime("%Y-%m-%d"),
            "竣工": None
        }

        return {
            "success": True,
            "content": f"已记录项目 {project_name} 开工日期: {self.project_dates[project_name]['开工']}",
            "confidence": 100,
            "metadata": {"action": "record_start", "date": self.project_dates[project_name]['开工']}
        }

    def _record_end_date(self, project_name: str) -> Dict[str, Any]:
        """记录竣工日期"""
        if project_name in self.project_dates:
            self.project_dates[project_name]["竣工"] = datetime.now().strftime("%Y-%m-%d")

        return {
            "success": True,
            "content": f"已记录项目 {project_name} 竣工日期: {self.project_dates[project_name]['竣工']}",
            "confidence": 100,
            "metadata": {"action": "record_end", "date": self.project_dates[project_name]['竣工']}
        }

    async def _handle_baoyan(self, request: str) -> Dict[str, Any]:
        """处理材料报验"""
        content = """材料报验资料：
- 材料进场报验单（模板）
- 合格证收集清单
- 检验批验收记录"""

        return {
            "success": True,
            "content": content,
            "confidence": 90,
            "metadata": {"doc_type": "baoyan"}
        }

    async def _handle_qianzheng(self, request: str) -> Dict[str, Any]:
        """处理签证/联系单"""
        content = """签证资料：
- 现场签证单（模板）
- 工程量计算书
- 影像资料清单"""

        return {
            "success": True,
            "content": content,
            "confidence": 90,
            "metadata": {"doc_type": "qianzheng"}
        }

    async def _handle_general(self, request: str) -> Dict[str, Any]:
        """通用资料处理"""
        return {
            "success": True,
            "content": "资料处理完成",
            "confidence": 80,
            "metadata": {"doc_type": "general"}
        }
