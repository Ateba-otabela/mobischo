import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/mobischo_ai_service.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class MobischoAiScreen extends StatefulWidget {
  final User user;
  final MobischoAiService? aiService;

  const MobischoAiScreen({
    Key? key,
    required this.user,
    this.aiService,
  }) : super(key: key);

  @override
  State<MobischoAiScreen> createState() => _MobischoAiScreenState();
}

class _MobischoAiScreenState extends State<MobischoAiScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final MobischoAiService _aiService;
  final List<_ChatMessage> _messages = [];
  bool _assistantTyping = false;
  bool _loadingHistory = true;
  int? _conversationId;
  List<Map<String, dynamic>> _conversations = [];
  int _historyPage = 1;
  bool _historyHasMore = false;
  String? _resolvedLocaleName;

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? MobischoAiService();
    _loadConversations(openLatest: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeName = AppLocalizations.of(context).localeName;
    if (_messages.isEmpty) {
      _messages.add(_welcomeMessage());
    } else if (_resolvedLocaleName != localeName &&
        _messages.length == 1 &&
        !_messages.single.fromUser) {
      _messages[0] = _welcomeMessage();
    }
    _resolvedLocaleName = localeName;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    if (widget.aiService == null) _aiService.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? suggestedText]) async {
    final l10n = AppLocalizations.of(context);
    final text = (suggestedText ?? _controller.text).trim();
    if (text.isEmpty || _assistantTyping || _loadingHistory) return;

    debugPrint(
      '[MobischoAI] role=${widget.user.account_type}; '
      'step=message send entry; '
      'aiTokenPresent=${widget.user.aiToken.trim().isNotEmpty}',
    );
    _controller.clear();
    setState(() => _assistantTyping = true);
    try {
      if (_conversationId == null) {
        debugPrint(
          '[MobischoAI] role=${widget.user.account_type}; '
          'step=conversation setup required',
        );
        final created = await _aiService.createConversation(widget.user);
        _conversationId = int.tryParse(created['id'].toString());
      }
      if (!mounted) return;
    } on MobischoAiServiceException catch (error) {
      debugPrint(
        '[MobischoAI] role=${widget.user.account_type}; '
        'step=conversation setup; caughtType=${error.runtimeType}; '
        'caughtMessage=service error',
      );
      if (mounted) {
        setState(() => _assistantTyping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_localizedServiceMessage(error.userMessage))),
        );
      }
      return;
    } catch (error) {
      debugPrint(
        '[MobischoAI] role=${widget.user.account_type}; '
        'step=conversation setup; caughtType=${error.runtimeType}; '
        'caughtMessage omitted for safety',
      );
      if (mounted) {
        setState(() => _assistantTyping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.createConversationError)),
        );
      }
      return;
    }

    if (_conversationId == null) {
      if (mounted) setState(() => _assistantTyping = false);
      return;
    }
    setState(() {
      _messages.add(
        _ChatMessage(text: text, fromUser: true, sentAt: DateTime.now()),
      );
      _assistantTyping = true;
    });
    _scrollToLatest();

    final conversation = _messages
        .take(_messages.length - 1)
        .map((message) => <String, String>{
              'role': message.fromUser ? 'user' : 'assistant',
              'text': message.text,
            })
        .toList();
    String reply;
    try {
      reply = await _aiService.sendMessage(
        user: widget.user,
        message: text,
        conversation: conversation,
        conversationId: _conversationId,
        languageCode: l10n.localeName,
      );
    } on MobischoAiServiceException catch (error) {
      debugPrint(
        '[MobischoAI] role=${widget.user.account_type}; '
        'step=chat screen catch; caughtType=${error.runtimeType}; '
        'caughtMessage=service error',
      );
      reply = _localizedServiceMessage(error.userMessage);
    } catch (error) {
      debugPrint(
        '[MobischoAI] role=${widget.user.account_type}; '
        'step=chat screen catch; caughtType=${error.runtimeType}; '
        'caughtMessage omitted for safety',
      );
      reply = l10n.requestFailed;
    }
    if (!mounted) return;
    setState(() {
      _assistantTyping = false;
      _messages.add(
        _ChatMessage(text: reply, fromUser: false, sentAt: DateTime.now()),
      );
    });
    _loadConversations();
    _scrollToLatest();
  }

  Future<void> _loadConversations(
      {bool openLatest = false, bool append = false}) async {
    debugPrint(
      '[MobischoAI] role=${widget.user.account_type}; '
      'step=conversation history screen entry; '
      'aiTokenPresent=${widget.user.aiToken.trim().isNotEmpty}; '
      'openLatest=$openLatest; append=$append',
    );
    try {
      final result = await _aiService.fetchConversations(
        widget.user,
        page: append ? _historyPage + 1 : 1,
      );
      final pageItems =
          (result['data'] is List ? result['data'] as List : const [])
              .whereType<Map<String, dynamic>>()
              .toList();
      if (!mounted) return;
      setState(() {
        _conversations = append ? [..._conversations, ...pageItems] : pageItems;
        _historyPage = (result['page'] as num?)?.toInt() ?? 1;
        _historyHasMore = result['has_more'] == true;
        _loadingHistory = openLatest && pageItems.isNotEmpty;
      });
      if (openLatest && pageItems.isNotEmpty) {
        final id = int.tryParse(pageItems.first['id'].toString());
        if (id != null) await _openConversation(id);
      }
      if (mounted) setState(() => _loadingHistory = false);
    } on MobischoAiServiceException catch (error) {
      debugPrint(
        '[MobischoAI] role=${widget.user.account_type}; '
        'step=conversation history screen catch; '
        'caughtType=${error.runtimeType}; caughtMessage=service error',
      );
      if (!mounted) return;
      setState(() => _loadingHistory = false);
    } catch (error) {
      debugPrint(
        '[MobischoAI] role=${widget.user.account_type}; '
        'step=conversation history screen catch; '
        'caughtType=${error.runtimeType}; caughtMessage omitted for safety',
      );
      if (!mounted) return;
      setState(() => _loadingHistory = false);
    }
  }

  Future<void> _openConversation(int conversationId) async {
    debugPrint(
      '[MobischoAI] role=${widget.user.account_type}; '
      'step=open conversation; id=$conversationId',
    );
    try {
      final conversation =
          await _aiService.fetchConversation(widget.user, conversationId);
      if (!mounted) return;
      final rawMessages = conversation['messages'];
      final messages = rawMessages is List
          ? rawMessages.whereType<Map<String, dynamic>>().map((item) {
              final createdAt = DateTime.tryParse(
                    item['created_at']?.toString() ?? '',
                  ) ??
                  DateTime.now();
              return _ChatMessage(
                text: item['role'] == 'user'
                    ? _removeStoredLanguageInstruction(
                        item['content']?.toString() ?? '',
                      )
                    : item['content']?.toString() ?? '',
                fromUser: item['role'] == 'user',
                sentAt: createdAt,
              );
            }).toList()
          : <_ChatMessage>[];
      setState(() {
        _conversationId = conversationId;
        _messages
          ..clear()
          ..addAll(messages.isEmpty ? [_welcomeMessage()] : messages);
      });
      _scrollToLatest();
    } on MobischoAiServiceException catch (error) {
      debugPrint(
        '[MobischoAI] role=${widget.user.account_type}; '
        'step=open conversation; caughtType=${error.runtimeType}; '
        'caughtMessage=service error',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    } catch (error) {
      debugPrint(
        '[MobischoAI] role=${widget.user.account_type}; '
        'step=open conversation; caughtType=${error.runtimeType}; '
        'caughtMessage omitted for safety',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_localizedServiceMessage(
                'Impossible d’ouvrir cette conversation.'))),
      );
    }
  }

  Future<void> _startNewConversation() async {
    try {
      final created = await _aiService.createConversation(widget.user);
      final id = int.tryParse(created['id'].toString());
      if (id == null || !mounted) return;
      setState(() {
        _conversationId = id;
        _messages
          ..clear()
          ..add(_welcomeMessage());
      });
      await _loadConversations();
    } on MobischoAiServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context).createConversationError)),
      );
    }
  }

  _ChatMessage _welcomeMessage() => _ChatMessage(
        text: AppLocalizations.of(context).aiGreeting,
        fromUser: false,
        sentAt: DateTime.now(),
      );

  String _removeStoredLanguageInstruction(String message) {
    const instructions = [
      'Please respond in English, regardless of the language of the question.',
      'Réponds en français, quelle que soit la langue de la question.',
    ];
    for (final instruction in instructions) {
      final suffix = '\n\n$instruction';
      if (message.endsWith(suffix)) {
        return message.substring(0, message.length - suffix.length);
      }
    }
    return message;
  }

  String _localizedServiceMessage(String message) {
    final l10n = AppLocalizations.of(context);
    switch (message) {
      case 'Votre session doit être renouvelée. Veuillez vous reconnecter.':
        return l10n.sessionExpired;
      case 'Impossible de créer une conversation.':
        return l10n.createConversationError;
      case 'Impossible d’ouvrir cette conversation.':
        return l10n.openConversationError;
      case 'Impossible de supprimer cette conversation.':
        return l10n.deleteConversationError;
      case 'Désolé, je rencontre actuellement un problème de connexion. Veuillez réessayer.':
        return l10n.requestFailed;
      case 'Je n’ai pas reçu de réponse. Veuillez réessayer.':
        return l10n.emptyAiResponse;
      case 'La réponse prend trop de temps. Vérifiez votre connexion et réessayez.':
        return l10n.responseTimeout;
      default:
        return message;
    }
  }

  Future<void> _showConversationList() async {
    final l10n = AppLocalizations.of(context);
    await _loadConversations();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.conversations,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.newConversation,
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await _startNewConversation();
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _loadingHistory
                      ? const Center(child: CircularProgressIndicator())
                      : _conversations.isEmpty
                          ? Center(child: Text(l10n.noConversations))
                          : ListView.builder(
                              itemCount: _conversations.length +
                                  (_historyHasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _conversations.length) {
                                  return TextButton(
                                    onPressed: () async {
                                      final result =
                                          await _aiService.fetchConversations(
                                        widget.user,
                                        page: _historyPage + 1,
                                      );
                                      if (!mounted) return;
                                      final older = (result['data'] is List
                                              ? result['data'] as List
                                              : const [])
                                          .whereType<Map<String, dynamic>>()
                                          .toList();
                                      setState(() {
                                        _conversations = [
                                          ..._conversations,
                                          ...older
                                        ];
                                        _historyPage =
                                            (result['page'] as num?)?.toInt() ??
                                                _historyPage;
                                        _historyHasMore =
                                            result['has_more'] == true;
                                      });
                                      setSheetState(() {});
                                    },
                                    child: Text(l10n.loadOlderConversations),
                                  );
                                }
                                final item = _conversations[index];
                                final id = int.tryParse(item['id'].toString());
                                final updatedAt = DateTime.tryParse(
                                  item['updated_at']?.toString() ?? '',
                                );
                                return ListTile(
                                  leading:
                                      const Icon(Icons.chat_bubble_outline),
                                  title: Text(
                                    item['title']?.toString() ??
                                        l10n.newConversationFallback,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    updatedAt == null
                                        ? l10n.genericConversation
                                        : '${MaterialLocalizations.of(context).formatMediumDate(updatedAt)} • '
                                            '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(updatedAt))}',
                                  ),
                                  selected: id == _conversationId,
                                  onTap: id == null
                                      ? null
                                      : () async {
                                          Navigator.pop(sheetContext);
                                          await _openConversation(id);
                                        },
                                  trailing: id == null
                                      ? null
                                      : IconButton(
                                          tooltip:
                                              l10n.deleteConversationTooltip,
                                          icon:
                                              const Icon(Icons.delete_outline),
                                          onPressed: () async {
                                            final shouldDelete =
                                                await showDialog<bool>(
                                                      context: sheetContext,
                                                      builder:
                                                          (dialogContext) =>
                                                              AlertDialog(
                                                        title: Text(l10n
                                                            .deleteConversationConfirm),
                                                        content: Text(l10n
                                                            .irreversibleAction),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    dialogContext,
                                                                    false),
                                                            child: Text(
                                                                l10n.cancel),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    dialogContext,
                                                                    true),
                                                            child: Text(
                                                                l10n.delete),
                                                          ),
                                                        ],
                                                      ),
                                                    ) ??
                                                    false;
                                            if (!shouldDelete) return;
                                            await _deleteConversation(id);
                                            if (sheetContext.mounted) {
                                              Navigator.pop(sheetContext);
                                            }
                                          },
                                        ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteConversation(int id) async {
    try {
      await _aiService.deleteConversation(widget.user, id);
      if (!mounted) return;
      setState(() {
        _conversations.removeWhere((conversation) =>
            int.tryParse(conversation['id'].toString()) == id);
        if (_conversationId == id) {
          _conversationId = null;
          _messages
            ..clear()
            ..add(_welcomeMessage());
        }
      });
    } on MobischoAiServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_localizedServiceMessage(error.userMessage))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context).deleteConversationError)),
      );
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F5F7),
      child: Column(
        children: [
          _ChatHeader(
            onHistory: _showConversationList,
            onNewChat: _startNewConversation,
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
              itemCount: _messages.length +
                  (_messages.length == 1 ? 1 : 0) +
                  (_assistantTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _MessageBubble(message: _messages[index]);
                }
                if (_messages.length == 1) {
                  return _SuggestedActions(
                    suggestions: [
                      AppLocalizations.of(context).aiSuggestionAttendance,
                      AppLocalizations.of(context).aiSuggestionClass,
                      AppLocalizations.of(context).aiSuggestionHelp,
                    ],
                    onSelected: _sendMessage,
                  );
                }
                return const _TypingIndicator();
              },
            ),
          ),
          _MessageComposer(
            controller: _controller,
            onSend: _sendMessage,
            isSending: _assistantTyping || _loadingHistory,
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final VoidCallback onHistory;
  final VoidCallback onNewChat;

  const _ChatHeader({required this.onHistory, required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(
                radius: 23,
                backgroundColor: Color(0xFFE7F0FA),
                child: Icon(Icons.smart_toy_outlined,
                    color: CustomTheme.blue, size: 26),
              ),
              Positioned(
                right: -1,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF35B879),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mobischo AI',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: CustomTheme.dark,
                      ),
                ),
                Text(
                  l10n.aiAssistant,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.conversationHistory,
            onPressed: onHistory,
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: l10n.newConversation,
            onPressed: onNewChat,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool fromUser;
  final DateTime sentAt;

  const _ChatMessage({
    required this.text,
    required this.fromUser,
    required this.sentAt,
  });
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  void _copyResponse(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.copied),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  MarkdownStyleSheet _markdownStyleSheet(BuildContext context) {
    final theme = Theme.of(context);
    final bodyText =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

    return MarkdownStyleSheet(
      a: bodyText.copyWith(color: CustomTheme.blue),
      p: bodyText.copyWith(height: 1.55, color: const Color(0xFF263746)),
      code: bodyText.copyWith(
        fontFamily: 'monospace',
        fontSize: 12.5,
        color: const Color(0xFFE8EEF3),
        backgroundColor: const Color(0xFF1F2933),
      ),
      h1: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFF263746),
            fontWeight: FontWeight.w700,
            height: 1.3,
          ) ??
          bodyText.copyWith(fontWeight: FontWeight.w700),
      h2: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFF263746),
            fontWeight: FontWeight.w700,
            height: 1.35,
          ) ??
          bodyText.copyWith(fontWeight: FontWeight.w700),
      h3: theme.textTheme.titleSmall?.copyWith(
            color: const Color(0xFF263746),
            fontWeight: FontWeight.w700,
            height: 1.4,
          ) ??
          bodyText.copyWith(fontWeight: FontWeight.w700),
      h4: bodyText.copyWith(
        color: const Color(0xFF263746),
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      h5: bodyText.copyWith(
        color: const Color(0xFF263746),
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      h6: bodyText.copyWith(
        color: const Color(0xFF263746),
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      em: bodyText.copyWith(fontStyle: FontStyle.italic),
      strong: bodyText.copyWith(fontWeight: FontWeight.w700),
      blockquote: bodyText.copyWith(
        color: Colors.grey.shade800,
        height: 1.5,
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      blockquoteDecoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: CustomTheme.blue.withOpacity(0.5),
            width: 3,
          ),
        ),
      ),
      pPadding: EdgeInsets.zero,
      blockSpacing: 8,
      listIndent: 18,
      listBulletPadding: const EdgeInsets.only(right: 8),
      codeblockPadding: const EdgeInsets.all(10),
      codeblockDecoration: BoxDecoration(
        color: const Color(0xFF1F2933),
        borderRadius: BorderRadius.circular(10),
      ),
      tableBorder: TableBorder.all(color: Colors.grey.shade300),
      tableCellsPadding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      textAlign: WrapAlignment.start,
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        message.fromUser ? const Color(0xFFDBECFF) : Colors.white;
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(message.sentAt));

    final content = message.fromUser
        ? Text(
            message.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  color: const Color(0xFF263746),
                ),
          )
        : MarkdownBody(
            data: message.text,
            selectable: true,
            styleSheet: _markdownStyleSheet(context),
            onTapLink: (text, href, title) {
              if (href == null || href.isEmpty) return;
              final uri = Uri.tryParse(href);
              if (uri != null) {
                launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            softLineBreak: true,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment:
            message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.84,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(message.fromUser ? 18 : 5),
                bottomRight: Radius.circular(message.fromUser ? 5 : 18),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0B17324D),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  content,
                  const SizedBox(height: 6),
                  if (!message.fromUser)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _copyResponse(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.copy_all_rounded,
                                  size: 13,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context).copy,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          time,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.grey.shade600,
                                    fontSize: 10,
                                  ),
                        ),
                      ],
                    )
                  else
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        time,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestedActions extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  const _SuggestedActions({
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 14),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions
              .map((suggestion) => ActionChip(
                    label: Text(suggestion),
                    onPressed: () => onSelected(suggestion),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: CustomTheme.blue.withOpacity(0.22)),
                    labelStyle: const TextStyle(
                      color: CustomTheme.blue,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ))
              .toList(),
        ),
      );
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(left: 4, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).aiTyping,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
            ],
          ),
        ),
      );
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final bool isSending;

  const _MessageComposer({
    required this.controller,
    required this.onSend,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5F7),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: isSending ? null : onSend,
                        decoration: InputDecoration(
                          hintText: l10n.writeMessage,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final hasText = value.text.trim().isNotEmpty;
                return Material(
                  color: CustomTheme.blue,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip:
                        hasText ? l10n.sendTooltip : l10n.microphoneUnavailable,
                    onPressed:
                        hasText && !isSending ? () => onSend(value.text) : null,
                    icon: Icon(
                      hasText ? Icons.send_rounded : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
