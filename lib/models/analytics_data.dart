// 分析数据模型

/// 聊天统计数据
class ChatStatistics {
  final int totalMessages; // 总消息数
  final int textMessages; // 文本消息数
  final int imageMessages; // 图片消息数
  final int voiceMessages; // 语音消息数
  final int videoMessages; // 视频消息数
  final int otherMessages; // 其他消息数

  final int sentMessages; // 发送的消息数
  final int receivedMessages; // 接收的消息数
  final Map<int, int> messageTypeCounts; // 消息类型分布（local_type -> count）

  final DateTime? firstMessageTime; // 第一条消息时间
  final DateTime? lastMessageTime; // 最后一条消息时间

  final int activeDays; // 活跃天数

  ChatStatistics({
    required this.totalMessages,
    required this.textMessages,
    required this.imageMessages,
    required this.voiceMessages,
    required this.videoMessages,
    required this.otherMessages,
    required this.sentMessages,
    required this.receivedMessages,
    this.firstMessageTime,
    this.lastMessageTime,
    required this.activeDays,
    Map<int, int>? messageTypeCounts,
  }) : messageTypeCounts = messageTypeCounts ?? const {};

  /// 获取消息类型分布
  Map<String, int> get messageTypeDistribution {
    if (messageTypeCounts.isNotEmpty) {
      const typeLabels = {
        1: '文本',
        244813135921: '文本',
        3: '图片',
        34: '语音',
        43: '视频',
        47: '表情',
        48: '位置',
        49: '链接/文件',
        42: '名片',
        17179869233: '链接',
        21474836529: '图文',
        154618822705: '小程序',
        12884901937: '音乐',
        81604378673: '聊天记录',
        266287972401: '拍一拍',
        270582939697: '视频号',
        25769803825: '文件',
        8594229559345: '红包',
        8589934592049: '转账',
        10000: '系统消息',
      };
      const typeOrder = [
        1,
        244813135921,
        3,
        34,
        43,
        47,
        48,
        49,
        42,
        17179869233,
        21474836529,
        154618822705,
        12884901937,
        81604378673,
        266287972401,
        270582939697,
        25769803825,
        8594229559345,
        8589934592049,
        10000,
      ];

      final distribution = <String, int>{};
      final remaining = Map<int, int>.from(messageTypeCounts);
      for (final type in typeOrder) {
        final count = remaining.remove(type);
        if (count == null || count == 0) continue;
        final label = typeLabels[type] ?? '其他';
        distribution[label] = (distribution[label] ?? 0) + count;
      }
      final otherCount = remaining.values.fold<int>(
        0,
        (sum, count) => sum + count,
      );
      if (otherCount > 0) {
        distribution['其他'] = (distribution['其他'] ?? 0) + otherCount;
      }
      if (distribution.isNotEmpty) {
        return distribution;
      }
    }

    return {
      '文本': textMessages,
      '图片': imageMessages,
      '语音': voiceMessages,
      '视频': videoMessages,
      '其他': otherMessages,
    };
  }

  /// 获取发送/接收比例
  Map<String, int> get sendReceiveRatio => {
    '发送': sentMessages,
    '接收': receivedMessages,
  };

  /// 计算聊天时长（天数）
  int get chatDurationDays {
    if (firstMessageTime == null || lastMessageTime == null) return 0;
    return lastMessageTime!.difference(firstMessageTime!).inDays + 1;
  }

  /// 平均每天消息数
  double get averageMessagesPerDay {
    if (chatDurationDays == 0) return 0;
    return totalMessages / chatDurationDays;
  }

  Map<String, dynamic> toJson() => {
    'totalMessages': totalMessages,
    'textMessages': textMessages,
    'imageMessages': imageMessages,
    'voiceMessages': voiceMessages,
    'videoMessages': videoMessages,
    'otherMessages': otherMessages,
    'sentMessages': sentMessages,
    'receivedMessages': receivedMessages,
    'firstMessageTime': firstMessageTime?.toIso8601String(),
    'lastMessageTime': lastMessageTime?.toIso8601String(),
    'activeDays': activeDays,
    'messageTypeCounts': messageTypeCounts.map(
      (key, value) => MapEntry(key.toString(), value),
    ),
  };

  factory ChatStatistics.fromJson(Map<String, dynamic> json) => ChatStatistics(
    totalMessages: json['totalMessages'],
    textMessages: json['textMessages'],
    imageMessages: json['imageMessages'],
    voiceMessages: json['voiceMessages'],
    videoMessages: json['videoMessages'],
    otherMessages: json['otherMessages'],
    sentMessages: json['sentMessages'],
    receivedMessages: json['receivedMessages'],
    firstMessageTime: json['firstMessageTime'] != null
        ? DateTime.parse(json['firstMessageTime'])
        : null,
    lastMessageTime: json['lastMessageTime'] != null
        ? DateTime.parse(json['lastMessageTime'])
        : null,
    activeDays: json['activeDays'],
    messageTypeCounts: _parseMessageTypeCounts(json['messageTypeCounts']),
  );

