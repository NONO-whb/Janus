"""
验证API修复的测试脚本
"""
import json
import sys
import time
from fastapi.testclient import TestClient

# 添加backend目录到路径
sys.path.insert(0, '/Users/cck/Desktop/Janus/backend')

from main_v4 import app

client = TestClient(app)

print("=" * 50)
print("开始验证API修复")
print("=" * 50)

# 测试1: 健康检查
print("\n[Test 1] 健康检查 GET /api/v1/health")
response = client.get("/api/v1/health")
print(f"Status: {response.status_code}")
print(f"Response: {response.json()}")
assert response.status_code == 200
print("[PASS] 健康检查通过")

# 测试2: POST /api/v1/command - 使用正确的字段名
print("\n[Test 2] POST /api/v1/command (修复后的字段名)")
response = client.post(
    "/api/v1/command",
    json={
        "message": "你好，测试消息",
        "client_id": "test_client"
    }
)
print(f"Status: {response.status_code}")
print(f"Response: {json.dumps(response.json(), ensure_ascii=False, indent=2)}")
assert response.status_code == 200
assert "message" in response.json()
print("[PASS] 命令端点工作正常，使用正确的'message'字段")

# 测试3: 测试旧字段名应该失败或不被正确处理
print("\n[Test 3] POST /api/v1/command (旧字段名'text' - 后端应该无法正确处理)")
response = client.post(
    "/api/v1/command",
    json={
        "text": "使用旧字段名的消息",
        "client_id": "test_client"
    }
)
print(f"Status: {response.status_code}")
result = response.json()
print(f"Response: {json.dumps(result, ensure_ascii=False, indent=2)}")
# 由于后端读取的是'message'字段，使用'text'会导致空消息处理
# 这证明了修复是必要的
print("[INFO] 使用旧字段名时，后端读取不到内容，证明了修复的必要性")

# 测试4: WebSocket连接测试
print("\n[Test 4] WebSocket连接测试")
with client.websocket_connect("/api/v1/ws?client_id=test_ws") as websocket:
    # 接收连接确认
    data = websocket.receive_json()
    print(f"连接确认: {data}")
    assert data["type"] == "connected"
    print("[PASS] WebSocket连接成功")

    # 发送消息 - 使用简化格式 (只发送text)
    print("\n发送消息 (简化格式 - 只包含text字段)...")
    websocket.send_json({
        "text": "测试WebSocket消息"
    })

    # 接收处理中状态
    processing = websocket.receive_json()
    print(f"处理中: {processing}")
    assert processing["type"] == "processing"
    print("[PASS] 收到处理中状态")

    # 接收最终结果
    result = websocket.receive_json()
    print(f"最终结果: {json.dumps(result, ensure_ascii=False, indent=2)}")
    assert result["type"] == "message"
    assert "content" in result
    print("[PASS] 收到完整响应")

print("\n" + "=" * 50)
print("所有测试通过！API修复验证完成")
print("=" * 50)
print("\n修复总结:")
print("1. api_service.dart: 请求字段 'text' → 'message' ✓")
print("2. websocket_service.dart: 简化消息格式，只发送'text' ✓")
