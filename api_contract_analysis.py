"""
前后端API契约对比分析
"""

# ============ 后端API (main_v4.py) ============

BACKEND_APIS = {
    "GET /": {
        "response": {"service", "version", "architecture", "team", "status", "timestamp"}
    },
    "GET /api/v1/health": {
        "response": {"status", "architecture", "team_ready", "timestamp"}
    },
    "POST /api/v1/chat": {
        "request": {"message": str, "client_id": str, "context": Optional[list]},
        "response": {"success", "content", "confidence", "confidence_level", "requires_review", "departments", "timestamp"}
    },
    "POST /api/v1/command": {
        "request": {"message": str, "client_id": str, "context": Optional[list]},  # ChatRequest
        "response": {"status", "message", "confidence", "requires_review", "departments", "timestamp"}
    },
    "WebSocket /api/v1/ws": {
        "params": {"client_id": str},
        "client_to_server": {"text": str},
        "server_to_client": {
            "connected": {"type", "client_id", "architecture", "team", "timestamp"},
            "processing": {"type", "stage", "message"},
            "message": {"type", "content", "confidence", "confidence_level", "requires_review", "departments", "timestamp"},
            "error": {"type", "content"}
        }
    }
}

# ============ 前端API调用 (api_service.dart) ============

FRONTEND_CALLS = {
    "ApiService.healthCheck()": {
        "endpoint": "GET /api/v1/health",
        "match": True
    },
    "ApiService.getConnectionInfo()": {
        "endpoint": "GET /api/v1/status",  # ❌ 后端不存在
        "match": False,
        "issue": "后端缺少 /api/v1/status 端点"
    },
    "ApiService.getProjects()": {
        "endpoint": "GET /api/v1/projects",  # ❌ 后端不存在
        "match": False,
        "issue": "后端缺少 /api/v1/projects 端点"
    },
    "ApiService.getProjectDetail()": {
        "endpoint": "GET /api/v1/project",  # ❌ 后端不存在
        "match": False,
        "issue": "后端缺少 /api/v1/project 端点"
    },
    "ApiService.sendMessageToAgent()": {
        "endpoint": "POST /api/v1/command",
        "request_body": {"text": str, "source": str, "client_id": str},  # ❌ 字段名不匹配
        "expected_by_backend": {"message": str, "client_id": str, "context": Optional[list]},
        "match": False,
        "issue": "请求字段名不匹配: text vs message, 多余source字段"
    },
    "ApiService.uploadFile()": {
        "endpoint": "POST /api/v1/projects/{projectId}/files",  # ❌ 后端不存在
        "match": False,
        "issue": "后端缺少文件上传端点"
    },
    "ApiService.getBillOfQuantities()": {
        "endpoint": "GET /api/v1/projects/{projectId}/bills",  # ❌ 后端不存在
        "match": False,
        "issue": "后端缺少工程量清单端点"
    }
}

# ============ WebSocket 对比 ============

WEBSOCKET_ISSUES = {
    "前端发送": {
        "type": "command",
        "text": str,
        "source": "mobile",
        "client_id": str
    },
    "后端期望": {
        "text": str  # 只读取text字段
    },
    "问题": "前端发送多余字段，但后端能正常解析(只读取需要的字段)，不影响功能",
    "严重级别": "低"
}

# ============ 总结 ============

ISSUES_SUMMARY = """
【严重问题】
1. POST /api/v1/command 请求字段不匹配
   - 前端发送: {text, source, client_id}
   - 后端期望: {message, client_id}
   - 修复: 前端应将 'text' 改为 'message', 移除 'type' 和 'source'

2. 多个API端点后端未实现
   - GET /api/v1/status
   - GET /api/v1/projects
   - GET /api/v1/project
   - POST /api/v1/projects/{projectId}/files
   - GET /api/v1/projects/{projectId}/bills

   这些在前端是模拟数据或调用会失败，需要后端补充实现

【轻微问题】
3. WebSocket消息字段冗余但不影响功能

【建议修复优先级】
P0: 修复POST /api/v1/command字段名不匹配
P1: 实现项目列表/详情API
P2: 实现文件上传API
P3: 实现工程量清单API
"""

print(ISSUES_SUMMARY)
