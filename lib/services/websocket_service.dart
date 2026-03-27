import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

/// WebSocket 连接状态
enum WebSocketStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// WebSocket 消息类型
enum MessageType {
  user,
  agent,
  system,
  typing,
}

/// 聊天消息模型
class ChatMessage {
  final String id;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
  });

  factory ChatMessage.user({
    required String id,
    required String content,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id,
      type: MessageType.user,
      content: content,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  factory ChatMessage.agent({
    required String id,
    required String content,
    bool isStreaming = false,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id,
      type: MessageType.agent,
      content: content,
      timestamp: timestamp ?? DateTime.now(),
      isStreaming: isStreaming,
    );
  }

  factory ChatMessage.system({
    required String id,
    required String content,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id,
      type: MessageType.system,
      content: content,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  factory ChatMessage.typing({
    required String id,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id,
      type: MessageType.typing,
      content: '',
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

/// WebSocket 服务类 - 管理 WebSocket 连接和消息
class WebSocketService extends ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  WebSocketStatus _status = WebSocketStatus.disconnected;
  String? _currentProjectId;
  String? _errorMessage;

  // 消息流控制器
  final _messageController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStream => _messageController.stream;

  // 状态流控制器
  final _statusController = StreamController<WebSocketStatus>.broadcast();
  Stream<WebSocketStatus> get statusStream => _statusController.stream;

  // 当前消息列表
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  WebSocketStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _status == WebSocketStatus.connected;
  String? get currentProjectId => _currentProjectId;

  // 重连配置
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 3);
  Timer? _reconnectTimer;

  /// 连接到 WebSocket
  Future<void> connect(String projectId) async {
    if (_status == WebSocketStatus.connecting) return;
    if (_currentProjectId == projectId && isConnected) return;

    _currentProjectId = projectId;
    _setStatus(WebSocketStatus.connecting);
    _errorMessage = null;

    try {
      // 将 HTTP URL 转换为 WebSocket URL
      final wsUrl = ApiConfig.baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
      final uri = Uri.parse('$wsUrl/api/v1/ws?client_id=$projectId&device_type=mobile');

      if (kDebugMode) {
        print('Connecting to WebSocket: $uri');
      }

      _channel = WebSocketChannel.connect(uri);

      // 监听连接成功
      _channel!.ready.then((_) {
        _setStatus(WebSocketStatus.connected);
        _reconnectAttempts = 0;
        _addSystemMessage('已连接到 Agent');
      });

      // 监听消息
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      _setStatus(WebSocketStatus.error);
      _errorMessage = '连接失败: $e';
      _scheduleReconnect();
    }
  }

  /// 断开连接
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts = maxReconnectAttempts; // 防止自动重连
    _channel?.sink.close();
    _channel = null;
    _setStatus(WebSocketStatus.disconnected);
    _currentProjectId = null;
    _messages.clear();
  }

  /// 发送消息
  void sendMessage(String content) {
    if (!isConnected) {
      _addSystemMessage('未连接到服务器，请稍后重试');
      return;
    }

    if (content.trim().isEmpty) return;

    // 添加用户消息到本地
    final userMessage = ChatMessage.user(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
    );
    _addMessage(userMessage);

    // 添加打字中指示器
    final typingMessage = ChatMessage.typing(
      id: 'typing_${DateTime.now().millisecondsSinceEpoch}',
    );
    _addMessage(typingMessage);

    // 发送消息到服务器
    try {
      _channel!.sink.add(jsonEncode({
        'type': 'command',
        'text': content.trim(),
        'source': 'mobile',
        'client_id': _currentProjectId,
      }));
    } catch (e) {
      _removeMessage(typingMessage.id);
      _addSystemMessage('发送失败: $e');
    }
  }

  /// 接收消息处理
  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String);
      final type = json['type'] as String?;

      // 移除打字中指示器
      _removeTypingIndicator();

      switch (type) {
        case 'message':
          final message = ChatMessage.agent(
            id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            content: json['content'] ?? '',
            timestamp: json['timestamp'] != null
                ? DateTime.parse(json['timestamp'])
                : DateTime.now(),
          );
          _addMessage(message);
          break;

        case 'streaming':
          _handleStreamingMessage(json);
          break;

        case 'error':
          _addSystemMessage('错误: ${json['content'] ?? '未知错误'}');
          break;

        case 'connected':
          // 连接确认消息
          break;

        default:
          if (json['content'] != null) {
            final message = ChatMessage.agent(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content: json['content'],
            );
            _addMessage(message);
          }
      }
    } catch (e) {
      if (kDebugMode) {
        print('WebSocket message parse error: $e');
      }
    }
  }

  /// 处理流式消息
  void _handleStreamingMessage(Map<String, dynamic> json) {
    final content = json['content'] as String? ?? '';
    final isDone = json['done'] as bool? ?? false;
    final messageId = json['message_id'] ?? 'streaming_${_currentProjectId ?? ''}';

    // 查找是否已有该流消息
    final existingIndex = _messages.indexWhere(
      (m) => m.id == messageId && m.isStreaming,
    );

    if (existingIndex >= 0) {
      // 更新现有消息
      final existing = _messages[existingIndex];
      final updated = ChatMessage(
        id: existing.id,
        type: existing.type,
        content: existing.content + content,
        timestamp: existing.timestamp,
        isStreaming: !isDone,
      );
      _messages[existingIndex] = updated;
    } else if (!isDone) {
      // 创建新的流消息
      final message = ChatMessage.agent(
        id: messageId,
        content: content,
        isStreaming: true,
      );
      _addMessage(message);
    }

    notifyListeners();
    _messageController.add(_messages.last);
  }

  /// 错误处理
  void _onError(dynamic error) {
    _setStatus(WebSocketStatus.error);
    _errorMessage = '连接错误: $error';
    _scheduleReconnect();
  }

  /// 连接关闭处理
  void _onDone() {
    if (_status != WebSocketStatus.disconnected) {
      _setStatus(WebSocketStatus.disconnected);
      _scheduleReconnect();
    }
  }

  /// 安排重连
  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      _addSystemMessage('连接已断开，请手动刷新重试');
      return;
    }

    _reconnectAttempts++;
    _addSystemMessage('连接断开，$_reconnectAttempts 秒后自动重连...');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      reconnectDelay * _reconnectAttempts,
      () {
        if (_currentProjectId != null) {
          connect(_currentProjectId!);
        }
      },
    );
  }

  /// 设置状态
  void _setStatus(WebSocketStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
    notifyListeners();
  }

  /// 添加消息
  void _addMessage(ChatMessage message) {
    _messages.add(message);
    _messageController.add(message);
    notifyListeners();
  }

  /// 移除消息
  void _removeMessage(String messageId) {
    _messages.removeWhere((m) => m.id == messageId);
    notifyListeners();
  }

  /// 移除打字中指示器
  void _removeTypingIndicator() {
    _messages.removeWhere((m) => m.type == MessageType.typing);
    notifyListeners();
  }

  /// 添加系统消息
  void _addSystemMessage(String content) {
    final message = ChatMessage.system(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
    );
    _addMessage(message);
  }

  /// 清除所有消息
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  /// 释放资源
  @override
  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
    super.dispose();
  }
}
