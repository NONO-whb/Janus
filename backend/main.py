"""
Janus 造价助手后端服务
AI Agent Team 架构 - 协调Agent + 各专业Agent
"""

import json
import os
import socket
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any, List
from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI, File, Form, UploadFile, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# ==================== 配置管理 ====================

class Settings:
    """应用配置"""
    # 服务器配置
    PORT: int = int(os.getenv("JANUS_PORT", "8080"))
    HOST: str = os.getenv("JANUS_HOST", "0.0.0.0")

    # 文件上传配置
    UPLOAD_DIR: Path = Path(os.getenv("JANUS_UPLOAD_DIR", "~/Desktop/造价项目")).expanduser()
    MAX_UPLOAD_SIZE: int = 50 * 1024 * 1024  # 50MB

    # CORS配置
    CORS_ORIGINS: List[str] = os.getenv("CORS_ORIGINS", "*").split(",")

    # Agent配置目录
    AGENT_CONFIG_DIR: Path = Path.home() / ".claude" / "projects" / "-Users-cck" / "memory" / "MODULES" / "construction-cost" / "AGENTS"

    # 协调Agent API配置
    COORDINATOR_API_URL: str = os.getenv("COORDINATOR_API_URL", "")
    COORDINATOR_API_KEY: str = os.getenv("COORDINATOR_API_KEY", "")

    # 各Agent配置缓存
    AGENT_CONFIGS: Dict[str, Dict[str, Any]] = {}

settings = Settings()

# ==================== 数据模型 ====================

class Project(BaseModel):
    id: str
    name: str
    status: str
    progress: float
    specialty: str
    updated: str
    color: str = "#007AFF"
    files: Optional[List[Dict[str, str]]] = None
    specialties: Optional[List[str]] = None
    active_specialties: Optional[List[str]] = None

class AgentMessage(BaseModel):
    project_id: str = Field(default="default")
    message: str
    source: str = Field(default="mobile")

class ChatCommand(BaseModel):
    text: str
    source: str = Field(default="mobile")
    client_id: str = Field(default="default")

class BillItem(BaseModel):
    id: str
    code: str
    name: str
    unit: str
    quantity: float
    unit_price: Optional[float] = None
    total: Optional[float] = None
    specialty: Optional[str] = None
    description: Optional[str] = None

class BillOfQuantities(BaseModel):
    project_id: str
    project_name: str
    items: List[BillItem]
    updated_at: Optional[str] = None

class ConnectionInfo(BaseModel):
    server_name: str
    local_ip: str
    port: int
    status: str
    qr_data: str
    agent_status: Dict[str, str]

# ==================== Agent配置加载 ====================

def load_agent_config(agent_name: str) -> Optional[Dict[str, Any]]:
    """加载指定Agent的配置"""
    if agent_name in settings.AGENT_CONFIGS:
        return settings.AGENT_CONFIGS[agent_name]

    config_path = settings.AGENT_CONFIG_DIR / agent_name / "config.json"
    if not config_path.exists():
        return None

    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
            settings.AGENT_CONFIGS[agent_name] = config
            return config
    except Exception as e:
        print(f"[ERROR] Failed to load agent config for {agent_name}: {e}")
        return None

def get_all_agent_configs() -> Dict[str, Dict[str, Any]]:
    """加载所有Agent配置"""
    agents = ["coordinator", "building", "installation", "municipal", "garden", "antique"]
    configs = {}
    for agent in agents:
        config = load_agent_config(agent)
        if config:
            configs[agent] = config
    return configs

# ==================== Agent调用服务 ====================

