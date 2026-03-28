"""
CEO (Layer 2)
职责: 项目管家、任务分发、进度记录
"""
from typing import Dict, Any, List
from datetime import datetime
import uuid
import os
import yaml
from pathlib import Path


class CEOAgent:
    """CEO - 项目大脑"""

    def __init__(self, projects_dir: str = None):
        self.projects_dir = Path(projects_dir or os.path.expanduser("~/Desktop/造价项目"))
        self.projects_dir.mkdir(parents=True, exist_ok=True)

    async def process(self, shoufu_output: Dict[str, Any]) -> Dict[str, Any]:
        """处理首辅输出"""

        raw_request = shoufu_output.get("raw_request", "")
        keywords = shoufu_output.get("extracted_keywords", [])
        is_followup = shoufu_output.get("is_followup", False)

        # 1. 检测/加载项目
        project_info = self._detect_project(raw_request, keywords)

        if project_info["is_new"]:
            # 新项目 - 设立
            project_path = self._create_project(project_info["name"])
            self._init_project_status(project_path, project_info["name"])
        else:
            # 现有项目 - 加载
            project_path = project_info["path"]

        # 2. 分析需求，识别部门
        departments = self._identify_departments(raw_request, keywords)

        # 3. 记录任务分发
        self._update_timeline(project_path, "CEO", "任务分发", f"识别需要: {', '.join(departments)}")

        return {
            "project_name": project_info["name"],
            "project_path": str(project_path),
            "is_new_project": project_info["is_new"],
            "departments": departments,
            "request": raw_request,
            "context": {
                "keywords": keywords,
                "is_followup": is_followup
            }
        }

    def _detect_project(self, request: str, keywords: List[str]) -> Dict[str, Any]:
        """检测项目（新/现有）"""

        # 尝试从请求中提取项目名称
        project_name = self._extract_project_name(request)

        if not project_name:
            # 默认项目名称
            project_name = f"项目_{datetime.now().strftime('%Y%m%d_%H%M')}"

        project_path = self.projects_dir / project_name

        if project_path.exists():
            return {
                "name": project_name,
                "path": project_path,
                "is_new": False
            }

        return {
            "name": project_name,
            "path": project_path,
            "is_new": True
        }

    def _extract_project_name(self, request: str) -> str:
        """从请求中提取项目名称"""
        # 简单规则：提取引号内或书名号内的内容
        import re

        # "项目名称" 或 《项目名称》
        patterns = [
            r'["""]([^"""]+)["""]',
            r'《([^》]+)》',
            r'(\w+项目)',
            r'(\w+工程)'
        ]

        for pattern in patterns:
            match = re.search(pattern, request)
            if match:
                return match.group(1)

        return ""

    def _create_project(self, project_name: str) -> Path:
        """创建项目目录结构"""
        project_path = self.projects_dir / project_name

        # 创建目录
        (project_path / "图纸").mkdir(parents=True, exist_ok=True)
        (project_path / "清单").mkdir(parents=True, exist_ok=True)
        (project_path / "资料").mkdir(parents=True, exist_ok=True)
        (project_path / "成果").mkdir(parents=True, exist_ok=True)

        return project_path

    def _init_project_status(self, project_path: Path, project_name: str):
        """初始化项目状态"""
        status = {
            "project_name": project_name,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "timeline": [
                {
                    "time": datetime.now().isoformat(),
                    "actor": "CEO",
                    "action": "项目设立",
                    "detail": f"创建项目目录 {project_path}"
                }
            ],
            "progress": {
                "工程部": {"total": 0, "completed": 0, "status": "未启动"},
                "信息部": {"total": 0, "completed": 0, "status": "未启动"},
                "资料部": {"total": 0, "completed": 0, "status": "未启动"}
            },
            "overall_status": "created",
            "current_stage": "项目初始化",
            "next_action": "等待用户提交资料",
            "blockers": [],
            "files": {}
        }

        self._save_status(project_path, status)

    def _identify_departments(self, request: str, keywords: List[str]) -> List[str]:
        """识别需要哪些部门"""
        departments = []

        # 工程部关键词
        gongchengbu_keywords = ["定额", "清单", "造价", "套", "工程量", "建筑", "安装", "市政", "园林", "仿古", "混凝土", "钢筋", "图纸"]
        if any(kw in request for kw in gongchengbu_keywords):
            departments.append("工程部")

        # 信息部关键词
        xinxibu_keywords = ["查询", "招标", "中标", "价格", "行情", "审查", "合同", "投标"]
        if any(kw in request for kw in xinxibu_keywords):
            departments.append("信息部")

        # 资料部关键词
        ziliaobu_keywords = ["报告", "文档", "资料", "报验", "竣工", "签证", "联系单", "开工", "记录"]
        if any(kw in request for kw in ziliaobu_keywords):
            departments.append("资料部")

        # 默认工程部
        if not departments:
            departments.append("工程部")

        return departments

    def _update_timeline(self, project_path: Path, actor: str, action: str, detail: str):
        """更新时间线"""
        status = self._load_status(project_path)

        status["timeline"].append({
            "time": datetime.now().isoformat(),
            "actor": actor,
            "action": action,
            "detail": detail
        })
        status["updated_at"] = datetime.now().isoformat()

        self._save_status(project_path, status)

    def update_department_progress(self, project_path: Path, department: str,
                                    total: int, completed: int, status_str: str):
        """更新部门进度"""
        status = self._load_status(project_path)

        status["progress"][department] = {
            "total": total,
            "completed": completed,
            "status": status_str
        }
        status["updated_at"] = datetime.now().isoformat()

        self._save_status(project_path, status)

    def _load_status(self, project_path: Path) -> Dict[str, Any]:
        """加载项目状态"""
        status_file = project_path / "PROJECT-STATUS.yaml"

        if status_file.exists():
            with open(status_file, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)

        return {}

    def _save_status(self, project_path: Path, status: Dict[str, Any]):
        """保存项目状态"""
        status_file = project_path / "PROJECT-STATUS.yaml"

        with open(status_file, 'w', encoding='utf-8') as f:
            yaml.dump(status, f, allow_unicode=True, sort_keys=False)

    async def finalize_result(self, project_path: Path, results: Dict[str, Any]) -> Dict[str, Any]:
        """汇总结果，更新状态"""
        status = self._load_status(project_path)

        # 更新时间线
        for dept, result in results.items():
            confidence = result.get("confidence", 0)
            self._update_timeline(
                project_path,
                f"{dept}经理",
                "任务完成",
                f"置信度: {confidence:.0f}%"
            )

        # 更新总体状态
        status["overall_status"] = "in_progress"
        status["current_stage"] = "处理完成"
        status["next_action"] = "等待用户确认"
        status["updated_at"] = datetime.now().isoformat()

        self._save_status(project_path, status)

        return {
            "success": True,
            "project_name": status.get("project_name"),
            "results": results,
            "timeline": status.get("timeline", [])[-5:]  # 最近5条
        }
