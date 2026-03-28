"""
定额域Agent (Layer 3)
包含: 定额域知识Agent + 4步流水线执行Agent
"""
from typing import Dict, Any, List, Optional
import re
from .models import TaskResult, BillItem, BillOfQuantities, ConfidenceLevel


class QuotaDomainKnowledgeAgent:
    """定额域知识Agent - 管理定额知识,分发4步任务"""

    def __init__(self):
        self.knowledge_base = {
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
            # 其他专业...
        }

    async def process(self, parameters: Dict[str, Any]) -> TaskResult:
        """处理定额域任务 - 执行4步流水线"""
        specialty = parameters.get("specialty", "建筑")
        description = parameters.get("description", "")

        # Step 1: 清单初步整理
        step1_result = await self._step1_preliminary_organization(description, specialty)
        if step1_result.confidence < 70:
            return step1_result

        # Step 2: 清单标准化整理
        step2_result = await self._step2_standardization(step1_result.metadata.get("items", []), specialty)
        if step2_result.confidence < 70:
            return step2_result

        # Step 3: 定额套取
        step3_result = await self._step3_quota_matching(step2_result.metadata.get("items", []), specialty)
        if step3_result.confidence < 70:
            return step3_result

        # Step 4: 复核
        step4_result = await self._step4_review(step3_result.metadata.get("items", []))

        # 汇总4步结果
        final_confidence = (step1_result.confidence + step2_result.confidence +
                           step3_result.confidence + step4_result.confidence) / 4

        return TaskResult(
            success=True,
            content=self._format_final_result(step4_result.metadata.get("items", [])),
            confidence=final_confidence,
            confidence_level=self._calculate_level(final_confidence),
            agent_name="quota_domain",
            metadata={
                "specialty": specialty,
                "step_results": {
                    "step1": step1_result.dict(),
                    "step2": step2_result.dict(),
                    "step3": step3_result.dict(),
                    "step4": step4_result.dict()
                }
            },
            requires_human_review=final_confidence < 70
        )

    async def _step1_preliminary_organization(self, description: str, specialty: str) -> TaskResult:
        """Step 1: 清单初步整理Agent"""
        # 提取项目特征
        items = self._extract_items_from_description(description, specialty)

        confidence = 85.0 if items else 60.0

        return TaskResult(
            success=True,
            content=f"初步整理完成,识别到{len(items)}个分部分项",
            confidence=confidence,
            confidence_level=self._calculate_level(confidence),
            agent_name="step1_preliminary",
            metadata={"items": items, "specialty": specialty}
        )

    async def _step2_standardization(self, items: List[Dict], specialty: str) -> TaskResult:
        """Step 2: 清单标准化整理Agent"""
        standardized_items = []

        for item in items:
            # 标准化处理
            std_item = {
                "id": item.get("id"),
                "name": self._standardize_name(item.get("name", "")),
                "unit": self._standardize_unit(item.get("unit", "")),
                "quantity": item.get("quantity", 0),
                "features": self._extract_features(item.get("name", "")),
                "specialty": specialty
            }
            standardized_items.append(std_item)

        confidence = 90.0  # 标准化规则明确,置信度较高

        return TaskResult(
            success=True,
            content=f"标准化完成,{len(standardized_items)}项",
            confidence=confidence,
            confidence_level=self._calculate_level(confidence),
            agent_name="step2_standardization",
            metadata={"items": standardized_items}
        )

    async def _step3_quota_matching(self, items: List[Dict], specialty: str) -> TaskResult:
        """Step 3: 定额套取Agent"""
        matched_items = []

        for item in items:
            # 模拟定额匹配
            quota_code = self._match_quota_code(item, specialty)
            unit_price = self._get_unit_price(quota_code, specialty)

            matched_item = {
                **item,
                "code": quota_code,
                "unit_price": unit_price,
                "total": item.get("quantity", 0) * unit_price if unit_price else None
            }
            matched_items.append(matched_item)

        confidence = 75.0  # AI匹配有一定不确定性

        return TaskResult(
            success=True,
            content=f"定额套取完成,匹配{len(matched_items)}项",
            confidence=confidence,
            confidence_level=self._calculate_level(confidence),
            agent_name="step3_matching",
            metadata={"items": matched_items}
        )

    async def _step4_review(self, items: List[Dict]) -> TaskResult:
        """Step 4: 复核Agent"""
        total_amount = sum(item.get("total", 0) or 0 for item in items)

        # 检查合理性
        issues = []
        for item in items:
            if not item.get("code"):
                issues.append(f"{item.get('name')}未匹配定额")
            if item.get("unit_price", 0) <= 0:
                issues.append(f"{item.get('name')}单价异常")

        confidence = 85.0 if not issues else 70.0

        return TaskResult(
            success=True,
            content=f"复核完成,总价{total_amount:.2f}元",
            confidence=confidence,
            confidence_level=self._calculate_level(confidence),
            agent_name="step4_review",
            metadata={"items": items, "total": total_amount, "issues": issues}
        )

    def _extract_items_from_description(self, description: str, specialty: str) -> List[Dict]:
        """从描述中提取清单项"""
        items = []

        # 简单的模式匹配提取
        patterns = [
            r"(\d+\.?\d*)\s*(m3|立方米)\s*([\u4e00-\u9fa5]+)",
            r"(\d+\.?\d*)\s*(m2|平方米)\s*([\u4e00-\u9fa5]+)",
            r"([\u4e00-\u9fa5]+)\s*(\d+\.?\d*)\s*(m3|m2|m|个|套)"
        ]

        for pattern in patterns:
            matches = re.findall(pattern, description)
            for i, match in enumerate(matches):
                items.append({
                    "id": f"item_{i}",
                    "name": match[-1] if isinstance(match[-1], str) else match[0],
                    "quantity": float(match[0]) if match[0].replace('.', '').isdigit() else float(match[1]),
                    "unit": match[1] if match[1] in ['m3', 'm2', 'm'] else 'm3'
                })

        # 如果没有提取到,生成默认项
        if not items:
            items = [{
                "id": "item_1",
                "name": f"{specialty}工程",
                "quantity": 100,
                "unit": "m2"
            }]

        return items

    def _standardize_name(self, name: str) -> str:
        """标准化项目名称"""
        # 移除多余空格,统一格式
        return name.strip()

    def _standardize_unit(self, unit: str) -> str:
        """标准化单位"""
        unit_map = {
            "m3": "m³", "立方米": "m³",
            "m2": "m²", "平方米": "m²",
            "m": "m", "米": "m"
        }
        return unit_map.get(unit, unit)

    def _extract_features(self, name: str) -> str:
        """提取工程特征"""
        # 简单的特征提取逻辑
        return "待补充"

    def _match_quota_code(self, item: Dict, specialty: str) -> str:
        """匹配定额编码"""
        # 模拟定额匹配
        specialty_prefix = {
            "建筑": "A", "安装": "B", "市政": "C",
            "园林": "D", "仿古": "E"
        }
        prefix = specialty_prefix.get(specialty, "A")
        return f"{prefix}1-{len(item.get('name', '')) % 100}"

    def _get_unit_price(self, quota_code: str, specialty: str) -> float:
        """获取定额单价"""
        # 模拟单价查询
        base_prices = {
            "建筑": 350.0, "安装": 120.0, "市政": 280.0,
            "园林": 150.0, "仿古": 420.0
        }
        return base_prices.get(specialty, 300.0)

    def _calculate_level(self, confidence: float) -> ConfidenceLevel:
        """计算置信度等级"""
        if confidence >= 90:
            return ConfidenceLevel.HIGH
        elif confidence >= 70:
            return ConfidenceLevel.MEDIUM
        else:
            return ConfidenceLevel.LOW

    def _format_final_result(self, items: List[Dict]) -> str:
        """格式化最终结果"""
        lines = ["工程量清单汇总:", "-" * 40]
        total = 0

        for item in items:
            line = f"{item.get('name')} | {item.get('code')} | {item.get('quantity')} {item.get('unit')} | {item.get('unit_price')}元 | 合价:{item.get('total', 0):.2f}元"
            lines.append(line)
            total += item.get("total", 0) or 0

        lines.append("-" * 40)
        lines.append(f"总价: {total:.2f}元")

        return "\n".join(lines)
