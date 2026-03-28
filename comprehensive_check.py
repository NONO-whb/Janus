# -*- coding: utf-8 -*-
"""
前后端彻底测试 - 验证所有API契约（包含新增端点）
"""
from __future__ import print_function
import json
import sys
import asyncio
from pathlib import Path
from io import BytesIO

sys.path.insert(0, '/Users/cck/Desktop/Janus/backend')

from fastapi.testclient import TestClient
from main_v4 import app, orchestrator

client = TestClient(app)

ERRORS = []
WARNINGS = []

def log_error(msg):
    ERRORS.append(msg)
    print(f"  ❌ ERROR: {msg}")

def log_warning(msg):
    WARNINGS.append(msg)
    print(f"  ⚠️  WARNING: {msg}")

def check(condition, msg):
    if condition:
        print(f"  ✅ {msg}")
        return True
    else:
        log_error(msg)
        return False

print("=" * 60)
print("前后端彻底测试 - 模拟测试")
print("=" * 60)

# ============ 1. 后端API端点检查 ============
print("\n【1. 后端API端点检查】")

# 1.1 根端点
print("\n  [1.1] GET /")
resp = client.get("/")
check(resp.status_code == 200, "根端点响应200")
if resp.status_code == 200:
    data = resp.json()
    check("service" in data, "包含service字段")
    check("version" in data, "包含version字段")
    check("team" in data, "包含team字段")

# 1.2 健康检查
print("\n  [1.2] GET /api/v1/health")
resp = client.get("/api/v1/health")
check(resp.status_code == 200, "健康检查响应200")
if resp.status_code == 200:
    data = resp.json()
    check(data.get("status") == "healthy", "status为healthy")
    check("team_ready" in data, "包含team_ready字段")

# 1.3 Chat端点 (POST)
print("\n  [1.3] POST /api/v1/chat")
resp = client.post(
    "/api/v1/chat",
    json={"message": "测试", "client_id": "test"}
)
check(resp.status_code == 200, "Chat端点响应200")
if resp.status_code == 200:
    data = resp.json()
    check("success" in data, "包含success字段")
    check("content" in data, "包含content字段")
    check("confidence" in data, "包含confidence字段")
    check("confidence_level" in data, "包含confidence_level字段")
    check("requires_review" in data, "包含requires_review字段")
    check("departments" in data, "包含departments字段")
    check(isinstance(data.get("departments"), list), "departments是列表")

# 1.4 Command端点 (POST) - 前端使用的端点
print("\n  [1.4] POST /api/v1/command (前端主要端点)")

# 测试正确字段名
resp = client.post(
    "/api/v1/command",
    json={"message": "测试定额", "client_id": "test"}
)
check(resp.status_code == 200, "使用'message'字段响应200")
if resp.status_code == 200:
    data = resp.json()
    check("status" in data, "包含status字段")
    check("message" in data, "包含message字段")
    check("confidence" in data, "包含confidence字段")
    check("departments" in data, "包含departments字段")

# 测试错误字段名 (应该失败)
resp_wrong = client.post(
    "/api/v1/command",
    json={"text": "测试", "client_id": "test"}
)
check(resp_wrong.status_code == 422, "使用错误字段'text'返回422")

# 1.5 新增端点检查
print("\n【1.5】新增端点检查（前端需要）")

print("\n  [1.5.1] GET /api/v1/status")
resp = client.get("/api/v1/status")
check(resp.status_code == 200, f"/api/v1/status 响应200")
if resp.status_code == 200:
    data = resp.json()
    check(data.get("orchestrator_ready") == True, "status包含orchestrator_ready")
    check("active_project" in data, "status包含active_project")

print("\n  [1.5.2] GET /api/v1/projects")
resp = client.get("/api/v1/projects")
check(resp.status_code == 200, f"/api/v1/projects 响应200")
if resp.status_code == 200:
    data = resp.json()
    check("projects" in data, "包含projects字段")
    check(isinstance(data.get("projects"), list), "projects是列表")