class AgentService:
    """Agent调用服务"""

    def __init__(self):
        self.client = httpx.AsyncClient(timeout=60.0)
        self._stream_client: Optional[httpx.AsyncClient] = None

    async def call_agent(
        self,
        agent_name: str,
        message: str,
        project_id: str,
        stream: bool = False
    ) -> Dict[str, Any]:
        """调用指定Agent的API"""
        config = load_agent_config(agent_name)

        # 如果没有配置，使用协调Agent作为回退
        if not config:
            if agent_name != "coordinator":
                print(f"[WARN] Agent {agent_name} not configured, falling back to coordinator")
                return await self._call_coordinator_fallback(message, project_id)
            else:
                return self._create_fallback_response(message, project_id)

        try:
            api_key = config.get("api_key", "")
            base_url = config.get("base_url", "")
            model = config.get("model", "kimi-latest")
            provider = config.get("provider", "openai")

            # 根据provider选择API格式
            if provider == "anthropic":
                # Anthropic API格式
                headers = {
                    "x-api-key": api_key,
                    "Content-Type": "application/json",
                    "anthropic-version": "2023-06-01"
                }
                system_prompt = self._build_system_prompt(agent_name, project_id)
                payload = {
                    "model": model,
                    "system": system_prompt,
                    "messages": [{"role": "user", "content": message}],
                    "max_tokens": 4096,
                    "temperature": config.get("temperature", 0.3),
                    "stream": stream
                }
                api_url = f"{base_url}/v1/messages"
            else:
                # OpenAI兼容格式
                headers = {
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json"
                }
                system_prompt = self._build_system_prompt(agent_name, project_id)
                payload = {
                    "model": model,
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": message}
                    ],
                    "temperature": config.get("temperature", 0.3),
                    "stream": stream
                }
                api_url = f"{base_url}/v1/chat/completions"

            if stream:
                return {"stream": True, "url": api_url, "payload": payload, "headers": headers}

            response = await self.client.post(api_url, json=payload, headers=headers)
            response.raise_for_status()
            result = response.json()

            # 提取回复内容 (支持Anthropic和OpenAI两种格式)
            if provider == "anthropic":
                content = result.get("content", [{}])[0].get("text", "")
            else:
                content = result.get("choices", [{}])[0].get("message", {}).get("content", "")

            return {
                "success": True,
                "reply": content,
                "agent": agent_name,
                "timestamp": datetime.now().isoformat()
            }

        except Exception as e:
            print(f"[ERROR] Agent call failed: {e}")
            if agent_name != "coordinator":
                return await self._call_coordinator_fallback(message, project_id)
            return self._create_fallback_response(message, project_id, str(e))

    async def _call_coordinator_fallback(self, message: str, project_id: str) -> Dict[str, Any]:
        """调用协调Agent作为回退"""
        return await self.call_agent("coordinator", message, project_id)

    def _create_fallback_response(self, message: str, project_id: str, error: str = "") -> Dict[str, Any]:
        """创建回退响应"""
        return {
            "success": True,
            "reply": f"Agent服务暂时不可用。您的消息\"{message[:50]}...\"已记录，项目ID: {project_id}",
            "agent": "fallback",
            "timestamp": datetime.now().isoformat(),
            "error": error
        }

    def _build_system_prompt(self, agent_name: str, project_id: str) -> str:
        """构建系统提示词"""
        prompts = {
            "coordinator": "你是Janus造价助手团队的协调Agent。你的职责是理解用户请求，分发给专业Agent，并汇总结果。",
            "building": "你是建筑专业Agent，精通建筑工程定额、造价计算。请提供准确的定额编码和价格。",
            "installation": "你是安装专业Agent，精通电气、给排水、暖通、消防等安装工程定额。",
            "municipal": "你是市政专业Agent，精通道路、桥涵、管网等市政工程定额。",
            "garden": "你是园林专业Agent，精通绿化、景观等园林工程定额。",
            "antique": "你是仿古专业Agent，精通仿古建筑工程定额。"
        }
        base_prompt = prompts.get(agent_name, "你是专业的造价工程助手。")
        return f"{base_prompt}\n当前项目ID: {project_id}"

    def route_to_agent(self, message: str) -> str:
        """根据消息内容路由到对应Agent"""
        # 关键词路由规则
        keywords = {
            "building": ["建筑", "土建", "混凝土", "钢筋", "砌体", "装饰", "装修", "地面", "墙面", "天棚"],
            "installation": ["安装", "电气", "给排水", "暖通", "消防", "空调", "配电", "照明", "管道"],
            "municipal": ["市政", "道路", "桥涵", "管网", "排水", "给水", "路灯", "人行道"],
            "garden": ["园林", "绿化", "景观", "苗木", "草坪", "花坛", "园林小品"],
            "antique": ["仿古", "古建筑", "斗拱", "瓦作", "木作", "石作"]
        }

        for agent, words in keywords.items():
            for word in words:
                if word in message:
                    return agent

        return "coordinator"  # 默认路由到协调Agent

    async def close(self):
        await self.client.aclose()

agent_service = AgentService()

# ==================== 模拟数据 ====================

