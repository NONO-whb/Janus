"""
交互Agent (Layer 1)
职责: 用户对话接口、意图识别、结果展示
"""
from typing import Dict, Any, List
from .models import AgentMessage


class InteractionAgent:
    """交互Agent - 用户入口"""

    def __init__(self):
        self.system_prompt = """你是Janus造价助手的交互Agent。

职责:
1. 接收用户输入,理解用户意图
2. 将用户请求转化为结构化的任务描述
3. 展示最终结果给用户

原则:
- 友好、专业的对话风格
- 准确识别用户意图(定额/查询/资料)
- 复杂请求要拆解说明
"""

    async def process_input(self, user_message: str, context: List[AgentMessage] = None) -> Dict[str, Any]:
        """处理用户输入,生成任务描述"""
        # 意图识别
        intent = self._classify_intent(user_message)

        return {
            "intent": intent["type"],
            "task_description": intent["description"],
            "domains": intent["domains"],
            "original_message": user_message
        }

    def _classify_intent(self, message: str) -> Dict[str, Any]:
        """意图分类"""
        message = message.lower()

        # 定额域关键词
        quota_keywords = ["定额", "造价", "工程量", "套取", "清单", "土建", "安装",
                         "市政", "园林", "仿古", "混凝土", "钢筋", "砌筑"]

        # 查询域关键词
        query_keywords = ["查询", "招标", "中标", "价格", "行情", "多少钱", "信息价",
                         "市场价", "历史", "类似项目"]

        # 资料域关键词
        document_keywords = ["报告", "文档", "生成", "导出", "打印", "PDF", "Word",
                           "整理", "归档", "资料"]

        quota_score = sum(1 for kw in quota_keywords if kw in message)
        query_score = sum(1 for kw in query_keywords if kw in message)
        document_score = sum(1 for kw in document_keywords if kw in message)

        domains = []
        if quota_score > 0:
            domains.append("quota")
        if query_score > 0:
            domains.append("query")
        if document_score > 0:
            domains.append("document")

        if not domains:
            domains = ["quota"]  # 默认定额域

        return {
            "type": "multi_domain" if len(domains) > 1 else domains[0],
            "description": message,
            "domains": domains
        }

    async def format_output(self, results: Dict[str, Any]) -> str:
        """格式化输出结果"""
        output_parts = []

        # 汇总各域结果
        for domain, result in results.items():
            if result.get("success"):
                output_parts.append(f"【{domain}结果】\n{result.get('content', '')}")

                # 低置信度警告
                if result.get("confidence", 100) < 90:
                    output_parts.append(f"⚠️ 置信度较低({result.get('confidence', 0):.0f}%), 建议复核")
            else:
                output_parts.append(f"【{domain}】执行失败: {result.get('error', '未知错误')}")

        return "\n\n".join(output_parts)
