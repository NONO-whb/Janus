#!/bin/bash
# 启动 ENG 后端服务

cd "$(dirname "$0")"

# 激活虚拟环境
source venv/bin/activate

# 安装依赖（如果没有）
if ! pip show fastapi &> /dev/null; then
    echo "Installing dependencies..."
    pip install -r requirements.txt
fi

# 启动服务
echo "Starting ENG Backend Server..."
echo "API docs: http://localhost:8080/docs"
python main.py