print("\n  [1.5.3] GET /api/v1/project")
resp = client.get("/api/v1/project")
check(resp.status_code == 200, f"/api/v1/project 响应200")
if resp.status_code == 200:
    data = resp.json()
    check("active_project" in data, "包含active_project字段")
    check("status" in data, "包含status字段")

print("\n  [1.5.4] POST /api/v1/projects/test/files")
test_file = BytesIO(b"test file content")
resp = client.post(
    "/api/v1/projects/test/files",
    files={"file": ("test.txt", test_file, "text/plain")}
)
check(resp.status_code == 200, f"/api/v1/projects/test/files 响应200")
if resp.status_code == 200:
    data = resp.json()
    check(data.get("success") == True, "上传成功")
    check("file" in data, "返回file信息")

print("\n  [1.5.5] GET /api/v1/projects/test/bills")
resp = client.get("/api/v1/projects/test/bills")
check(resp.status_code == 200, f"/api/v1/projects/test/bills 响应200")
if resp.status_code == 200:
    data = resp.json()
    check("project_id" in data, "包含project_id字段")
    check("items" in data, "包含items字段")
    check(isinstance(data.get("items"), list), "items是列表")

# ============ 2. WebSocket检查 ============
print("\n【2. WebSocket连接检查】")

print("\n  [2.1] WebSocket连接和消息格式")
try:
    with client.websocket_connect("/api/v1/ws?client_id=ws_test") as ws:
        # 接收连接确认
        conn_msg = ws.receive_json()
        check(conn_msg.get("type") == "connected", "收到connected消息")
        check("client_id" in conn_msg, "connected消息包含client_id")
        check("architecture" in conn_msg, "connected消息包含architecture")
        check("team" in conn_msg, "connected消息包含team")

        # 测试简化格式 (修复后的格式)
        print("\n  [2.2] WebSocket消息格式 (简化格式 - 修复后)")
        ws.send_json({"text": "测试消息"})

        processing = ws.receive_json()
        check(processing.get("type") == "processing", "收到processing消息")

        result = ws.receive_json()
        check(result.get("type") == "message", "收到message结果")
        check("content" in result, "结果包含content")
        check("confidence" in result, "结果包含confidence")

except Exception as e:
    log_error(f"WebSocket测试失败: {e}")

# ============ 3. 数据模型检查 ============
print("\n【3. 数据模型一致性检查】")

print("\n  [3.1] ChatRequest模型")
from main_v4 import ChatRequest

try:
    req = ChatRequest(message="测试", client_id="test")
    check(True, "ChatRequest可创建")
    check(hasattr(req, "message"), "ChatRequest有message字段")
    check(hasattr(req, "client_id"), "ChatRequest有client_id字段")
    check(hasattr(req, "context"), "ChatRequest有context字段")
except Exception as e:
    log_error(f"ChatRequest模型错误: {e}")

print("\n  [3.2] ChatResponse模型")
from main_v4 import ChatResponse

try:
    resp = ChatResponse(
        success=True,
        content="测试",
        confidence=0.95,
        confidence_level="high",
        requires_review=False,
        departments=["工程部"],
        timestamp="2024-01-01T00:00:00"
    )
    check(True, "ChatResponse可创建")
except Exception as e:
    log_error(f"ChatResponse模型错误: {e}")

# ============ 4. 前端服务代码静态检查 ============
print("\n【4. 前端服务代码静态检查】")

api_service_path = Path("/Users/cck/Desktop/Janus/lib/services/api_service.dart")
websocket_service_path = Path("/Users/cck/Desktop/Janus/lib/services/websocket_service.dart")

print("\n  [4.1] api_service.dart 字段检查")
api_content = api_service_path.read_text()

# 检查POST /api/v1/command 使用正确字段
if "'message': message" in api_content:
    print("  ✅ POST /api/v1/command 使用正确字段 'message'")
else:
    log_error("POST /api/v1/command 未找到 'message' 字段")

# 检查没有使用旧字段名
if "'text': message" in api_content and "'message': message" not in api_content:
    log_error("POST /api/v1/command 仍在使用错误的 'text' 字段")

# 检查多余的字段
if "'source': 'mobile'" in api_content:
    log_warning("api_service.dart 仍包含多余的 'source' 字段")
else:
    print("  ✅ 已移除多余的 'source' 字段")

