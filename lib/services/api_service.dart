import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

// API 配置
class ApiConfig {
  // 使用动态IP检测或配置
  static String _detectedIp = '127.0.0.1';

  // 默认本机地址
  static String get baseUrl => 'http://$_detectedIp:8080';

  static void setBaseUrl(String ip) {
    _detectedIp = ip;
  }

  // 初始化时尝试从设置加载
  static Future<void> init() async {
    // 可在此处添加SharedPreferences加载逻辑
    _detectedIp = await _getLocalIp();
  }

  // 获取本地IP（用于开发环境）
  static Future<String> _getLocalIp() async {
    // 简化处理，实际应从设置读取或使用mdns
    return _detectedIp;
  }
}

// 项目模型
class Project {
  final String id;
  final String name;
  final String status;
  final double progress;
  final String specialty;
  final String updated;
  final String color;
  final List<ProjectFile>? files;
  final List<String>? specialties;
  final List<String>? activeSpecialties;

  Project({
    required this.id,
    required this.name,
    required this.status,
    required this.progress,
    required this.specialty,
    required this.updated,
    required this.color,
    this.files,
    this.specialties,
    this.activeSpecialties,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      progress: json['progress'].toDouble(),
      specialty: json['specialty'],
      updated: json['updated'],
      color: json['color'],
      files: json['files'] != null
          ? (json['files'] as List).map((f) => ProjectFile.fromJson(f)).toList()
          : null,
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'])
          : null,
      activeSpecialties: json['active_specialties'] != null
          ? List<String>.from(json['active_specialties'])
          : null,
    );
  }

  Color getColor() {
    switch (color) {
      case '#007AFF':
        return const Color(0xFF007AFF);
      case '#FF9500':
        return const Color(0xFFFF9500);
      case '#34C759':
        return const Color(0xFF34C759);
      default:
        return const Color(0xFF007AFF);
    }
  }
}

// 项目文件模型
class ProjectFile {
  final String name;
  final String size;
  final String type;

  ProjectFile({
    required this.name,
    required this.size,
    required this.type,
  });

  factory ProjectFile.fromJson(Map<String, dynamic> json) {
    return ProjectFile(
      name: json['name'],
      size: json['size'],
      type: json['type'],
    );
  }

  IconData get icon {
    switch (type) {
      case 'pdf':
        return CupertinoIcons.doc_text;
      case 'xlsx':
        return CupertinoIcons.chart_bar;
      case 'dwg':
        return CupertinoIcons.layers;
      default:
        return CupertinoIcons.doc;
    }
  }
}

// Agent 响应模型
class AgentResponse {
  final bool success;
  final String reply;
  final String timestamp;

  AgentResponse({
    required this.success,
    required this.reply,
    required this.timestamp,
  });

  factory AgentResponse.fromJson(Map<String, dynamic> json) {
    return AgentResponse(
      success: json['success'],
      reply: json['reply'],
      timestamp: json['timestamp'],
    );
  }
}

// 连接信息模型
class ConnectionInfo {
  final String serverName;
  final String localIp;
  final int port;
  final String status;
  final String qrData;

  ConnectionInfo({
    required this.serverName,
    required this.localIp,
    required this.port,
    required this.status,
    required this.qrData,
  });

  factory ConnectionInfo.fromJson(Map<String, dynamic> json) {
    return ConnectionInfo(
      serverName: json['server_name'],
      localIp: json['local_ip'],
      port: json['port'],
      status: json['status'],
      qrData: json['qr_data'],
    );
  }
}

// 工程量清单项目模型
class BillItem {
  final String id;
  final String code;
  final String name;
  final String unit;
  final double quantity;
  final double? unitPrice;
  final double? total;
  final String? specialty;
  final String? description;

  BillItem({
    required this.id,
    required this.code,
    required this.name,
    required this.unit,
    required this.quantity,
    this.unitPrice,
    this.total,
    this.specialty,
    this.description,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      unit: json['unit'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitPrice: json['unit_price']?.toDouble(),
      total: json['total']?.toDouble(),
      specialty: json['specialty'],
      description: json['description'],
    );
  }

  // 计算总价（如果后端未提供）
  double get calculatedTotal => total ?? (quantity * (unitPrice ?? 0));
}

// 工程量清单模型
class BillOfQuantities {
  final String projectId;
  final String projectName;
  final List<BillItem> items;
  final DateTime? updatedAt;

