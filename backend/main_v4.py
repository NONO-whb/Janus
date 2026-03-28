"""
Janus v4.0 后端服务
Janus 造价咨询团队架构
"""

import json
import os
import socket
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any, List
from contextlib import asynccontextmanager

from fastapi import FastAPI, File, Form, UploadFile, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Janus 造价咨询团队
from agents import (
    ShouFuAgent,           # 首辅 - L1
    CEOAgent,              # CEO - L2
    GongchengbuManager,    # 工程部经理 - L3
    XinxibuManager,        # 信息部经理 - L3
    ZiliaobuManager,       # 资料部经理 - L3
    Houqinbu               # 后勤部 - 跨域协调
)

# ==================== 配置管理 ====================

class Settings:
    """应用配置"""
    PORT: int = int(os.getenv("JANUS_PORT", "8080"))
    HOST: str = os.getenv("JANUS_HOST", "0.0.0.0")
    UPLOAD_DIR: Path = Path(os.getenv("JANUS_UPLOAD_DIR", "~/Desktop/造价项目")).expanduser()
    MAX_UPLOAD_SIZE: int = 50 * 1024 * 1024
    CORS_ORIGINS: List[str] = os.getenv("CORS_ORIGINS", "*").split(",")

settings = Settings()

# ==================== 数据模型 ====================

class ChatRequest(BaseModel):
    """对话请求"""
    message: str
    client_id: str = Field(default="default")
    context: Optional[List[Dict[str, str]]] = None

class ChatResponse(BaseModel):
    """对话响应"""
    success: bool
    content: str
    confidence: float
    confidence_level: str
    requires_review: bool
    departments: List[str]
    timestamp: str

# ==================== Janus 团队编排器 ====================

class JanusOrchestrator:
    """Janus 造价咨询团队编排器"""

    def __init__(self):
        # 首辅 (L1)
        self.shoufu = ShouFuAgent()

        # CEO (L2)
        self.ceo = CEOAgent(str(settings.UPLOAD_DIR))

        # 各部门经理 (L3)
        self.gongchengbu = GongchengbuManager()
        self.xinxibu = XinxibuManager()
        self.ziliaobu = ZiliaobuManager()

        # 后勤部 (跨域协调)
        self.houqinbu = Houqinbu()

        # 注册部门到后勤部
        self.houqinbu.register_department("工程部", self.gongchengbu)
        self.houqinbu.register_department("信息部", self.xinxibu)
        self.houqinbu.register_department("资料部", self.ziliaobu)

    async def process(self, message: str, client_id: str = "default") -> Dict[str, Any]:
        """处理用户请求 - 完整流水线"""

        # Step 1: L1 - 首辅处理输入
        shoufu_result = await self.shoufu.process_input(message)

        # 如果是助手模式，直接返回
        if shoufu_result.get("mode") == "assistant":
            return {
                "success": True,
                "content": shoufu_result.get("content", ""),
                "confidence": 100.0,
                "confidence_level": "high",
                "requires_review": False,
                "departments": ["首辅助手"],
                "timestamp": datetime.now().isoformat()
            }

        # Step 2: L2 - CEO 项目管家
        ceo_result = await self.ceo.process(shoufu_result)

        # Step 3: L3 - 后勤部协调各部门
        coordination_result = await self.houqinbu.coordinate(
            project_path=ceo_result.get("project_path", ""),
            departments=ceo_result.get("departments", []),
            task=ceo_result
        )

        # Step 4: CEO 汇总结果
        final_result = await self.ceo.finalize_result(
            Path(ceo_result.get("project_path", "")),
            coordination_result.get("results", {})
        )

        # Step 5: L1 - 首辅格式化输出
        output_content = await self.shoufu.format_output(
            coordination_result.get("results", {})
        )

        # 汇总低置信度警告
        warnings = []
        if coordination_result.get("low_confidence_tasks"):
            for task in coordination_result["low_confidence_tasks"]:
                warnings.append(f"【{task['department']}】置信度{task['confidence']:.0f}% - {task['reason']}")

        if warnings:
            output_content += "\n\n⚠️ 注意事项:\n" + "\n".join(warnings)

        return {
            "success": coordination_result["success"],
            "content": output_content,
            "confidence": coordination_result["global_confidence"],
            "confidence_level": "high" if coordination_result["global_confidence"] >= 90
                               else ("medium" if coordination_result["global_confidence"] >= 70 else "low"),
            "requires_review": coordination_result["requires_human_review"],
            "departments": ceo_result.get("departments", []),
            "project_name": ceo_result.get("project_name"),
            "timestamp": datetime.now().isoformat()
        }

