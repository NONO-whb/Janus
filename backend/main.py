"""
ENG 造价助手后端服务
薄客户端架构 - 手机端 UI + 电脑端 AI 处理
"""

import json
import os
from datetime import datetime
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, File, Form, UploadFile, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel

# FastAPI 应用实例
app = FastAPI(
    title="ENG 造价助手 API",
    description="手机端与电脑端 AI Agent 的桥梁",
    version="1.0.0"
)

# 允许跨域（手机端访问）
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================== 数据模型 ====================

class Project(BaseModel):
    id: str
    name: str
    status: str
    progress: float
    specialty: str
    updated: str

class AgentMessage(BaseModel):
    project_id: str
    message: str

class ConnectionInfo(BaseModel):
    device_name: str
    connected_at: str

# ==================== 模拟数据 ====================

MOCK_PROJECTS = [
    {
        "id": "proj_001",
        "name": "学校综合楼",
        "status": "进行中",
        "progress": 0.65,
        "specialty": "建筑/安装",
        "updated": "2小时前",
        "color": "#007AFF"
    },
    {
        "id": "proj_002",
        "name": "市政道路工程",
        "status": "待确认",
        "progress": 0.30,
        "specialty": "市政",
        "updated": "昨天",
        "color": "#FF9500"
    },
    {
        "id": "proj_003",
        "name": "住宅小区景观",
        "status": "已完成",
        "progress": 1.0,
        "specialty": "园林",
        "updated": "3天前",
        "color": "#34C759"
    },
]

# WebSocket 连接管理
class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def send_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)

manager = ConnectionManager()

# ==================== API 路由 ====================

@app.get("/")
async def root():
    """健康检查"""
    return {
        "status": "ok",
        "service": "ENG 造价助手 API",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/api/health")
async def health_check():
    """健康检查端点"""
    return {"status": "healthy", "agent_ready": True}

# -------------------- 项目相关 --------------------

@app.get("/api/projects")
async def get_projects():
    """获取所有项目列表"""
    return {"projects": MOCK_PROJECTS, "total": len(MOCK_PROJECTS)}

@app.get("/api/projects/{project_id}")
async def get_project(project_id: str):
    """获取单个项目详情"""
    for proj in MOCK_PROJECTS:
        if proj["id"] == project_id:
            # 添加详细字段
            proj_detail = proj.copy()
            proj_detail["files"] = [
                {"name": "招标文件.pdf", "size": "2.3 MB", "type": "pdf"},
                {"name": "工程量清单.xlsx", "size": "856 KB", "type": "xlsx"},
                {"name": "施工图纸.dwg", "size": "15.2 MB", "type": "dwg"},
            ]
            proj_detail["specialties"] = ["建筑", "安装", "市政", "园林"]
            proj_detail["active_specialties"] = proj["specialty"].split("/")
            return proj_detail
    return JSONResponse(
        status_code=404,
        content={"error": "Project not found"}
    )

@app.post("/api/projects/{project_id}/files")
async def upload_file(
    project_id: str,
    file: UploadFile = File(...),
    description: Optional[str] = Form(None)
):
    """上传项目文件"""
    # 创建上传目录
    upload_dir = Path(f"~/Desktop/造价项目/{project_id}/sources").expanduser()
    upload_dir.mkdir(parents=True, exist_ok=True)

    # 保存文件
    file_path = upload_dir / file.filename
    with open(file_path, "wb") as f:
        content = await file.read()
        f.write(content)

    return {
        "success": True,
        "filename": file.filename,
        "saved_to": str(file_path),
        "size": len(content)
    }

# -------------------- Agent 对话 --------------------

@app.post("/api/agent/chat")
async def agent_chat(message: AgentMessage):
    """发送消息给协调 Agent"""
    # 模拟 Agent 响应
    responses = {
        "进度": f"项目 {message.project_id} 当前进度：\n- 建筑专业：65%（钢结构防火涂料定额匹配中）\n- 安装专业：尚未开始\n- 阻塞问题：Q-B001 等待业主确认",
        "文件": "当前项目文件：\n- 招标文件.pdf（已上传）\n- 工程量清单.xlsx（已解析）\n- 施工图纸.dwg（待处理）",
        "定额": "建议套以下定额：\n- 钢结构防火涂料：参考 B-3-42\n- 需要确认：涂料类型（超薄/薄/厚）",
    }

    # 简单关键词匹配
    reply = "收到您的消息，协调 Agent 正在处理..."
    for key, resp in responses.items():
        if key in message.message:
            reply = resp
            break

    return {
        "success": True,
        "reply": reply,
        "timestamp": datetime.now().isoformat()
    }

@app.websocket("/ws/agent")
async def websocket_endpoint(websocket: WebSocket):
    """Agent WebSocket 实时对话"""
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)

            # 模拟 Agent 处理
            response = {
                "type": "agent_response",
                "text": f"Agent 收到: {message.get('text', '')}",
                "timestamp": datetime.now().isoformat()
            }
            await websocket.send_text(json.dumps(response))

    except WebSocketDisconnect:
        manager.disconnect(websocket)

# -------------------- 连接管理 --------------------

@app.get("/api/connection/info")
async def get_connection_info():
    """获取连接信息"""
    return {
        "server_name": "MacBook-Pro",
        "local_ip": "192.168.1.100",
        "port": 8080,
        "status": "ready",
        "qr_data": "http://192.168.1.100:8080"
    }

@app.get("/api/system/status")
async def system_status():
    """系统状态"""
    return {
        "agent_status": "ready",
        "projects_count": len(MOCK_PROJECTS),
        "active_connections": len(manager.active_connections),
        "memory_usage": "正常",
        "last_sync": datetime.now().isoformat()
    }

# ==================== 启动入口 ====================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
