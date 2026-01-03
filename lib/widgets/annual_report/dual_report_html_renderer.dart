import 'package:flutter/services.dart';
import 'dart:convert';

/// 双人报告HTML渲染器
class DualReportHtmlRenderer {
  /// 构建双人报告HTML
  static Future<String> build({
    required Map<String, dynamic> reportData,
    required String myName,
    required String friendName,
  }) async {
    // 加载字体
    final fonts = await _loadFonts();

    // 构建HTML
    final buffer = StringBuffer();

    // HTML头部
    buffer.writeln('<!doctype html>');
    buffer.writeln('<html lang="zh-CN">');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="utf-8" />');
    buffer.writeln('<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />');
    buffer.writeln('<title>双人聊天报告</title>');
    buffer.writeln('<script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>');
    buffer.writeln('<style>');
    buffer.writeln(_buildCss(fonts['regular']!, fonts['bold']!));
    buffer.writeln('</style>');
    buffer.writeln('</head>');

    // 内容主体
    buffer.writeln('<body>');
    buffer.writeln('<main class="main-container" id="capture">');

    // 第一部分：封面（我的名字 & 好友名字）
    buffer.writeln(_buildSection('cover', _buildCoverBody(myName, friendName)));

    // 第二部分：第一次聊天
    final firstChat = reportData['firstChat'] as Map<String, dynamic>?;
    final thisYearFirstChat = reportData['thisYearFirstChat'] as Map<String, dynamic>?;
    buffer.writeln(_buildSection('first-chat', _buildFirstChatBody(firstChat, thisYearFirstChat, myName, friendName)));

    // 第三部分：年度统计
    final yearlyStats = reportData['yearlyStats'] as Map<String, dynamic>?;
    buffer.writeln(_buildSection('yearly-stats', _buildYearlyStatsBody(yearlyStats, myName, friendName, reportData['year'] as int?)));

    // 第四部分：常用语（词云）
    final wordCloudData = reportData['wordCloud'] as Map<String, dynamic>?;
    buffer.writeln(_buildSection('word-cloud', _buildWordCloudBody(wordCloudData, myName, friendName, reportData['year'] as int?)));

    buffer.writeln('</main>');

    // JavaScript
    buffer.writeln(_buildScript());

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  /// 加载字体文件
  static Future<Map<String, String>> _loadFonts() async {
    final regular = await rootBundle.load('assets/HarmonyOS_SansSC/HarmonyOS_SansSC_Regular.ttf');
    final bold = await rootBundle.load('assets/HarmonyOS_SansSC/HarmonyOS_SansSC_Bold.ttf');

    return {
      'regular': base64Encode(regular.buffer.asUint8List()),
      'bold': base64Encode(bold.buffer.asUint8List()),
    };
  }

  /// 构建CSS样式
  static String _buildCss(String regularFont, String boldFont) {
    return '''
@font-face {
  font-family: "H";
  src: url("data:font/ttf;base64,$regularFont") format("truetype");
  font-weight: 400;
  font-style: normal;
}

@font-face {
  font-family: "H";
  src: url("data:font/ttf;base64,$boldFont") format("truetype");
  font-weight: 700;
  font-style: normal;
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

:root {
  --primary: #07C160;
  --accent: #F2AA00;
  --text-main: #222222;
  --text-sub: #555555;
  --bg-color: #F9F8F6;
  --line-color: rgba(0,0,0,0.06);
}

html {
  min-height: 100%;
  scroll-behavior: smooth;
}

body {
  min-height: 100vh;
  width: 100%;
  font-family: "H", "PingFang SC", sans-serif;
  background: var(--bg-color);
  color: var(--text-main);
  overflow-x: hidden;
}

body::before {
  content: "";
  position: fixed;
  inset: 0;
  background:
    radial-gradient(circle at 90% 5%, rgba(242, 170, 0, 0.06), transparent 50%),
    radial-gradient(circle at 5% 90%, rgba(7, 193, 96, 0.08), transparent 50%);
  pointer-events: none;
  z-index: -1;
}

.main-container {
  width: 100%;
  background: var(--bg-color);
  scroll-snap-type: y mandatory;
}

section.page {
  min-height: 100vh;
  width: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 80px max(8%, 30px);
  position: relative;
  scroll-snap-align: start;
}

.content-wrapper {
  max-width: 1000px;
  width: 100%;
  margin: 0 auto;
  text-align: left;
  opacity: 1;
  transform: translateY(0);
}

section.page.visible .content-wrapper {
  animation: fadeUp 1s cubic-bezier(0.2, 0.8, 0.2, 1) forwards;
}

@keyframes fadeUp {
  from { opacity: 0; transform: translateY(40px); }
  to { opacity: 1; transform: translateY(0); }
}


.label-text {
  font-size: 13px;
  letter-spacing: 3px;
  text-transform: uppercase;
  color: #888;
  margin-bottom: 16px;
  font-weight: 600;
}

.hero-title {
  font-size: clamp(36px, 5vw, 64px);
  font-weight: 700;
  line-height: 1.2;
  margin-bottom: 24px;
}

.hero-names {
  font-size: clamp(32px, 5vw, 56px);
  font-weight: 700;
  line-height: 1.3;
  margin: 20px 0 24px;
}

.hero-names .ampersand {
  color: var(--primary);
  margin: 0 12px;
}

.hero-desc {
  font-size: 18px;
  line-height: 1.7;
  color: var(--text-sub);
  max-width: 650px;
}

.divider {
  border: none;
  height: 3px;
  width: 80px;
  background: var(--accent);
  margin: 28px 0;
  opacity: 0.8;
}

.info-card {
  background: #FFFFFF;
  border-radius: 20px;
  padding: 32px;
  margin: 24px 0;
  border: 1px solid var(--line-color);
  box-shadow: 0 10px 24px rgba(0, 0, 0, 0.05);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.info-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 16px 32px rgba(0, 0, 0, 0.08);
}

.info-row {
  display: flex;
  gap: 24px;
  flex-wrap: wrap;
  align-items: flex-start;
}

.info-item {
  flex: 1 1 200px;
  min-width: 200px;
}

.info-label {
  font-size: 14px;
  color: #777;
  margin-bottom: 12px;
  letter-spacing: 1px;
}

.info-value {
  font-size: 28px;
  font-weight: 700;
  color: var(--text-main);
  margin-bottom: 24px;
}

.info-row .info-value {
  margin-bottom: 0;
}

.info-value-sm {
  font-size: 20px;
  font-weight: 600;
  color: var(--text-main);
  word-break: break-all;
}

.emoji-thumb {
  width: 72px;
  height: 72px;
  object-fit: contain;
  border-radius: 12px;
  background: #FFFFFF;
  border: 1px solid var(--line-color);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.06);
  margin-bottom: 8px;
}

.info-value .highlight {
  color: var(--primary);
  font-size: 36px;
}

.info-value .sub-highlight {
  color: #666;
  font-size: 18px;
  font-weight: 400;
}

.conversation-box {
  background: #F3F3F3;
  border-radius: 16px;
  padding: 20px;
  margin-top: 24px;
}

.message-bubble {
  background: #FFFFFF;
  border-radius: 12px;
  padding: 16px 20px;
  margin-bottom: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.message-bubble:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 18px rgba(0, 0, 0, 0.08);
}

.message-bubble:last-child {
  margin-bottom: 0;
}

.message-sender {
  font-size: 14px;
  color: var(--primary);
  font-weight: 700;
  margin-bottom: 8px;
}

.message-content {
  font-size: 16px;
  color: var(--text-main);
  line-height: 1.6;
}

@media (max-width: 768px) {
  section.page {
    padding: 60px 24px;
  }

  .hero-title {
    font-size: 40px;
  }

  .hero-names {
    font-size: 28px;
  }

  .info-value .highlight {
    font-size: 28px;
  }
}

@media (prefers-reduced-motion: reduce) {
  * { animation-duration: 0.001ms !important; animation-iteration-count: 1 !important; transition-duration: 0.001ms !important; scroll-behavior: auto !important; }
  .main-container { scroll-snap-type: none; }
}

.word-cloud-container {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  justify-content: center;
  align-items: center;
  padding: 30px 20px;
  background: #FFFFFF;
  border-radius: 20px;
  margin: 24px 0;
  border: 1px solid var(--line-color);
  box-shadow: 0 10px 24px rgba(0, 0, 0, 0.05);
}

.word-tag {
  display: inline-block;
  padding: 8px 16px;
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
  border-radius: 20px;
  white-space: nowrap;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  cursor: default;
}

.word-tag:hover {
  transform: scale(1.05);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.top-phrases {
  margin-top: 20px;
  padding: 20px;
  background: linear-gradient(135deg, rgba(7, 193, 96, 0.08) 0%, rgba(242, 170, 0, 0.05) 100%);
  border-radius: 16px;
}

.top-phrases-title {
  font-size: 14px;
  color: #888;
  margin-bottom: 12px;
  letter-spacing: 1px;
}

.top-phrases-list {
  font-size: 18px;
  color: var(--primary);
  font-weight: 600;
  line-height: 1.8;
}
''';
  }

  /// 构建封面
  static String _buildCoverBody(String myName, String friendName) {
    final escapedMyName = _escapeHtml(myName);
    final escapedFriendName = _escapeHtml(friendName);
    return '''
<div class="label-text">ECHO TRACE · DUAL REPORT</div>
<div class="hero-names">
  <span class="name">$escapedMyName</span>
  <span class="ampersand">&</span>
  <span class="name">$escapedFriendName</span>
</div>
<hr class="divider">
<div class="hero-desc">每一段对话<br>都是独一无二的相遇<br><br>让我们一起回顾<br>那些珍贵的聊天时光</div>
''';
  }

  /// 构建第一次聊天部分
  static String _buildFirstChatBody(
    Map<String, dynamic>? firstChat,
    Map<String, dynamic>? thisYearFirstChat,
    String myName,
    String friendName,
  ) {
    if (firstChat == null) {
      return '''
<div class="label-text">第一次聊天</div>
<div class="hero-title">暂无数据</div>
''';
    }

    final firstDate = DateTime.fromMillisecondsSinceEpoch(firstChat['createTime'] as int);
    final daysSince = DateTime.now().difference(firstDate).inDays;

    String thisYearSection = '';
    if (thisYearFirstChat != null) {
      final initiator = thisYearFirstChat['isSentByMe'] == true ? myName : friendName;
      final messages = thisYearFirstChat['firstThreeMessages'] as List<dynamic>?;

      String messagesHtml = '';
      if (messages != null && messages.isNotEmpty) {
        messagesHtml = messages.map((msg) {
          final sender = msg['isSentByMe'] == true ? myName : friendName;
          final content = _escapeHtml(msg['content'].toString());
          final timeStr = msg['createTimeStr']?.toString() ?? '';
          return '''
<div class="message-bubble">
  <div class="message-sender">$sender · $timeStr</div>
  <div class="message-content">$content</div>
</div>
''';
        }).join();
      }

      thisYearSection = '''
<div class="info-card">
  <div class="info-label">今年第一段对话</div>
  <div class="info-value">
    由 <span class="highlight">${_escapeHtml(initiator)}</span> 发起
  </div>
  <div class="info-label">前三句对话</div>
  <div class="conversation-box">
    $messagesHtml
  </div>
</div>
''';
    }

    return '''
<div class="label-text">第一次聊天</div>
<div class="hero-title">故事的开始</div>
<div class="info-card">
  <div class="info-label">我们第一次聊天在</div>
  <div class="info-value">
    <span class="highlight">${firstDate.year}年${firstDate.month}月${firstDate.day}日</span>
  </div>
  <div class="info-label">距今已有</div>
  <div class="info-value">
    <span class="highlight">$daysSince</span> <span class="sub-highlight">天</span>
  </div>
</div>
$thisYearSection
''';
  }

  /// 构建年度统计部分
  static String _buildYearlyStatsBody(
    Map<String, dynamic>? yearlyStats,
    String myName,
    String friendName,
    int? year,
  ) {
    final yearText = year != null ? '${year}年' : '历史以来';
    final sectionLabel = year != null ? '年度统计' : '历史统计';
    if (yearlyStats == null) {
      return '''
<div class="label-text">$sectionLabel</div>
<div class="hero-title">暂无数据</div>
''';
    }

    final totalMessages = yearlyStats['totalMessages'] as int? ?? 0;
    final totalWords = yearlyStats['totalWords'] as int? ?? 0;
    final imageCount = yearlyStats['imageCount'] as int? ?? 0;
    final voiceCount = yearlyStats['voiceCount'] as int? ?? 0;
    final emojiCount = yearlyStats['emojiCount'] as int? ?? 0;
    final myTopEmojiMd5 = yearlyStats['myTopEmojiMd5'] as String?;
    final friendTopEmojiMd5 = yearlyStats['friendTopEmojiMd5'] as String?;
    final myTopEmojiDataUrl = yearlyStats['myTopEmojiDataUrl'] as String?;
    final friendTopEmojiDataUrl =
        yearlyStats['friendTopEmojiDataUrl'] as String?;

    // 格式化数字：千分位
    String formatNumber(int n) {
      return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }

    String formatEmojiMd5(String? md5) {
      if (md5 == null || md5.isEmpty) return '暂无';
      return md5;
    }

    String buildEmojiBlock(String? dataUrl, String? md5) {
      if (dataUrl == null || dataUrl.isEmpty) {
        final label = _escapeHtml(formatEmojiMd5(md5));
        return '<div class="info-value info-value-sm">$label</div>';
      }
      final safeUrl = _escapeHtml(dataUrl);
      return '''
<img class="emoji-thumb" src="$safeUrl" alt="" loading="lazy" decoding="async" />
''';
    }


    return '''
<div class="label-text">$sectionLabel</div>
<div class="hero-title">${_escapeHtml(myName)} & ${_escapeHtml(friendName)}的$yearText</div>
<div class="info-card">
  <div class="info-label">一共发出</div>
  <div class="info-value">
    <span class="highlight">${formatNumber(totalMessages)}</span> <span class="sub-highlight">条消息</span>
  </div>
  <div class="info-label">总计</div>
  <div class="info-value">
    <span class="highlight">${formatNumber(totalWords)}</span> <span class="sub-highlight">字</span>
  </div>
  <div class="info-label">图片</div>
  <div class="info-value">
    <span class="highlight">${formatNumber(imageCount)}</span> <span class="sub-highlight">张</span>
  </div>
  <div class="info-label">语音</div>
  <div class="info-value">
    <span class="highlight">${formatNumber(voiceCount)}</span> <span class="sub-highlight">条</span>
  </div>
  <div class="info-row">
    <div class="info-item">
      <div class="info-label">表情包</div>
      <div class="info-value">
        <span class="highlight">${formatNumber(emojiCount)}</span> <span class="sub-highlight">张</span>
      </div>
    </div>
    <div class="info-item">
      <div class="info-label">我最常用的表情包</div>
      ${buildEmojiBlock(myTopEmojiDataUrl, myTopEmojiMd5)}
    </div>
    <div class="info-item">
      <div class="info-label">${_escapeHtml(friendName)}常用的表情包</div>
      ${buildEmojiBlock(friendTopEmojiDataUrl, friendTopEmojiMd5)}
    </div>
  </div>
</div>
''';
  }

  /// HTML转义
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// 构建词云部分
  static String _buildWordCloudBody(
    Map<String, dynamic>? wordCloudData,
    String myName,
    String friendName,
    int? year,
  ) {
    final yearText = year != null ? '${year}年' : '历史以来';

    if (wordCloudData == null) {
      return '''
<div class="label-text">常用语</div>
<div class="hero-title">暂无数据</div>
<div class="hero-desc">需要足够的文本消息才能生成</div>
''';
    }

    final words = (wordCloudData['words'] as List?) ?? [];

    if (words.isEmpty) {
      return '''
<div class="label-text">常用语</div>
<div class="hero-title">暂无数据</div>
<div class="hero-desc">需要足够的文本消息才能生成</div>
''';
    }

    // 获取最大频率用于计算字体大小
    final maxCount = words.isNotEmpty
        ? ((words.first as Map)['count'] as int? ?? 1)
        : 1;

    // 构建词云标签（显示前15个）
    final wordItems = words
        .take(15)
        .map((item) {
          final sentence = _escapeHtml((item as Map)['word']?.toString() ?? '');
          final count = (item['count'] as int?) ?? 1;

          // 根据频率计算字体大小 (14px - 28px)
          final ratio = count / maxCount;
          final fontSize = (14 + ratio * 14).round();

          // 根据频率选择颜色
          String color;
          if (ratio > 0.65) {
            color = '#07C160';
          } else if (ratio > 0.4) {
            color = '#F2AA00';
          } else if (ratio > 0.2) {
            color = '#2F3437';
          } else {
            color = '#6B6F73';
          }

          return '''
<span class="word-tag" style="font-size: ${fontSize}px; color: $color;" title="出现 $count 次">$sentence</span>''';
        })
        .join('');

    // 获取前3个高频句子
    final topThree = words
        .take(3)
        .map((item) => _escapeHtml((item as Map)['word']?.toString() ?? ''))
        .join('、');

    return '''
<div class="label-text">常用语</div>
<div class="hero-title">独属于你们的秘密</div>
<div class="hero-desc">$yearText，你们说得最多的是：</div>
<div class="word-cloud-container">$wordItems</div>
<div class="top-phrases">
  <div class="top-phrases-title">TOP 3 高频句子</div>
  <div class="top-phrases-list">$topThree</div>
</div>
<div class="hero-desc" style="margin-top: 20px; font-size: 14px; color: #999;">句子越大、颜色越深，出现频率越高</div>
''';
  }


  /// 构建section
  static String _buildSection(String className, String content) {
    return '''
<section class="page $className" id="$className">
  <div class="content-wrapper">$content</div>
</section>
''';
  }

  /// 构建JavaScript
  static String _buildScript() {
    return '''
<script>
document.addEventListener('DOMContentLoaded', function() {
  const sections = document.querySelectorAll('section.page');

  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
      }
    });
  }, { threshold: 0.2 });

  sections.forEach((section) => observer.observe(section));
});
</script>
''';
  }
}