# 全局编排器实例
orchestrator = JanusOrchestrator()

# ==================== FastAPI应用 ====================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    print("[INIT] Janus v4.0 造价咨询团队启动...")
    print("[INIT] 团队成员: 首辅, CEO, 工程部经理, 信息部经理, 资料部经理, 后勤部")
    yield
    print("[SHUTDOWN] Janus v4.0 团队解散...")

app = FastAPI(
    title="Janus v4.0 造价助手 API",
    description="Janus造价咨询团队 - 首辅/CEO/工程部/信息部/资料部/后勤部",
    version="4.0.0",
    lifespan=lifespan
)

# CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================== 项目状态存储 ====================

class ProjectStore:
    """简单项目存储（内存中）"""
    def __init__(self):
        self.projects: Dict[str, Dict[str, Any]] = {}
        self.active_project: Optional[str] = None
        self.bills: Dict[str, List[Dict[str, Any]]] = {}

    def get_or_create(self, project_id: str) -> Dict[str, Any]:
        if project_id not in self.projects:
            self.projects[project_id] = {
                "id": project_id,
                "name": project_id,
                "created_at": datetime.now().isoformat(),
                "status": "active",
                "progress": 0.0,
                "specialties": ["building"],
                "files": []
            }
        return self.projects[project_id]

    def set_active(self, project_id: str):
        self.active_project = project_id

    def get_bill(self, project_id: str) -> List[Dict[str, Any]]:
        if project_id not in self.bills:
            # 返回示例数据
            self.bills[project_id] = [
                {
                    "id": "item-001",
                    "code": "A1-1",
                    "name": "土方开挖",
                    "unit": "m³",
                    "quantity": 100.0,
                    "unit_price": 50.0,
                    "total": 5000.0,
                    "specialty": "建筑",
                    "description": "基础土方开挖"
                },
                {
                    "id": "item-002",
                    "code": "A1-2",
                    "name": "混凝土浇筑",
                    "unit": "m³",
                    "quantity": 50.0,
                    "unit_price": 500.0,
                    "total": 25000.0,
                    "specialty": "建筑",
                    "description": "C30混凝土"
                }
            ]
        return self.bills[project_id]

# 全局项目存储
project_store = ProjectStore()

# ==================== API路由 ====================

