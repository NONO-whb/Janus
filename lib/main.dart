import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'services/api_service.dart';

void main() {
  runApp(const EngApp());
}

// ==================== 应用入口 ====================
class EngApp extends StatelessWidget {
  const EngApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'ENG',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        primaryColor: Colors.black,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            fontFamily: 'Noto Sans SC',
            fontFamilyFallback: DesignTokens._fontFallback,
            fontSize: 16,
            color: DesignTokens.primaryText,
          ),
          navTitleTextStyle: TextStyle(
            fontFamily: 'Noto Sans SC',
            fontFamilyFallback: DesignTokens._fontFallback,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: DesignTokens.primaryText,
          ),
          navLargeTitleTextStyle: TextStyle(
            fontFamily: 'Noto Sans SC',
            fontFamilyFallback: DesignTokens._fontFallback,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: DesignTokens.primaryText,
          ),
          actionTextStyle: TextStyle(
            fontFamily: 'Noto Sans SC',
            fontFamilyFallback: DesignTokens._fontFallback,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
      home: HomeView(),
    );
  }
}

// ==================== 设计规范 ====================
class DesignTokens {
  // 背景色
  static const Color background = Color(0xFFFFFFFF);
  static const Color secondaryBackground = Color(0xFFF7F7F8);
  static const Color cardBackground = Color(0xFFF7F7F8);

  // 文字色
  static const Color primaryText = Color(0xFF343541);
  static const Color secondaryText = Color(0xFF6E6E80);
  static const Color tertiaryText = Color(0xFFACACBE);

  // 强调色（黑色系）
  static const Color accentBlue = Color(0xFF000000);
  static const Color accentGreen = Color(0xFF1A1A1A);
  static const Color accentOrange = Color(0xFF333333);
  static const Color accentRed = Color(0xFF000000);

  // 功能色
  static const Color quotaHighlight = Color(0xFF0066CC);
  static const Color confidenceLow = Color(0xFFFF9500);
  static const Color confidenceMedium = Color(0xFF5856D6);
  static const Color confidenceHigh = Color(0xFF34C759);

  // 分隔线
  static const Color separator = Color(0xFFD9D9E3);
  static const Color border = Color(0xFFE5E5E5);

  // 尺寸
  static const double navBarHeight = 50;
  static const double inputHeight = 44;
  static const double bottomSafeArea = 34;

  // 字号
  static const double fontSizeTitle = 17;
  static const double fontSizeBody = 16;
  static const double fontSizeSmall = 14;
  static const double fontSizeCaption = 12;

  // 字体回退
  static const List<String> _fontFallback = [
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'Noto Sans SC',
    'PingFang SC',
    'Microsoft YaHei',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  static TextStyle get titleStyle => const TextStyle(
    fontSize: fontSizeTitle,
    fontWeight: FontWeight.w600,
    color: primaryText,
    fontFamilyFallback: _fontFallback,
  );

  static TextStyle get bodyStyle => const TextStyle(
    fontSize: fontSizeBody,
    color: primaryText,
    fontFamilyFallback: _fontFallback,
  );

  static TextStyle get secondaryStyle => const TextStyle(
    fontSize: fontSizeSmall,
    color: secondaryText,
    fontFamilyFallback: _fontFallback,
  );

  static TextStyle get captionStyle => const TextStyle(
    fontSize: fontSizeCaption,
    color: tertiaryText,
    fontFamilyFallback: _fontFallback,
  );

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.04),
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];
}

// ==================== 数据模型 ====================

// 引用来源
class Reference {
  final String title;
  final String source;
  final String detail;

  Reference({required this.title, required this.source, this.detail = ''});
}

// 思考阶段
enum ThinkingStage {
  analyzing,
  matching,
  calculating,
  verifying,
}

// 置信度等级
enum ConfidenceLevel { high, medium, low }

// 项目模型
class Project {
  final String id;
  final String name;
  final String description;
  final DateTime lastModified;
  final double progress;
  final bool isActive;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.lastModified,
    this.progress = 0.0,
    this.isActive = false,
  });
}

// 消息模型
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<Reference>? references;
  final ThinkingStage? thinkingStage;
  final ConfidenceLevel? confidenceLevel;
  final bool isTyping;
  final List<String>? mentions;
  // 编辑/撤回支持
  final bool isRecalled;
  final DateTime? editedAt;
  final String? originalContent;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.references,
    this.thinkingStage,
    this.confidenceLevel,
    this.isTyping = false,
    this.mentions,
    this.isRecalled = false,
    this.editedAt,
    this.originalContent,
  });

  // 复制并更新字段
  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    List<Reference>? references,
    ThinkingStage? thinkingStage,
    ConfidenceLevel? confidenceLevel,
    bool? isTyping,
    List<String>? mentions,
    bool? isRecalled,
    DateTime? editedAt,
    String? originalContent,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      references: references ?? this.references,
      thinkingStage: thinkingStage ?? this.thinkingStage,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      isTyping: isTyping ?? this.isTyping,
      mentions: mentions ?? this.mentions,
      isRecalled: isRecalled ?? this.isRecalled,
      editedAt: editedAt ?? this.editedAt,
      originalContent: originalContent ?? this.originalContent,
    );
  }
}

// ==================== 首页 ====================
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatView();
  }
}

// ==================== Logo动画 ====================
class LogoAnimation extends StatefulWidget {
  const LogoAnimation({super.key});

  @override
  State<LogoAnimation> createState() => _LogoAnimationState();
}