  BillOfQuantities({
    required this.projectId,
    required this.projectName,
    required this.items,
    this.updatedAt,
  });

  factory BillOfQuantities.fromJson(Map<String, dynamic> json) {
    return BillOfQuantities(
      projectId: json['project_id'] ?? '',
      projectName: json['project_name'] ?? '',
      items: (json['items'] as List?)
              ?.map((e) => BillItem.fromJson(e))
              .toList() ??
          [],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // 按专业分组
  Map<String, List<BillItem>> get itemsBySpecialty {
    final result = <String, List<BillItem>>{};
    for (final item in items) {
      final specialty = item.specialty ?? '未分类';
      result.putIfAbsent(specialty, () => []);
      result[specialty]!.add(item);
    }
    return result;
  }

  // 清单总价
  double get grandTotal =>
      items.fold(0, (sum, item) => sum + item.calculatedTotal);
}

// API 服务类
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP 客户端
  final http.Client _client = http.Client();

  // 健康检查
  Future<bool> healthCheck() async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl}/api/v1/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 获取连接信息
  Future<ConnectionInfo?> getConnectionInfo() async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl}/api/v1/status'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ConnectionInfo(
          serverName: '造价工程师后端',
          localIp: ApiConfig.baseUrl.replaceFirst('http://', '').split(':')[0],
          port: int.parse(ApiConfig.baseUrl.split(':').last),
          status: json['orchestrator_ready'] == true ? 'ready' : 'initializing',
          qrData: ApiConfig.baseUrl,
        );
      }
    } catch (e) {
      if (kDebugMode) print('Get connection info error: $e');
    }
    return null;
  }

  // 获取项目列表
  Future<List<Project>> getProjects() async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl}/api/v1/projects'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final projectNames = (json['projects'] as List).cast<String>();
        // 将项目名列表转换为Project对象列表
        return projectNames.map((name) => Project(
          id: name,
          name: name,
          status: 'active',
          progress: 0.0,
          specialty: 'building',
          updated: DateTime.now().toIso8601String(),
          color: '#007AFF',
        )).toList();
      }
    } catch (e) {
      if (kDebugMode) print('Get projects error: $e');
    }
    return [];
  }

  // 获取项目详情
  Future<Project?> getProjectDetail(String projectId) async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl}/api/v1/project'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final activeProject = json['active_project'] as String?;
        final status = json['status'] as Map<String, dynamic>?;

        return Project(
          id: projectId,
          name: projectId,
          status: activeProject == projectId ? 'active' : 'idle',
          progress: status?['progress']?.toDouble() ?? 0.0,
          specialty: 'building',
          updated: DateTime.now().toIso8601String(),
          color: '#007AFF',
          specialties: status?['specialties']?.cast<String>(),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Get project detail error: $e');
    }
    return null;
  }

  // 发送消息给 Agent
  Future<AgentResponse?> sendMessageToAgent(
      String projectId, String message) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/command'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'client_id': projectId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return AgentResponse(
          success: json['status'] != 'failed',
          reply: json['message'] ?? '',
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Send message error: $e');
    }
    return null;
  }

  // 上传文件
  Future<bool> uploadFile(
      String projectId, String filePath, String fileName) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/v1/projects/$projectId/files'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', filePath, filename: fileName),
      );

      final response = await request.send().timeout(const Duration(minutes: 2));
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Upload file error: $e');
      return false;
    }
  }

  // 上传文件（Web 平台使用 bytes）
  Future<bool> uploadFileBytes(
      String projectId, List<int> bytes, String fileName) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/v1/projects/$projectId/files'),
      );

      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      final response = await request.send().timeout(const Duration(minutes: 2));
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Upload file bytes error: $e');
      return false;
    }
  }

  // 获取工程量清单
  Future<BillOfQuantities?> getBillOfQuantities(String projectId) async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl}/api/v1/projects/$projectId/bills'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return BillOfQuantities.fromJson(json);
      }
    } catch (e) {
      if (kDebugMode) print('Get bill of quantities error: $e');
    }
    return null;
  }

  // 更新工程量清单项
  Future<bool> updateBillItem(String projectId, BillItem item) async {
    try {
      final response = await _client
          .put(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/projects/$projectId/bills/${item.id}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Update bill item error: $e');
      return false;
    }
  }
}
