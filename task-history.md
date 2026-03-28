---

## 2026-03-25 - 前端 UI 细节改进

**任务**: 改进页面结构及 UI 细节（不动 API 契约）
**状态**: ✅ 完成
**执行策略**: 只改 UI/交互，后端零影响

### 改进内容

| 模块 | 改动 | 技术要点 |
|------|------|----------|
| LogoAnimation | 呼吸动画 + 微旋转 + 阴影 | AnimationController + Tween(scale/rotate) |
| PromptCard | 点击缩放反馈 + 图标 + 跳转 | GestureDetector + onTapDown/Up |
| 首页输入框 | 可点击 → 跳转项目列表 | GestureDetector + Navigator |
| 设置页 | 服务器地址配置 | CupertinoTextField + ApiConfig.setBaseUrl |

### 关键代码片段

```dart
// Logo 呼吸动画
_controller = AnimationController(
  duration: const Duration(milliseconds: 2000),
)..repeat(reverse: true);

// 提示卡片跳转带问题
ProjectsListView(prefillMessage: cleanPrompt)

// 服务器地址配置
ApiConfig.setBaseUrl(ip); // 自动触发重连
```

### 下一步
- 后端整体功能改进（真数据、真 AI、WebSocket 优化）

---