print("\n  [4.2] websocket_service.dart 字段检查")
ws_content = websocket_service_path.read_text()

# 检查WebSocket消息格式
if "'text': content.trim()" in ws_content or '"text": content.trim()' in ws_content:
    print("  ✅ WebSocket使用简化的'text'字段")
else:
    log_error("WebSocket未使用简化格式")

# 检查是否还有多余字段
if "'type': 'command'" in ws_content or '"type": "command"' in ws_content:
    log_warning("websocket_service.dart 仍包含 'type' 字段")

if "'source': 'mobile'" in ws_content or '"source": "mobile"' in ws_content:
    log_warning("websocket_service.dart 仍包含 'source' 字段")

# ============ 5. Orchestrator检查 ============
print("\n【5. Orchestrator核心逻辑检查】")

print("\n  [5.1] 团队成员初始化")
check(hasattr(orchestrator, "shoufu"), "首辅已初始化")
check(hasattr(orchestrator, "ceo"), "CEO已初始化")
check(hasattr(orchestrator, "gongchengbu"), "工程部已初始化")
check(hasattr(orchestrator, "xinxibu"), "信息部已初始化")
check(hasattr(orchestrator, "ziliaobu"), "资料部已初始化")
check(hasattr(orchestrator, "houqinbu"), "后勤部已初始化")

print("\n  [5.2] 部门注册检查")
houqinbu = orchestrator.houqinbu
check("工程部" in houqinbu.departments, "工程部已注册到后勤部")
check("信息部" in houqinbu.departments, "信息部已注册到后勤部")
check("资料部" in houqinbu.departments, "资料部已注册到后勤部")

# ============ 6. CORS配置检查 ============
print("\n【6. CORS配置检查】")

# 实际测试跨域
resp = client.options("/api/v1/health", headers={
    "Origin": "http://localhost:3000",
    "Access-Control-Request-Method": "POST"
})
print(f"  CORS预检响应: {resp.status_code}")

# ============ 7. 端到端模拟测试 ============
print("\n【7. 端到端模拟测试】")

print("\n  [7.1] 完整项目流程模拟")
# Step 1: 获取状态
resp = client.get("/api/v1/status")
check(resp.status_code == 200, "1. 获取服务状态")

# Step 2: 获取项目列表
resp = client.get("/api/v1/projects")
check(resp.status_code == 200, "2. 获取项目列表")

# Step 3: 获取项目详情
resp = client.get("/api/v1/project")
check(resp.status_code == 200, "3. 获取项目详情")

# Step 4: 发送消息
resp = client.post(
    "/api/v1/command",
    json={"message": "查询土方开挖定额", "client_id": "e2e_test"}
)
check(resp.status_code == 200, "4. 发送消息给Agent")
if resp.status_code == 200:
    data = resp.json()
    print(f"      响应: {data.get('message', '')[:50]}...")

# Step 5: 获取工程量清单
resp = client.get("/api/v1/projects/e2e_test/bills")
check(resp.status_code == 200, "5. 获取工程量清单")

# Step 6: 上传文件
test_file = BytesIO(b"drawing file content")
resp = client.post(
    "/api/v1/projects/e2e_test/files",
    files={"file": ("drawing.dwg", test_file, "application/octet-stream")}
)
check(resp.status_code == 200, "6. 上传项目文件")

# ============ 总结 ============
print("\n" + "=" * 60)
print("测试结果汇总")
print("=" * 60)

if ERRORS:
    print(f"\n❌ 错误: {len(ERRORS)} 个")
    for e in ERRORS:
        print(f"   - {e}")
else:
    print("\n✅ 未发现错误")

if WARNINGS:
    print(f"\n⚠️  警告: {len(WARNINGS)} 个")
    for w in WARNINGS:
        print(f"   - {w}")
else:
    print("\n✅ 无警告")

print("\n" + "=" * 60)
if not ERRORS:
    print("✅ 模拟测试通过 - 前后端API全部正常")
else:
    print(f"❌ 发现 {len(ERRORS)} 个错误，需要修复")
print("=" * 60)

sys.exit(1 if ERRORS else 0)