class _LogoAnimationState extends State<LogoAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text(
              'E',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== 侧边栏视图 ====================
class _SidebarView extends StatelessWidget {
  final VoidCallback onClose;

  const _SidebarView({required this.onClose});

  final List<Map<String, dynamic>> _records = const [
    {'title': '混凝土基础定额匹配记录', 'date': '2026-03-27', 'type': '定额'},
    {'title': '钢筋工程量计算', 'date': '2026-03-26', 'type': '计算'},
    {'title': '招标文件分析', 'date': '2026-03-25', 'type': '分析'},
  ];

  final List<Map<String, dynamic>> _files = const [
    {'name': '学校综合楼图纸.pdf', 'size': '12.5 MB', 'type': 'pdf'},
    {'name': '工程量清单.xlsx', 'size': '856 KB', 'type': 'xlsx'},
    {'name': '招标文件.docx', 'size': '2.3 MB', 'type': 'doc'},
    {'name': '结构图.dwg', 'size': '5.1 MB', 'type': 'dwg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      height: MediaQuery.of(context).size.height,
      color: DesignTokens.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '工作空间',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.all(8), // 增大点击区域
                    minSize: 44, // 符合iOS点击规范
                    onPressed: onClose,
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 24,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 记录事项区域
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.clock,
                          size: 18,
                          color: DesignTokens.secondaryText,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '记录事项',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.secondaryText,
                          ),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: () {},
                          child: const Text(
                            '查看全部',
                            style: TextStyle(
                              fontSize: 12,
                              color: DesignTokens.quotaHighlight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _records.length,
                      itemBuilder: (context, index) {
                        final record = _records[index];
                        return _buildRecordItem(record);
                      },
                    ),
                  ),
                ],
              ),
            ),
            // 分隔线
            const Divider(height: 1, indent: 16, endIndent: 16),
            // 项目文件区域
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.folder,
                          size: 18,
                          color: DesignTokens.secondaryText,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '项目文件',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.secondaryText,
                          ),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: () {},
                          child: const Icon(
                            CupertinoIcons.plus,
                            size: 20,
                            color: DesignTokens.quotaHighlight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _files.length,
                      itemBuilder: (context, index) {
                        final file = _files[index];
                        return _buildFileItem(file);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItem(Map<String, dynamic> record) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: DesignTokens.separator, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: record['type'] == '定额'
                    ? CupertinoColors.activeBlue
                    : record['type'] == '计算'
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemOrange,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record['title'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: DesignTokens.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record['date']} · ${record['type']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: DesignTokens.tertiaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: DesignTokens.tertiaryText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(Map<String, dynamic> file) {
    IconData icon;
    Color color;
    switch (file['type']) {
      case 'pdf':
        icon = CupertinoIcons.doc_text;
        color = CupertinoColors.systemRed;
      case 'xlsx':
        icon = CupertinoIcons.chart_bar;
        color = CupertinoColors.systemGreen;
      case 'doc':
        icon = CupertinoIcons.doc;
        color = CupertinoColors.activeBlue;
      case 'dwg':
        icon = CupertinoIcons.layers;
        color = CupertinoColors.systemOrange;
      default:
        icon = CupertinoIcons.doc;
        color = DesignTokens.secondaryText;
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: DesignTokens.separator, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file['name'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: DesignTokens.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file['size'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: DesignTokens.tertiaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 项目列表页 ====================
class ProjectsListView extends StatefulWidget {
  const ProjectsListView({super.key});

  @override
  State<ProjectsListView> createState() => _ProjectsListViewState();
}

class _ProjectsListViewState extends State<ProjectsListView>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  List<Project> _projects = [];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadProjects();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // 模拟网络请求
    await Future.delayed(const Duration(seconds: 1));

    // 模拟数据
    setState(() {
      _projects = [
        Project(
          id: '1',
          name: '学校综合楼',
          description: '建筑面积：5000m²',
          lastModified: DateTime.now().subtract(const Duration(hours: 2)),
          progress: 0.6,
          isActive: true,
        ),
        Project(
          id: '2',
          name: '商业广场',
          description: '建筑面积：12000m²',
          lastModified: DateTime.now().subtract(const Duration(days: 1)),
          progress: 0.3,
        ),
        Project(
          id: '3',
          name: '住宅小区',
          description: '建筑面积：35000m²',
          lastModified: DateTime.now().subtract(const Duration(days: 3)),
          progress: 0.8,
        ),
      ];
      _isLoading = false;
    });

    _animationController.forward();
  }

  void _switchProject(Project project) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: const ChatView(),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _openBillOfQuantities(Project project) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => BillOfQuantitiesView(
          projectId: project.id,
          projectName: project.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: DesignTokens.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '项目列表',
          style: DesignTokens.titleStyle,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: () {},
          child: const Icon(
            CupertinoIcons.plus_circle,
            size: 24,
            color: Colors.black,
          ),
        ),
      ),
      child: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_hasError) {
      return ErrorRetryWidget(
        onRetry: _loadProjects,
      );
    }

    if (_isLoading) {
      return const SkeletonLoading();
    }

    if (_projects.isEmpty) {
      return EmptyStateGuide(
        onCreateProject: () {},
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProjects,
      color: Colors.black,
      backgroundColor: DesignTokens.background,
      child: CustomScrollView(
        slivers: [
          // Function entries section
          SliverToBoxAdapter(
            child: _buildFunctionEntries(),
          ),
          // Divider
          SliverToBoxAdapter(
            child: _buildSectionDivider('我的项目'),
          ),
          // Projects list
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final project = _projects[index];
                  return FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          index * 0.1,
                          0.5 + index * 0.1,
                          curve: Curves.easeOut,
                        ),
                      ),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            index * 0.1,
                            0.5 + index * 0.1,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      ),
                      child: ProjectCard(
                        key: ValueKey('project_${project.id}'),
                        project: project,
                        onTap: () => _switchProject(project),
                        onBillTap: () => _openBillOfQuantities(project),
                      ),
                    ),
                  );
                },
                childCount: _projects.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function entries grid
  Widget _buildFunctionEntries() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快捷功能',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: DesignTokens.secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFunctionEntry(
                icon: CupertinoIcons.doc_text_search,
                label: '分析图纸',
                color: const Color(0xFF007AFF),
                onTap: () => _showFeatureDialog('分析图纸'),
              ),
              _buildFunctionEntry(
                icon: CupertinoIcons.number,
                label: '匹配定额',
                color: const Color(0xFF34C759),
                onTap: () => _showFeatureDialog('匹配定额'),
              ),
              _buildFunctionEntry(
                icon: CupertinoIcons.money_dollar,
                label: '计算造价',
                color: const Color(0xFFFF9500),
                onTap: () => _showFeatureDialog('计算造价'),
              ),
              _buildFunctionEntry(
                icon: CupertinoIcons.search,
                label: '查定额',
                color: const Color(0xFF5856D6),
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => const QuotaSearchView(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionEntry({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: DesignTokens.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  void _showFeatureDialog(String feature) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(feature),
        content: Text('$feature功能开发中...'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // Section divider
  Widget _buildSectionDivider(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey[200],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey[200],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 骨架屏加载 ====================
class SkeletonLoading extends StatelessWidget {
  const SkeletonLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DesignTokens.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 180,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==================== 空状态引导 ====================
class EmptyStateGuide extends StatelessWidget {
  final VoidCallback onCreateProject;

  const EmptyStateGuide({
    super.key,
    required this.onCreateProject,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: DesignTokens.cardBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              CupertinoIcons.folder_badge_plus,
              size: 48,
              color: DesignTokens.secondaryText,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无项目',
            style: DesignTokens.titleStyle.copyWith(
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '创建一个新项目开始工作',
            style: DesignTokens.secondaryStyle,
          ),
          const SizedBox(height: 32),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            onPressed: onCreateProject,
            child: const Text(
              '创建项目',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamilyFallback: DesignTokens._fontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 错误重试组件 ====================
class ErrorRetryWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const ErrorRetryWidget({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 48,
            color: DesignTokens.confidenceLow,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: DesignTokens.titleStyle,
          ),
          const SizedBox(height: 8),
          Text(
            '请检查网络连接后重试',
            style: DesignTokens.secondaryStyle,
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            onPressed: onRetry,
            child: const Text(
              '重试',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamilyFallback: DesignTokens._fontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 项目卡片 ====================
class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback? onBillTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onBillTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: DesignTokens.cardShadow,
          border: project.isActive
              ? Border.all(color: Colors.black, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: project.isActive ? Colors.black : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      project.name.substring(0, 1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: project.isActive ? Colors.white : Colors.black,
                        fontFamilyFallback: DesignTokens._fontFallback,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: DesignTokens.bodyStyle.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        project.description,
                        style: DesignTokens.secondaryStyle,
                      ),
                    ],
                  ),
                ),
                if (project.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '当前',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamilyFallback: DesignTokens._fontFallback,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () => _showProjectMenu(context),
                  child: const Icon(
                    CupertinoIcons.ellipsis_vertical,
                    size: 20,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: project.progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(project.progress * 100).toInt()}%',
                  style: DesignTokens.captionStyle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '上次修改: ${_formatDate(project.lastModified)}',
              style: DesignTokens.captionStyle,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${diff.inDays}天前';
    }
  }

  void _showProjectMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(project.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              onTap();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.chat_bubble, size: 18),
                SizedBox(width: 8),
                Text('进入聊天'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              onBillTap?.call();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.list_bullet, size: 18),
                SizedBox(width: 8),
                Text('工程量清单'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: const Text('取消'),
        ),
      ),
    );
  }
}

// ==================== 聊天页 ====================
class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _editingMessageId;

  // 语音提示相关
  final List<String> _voiceHints = [
    '试试说：分析这张图纸的工程量',
    '试试说：帮我匹配土建定额',
    '试试说：计算钢筋混凝土用量',
    '试试说：审核这个项目的造价',
  ];
  int _currentHintIndex = 0;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    _startHintRotation();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _hintTimer?.cancel();
    super.dispose();
  }

  void _startHintRotation() {
    _hintTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentHintIndex = (_currentHintIndex + 1) % _voiceHints.length;
        });
      }
    });
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          id: 'welcome',
          content: '您好！我是ENG造价助手。我可以帮您：\n\n• 分析图纸并提取工程量\n• 智能匹配定额编码\n• 计算分部分项工程费\n• 审核造价合理性\n\n请告诉我您需要什么帮助？',
          isUser: false,
          timestamp: DateTime.now(),
          confidenceLevel: ConfidenceLevel.high,
        ),
      );
    });
  }

  void _sendMessage(String content) {
    if (content.trim().isEmpty) return;

    if (_editingMessageId != null) {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == _editingMessageId);
        if (index != -1) {
          final originalContent = _messages[index].content;
          _messages[index] = _messages[index].copyWith(
            content: content,
            editedAt: DateTime.now(),
            originalContent: _messages[index].originalContent ?? originalContent,
          );
        }
        _editingMessageId = null;
      });
      _showToast('消息已编辑');
      return;
    }

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: content,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
    });

    _scrollToBottom();
    _simulateAgentResponse();
  }

  void _simulateAgentResponse() {
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add(
          ChatMessage(
            id: 'thinking_${DateTime.now().millisecondsSinceEpoch}',
            content: '',
            isUser: false,
            timestamp: DateTime.now(),
            thinkingStage: ThinkingStage.analyzing,
            isTyping: true,
          ),
        );
      });
      _scrollToBottom();
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _messages.removeWhere((m) => m.thinkingStage != null);
        _messages.add(
          ChatMessage(
            id: 'response_${DateTime.now().millisecondsSinceEpoch}',
            content: '根据您提供的项目特征，我为您匹配到以下定额：\n\n5-123 混凝土基础\n单位：10m³\n基价：¥2,456.78\n\n该定额适用于现浇钢筋混凝土基础，包含模板、混凝土浇筑及养护。',
            isUser: false,
            timestamp: DateTime.now(),
            confidenceLevel: ConfidenceLevel.high,
            references: [
              Reference(
                title: '定额库',
                source: '建筑工程定额',
                detail: '第5章 混凝土工程',
              ),
              Reference(
                title: '规范3.2条',
                source: 'GB 50500-2013',
                detail: '工程量计算规则',
              ),
            ],
          ),
        );
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: DesignTokens.background,
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: () => _showProjectsList(context),
          child: const Icon(
            CupertinoIcons.line_horizontal_3,
            size: 24,
            color: Colors.black,
          ),
        ),
        middle: Text(
          'ENG 造价助手',
          style: DesignTokens.titleStyle,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: () => _showSettings(context),
          child: const Icon(
            CupertinoIcons.gear,
            size: 24,
            color: Colors.black,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return _buildVoiceHintCard();
                  }
                  final message = _messages[index];
                  if (message.isUser) {
                    return _buildUserMessage(message);
                  } else {
                    return _buildAgentMessage(message);
                  }
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  void _showProjectsList(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _SidebarView(
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const SettingsView(),
      ),
    );
  }

  Widget _buildUserMessage(ChatMessage message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onLongPress: () => _showMessageMenu(message, true),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: message.isRecalled ? Colors.grey[600] : Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildMessageContent(message.content, isUser: true),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.editedAt != null && !message.isRecalled)
                          Text(
                            '已编辑 ',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.5),
                              fontFamilyFallback: DesignTokens._fontFallback,
                            ),
                          ),
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.6),
                            fontFamilyFallback: DesignTokens._fontFallback,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.person_fill,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentMessage(ChatMessage message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'E',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamilyFallback: DesignTokens._fontFallback,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onLongPress: () => _showMessageMenu(message, false),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: DesignTokens.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (message.thinkingStage != null)
                                ThinkingIndicator(stage: message.thinkingStage!)
                              else if (message.isTyping)
                                const TypewriterText(
                                  text: '正在输入...',
                                  speed: Duration(milliseconds: 50),
                                )
                              else
                                _buildMessageContent(
                                  message.content,
                                  isUser: false,
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (message.confidenceLevel != null)
                        ConfidenceBadge(level: message.confidenceLevel!),
                      if (message.references != null && message.references!.isNotEmpty)
                        ReferenceIndex(references: message.references!),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(String content, {required bool isUser}) {
    final List<TextSpan> spans = [];
    final RegExp quotaPattern = RegExp(r'\d+-\d+');
    final matches = quotaPattern.allMatches(content);

    int lastEnd = 0;
    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: content.substring(lastEnd, match.start),
          style: TextStyle(
            color: isUser ? Colors.white : DesignTokens.primaryText,
            fontFamilyFallback: DesignTokens._fontFallback,
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(
          color: DesignTokens.quotaHighlight,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
          fontFamilyFallback: DesignTokens._fontFallback,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastEnd),
        style: TextStyle(
          color: isUser ? Colors.white : DesignTokens.primaryText,
          fontFamilyFallback: DesignTokens._fontFallback,
        ),
      ));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
          fontFamilyFallback: DesignTokens._fontFallback,
        ),
        children: spans,
      ),
    );
  }

  void _showMessageMenu(ChatMessage message, bool isUser) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          if (isUser) ...[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _editMessage(message);
              },
              child: const Text('编辑'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _recallMessage(message);
              },
              child: const Text('撤回'),
            ),
          ],
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: message.content));
              _showToast('已复制');
            },
            child: const Text('复制'),
          ),
          if (!isUser)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _quoteMessage(message);
              },
              child: const Text('引用'),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _selectMultipleMessages();
            },
            child: const Text('多选'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _forwardMessage(message);
            },
            child: const Text('转发'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _quoteMessage(ChatMessage message) {
    setState(() {
      _editingMessageId = null;
    });
  }

  void _editMessage(ChatMessage message) {
    setState(() {
      _editingMessageId = message.id;
    });
    _showToast('已进入编辑模式');
  }

  void _recallMessage(ChatMessage message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('撤回消息'),
        content: const Text('确定要撤回这条消息吗？'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _performRecall(message);
            },
            child: const Text('撤回'),
          ),
        ],
      ),
    );
  }

  void _performRecall(ChatMessage message) {
    setState(() {
      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          isRecalled: true,
          content: '消息已撤回',
        );
      }
    });
    _showToast('消息已撤回');
  }

  void _selectMultipleMessages() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('多选模式'),
        content: const Text('多选功能开发中...'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _forwardMessage(ChatMessage message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('转发'),
        content: const Text('选择转发目标...'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        Future.delayed(const Duration(seconds: 1), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontFamilyFallback: DesignTokens._fontFallback,
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildVoiceHintCard() {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentHintIndex = (_currentHintIndex + 1) % _voiceHints.length;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(left: 40, top: 8, bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.lightbulb_fill,
                size: 14,
                color: CupertinoColors.systemYellow,
              ),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _voiceHints[_currentHintIndex],
                  key: ValueKey<int>(_currentHintIndex),
                  style: const TextStyle(
                    fontSize: 13,
                    color: DesignTokens.secondaryText,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.arrow_2_circlepath,
                size: 12,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final editMessage = _editingMessageId != null
        ? _messages.firstWhere((m) => m.id == _editingMessageId,
            orElse: () => ChatMessage(
                id: '', content: '', isUser: true, timestamp: DateTime.now()))
        : null;

    return BottomActions(
      onSendMessage: _sendMessage,
      isEditing: _editingMessageId != null,
      onEditingCancel: () {
        setState(() {
          _editingMessageId = null;
        });
      },
      editMessageContent:
          _editingMessageId != null ? editMessage?.content : null,
    );
  }
}

// ==================== 打字机效果组件 ====================
class TypewriterText extends StatefulWidget {
  final String text;
  final Duration speed;

  const TypewriterText({
    super.key,
    required this.text,
    this.speed = const Duration(milliseconds: 30),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_currentIndex];
          _currentIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          _displayedText,
          style: const TextStyle(
            fontSize: 15,
            color: DesignTokens.primaryText,
            fontFamilyFallback: DesignTokens._fontFallback,
          ),
        ),
        if (_currentIndex < widget.text.length)
          Container(
            width: 2,
            height: 16,
            color: DesignTokens.primaryText,
            margin: const EdgeInsets.only(left: 2),
          ),
      ],
    );
  }
}

// ==================== 引用索引组件 ====================
class ReferenceIndex extends StatefulWidget {
  final List<Reference> references;

  const ReferenceIndex({
    super.key,
    required this.references,
  });

  @override
  State<ReferenceIndex> createState() => _ReferenceIndexState();
}

class _ReferenceIndexState extends State<ReferenceIndex> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.link,
                  size: 12,
                  color: DesignTokens.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  '参考：${widget.references.map((r) => r.title).join('、')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DesignTokens.secondaryText,
                    fontFamilyFallback: DesignTokens._fontFallback,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    CupertinoIcons.chevron_down,
                    size: 12,
                    color: DesignTokens.secondaryText,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.references.map((ref) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ref.source,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.primaryText,
                            fontFamilyFallback: DesignTokens._fontFallback,
                          ),
                        ),
                        if (ref.detail.isNotEmpty)
                          Text(
                            ref.detail,
                            style: const TextStyle(
                              fontSize: 11,
                              color: DesignTokens.secondaryText,
                              fontFamilyFallback: DesignTokens._fontFallback,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 思考状态指示器 ====================
class ThinkingIndicator extends StatelessWidget {
  final ThinkingStage stage;

  const ThinkingIndicator({
    super.key,
    required this.stage,
  });

  String get _stageText {
    switch (stage) {
      case ThinkingStage.analyzing:
        return '正在分析图纸...';
      case ThinkingStage.matching:
        return '匹配定额中...';
      case ThinkingStage.calculating:
        return '计算工程量...';
      case ThinkingStage.verifying:
        return '验证结果...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CupertinoActivityIndicator(
            radius: 8,
            color: DesignTokens.secondaryText,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _stageText,
          style: const TextStyle(
            fontSize: 14,
            color: DesignTokens.secondaryText,
            fontFamilyFallback: DesignTokens._fontFallback,
          ),
        ),
      ],
    );
  }
}

