"""
工程部经理 (Layer 3)
职责: 套定额总负责，指挥4个专员，复核结果
"""
from typing import Dict, Any, List
from datetime import datetime
from pathlib import Path


class GongchengbuManager:
    """工程部经理 - 造价域大脑"""

    def __init__(self):
        # 知识库（简化版，实际应加载完整定额库）
        self.knowledge_base = {
            "建筑": {
                "定额前缀": "A",
                "单位_map": {"m3": "m³", "m2": "m²", "立方米": "m³", "平方米": "m²"},
                "基价参考": {"人工": 120, "材料": 200, "机械": 80}
            },
            "安装": {
                "定额前缀": "B",
                "单位_map": {"m": "m", "套": "套", "台": "台"},
                "基价参考": {"人工": 150, "材料": 180, "机械": 60}
            }
        }

        # 下属专员（实际应实例化专员对象）
        self.tuzhi_agent = None  # 图纸专员
        self.xinxi_agent = None  # 信息专员
        self.qingdan_agent = None  # 清单整理员
        self.taoding_agent = None  # 套定额员

    async def process(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """处理工程部任务"""

        project_path = Path(task.get("project_path", ""))
        request = task.get("request", "")

        # 1. 启动图纸专员和信息专员（并行）
        # 实际应该并行调用，这里简化顺序调用

        # 模拟图纸分析
        tuzhi_result = await self._mock_tuzhi_analysis(project_path, request)

        # 模拟信息分析
        xinxi_result = await self._mock_xinxi_analysis(project_path, request)

        # 2. 清单整理
        qingdan_result = await self._mock_qingdan_zhengli(
            project_path, tuzhi_result, xinxi_result
        )

        # 3. 套定额
        taoding_result = await self._mock_taoding(project_path, qingdan_result)

        # 4. 经理复核
        final_result = self._review_result(taoding_result)

        return final_result

    async def _mock_tuzhi_analysis(self, project_path: Path, request: str) -> Dict[str, Any]:
        """模拟图纸分析"""
        # 实际应调用图纸专员
        return {
            "pdf_path": str(project_path / "图纸要点摘要.pdf"),
            "key_points": ["混凝土强度C30", "钢筋保护层25mm"],
            "confidence": 85
        }

    async def _mock_xinxi_analysis(self, project_path: Path, request: str) -> Dict[str, Any]:
        """模拟信息分析"""
        # 实际应调用信息专员
        return {
            "pdf_path": str(project_path / "项目条件摘要.pdf"),
            "contract_terms": ["预付款10%", "变更14天内提出"],
            "confidence": 90
        }

    async def _mock_qingdan_zhengli(self, project_path: Path,
                                     tuzhi_result: Dict, xinxi_result: Dict) -> Dict[str, Any]:
        """模拟清单整理"""
        # 实际应调用清单整理员
        return {
            "items": [
                {"name": "平整场地", "unit": "m2", "quantity": 1200},
                {"name": "挖土方", "unit": "m3", "quantity": 450}
            ],
            "total_items": 2,
            "confidence": 80
        }

    async def _mock_taoding(self, project_path: Path, qingdan_result: Dict) -> Dict[str, Any]:
        """模拟套定额"""
        # 实际应调用套定额员
        items = qingdan_result.get("items", [])

        result_items = []
        total_amount = 0

        for item in items:
            # 模拟定额匹配
            code = f"A1-{len(item['name'])}"
            unit_price = 350.0
            total = item["quantity"] * unit_price
            total_amount += total

            result_items.append({
                **item,
                "code": code,
                "unit_price": unit_price,
                "total": total,
                "reason": "工作内容匹配"
            })

        return {
            "items": result_items,
            "total_amount": total_amount,
            "matched": len(items),
            "unmatched": 0,
            "confidence": 75
        }

    def _review_result(self, taoding_result: Dict[str, Any]) -> Dict[str, Any]:
        """经理复核"""
        confidence = taoding_result.get("confidence", 0)
        items = taoding_result.get("items", [])
        total = taoding_result.get("total_amount", 0)

        # 生成结果文本
        lines = ["工程量清单汇总:", "-" * 40]

        for item in items:
            line = f"{item['name']} | {item.get('code', 'N/A')} | {item['quantity']}{item['unit']} | {item.get('unit_price', 0)}元 | 合价:{item.get('total', 0):.2f}元"
            lines.append(line)

        lines.append("-" * 40)
        lines.append(f"总价: {total:.2f}元")

        content = "\n".join(lines)

        return {
            "success": True,
            "content": content,
            "confidence": confidence,
            "metadata": {
                "total_items": len(items),
                "total_amount": total,
                "unmatched": taoding_result.get("unmatched", 0)
            }
        }