MOCK_PROJECTS = [
    {
        "id": "proj_001",
        "name": "学校综合楼",
        "status": "进行中",
        "progress": 0.65,
        "specialty": "建筑/安装",
        "updated": "2小时前",
        "color": "#007AFF",
        "files": [
            {"name": "招标文件.pdf", "size": "2.3 MB", "type": "pdf"},
            {"name": "工程量清单.xlsx", "size": "856 KB", "type": "xlsx"},
            {"name": "施工图纸.dwg", "size": "15.2 MB", "type": "dwg"},
        ],
        "specialties": ["建筑", "安装", "市政", "园林"],
        "active_specialties": ["建筑", "安装"]
    },
    {
        "id": "proj_002",
        "name": "市政道路工程",
        "status": "待确认",
        "progress": 0.30,
        "specialty": "市政",
        "updated": "昨天",
        "color": "#FF9500",
        "files": [],
        "specialties": ["市政"],
        "active_specialties": ["市政"]
    },
    {
        "id": "proj_003",
        "name": "住宅小区景观",
        "status": "已完成",
        "progress": 1.0,
        "specialty": "园林",
        "updated": "3天前",
        "color": "#34C759",
        "files": [],
        "specialties": ["园林"],
        "active_specialties": ["园林"]
    },
]

# 工程量清单模拟数据
MOCK_BILLS: Dict[str, BillOfQuantities] = {}

def init_mock_bills():
    """初始化模拟清单数据"""
    global MOCK_BILLS
    MOCK_BILLS = {
        "proj_001": BillOfQuantities(
            project_id="proj_001",
            project_name="学校综合楼",
            items=[
                BillItem(id="1", code="A1-1", name="人工挖土方", unit="m³", quantity=1250.5, unit_price=35.0, specialty="建筑"),
                BillItem(id="2", code="A1-45", name="混凝土基础", unit="m³", quantity=856.3, unit_price=420.0, specialty="建筑"),
                BillItem(id="3", code="A3-1", name="砖墙砌筑", unit="m³", quantity=2340.0, unit_price=380.0, specialty="建筑"),
                BillItem(id="4", code="B1-12", name="电气配管", unit="m", quantity=5200.0, unit_price=15.5, specialty="安装"),
                BillItem(id="5", code="B2-8", name="给排水管道", unit="m", quantity=1800.0, unit_price=85.0, specialty="安装"),
            ],
            updated_at=datetime.now().isoformat()
        )
    }

init_mock_bills()

# ==================== WebSocket连接管理 ====================

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        self.connection_info: Dict[str, Dict[str, Any]] = {}

    async def connect(self, websocket: WebSocket, client_id: str):
        await websocket.accept()
        self.active_connections[client_id] = websocket
        self.connection_info[client_id] = {
            "connected_at": datetime.now().isoformat(),
            "message_count": 0
        }
        print(f"[WS] Client {client_id} connected")

    def disconnect(self, client_id: str):
        if client_id in self.active_connections:
            del self.active_connections[client_id]
        if client_id in self.connection_info:
            del self.connection_info[client_id]
        print(f"[WS] Client {client_id} disconnected")

    async def send_message(self, client_id: str, message: Dict[str, Any]):
        if client_id in self.active_connections:
            try:
                await self.active_connections[client_id].send_text(json.dumps(message))
            except Exception as e:
                print(f"[WS] Send error to {client_id}: {e}")

    async def broadcast(self, message: Dict[str, Any]):
        disconnected = []
        for client_id, connection in self.active_connections.items():
            try:
                await connection.send_text(json.dumps(message))
            except Exception as e:
                print(f"[WS] Broadcast error to {client_id}: {e}")
                disconnected.append(client_id)

        for client_id in disconnected:
            self.disconnect(client_id)

manager = ConnectionManager()

# ==================== 工具函数 ====================