// ==================== 置信度徽章 ====================
class ConfidenceBadge extends StatelessWidget {
  final ConfidenceLevel level;

  const ConfidenceBadge({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    if (level == ConfidenceLevel.high) {
      return const SizedBox.shrink();
    }

    Color color;
    String text;

    switch (level) {
      case ConfidenceLevel.high:
        color = DesignTokens.confidenceHigh;
        text = '高置信度';
      case ConfidenceLevel.medium:
        color = DesignTokens.confidenceMedium;
        text = '中置信度';
      case ConfidenceLevel.low:
        color = DesignTokens.confidenceLow;
        text = '低置信度 - 建议人工复核';
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            level == ConfidenceLevel.low
                ? CupertinoIcons.exclamationmark_triangle_fill
                : CupertinoIcons.checkmark_circle_fill,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
              fontFamilyFallback: DesignTokens._fontFallback,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 定额卡片 ====================
class QuotaCard extends StatelessWidget {
  final String code;
  final String name;
  final String unit;
  final double basePrice;

  const QuotaCard({
    super.key,
    required this.code,
    required this.name,
    required this.unit,
    required this.basePrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: DesignTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignTokens.quotaHighlight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.quotaHighlight,
                    fontFamily: 'monospace',
                    fontFamilyFallback: DesignTokens._fontFallback,
                  ),
                ),
              ),
              const Spacer(),
              const MaterialPriceTag(source: '市场价'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: DesignTokens.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '单位: $unit',
                style: DesignTokens.secondaryStyle,
              ),
              const Spacer(),
              Text(
                '¥${basePrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.primaryText,
                  fontFamilyFallback: DesignTokens._fontFallback,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== 材料价格标签 ====================
class MaterialPriceTag extends StatelessWidget {
  final String source;

  const MaterialPriceTag({
    super.key,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.tag_fill,
            size: 10,
            color: DesignTokens.secondaryText,
          ),
          const SizedBox(width: 2),
          Text(
            source,
            style: const TextStyle(
              fontSize: 10,
              color: DesignTokens.secondaryText,
              fontFamilyFallback: DesignTokens._fontFallback,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 设置页 ====================
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: DesignTokens.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '设置',
          style: DesignTokens.titleStyle,
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildConnectionStatus(),
            const SizedBox(height: 24),
            _buildSettingsGroup(
              title: '通用',
              children: [
                _buildSettingsItem(
                  icon: CupertinoIcons.person,
                  title: '账号设置',
                  onTap: () {},
                ),
                _buildSettingsItem(
                  icon: CupertinoIcons.bell,
                  title: '通知设置',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsGroup(
              title: '专业设置',
              children: [
                _buildSettingsItem(
                  icon: CupertinoIcons.building_2_fill,
                  title: '建筑专业',
                  subtitle: '已启用',
                  onTap: () {},
                ),
                _buildSettingsItem(
                  icon: CupertinoIcons.wrench_fill,
                  title: '安装专业',
                  subtitle: '已启用',
                  onTap: () {},
                ),
                _buildSettingsItem(
                  icon: CupertinoIcons.map,
                  title: '市政专业',
                  subtitle: '已启用',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsGroup(
              title: '关于',
              children: [
                _buildSettingsItem(
                  icon: CupertinoIcons.info,
                  title: '版本信息',
                  subtitle: 'v1.0.0',
                  onTap: () {},
                ),
                _buildSettingsItem(
                  icon: CupertinoIcons.question_circle,
                  title: '帮助与反馈',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.confidenceHigh.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DesignTokens.confidenceHigh.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: DesignTokens.confidenceHigh,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '连接正常',
                  style: DesignTokens.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '与服务器通信正常',
                  style: DesignTokens.captionStyle,
                ),
              ],
            ),
          ),
          const Icon(
            CupertinoIcons.wifi,
            color: DesignTokens.confidenceHigh,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: DesignTokens.captionStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: DesignTokens.secondaryText,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: DesignTokens.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: _addDividers(children),
          ),
        ),
      ],
    );
  }

  List<Widget> _addDividers(List<Widget> children) {
    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          const Divider(
            height: 1,
            indent: 56,
            color: DesignTokens.separator,
          ),
        );
      }
    }
    return result;
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: DesignTokens.secondaryText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: DesignTokens.bodyStyle,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: DesignTokens.secondaryStyle,
              ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: DesignTokens.tertiaryText,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 底部操作栏 ====================
class BottomActions extends StatefulWidget {
  final Function(String) onSendMessage;
  final VoidCallback? onEditingCancel;
  final bool isEditing;
  final String? editMessageContent;

  const BottomActions({
    super.key,
    required this.onSendMessage,
    this.onEditingCancel,
    this.isEditing = false,
    this.editMessageContent,
  });

  @override
  State<BottomActions> createState() => _BottomActionsState();
}

class _BottomActionsState extends State<BottomActions>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isVoiceMode = false;
  bool _isRecording = false;
  bool _isProcessingVoice = false; // 防抖标志
  bool _isOptionsExpanded = false; // +按钮展开状态
  late AnimationController _waveAnimationController;

  String _voiceStatus = '点击 说话';
  final List<String> _voiceHints = [
    '试试说："1-1-1 人工挖土方"',
    '试试说："查询混凝土基础定额"',
    '试试说："计算工程量 150 立方米"',
    '试试说："换算材料价格"',
  ];
  int _currentHintIndex = 0;

  @override
  void initState() {
    super.initState();
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _textController.addListener(() {
      setState(() {});
    });

    if (widget.editMessageContent != null) {
      _textController.text = widget.editMessageContent!;
      _focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(BottomActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editMessageContent != oldWidget.editMessageContent &&
        widget.editMessageContent != null) {
      _textController.text = widget.editMessageContent!;
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _waveAnimationController.dispose();
    super.dispose();
  }

  void _toggleInputMode() {
    setState(() {
      _isVoiceMode = !_isVoiceMode;
      if (_isVoiceMode) {
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  void _startRecording() {
    if (_isProcessingVoice) return; // 防止重复触发
    _isProcessingVoice = true;
    setState(() {
      _isRecording = true;
      _voiceStatus = '点击 结束';
    });
  }

  void _stopRecording() {
    if (!_isProcessingVoice) return;
    setState(() {
      _isRecording = false;
      _voiceStatus = '点击 说话';
    });
    _simulateVoiceRecognition();
    Future.delayed(const Duration(milliseconds: 300), () {
      _isProcessingVoice = false;
    });
  }

  void _simulateVoiceRecognition() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final hint = _voiceHints[_currentHintIndex];
        setState(() {
          _textController.text = hint.replaceAll('试试说：', '').replaceAll('"', '');
          _isVoiceMode = false;
        });
      }
    });
  }

  void _cycleHint() {
    setState(() {
      _currentHintIndex = (_currentHintIndex + 1) % _voiceHints.length;
    });
  }

  void _toggleOptions() {
    setState(() {
      _isOptionsExpanded = !_isOptionsExpanded;
    });
  }

  void _takePhoto() async {
    setState(() {
      _isOptionsExpanded = false;
    });
    // TODO: 实现拍照功能（需要 image_picker 插件）
    widget.onSendMessage('[拍照上传]');
  }

  void _pickImage() async {
    setState(() {
      _isOptionsExpanded = false;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        widget.onSendMessage('[图片: ${result.files.first.name}]');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _pickFile() async {
    setState(() {
      _isOptionsExpanded = false;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        widget.onSendMessage('[文件: ${result.files.first.name}]');
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Widget _buildExpandedOptions() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: _isOptionsExpanded ? 90 : 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isOptionsExpanded ? 1.0 : 0.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOptionButton(
                icon: CupertinoIcons.camera_fill,
                label: '拍照',
                onTap: _takePhoto,
              ),
              _buildOptionButton(
                icon: CupertinoIcons.photo_fill,
                label: '图片',
                onTap: _pickImage,
              ),
              _buildOptionButton(
                icon: CupertinoIcons.doc_fill,
                label: '文件',
                onTap: _pickFile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200] ?? Colors.grey),
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: DesignTokens.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_textController.text.trim().isNotEmpty) {
      widget.onSendMessage(_textController.text.trim());
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: DesignTokens.background,
        border: Border(
          top: BorderSide(color: DesignTokens.separator, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildVoiceHint(), // 提示卡始终显示
            const SizedBox(height: 8),
            _buildMainInputRow(),
            _buildExpandedOptions(), // 展开的功能选项
          ],
        ),
      ),
    );
  }

  Widget _buildMainInputRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildWaveToggleButton(),
        const SizedBox(width: 10),
        Expanded(
          child: _isVoiceMode ? _buildVoiceButton() : _buildTextInput(),
        ),
        const SizedBox(width: 10),
        _buildPlusButton(),
      ],
    );
  }

  Widget _buildWaveToggleButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: _toggleInputMode,
      child: AnimatedBuilder(
        animation: _waveAnimationController,
        builder: (context, child) {
          return Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _isVoiceMode
                  ? CupertinoColors.activeBlue.withOpacity(0.1)
                  : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildWaveBar(0, 0.3),
                  const SizedBox(width: 2),
                  _buildWaveBar(1, 0.7),
                  const SizedBox(width: 2),
                  _buildWaveBar(2, 0.5),
                  const SizedBox(width: 2),
                  _buildWaveBar(3, 0.3),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaveBar(int index, double baseHeightRatio) {
    return AnimatedBuilder(
      animation: _waveAnimationController,
      builder: (context, child) {
        final double phase = index * 0.25;
        final double sineValue = math.sin(
          (_waveAnimationController.value * 2 * math.pi) + (phase * 2 * math.pi),
        );
        final double baseHeight = 20 * baseHeightRatio;
        final double height = baseHeight + (sineValue * 6);

        return Container(
          width: 3,
          height: height.abs().clamp(6.0, 24.0),
          decoration: BoxDecoration(
            color: _isVoiceMode
                ? CupertinoColors.activeBlue
                : CupertinoColors.systemGrey,
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      },
    );
  }

  Widget _buildVoiceButton() {
    return GestureDetector(
      onTap: () {
        if (_isRecording) {
          _stopRecording();
        } else {
          _startRecording();
        }
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: _isRecording
              ? CupertinoColors.systemRed.withOpacity(0.1)
              : CupertinoColors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _isRecording
                ? CupertinoColors.systemRed
                : Colors.grey[300] ?? Colors.grey,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isRecording ? CupertinoIcons.stop_fill : CupertinoIcons.mic_fill,
                size: 16,
                color: _isRecording
                    ? CupertinoColors.systemRed
                    : DesignTokens.primaryText,
              ),
              const SizedBox(width: 6),
              Text(
                _voiceStatus,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _isRecording
                      ? CupertinoColors.systemRed
                      : DesignTokens.primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    final bool hasText = _textController.text.isNotEmpty;

    return Container(
      constraints: const BoxConstraints(
        minHeight: 40,
        maxHeight: 120,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300] ?? Colors.grey, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _textController,
              focusNode: _focusNode,
              placeholder: '发送消息...',
              placeholderStyle: TextStyle(
                color: DesignTokens.tertiaryText,
                fontSize: 16,
                fontFamilyFallback: DesignTokens._fontFallback,
              ),
              style: const TextStyle(
                color: DesignTokens.primaryText,
                fontSize: 16,
                fontFamilyFallback: DesignTokens._fontFallback,
              ),
              decoration: const BoxDecoration(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              maxLines: null,
              minLines: 1,
            ),
          ),
          if (hasText)
            CupertinoButton(
              padding: const EdgeInsets.only(right: 8),
              minSize: 0,
              onPressed: _sendMessage,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.arrow_up,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            )
          else
            CupertinoButton(
              padding: const EdgeInsets.only(right: 8),
              minSize: 0,
              onPressed: () {
                setState(() {
                  _isVoiceMode = true;
                });
              },
              child: const Icon(
                CupertinoIcons.mic_fill,
                size: 22,
                color: CupertinoColors.systemGrey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlusButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: _toggleOptions,
      child: AnimatedRotation(
        duration: const Duration(milliseconds: 250),
        turns: _isOptionsExpanded ? 0.125 : 0, // 旋转45度
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(top: 4), // 下移 4（约0.1倍高度）
          decoration: BoxDecoration(
            color: _isOptionsExpanded ? Colors.black : Colors.grey[200],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            CupertinoIcons.add,
            size: 24,
            color: _isOptionsExpanded ? Colors.white : CupertinoColors.systemGrey,
          ),
        ),
      ),
    );
  }

  // 3个固定提示卡数据
  final List<Map<String, dynamic>> _hintCards = [
    {
      'icon': CupertinoIcons.lightbulb_fill,
      'text': '查询定额',
      'color': CupertinoColors.systemYellow,
    },
    {
      'icon': CupertinoIcons.number,
      'text': '工程量计算',
      'color': CupertinoColors.systemBlue,
    },
    {
      'icon': CupertinoIcons.arrow_2_circlepath,
      'text': '材料换算',
      'color': CupertinoColors.systemGreen,
    },
  ];

  Widget _buildVoiceHint() {
    const double fontSize = 13;
    const double cardHeight = fontSize * 2.5; // 文字高度的2.5倍

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _hintCards.map((hint) {
        return GestureDetector(
          onTap: () {
            // 点击填充对应提示到输入框
            final textMap = {
              '查询定额': '查询 1-1-1 人工挖土方定额',
              '工程量计算': '计算 150 立方米土方工程量',
              '材料换算': '换算混凝土材料价格',
            };
            _textController.text = textMap[hint['text']] ?? '';
          },
          child: Container(
            height: cardHeight,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(cardHeight / 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hint['icon'] as IconData,
                  size: 12,
                  color: hint['color'] as Color,
                ),
                const SizedBox(width: 6),
                Text(
                  hint['text'] as String,
                  style: const TextStyle(
                    fontSize: fontSize,
                    color: DesignTokens.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ==================== 工程量清单表格视图 ====================
class BillOfQuantitiesView extends StatefulWidget {
  final String projectId;
  final String projectName;

  const BillOfQuantitiesView({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<BillOfQuantitiesView> createState() => _BillOfQuantitiesViewState();
}

class _BillOfQuantitiesViewState extends State<BillOfQuantitiesView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _hasError = false;
  BillOfQuantities? _billData;
  String? _selectedSpecialty;

  @override
  void initState() {
    super.initState();
    _loadBillData();
  }

  Future<void> _loadBillData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final data = await _apiService.getBillOfQuantities(widget.projectId);

    setState(() {
      _billData = data;
      _isLoading = false;
      _hasError = data == null;
    });
  }

  List<BillItem> get _filteredItems {
    if (_billData == null) return [];
    if (_selectedSpecialty == null) return _billData!.items;
    return _billData!.items
        .where((item) => item.specialty == _selectedSpecialty)
        .toList();
  }

  List<String> get _specialties {
    if (_billData == null) return [];
    return _billData!.itemsBySpecialty.keys.toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: DesignTokens.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '工程量清单',
          style: DesignTokens.titleStyle,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: _isLoading ? null : _loadBillData,
          child: const Icon(
            CupertinoIcons.refresh,
            size: 22,
            color: Colors.black,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_specialties.isNotEmpty) _buildSpecialtyFilter(),
            Expanded(child: _buildContent()),
            if (_billData != null) _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: Border(
          bottom: BorderSide(color: CupertinoColors.systemGrey5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.projectName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '共 ${_billData?.items.length ?? 0} 项工程量',
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _specialties.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedSpecialty == null;
            return _buildFilterChip('全部', isSelected, () {
              setState(() => _selectedSpecialty = null);
            });
          }
          final specialty = _specialties[index - 1];
          final isSelected = _selectedSpecialty == specialty;
          return _buildFilterChip(specialty, isSelected, () {
            setState(() => _selectedSpecialty = specialty);
          });
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : CupertinoColors.systemGrey,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_hasError) {
      return ErrorRetryWidget(onRetry: _loadBillData);
    }

    if (_filteredItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text,
              size: 48,
              color: CupertinoColors.systemGrey4,
            ),
            SizedBox(height: 16),
            Text(
              '暂无工程量数据',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(CupertinoColors.systemGrey6),
          dataRowMinHeight: 48,
          dataRowMaxHeight: 56,
          columns: const [
            DataColumn(label: Text('序号', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('编码', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('名称', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('单位', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('数量', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('单价', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('合价', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _filteredItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return DataRow(
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(
                  Text(
                    item.code,
                    style: const TextStyle(
                      fontFamily: 'SF Mono',
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ),
                DataCell(Text(item.name)),
                DataCell(Text(item.unit)),
                DataCell(
                  Text(
                    item.quantity.toStringAsFixed(2),
                    textAlign: TextAlign.right,
                  ),
                ),
                DataCell(
                  Text(
                    item.unitPrice != null
                        ? '¥${item.unitPrice!.toStringAsFixed(2)}'
                        : '-',
                    textAlign: TextAlign.right,
                  ),
                ),
                DataCell(
                  Text(
                    '¥${item.calculatedTotal.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final total = _filteredItems.fold<double>(
      0,
      (sum, item) => sum + item.calculatedTotal,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: Border(
          top: BorderSide(color: CupertinoColors.systemGrey5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_selectedSpecialty ?? '全部'}合计',
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            '¥${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.activeBlue,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 定额查询视图 ====================
class QuotaSearchView extends StatefulWidget {
  const QuotaSearchView({super.key});

  @override
  State<QuotaSearchView> createState() => _QuotaSearchViewState();
}

class _QuotaSearchViewState extends State<QuotaSearchView> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _searchResults.clear();
        _searchResults.addAll([
          {
            'code': '1-1-1',
            'name': '人工挖土方',
            'unit': 'm³',
            'price': 45.50,
            'category': '土石方工程',
          },
          {
            'code': '1-1-2',
            'name': '机械挖土方',
            'unit': 'm³',
            'price': 28.30,
            'category': '土石方工程',
          },
          {
            'code': '5-123',
            'name': '混凝土基础',
            'unit': '10m³',
            'price': 2456.78,
            'category': '混凝土工程',
          },
        ]);
        _isSearching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: DesignTokens.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '定额查询',
          style: DesignTokens.titleStyle,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: CupertinoTextField(
                controller: _searchController,
                placeholder: '搜索定额编码或名称...',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(
                    CupertinoIcons.search,
                    color: DesignTokens.tertiaryText,
                  ),
                ),
                suffix: _searchController.text.isNotEmpty
                    ? CupertinoButton(
                        padding: const EdgeInsets.only(right: 8),
                        minSize: 0,
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                        child: const Icon(
                          CupertinoIcons.clear_circled_solid,
                          color: DesignTokens.tertiaryText,
                        ),
                      )
                    : null,
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300] ?? Colors.grey),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                onChanged: _performSearch,
              ),
            ),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.search,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '输入定额编码或名称搜索',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.search,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '未找到相关定额',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: DesignTokens.quotaHighlight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      result['code'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.quotaHighlight,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      result['category'],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                result['name'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '单位: ${result['unit']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '¥${result['price'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.primaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}