  static Map<int, int> _parseMessageTypeCounts(dynamic raw) {
    if (raw is! Map) return {};
    final result = <int, int>{};
    raw.forEach((key, value) {
      final parsedKey = int.tryParse(key.toString());
      final parsedValue = value is int ? value : int.tryParse(value.toString());
      if (parsedKey != null && parsedValue != null) {
        result[parsedKey] = parsedValue;
      }
    });
    return result;
  }
}

/// 时间分布统计
class TimeDistribution {
  final Map<int, int> hourlyDistribution; // 小时分布 (0-23)
  final Map<int, int> weekdayDistribution; // 星期分布 (1-7)
  final Map<String, int> monthlyDistribution; // 月份分布 (YYYY-MM)

  TimeDistribution({
    required this.hourlyDistribution,
    required this.weekdayDistribution,
    required this.monthlyDistribution,
  });

  /// 获取最活跃的小时
  int get mostActiveHour {
    if (hourlyDistribution.isEmpty) return 0;
    return hourlyDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// 获取最活跃的星期几
  int get mostActiveWeekday {
    if (weekdayDistribution.isEmpty) return 1;
    return weekdayDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// 获取最活跃的月份
  String get mostActiveMonth {
    if (monthlyDistribution.isEmpty) return '';
    return monthlyDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// 获取星期几的中文名称
  static String getWeekdayName(int weekday) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[(weekday - 1) % 7];
  }
}

/// 词频统计
class WordFrequency {
  final Map<String, int> wordCount; // 词语及其出现次数
  final int totalWords; // 总词数

  WordFrequency({required this.wordCount, required this.totalWords});

  /// 获取前N个高频词
  List<MapEntry<String, int>> getTopWords(int n) {
    final sorted = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }

  /// 获取词语出现的百分比
  double getWordPercentage(String word) {
    if (totalWords == 0) return 0;
    return (wordCount[word] ?? 0) / totalWords * 100;
  }
}

/// 联系人聊天排名
class ContactRanking {
  final String username; // 用户名
  final String displayName; // 显示名称
  final int messageCount; // 消息数量
  final int sentCount; // 发送数量
  final int receivedCount; // 接收数量
  final DateTime? lastMessageTime; // 最后消息时间

  ContactRanking({
    required this.username,
    required this.displayName,
    required this.messageCount,
    required this.sentCount,
    required this.receivedCount,
    this.lastMessageTime,
  });

  /// 计算互动亲密度（综合考虑消息量和互动平衡性）
  double get intimacyScore {
    if (messageCount == 0) return 0;

    // 计算互动平衡度，越接近1:1越好
    final balanceRatio = sentCount > receivedCount
        ? receivedCount / sentCount
        : sentCount / receivedCount;

    // 用消息数量的对数乘以平衡度，给出综合评分
    return messageCount.toDouble().clamp(1, 10000) * balanceRatio;
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'displayName': displayName,
    'messageCount': messageCount,
    'sentCount': sentCount,
    'receivedCount': receivedCount,
    'lastMessageTime': lastMessageTime?.toIso8601String(),
  };

  factory ContactRanking.fromJson(Map<String, dynamic> json) => ContactRanking(
    username: json['username'],
    displayName: json['displayName'],
    messageCount: json['messageCount'],
    sentCount: json['sentCount'],
    receivedCount: json['receivedCount'],
    lastMessageTime: json['lastMessageTime'] != null
        ? DateTime.parse(json['lastMessageTime'])
        : null,
  );
}

/// 私聊分析结果
class PrivateChatAnalytics {
  final ChatStatistics statistics; // 基础统计
  final TimeDistribution timeDistribution; // 时间分布
  final WordFrequency? wordFrequency; // 词频分析（可选）
  final List<ContactRanking> contactRankings; // 联系人排名

  PrivateChatAnalytics({
    required this.statistics,
    required this.timeDistribution,
    this.wordFrequency,
    required this.contactRankings,
  });
}

/// 消息内容分析
class MessageContent {
  final String content; // 消息内容
  final int createTime; // 创建时间
  final int localType; // 消息类型
  final bool isSent; // 是否是发送的

  MessageContent({
    required this.content,
    required this.createTime,
    required this.localType,
    required this.isSent,
  });

  /// 检查是否为有效的文本消息（可用于内容分析）
  bool get isValidTextMessage {
    // 只保留普通文本消息和富文本消息
    if (localType != 1 && localType != 244813135921) return false;

    // 过滤掉空消息和各种占位符格式
    if (content.isEmpty || content.startsWith('[') && content.endsWith(']')) {
      return false;
    }

    return true;
  }

  /// 获取可用于分析的文本内容
  String get analyzableText {
    if (!isValidTextMessage) return '';
    return content.trim();
  }
}