def get_local_ip() -> str:
    """获取本地IP地址"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.settimeout(0)
        try:
            s.connect(('10.254.254.254', 1))
            ip = s.getsockname()[0]
        except Exception:
            ip = '127.0.0.1'
        finally:
            s.close()
        return ip
    except Exception:
        return '127.0.0.1'

# ==================== FastAPI应用 ====================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时加载所有Agent配置
    print("[INIT] Loading agent configurations...")
    configs = get_all_agent_configs()
    print(f"[INIT] Loaded {len(configs)} agent configs: {list(configs.keys())}")

    yield

    # 关闭时清理资源
    print("[SHUTDOWN] Closing resources...")
    await agent_service.close()

app = FastAPI(
    title="Janus 造价助手 API",
    description="Janus AI Agent Team 后端服务 - 协调Agent与各专业Agent的桥梁",
    version="1.0.0",
    lifespan=lifespan
)

# CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS if settings.CORS_ORIGINS != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================== API路由 - 健康检查 ====================

@app.get("/")
async def root():
    """根端点 - 服务信息"""
    return {
        "status": "ok",
        "service": "Janus 造价助手 API",
        "version": "1.0.0",
        "agents": list(get_all_agent_configs().keys()),
        "timestamp": datetime.now().isoformat()
    }

@app.get("/api/v1/health")
async def health_check():
    """健康检查端点 - v1版本"""
    agent_configs = get_all_agent_configs()
    return {
        "status": "healthy",
        "agent_ready": len(agent_configs) > 0,
        "agent_count": len(agent_configs),
        "timestamp": datetime.now().isoformat()
    }

# 向后兼容的旧端点
@app.get("/api/health")
async def health_check_legacy():
    """健康检查端点 - 兼容旧版本"""
    return await health_check()

@app.get("/api/v1/status")
async def system_status():
    """系统状态"""
    agent_configs = get_all_agent_configs()
    return {
        "status": "healthy",
        "orchestrator_ready": len(agent_configs) > 0,
        "agent_count": len(agent_configs),
        "agents_loaded": list(agent_configs.keys()),
        "projects_count": len(MOCK_PROJECTS),
        "active_connections": len(manager.active_connections),
        "timestamp": datetime.now().isoformat()
    }

# ==================== API路由 - 项目管理 ====================

@app.get("/api/v1/projects")
async def get_projects():
    """获取所有项目列表 - v1版本"""
    return {"projects": MOCK_PROJECTS, "total": len(MOCK_PROJECTS)}

# 向后兼容
@app.get("/api/projects")
async def get_projects_legacy():
    """获取项目列表 - 兼容旧版本"""
    return await get_projects()

@app.get("/api/v1/projects/{project_id}")
async def get_project(project_id: str):
    """获取单个项目详情 - v1版本"""
    for proj in MOCK_PROJECTS:
        if proj["id"] == project_id:
            return proj
    raise HTTPException(status_code=404, detail="Project not found")

# 向后兼容
@app.get("/api/projects/{project_id}")
async def get_project_legacy(project_id: str):
    """获取项目详情 - 兼容旧版本"""
    return await get_project(project_id)

@app.get("/api/v1/project")
async def get_active_project():
    """获取当前活动项目 - 兼容前端旧调用"""
    return {
        "active_project": "proj_001",
        "status": {
            "progress": 0.65,
            "specialties": ["建筑", "安装"]
        }
    }

@app.post("/api/v1/projects/{project_id}/files")
async def upload_file(
    project_id: str,
    file: UploadFile = File(...),
    description: Optional[str] = Form(None)
):
    """上传项目文件 - v1版本"""
    try:
        # 检查文件大小
        content = await file.read()
        if len(content) > settings.MAX_UPLOAD_SIZE:
            raise HTTPException(status_code=413, detail="File too large")

        # 创建上传目录
        upload_dir = settings.UPLOAD_DIR / project_id / "sources"
        upload_dir.mkdir(parents=True, exist_ok=True)

        # 保存文件
        file_path = upload_dir / file.filename
        with open(file_path, "wb") as f:
            f.write(content)

        return {
            "success": True,
            "filename": file.filename,
            "saved_to": str(file_path),
            "size": len(content),
            "description": description
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

# 向后兼容
@app.post("/api/projects/{project_id}/files")
async def upload_file_legacy(project_id: str, file: UploadFile = File(...), description: Optional[str] = Form(None)):
    """上传文件 - 兼容旧版本"""
    return await upload_file(project_id, file, description)

# ==================== API路由 - Agent对话 ====================

@app.post("/api/v1/chat")
async def agent_chat(message: ChatCommand):
    """发送消息给Agent - v1版本"""
    # 路由到对应Agent
    target_agent = agent_service.route_to_agent(message.text)

    # 调用Agent
    result = await agent_service.call_agent(
        target_agent,
        message.text,
        message.client_id
    )

    return result

# 向后兼容
@app.post("/api/agent/chat")
async def agent_chat_legacy(message: AgentMessage):
    """Agent对话 - 兼容旧版本"""
    cmd = ChatCommand(text=message.message, client_id=message.project_id)
    return await agent_chat(cmd)

# 兼容前端sendMessageToAgent调用的/command端点
@app.post("/api/v1/command")
async def agent_command(message: ChatCommand):
    """Agent命令端点 - 兼容前端调用"""
    result = await agent_chat(message)
    return {
        "status": "success" if result.get("success") else "failed",
        "message": result.get("reply", ""),
        "agent": result.get("agent", "unknown"),
        "timestamp": result.get("timestamp")
    }

# ==================== API路由 - 工程量清单 ====================

@app.get("/api/v1/projects/{project_id}/bills")
async def get_bill_of_quantities(project_id: str):
    """获取工程量清单"""
    if project_id in MOCK_BILLS:
        return MOCK_BILLS[project_id]

    # 返回空清单
    return BillOfQuantities(
        project_id=project_id,
        project_name="未知项目",
        items=[],
        updated_at=datetime.now().isoformat()
    )

@app.put("/api/v1/projects/{project_id}/bills/{item_id}")
async def update_bill_item(project_id: str, item_id: str, update_data: Dict[str, Any]):
    """更新工程量清单项"""
    if project_id not in MOCK_BILLS:
        raise HTTPException(status_code=404, detail="Project not found")

    bill = MOCK_BILLS[project_id]
    for item in bill.items:
        if item.id == item_id:
            if "quantity" in update_data:
                item.quantity = update_data["quantity"]
            if "unit_price" in update_data:
                item.unit_price = update_data["unit_price"]
            # 重新计算总价
            if item.unit_price is not None:
                item.total = item.quantity * item.unit_price
            return {"success": True, "item": item}

    raise HTTPException(status_code=404, detail="Item not found")

# ==================== API路由 - 连接管理 ====================

@app.get("/api/v1/connection/info")
async def get_connection_info():
    """获取连接信息 - v1版本"""
    local_ip = get_local_ip()
    agent_configs = get_all_agent_configs()

    return {
        "server_name": socket.gethostname(),
        "local_ip": local_ip,
        "port": settings.PORT,
        "status": "ready" if len(agent_configs) > 0 else "initializing",
        "qr_data": f"http://{local_ip}:{settings.PORT}",
        "agent_status": {name: "ready" for name in agent_configs.keys()}
    }

# 向后兼容
@app.get("/api/connection/info")
async def get_connection_info_legacy():
    """获取连接信息 - 兼容旧版本"""
    return await get_connection_info()

# ==================== WebSocket路由 ====================

@app.websocket("/api/v1/ws")
async def websocket_endpoint_v1(websocket: WebSocket, client_id: str = "default"):
    """WebSocket连接 - v1版本"""
    await manager.connect(websocket, client_id)

    try:
        # 发送连接确认
        await manager.send_message(client_id, {
            "type": "connected",
            "client_id": client_id,
            "timestamp": datetime.now().isoformat()
        })

        while True:
            data = await websocket.receive_text()
            try:
                message = json.loads(data)
                text = message.get("text", "")

                # 更新统计
                if client_id in manager.connection_info:
                    manager.connection_info[client_id]["message_count"] += 1

                # 路由到对应Agent
                target_agent = agent_service.route_to_agent(text)

                # 调用Agent并获取响应
                result = await agent_service.call_agent(target_agent, text, client_id)

                # 发送响应
                await manager.send_message(client_id, {
                    "type": "message",
                    "id": f"msg_{datetime.now().timestamp()}",
                    "content": result.get("reply", "Agent无响应"),
                    "agent": result.get("agent", "unknown"),
                    "timestamp": datetime.now().isoformat()
                })

            except json.JSONDecodeError:
                await manager.send_message(client_id, {
                    "type": "error",
                    "content": "Invalid JSON format"
                })
            except Exception as e:
                await manager.send_message(client_id, {
                    "type": "error",
                    "content": f"Error processing message: {str(e)}"
                })

    except WebSocketDisconnect:
        manager.disconnect(client_id)
    except Exception as e:
        print(f"[WS] Error: {e}")
        manager.disconnect(client_id)

# 向后兼容
@app.websocket("/ws/agent")
async def websocket_endpoint_legacy(websocket: WebSocket):
    """WebSocket连接 - 兼容旧版本"""
    await websocket_endpoint_v1(websocket, "legacy_client")

# ==================== 启动入口 ====================

if __name__ == "__main__":
    import uvicorn
    print(f"[START] Janus API Server starting on {settings.HOST}:{settings.PORT}")
    print(f"[START] Agent config dir: {settings.AGENT_CONFIG_DIR}")
    uvicorn.run(app, host=settings.HOST, port=settings.PORT)