@app.get("/")
async def root():
    """服务信息"""
    return {
        "service": "Janus v4.0 造价助手 API",
        "version": "4.0.0",
        "architecture": "Janus造价咨询团队",
        "team": ["首辅", "CEO", "工程部经理", "信息部经理", "资料部经理", "后勤部"],
        "status": "ready",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/api/v1/health")
async def health_check():
    """健康检查"""
    return {
        "status": "healthy",
        "architecture": "v4.0",
        "team_ready": True,
        "timestamp": datetime.now().isoformat()
    }

@app.post("/api/v1/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """团队对话 - v4.0完整流水线"""
    try:
        result = await orchestrator.process(request.message, request.client_id)
        return ChatResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/command")
async def command(request: ChatRequest):
    """团队命令端点 - 兼容前端"""
    result = await orchestrator.process(request.message, request.client_id)
    return {
        "status": "success" if result["success"] else "failed",
        "message": result["content"],
        "confidence": result["confidence"],
        "requires_review": result["requires_review"],
        "departments": result["departments"],
        "timestamp": result["timestamp"]
    }

# ==================== WebSocket ====================

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, client_id: str):
        await websocket.accept()
        self.active_connections[client_id] = websocket
        print(f"[WS] Client {client_id} connected")

    def disconnect(self, client_id: str):
        if client_id in self.active_connections:
            del self.active_connections[client_id]
        print(f"[WS] Client {client_id} disconnected")

    async def send_message(self, client_id: str, message: Dict[str, Any]):
        if client_id in self.active_connections:
            await self.active_connections[client_id].send_json(message)

manager = ConnectionManager()

@app.websocket("/api/v1/ws")
async def websocket_endpoint(websocket: WebSocket, client_id: str = "default"):
    """WebSocket连接 - 流式响应"""
    await manager.connect(websocket, client_id)

    try:
        await manager.send_message(client_id, {
            "type": "connected",
            "client_id": client_id,
            "architecture": "v4.0",
            "team": ["首辅", "CEO", "工程部", "信息部", "资料部", "后勤部"],
            "timestamp": datetime.now().isoformat()
        })

        while True:
            data = await websocket.receive_text()
            try:
                message = json.loads(data)
                text = message.get("text", "")

                # 发送处理中状态
                await manager.send_message(client_id, {
                    "type": "processing",
                    "stage": "planning",
                    "message": "Janus团队正在分析任务..."
                })

                # 执行完整流水线
                result = await orchestrator.process(text, client_id)

                # 发送结果
                await manager.send_message(client_id, {
                    "type": "message",
                    "content": result["content"],
                    "confidence": result["confidence"],
                    "confidence_level": result["confidence_level"],
                    "requires_review": result["requires_review"],
                    "departments": result["departments"],
                    "timestamp": result["timestamp"]
                })

            except json.JSONDecodeError:
                await manager.send_message(client_id, {
                    "type": "error",
                    "content": "Invalid JSON format"
                })
            except Exception as e:
                await manager.send_message(client_id, {
                    "type": "error",
                    "content": f"Error: {str(e)}"
                })

    except WebSocketDisconnect:
        manager.disconnect(client_id)
    except Exception as e:
        print(f"[WS] Error: {e}")
        manager.disconnect(client_id)

# ==================== 新增API端点（前端需要）====================

@app.get("/api/v1/status")
async def get_status():
    """获取服务状态信息 - 前端 getConnectionInfo() 调用"""
    return {
        "orchestrator_ready": True,
        "version": "4.0.0",
        "team_ready": True,
        "active_project": project_store.active_project,
        "timestamp": datetime.now().isoformat()
    }

@app.get("/api/v1/projects")
async def get_projects():
    """获取项目列表 - 前端 getProjects() 调用"""
    # 返回所有项目ID列表
    projects = list(project_store.projects.keys())
    if not projects:
        # 如果没有项目，返回示例
        projects = ["示例项目"]
    return {
        "projects": projects,
        "count": len(projects),
        "timestamp": datetime.now().isoformat()
    }

@app.get("/api/v1/project")
async def get_project_detail():
    """获取当前项目详情 - 前端 getProjectDetail() 调用"""
    active = project_store.active_project or "未选择项目"
    project = project_store.get_or_create(active) if project_store.active_project else None

    return {
        "active_project": active,
        "status": {
            "progress": project["progress"] if project else 0.0,
            "specialties": project["specialties"] if project else ["building"],
            "file_count": len(project["files"]) if project else 0
        },
        "timestamp": datetime.now().isoformat()
    }

@app.post("/api/v1/projects/{project_id}/files")
async def upload_file(
    project_id: str,
    file: UploadFile = File(...)
):
    """上传文件 - 前端 uploadFile() 调用"""
    try:
        # 确保项目存在
        project = project_store.get_or_create(project_id)

        # 保存文件
        upload_dir = settings.UPLOAD_DIR / project_id
        upload_dir.mkdir(parents=True, exist_ok=True)

        file_path = upload_dir / file.filename
        content = await file.read()

        with open(file_path, "wb") as f:
            f.write(content)

        # 记录文件
        file_info = {
            "name": file.filename,
            "size": f"{len(content) / 1024:.1f} KB",
            "type": file.filename.split(".")[-1].lower() if "." in file.filename else "unknown",
            "uploaded_at": datetime.now().isoformat()
        }
        project["files"].append(file_info)

        return {
            "success": True,
            "message": f"文件 {file.filename} 上传成功",
            "file": file_info,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"上传失败: {str(e)}")

@app.get("/api/v1/projects/{project_id}/bills")
async def get_bill_of_quantities(project_id: str):
    """获取工程量清单 - 前端 getBillOfQuantities() 调用"""
    # 确保项目存在
    project = project_store.get_or_create(project_id)

    # 获取清单
    items = project_store.get_bill(project_id)

    return {
        "project_id": project_id,
        "project_name": project["name"],
        "items": items,
        "updated_at": datetime.now().isoformat(),
        "timestamp": datetime.now().isoformat()
    }

# ==================== 启动入口 ====================

if __name__ == "__main__":
    import uvicorn
    print(f"[START] Janus v4.0 造价咨询团队启动 on {settings.HOST}:{settings.PORT}")
    uvicorn.run(app, host=settings.HOST, port=settings.PORT)
