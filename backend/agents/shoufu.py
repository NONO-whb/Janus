"""
首辅 (Layer 1)
职责: 接待用户、传达需求、简单助手功能
"""
from typing import Dict, Any, List
from datetime import datetime
import json
import os
from .models import AgentMessage


class ShouFuAgent:
    """首辅 - 用户入口 + 个人助手"""

    ASSISTANT_KEYWORDS = ["记一下", "提醒我", "待办", "记着", "记得", "闹钟"]

    def __init__(self):
        # 待办存储文件
        self.todo_file = os.path.expanduser("~/.janus/todos.json")
        os.makedirs(os.path.dirname(self.todo_file), exist_ok=True)

    async def process_input(self, user_message: str, context: List[AgentMessage] = None) -> Dict[str, Any]:
        """处理用户输入"""

        # 检查是否是助手模式
        if self._is_assistant_mode(user_message):
            return await self._handle_assistant_task(user_message)

        # 业务翻译模式
        return self._handle_business_request(user_message, context)

    def _is_assistant_mode(self, message: str) -> bool:
        """判断是否是助手模式"""
        message = message.lower()
        return any(kw in message for kw in self.ASSISTANT_KEYWORDS)

    async def _handle_assistant_task(self, message: str) -> Dict[str, Any]:
        """处理助手任务"""

        # 记录待办
        if "记一下" in message or "待办" in message:
            todo_content = message.replace("记一下", "").replace("待办", "").strip()
            return await self._add_todo(todo_content)

        # 设置提醒
        if "提醒我" in message or "闹钟" in message:
            return {
                "mode": "assistant",
                "action": "reminder",
                "content": f"已设置提醒: {message}",
                "timestamp": datetime.now().isoformat()
            }

        # 其他简单对话
        return {
            "mode": "assistant",
            "action": "chat",
            "content": "收到",
            "timestamp": datetime.now().isoformat()
        }

    async def _add_todo(self, content: str) -> Dict[str, Any]:
        """添加待办"""
        todos = self._load_todos()
        todos.append({
            "id": len(todos) + 1,
            "content": content,
            "created_at": datetime.now().isoformat(),
            "done": False
        })
        self._save_todos(todos)

        return {
            "mode": "assistant",
            "action": "todo",
            "content": f"已记录待办: {content}",
            "todos": todos,
            "timestamp": datetime.now().isoformat()
        }

    def _load_todos(self) -> List[Dict]:
        """加载待办列表"""
        if os.path.exists(self.todo_file):
            with open(self.todo_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        return []

    def _save_todos(self, todos: List[Dict]):
        """保存待办列表"""
        with open(self.todo_file, 'w', encoding='utf-8') as f:
            json.dump(todos, f, ensure_ascii=False, indent=2)

    def _handle_business_request(self, message: str, context: List[AgentMessage] = None) -> Dict[str, Any]:
        """处理业务请求（翻译模式）"""

        # 提取关键词（简单分词）
        keywords = self._extract_keywords(message)

        # 检查是否是跟进对话
        is_followup = self._check_followup(context)

        return {
            "mode": "business",
            "raw_request": message,
            "extracted_keywords": keywords,
            "is_followup": is_followup,
            "conversation_context": [c.content for c in context[-3:]] if context else [],
            "timestamp": datetime.now().isoformat()
        }

    def _extract_keywords(self, message: str) -> List[str]:
        """提取关键词"""
        # 简单实现：提取可能的工程术语
        common_terms = [
            "定额", "清单", "招标", "价格", "报告", "项目",
            "建筑", "安装", "市政", "园林", "仿古",
            "混凝土", "钢筋", "土方", "砌筑"
        ]
        found = []
        for term in common_terms:
            if term in message:
                found.append(term)
        return found

    def _check_followup(self, context: List[AgentMessage]) -> bool:
        """检查是否是跟进对话"""
        if not context or len(context) < 2:
            return False
        # 如果上一轮有业务请求，这一轮可能是跟进
        last_user_msg = context[-2] if len(context) >= 2 else None
        if last_user_msg and last_user_msg.role == "user":
            followup_keywords = ["改成", "改为", "调整", "修改", "不对", "重新"]
            return any(kw in last_user_msg.content for kw in followup_keywords)
        return False

    async def format_output(self, results: Dict[str, Any]) -> str:
        """格式化输出结果"""
        output_parts = []

        # 汇总各部门结果
        for dept, result in results.items():
            if result.get("success"):
                output_parts.append(f"【{dept}】\n{result.get('content', '')}")

                # 低置信度警告
                if result.get("confidence", 100) < 90:
                    output_parts.append(f"⚠️ 置信度较低({result.get('confidence', 0):.0f}%), 建议复核")
            else:
                output_parts.append(f"【{dept}】执行失败: {result.get('error', '未知错误')}")

        return "\n\n".join(output_parts)
