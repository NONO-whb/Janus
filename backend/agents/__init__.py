"""
Agent模块初始化
Janus 造价咨询团队
"""
# 第一层
from .shoufu import ShouFuAgent

# 第二层
from .ceo import CEOAgent

# 第三层 - 各部门经理
from .gongchengbu import GongchengbuManager
from .xinxibu import XinxibuManager
from .ziliaobu import ZiliaobuManager

# 跨域
from .houqinbu import Houqinbu

# 数据模型
from .models import (
    ConfidenceLevel,
    DomainType,
    TaskResult,
    SubTask,
    ExecutionPlan,
    AgentMessage,
    BillItem,
    BillOfQuantities
)

__all__ = [
    # L1
    "ShouFuAgent",
    # L2
    "CEOAgent",
    # L3 Managers
    "GongchengbuManager",
    "XinxibuManager",
    "ZiliaobuManager",
    # Cross-domain
    "Houqinbu",
    # Models
    "ConfidenceLevel",
    "DomainType",
    "TaskResult",
    "SubTask",
    "ExecutionPlan",
    "AgentMessage",
    "BillItem",
    "BillOfQuantities"
]
