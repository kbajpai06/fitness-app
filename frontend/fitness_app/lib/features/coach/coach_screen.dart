import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/app_card.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  final _quickQuestions = [
    {'label': "Today's Workout", 'type': 'today_workout', 'icon': '💪'},
    {'label': "Today's Diet",    'type': 'today_diet',    'icon': '🍱'},
    {'label': 'Recovery Tip',   'type': 'recovery_tip',  'icon': '😴'},
    {'label': 'Motivate Me',    'type': 'motivation',    'icon': '🔥'},
  ];

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _loading = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();

    try {
      final history = _messages.length > 1
          ? _messages.sublist(0, _messages.length - 1)
          : <Map<String, String>>[];

      final res = await ApiClient.post('/coach/chat', {
        'message': message,
        'language': 'en',
        'conversation_history': history,
      });
      setState(() {
        _messages.add({'role': 'assistant', 'content': res['reply']});
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant',
          'content': 'Sorry, I couldn\'t respond. Check your connection.'});
        _loading = false;
      });
    }
  }

  Future<void> _quickQuestion(String type) async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.post('/coach/quick', {'question_type': type});
      setState(() {
        _messages.add({'role': 'assistant', 'content': res['reply']});
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentDim,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bolt,
                    color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FitCoach AI',
                      style: Theme.of(context).textTheme.titleLarge),
                    Text('Powered by Llama 3.3',
                      style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // Quick questions
            if (_messages.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("QUICK QUESTIONS",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.8,
                      children: _quickQuestions.map((q) =>
                        GestureDetector(
                          onTap: () => _quickQuestion(q['type']!),
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                            child: Row(children: [
                              Text(q['icon']!,
                                style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Flexible(child: Text(q['label']!,
                                style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis)),
                            ]),
                          ),
                        )
                      ).toList(),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text('or ask me anything below',
                        style: Theme.of(context).textTheme.bodySmall)),
                  ],
                ),
              ),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _messages.length) return _typingIndicator();
                  final msg = _messages[i];
                  final isUser = msg['role'] == 'user';
                  return _messageBubble(
                    context, msg['content']!, isUser);
                },
              ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Ask your coach...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppColors.accent, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _sendMessage(_msgCtrl.text),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.arrow_upward,
                      color: AppColors.background, size: 22),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageBubble(BuildContext context, String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser
              ? const Radius.circular(4) : const Radius.circular(16),
            bottomLeft: isUser
              ? const Radius.circular(16) : const Radius.circular(4),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Text(content,
          style: TextStyle(
            color: isUser ? AppColors.background : AppColors.textPrimary,
            fontSize: 14,
            height: 1.5,
          )),
      ),
    );
  }

  Widget _typingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4)),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _dot(0), _dot(150), _dot(300),
        ]),
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + delayMs),
      builder: (_, val, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 6, height: 6,
        decoration: BoxDecoration(
          color: AppColors.textMuted.withOpacity(val),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}