import 'package:flutter/material.dart';
import '../../core/services/chatbot_service.dart';
import '../../core/theme/app_theme.dart';

/// Floating chat-bubble FAB + slide-up chat panel overlay.
/// Drop this inside any Scaffold's Stack so it appears on every screen.
class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget>
    with SingleTickerProviderStateMixin {
  final _chatbot = ChatbotService.instance;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  late final AnimationController _animController;
  late final Animation<double> _slideAnim;

  bool _isOpen = false;
  bool _isTyping = false;

  // Local copy of messages so we can setState reactively.
  final List<_Msg> _messages = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _togglePanel() {
    if (_isOpen) {
      _animController.reverse().then((_) {
        if (mounted) setState(() => _isOpen = false);
      });
    } else {
      setState(() => _isOpen = true);
      _animController.forward();
    }
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isTyping) return;

    _textController.clear();
    setState(() {
      _messages.add(_Msg(role: 'user', content: text));
      _isTyping = true;
    });
    _scrollToBottom();

    final reply = await _chatbot.sendMessage(text);

    if (mounted) {
      setState(() {
        _messages.add(_Msg(role: 'assistant', content: reply));
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    final mq = MediaQuery.of(context);
    final bottomPadding = mq.padding.bottom;
    final keyboardHeight = mq.viewInsets.bottom;
    const navBarHeight = 72.0;

    // Panel height = 72% of screen, but never taller than the space between
    // the top safe-area and whatever is currently above the keyboard.
    // This prevents the panel from overflowing into the status bar.
    final maxPanelHeight =
        mq.size.height - mq.padding.top - 16 - keyboardHeight;
    final panelHeight = (mq.size.height * 0.72).clamp(200.0, maxPanelHeight);

    return Stack(
      children: [
        // ── Dimmed backdrop ────────────────────────────────────────────────
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _togglePanel,
              child: AnimatedBuilder(
                animation: _slideAnim,
                builder: (_, __) => ColoredBox(
                  color: Colors.black
                      .withValues(alpha: 0.45 * _slideAnim.value),
                ),
              ),
            ),
          ),

        // ── Chat panel — sits just above the keyboard ─────────────────────
        if (_isOpen)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: keyboardHeight,
            child: AnimatedBuilder(
              animation: _slideAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, (1 - _slideAnim.value) * 600),
                child: child,
              ),
              child: _buildPanel(theme, bottomPadding, panelHeight),
            ),
          ),

        // ── FAB ───────────────────────────────────────────────────────────
        Positioned(
          bottom: bottomPadding + navBarHeight + 16,
          right: 16,
          child: _buildFab(theme),
        ),
      ],
    );
  }

  Widget _buildFab(AppThemeData theme) {
    return AnimatedScale(
      scale: _isOpen ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: _togglePanel,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: theme.primaryAccent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.primaryAccent.withValues(alpha: 0.40),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.chat_bubble_rounded,
            color: theme.isDark ? const Color(0xFF0D0606) : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(AppThemeData theme, double bottomPadding, double panelHeight) {
    final panelBg = theme.isDark ? const Color(0xFF2A1111) : Colors.white;

    // Material is required: ChatbotWidget sits outside the Scaffold in the
    // MainShell Stack, so it has no Material ancestor for TextField.
    return Material(
      color: panelBg,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.20),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: panelHeight,
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(child: _buildMessageList(theme)),
            _buildInput(theme, bottomPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeData theme) {
    final headerBg =
        theme.isDark ? const Color(0xFF1A0A0A) : const Color(0xFFF9F9FB);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      decoration: BoxDecoration(
        color: headerBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(color: theme.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.primaryAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_bus_rounded,
                color: theme.primaryAccent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KUET Bus Assistant',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Powered by GPT-4o',
                  style: TextStyle(color: theme.subText, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _togglePanel,
            icon: Icon(Icons.close_rounded, color: theme.subText),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(AppThemeData theme) {
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ask me about bus schedules,\nroutes, or timings!',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.subText, fontSize: 14, height: 1.6),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _messages.length) return _TypingIndicator(theme: theme);
        return _MessageBubble(msg: _messages[i], theme: theme);
      },
    );
  }

  Widget _buildInput(AppThemeData theme, double bottomPadding) {
    return Container(
      // bottomPadding covers the device safe-area notch below the panel.
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomPadding),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(top: BorderSide(color: theme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: TextStyle(color: theme.text, fontSize: 14),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Ask about routes, times…',
                hintStyle: TextStyle(color: theme.subText, fontSize: 14),
                filled: true,
                fillColor: theme.surfaceDeep,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _isTyping
                    ? theme.subText.withValues(alpha: 0.30)
                    : theme.primaryAccent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                color: theme.isDark ? const Color(0xFF0D0606) : Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _Msg {
  final String role; // 'user' | 'assistant'
  final String content;
  const _Msg({required this.role, required this.content});
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _Msg msg;
  final AppThemeData theme;
  const _MessageBubble({required this.msg, required this.theme});

  bool get _isUser => msg.role == 'user';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _isUser
              ? theme.primaryAccent
              : theme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(_isUser ? 18 : 4),
            bottomRight: Radius.circular(_isUser ? 4 : 18),
          ),
          border: _isUser
              ? null
              : Border.all(color: theme.border),
        ),
        child: Text(
          msg.content,
          style: TextStyle(
            color: _isUser
                ? (theme.isDark ? const Color(0xFF0D0606) : Colors.white)
                : theme.text,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

// ── Typing indicator (animated 3 dots) ───────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  final AppThemeData theme;
  const _TypingIndicator({required this.theme});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.theme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: widget.theme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final phase = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
                final opacity = (0.3 + 0.7 * (1 - (phase - 0.5).abs() * 2))
                    .clamp(0.3, 1.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: widget.theme.subText.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
