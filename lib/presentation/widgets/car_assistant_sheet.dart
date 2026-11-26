import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../shared/constants/app_theme.dart';
import '../../models/backup_car.dart';
import '../../services/car_assistant_service.dart';

const List<String> kAssistantSuggestions = [
  'When should I change my oil?',
  'Best time to change tires?',
  'Why is my battery draining?',
  'Brake pads check?',
];

/// Opens the iOS-style assistant chat as a modal bottom sheet.
Future<void> showCarAssistantSheet(
  BuildContext context, {
  BackupCar? car,
  String? initialQuestion,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        CarAssistantSheet(car: car, initialQuestion: initialQuestion),
  );
}

class _Msg {
  final String text;
  final bool fromUser;
  const _Msg(this.text, this.fromUser);
}

class CarAssistantSheet extends StatefulWidget {
  final BackupCar? car;
  final String? initialQuestion;
  const CarAssistantSheet({super.key, this.car, this.initialQuestion});

  @override
  State<CarAssistantSheet> createState() => _CarAssistantSheetState();
}

class _CarAssistantSheetState extends State<CarAssistantSheet> {
  // Swap this one line for the real service when the backend is ready.
  final CarAssistantService _service = MockCarAssistantService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuestion?.trim();
    if (q != null && q.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(q));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _typing) return;
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(_Msg(text, true));
      _typing = true;
      _controller.clear();
    });
    _scrollToEnd();
    final reply = await _service.ask(text, widget.car);
    if (!mounted) return;
    setState(() {
      _messages.add(_Msg(reply, false));
      _typing = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final carLabel = widget.car != null
        ? '${widget.car!.brand} ${widget.car!.model} ${widget.car!.year}'
        : null;
    return Container(
      height: media.size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundGreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
            child: Row(
              children: [
                const Icon(CupertinoIcons.sparkles,
                    color: AppTheme.lightBackground, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Car Assistant',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done',
                      style: TextStyle(
                          color: AppTheme.lightBackground,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          if (carLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  Icon(CupertinoIcons.car_detailed,
                      size: 13, color: Colors.white.withOpacity(0.6)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Asking about: $carLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontFamily: 'Orbitron',
                            fontSize: 11)),
                  ),
                ],
              ),
            ),
          Divider(height: 1, color: Colors.white.withOpacity(0.08)),
          Expanded(
            child: _messages.isEmpty && !_typing
                ? _buildEmpty()
                : ListView.builder(
                    controller: _scroll,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_typing ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= _messages.length) return const _TypingBubble();
                      return _bubble(_messages[i]);
                    },
                  ),
          ),
          _buildInputBar(media),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ask anything about your car.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontFamily: 'Orbitron',
                  fontSize: 13)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kAssistantSuggestions
                .map((s) => _chip(s, () => _send(s)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.lightBackground.withOpacity(0.4)),
            ),
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.lightBackground,
                    fontFamily: 'Orbitron',
                    fontSize: 12.5)),
          ),
        ),
      ),
    );
  }

  Widget _bubble(_Msg m) {
    return Align(
      alignment:
          m.fromUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: m.fromUser ? AppTheme.lightBackground : AppTheme.darkAccentGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          m.text,
          style: TextStyle(
            color: m.fromUser ? AppTheme.backgroundGreen : Colors.white,
            fontFamily: 'Orbitron',
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(MediaQueryData media) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + media.viewInsets.bottom),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
              style: const TextStyle(color: Colors.white, fontFamily: 'Orbitron'),
              cursorColor: AppTheme.lightBackground,
              decoration: InputDecoration(
                hintText: 'Message',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: AppTheme.darkAccentGreen.withOpacity(0.5),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'Send message',
            child: Material(
              color: AppTheme.lightBackground,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _send(_controller.text),
                child: const Padding(
                  padding: EdgeInsets.all(11),
                  child: Icon(CupertinoIcons.arrow_up,
                      color: AppTheme.backgroundGreen, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Assistant "typing…" bubble with three animated dots.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.darkAccentGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = ((_c.value + i / 3) % 1.0);
                final o = 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(o),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
