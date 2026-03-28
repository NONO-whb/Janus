"""
数据模型定义
"""
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from enum import Enum


class ConfidenceLevel(str, Enum):
    """置信度等级"""
    HIGH = "high"      # >= 90%
    MEDIUM = "medium"  # 70-89%
    LOW = "low"        # < 70%


class DomainType(str, Enum):
    """执行域类型"""
    QUOTA = "quota"        # 定额域
    QUERY = "query"        # 查询域
    DOCUMENT = "document"  # 资料域


class TaskResult(BaseModel):
    """任务执行结果"""
    success: bool
    content: str
    confidence: float = Field(ge=0, le=100)
    confidence_level: ConfidenceLevel
    agent_name: str
    metadata: Dict[str, Any] = Field(default_factory=dict)
    requires_human_review: bool = False


class SubTask(BaseModel):
    """子任务"""
    id: str
    domain: DomainType
    description: str
    parameters: Dict[str, Any] = Field(default_factory=dict)
    dependencies: List[str] = Field(default_factory=list)


class ExecutionPlan(BaseModel):
    """执行计划"""
    plan_id: str
    original_request: str
    subtasks: List[SubTask]
    estimated_steps: int
    domains_involved: List[DomainType]


class AgentMessage(BaseModel):
    """Agent消息"""
    role: str  # user, assistant, system
    content: str
    metadata: Dict[str, Any] = Field(default_factory=dict)


class BillItem(BaseModel):
    """工程量清单项"""
    id: str
    code: Optional[str] = None
    name: str
    unit: str
    quantity: float
    unit_price: Optional[float] = None
    total: Optional[float] = None
    specialty: Optional[str] = None
    description: Optional[str] = None
    features: Optional[str] = None


class BillOfQuantities(BaseModel):
    """工程量清单"""
    project_id: str
    project_name: str
    items: List[BillItem]
    step: int = 0  # 当前步骤 1-4
    step_results: Dict[str, TaskResult] = Field(default_factory=dict)
    updated_at: Optional[str] = None
