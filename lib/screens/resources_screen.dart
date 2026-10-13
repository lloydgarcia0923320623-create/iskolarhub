import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import '../data/application_templates.dart';
import '../data/document_guide.dart';
import '../services/app_state.dart';
import '../services/ai_guidance_chat_service.dart';

class ResourcesScreen extends StatefulWidget {
  final AppState state;

  const ResourcesScreen({super.key, required this.state});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final _questionController = TextEditingController();
  final _chatScrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  AiGuidanceChatService? _chat;
  bool _sending = false;

  @override
  void dispose() {
    _questionController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Resources')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
              'General reference material. Always follow the latest instructions from the provider or issuing office.'),
          const SizedBox(height: 16),
          _buildGuidanceCard(context),
          const SizedBox(height: 12),
          _buildGuideCard(),
          const SizedBox(height: 12),
          _buildTemplatesCard(context),
        ],
      ),
    );
  }

  Widget _buildGuidanceCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('AI-Assisted Scholarship Guidance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
                'Ask about scholarships or the document guide. Answers are grounded in information stored in IskolarHub; the assistant cannot answer unrelated general questions.'),
            const SizedBox(height: 12),
            if (_messages.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 360),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  controller: _chatScrollController,
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return Align(
                      alignment: message.fromStudent
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: message.fromStudent
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(
                            message.text.isEmpty ? 'Thinking…' : message.text),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      labelText: 'Ask a question',
                      prefixIcon: Icon(Icons.chat_bubble_outline),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Send question',
                  onPressed: _sending ? null : _sendMessage,
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'If the stored information is insufficient, check the official provider or issuing agency. AI responses do not determine eligibility, verify documents, or make approval decisions.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCard() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.menu_book_outlined),
        title: const Text('Document Assistance Guide'),
        subtitle: const Text('General preparation steps for common documents'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
                'This guide does not replace instructions from the issuing agency, school, or scholarship provider.'),
          ),
          ...documentGuideEntries.map((entry) => ExpansionTile(
                title: Text(entry.name),
                subtitle: Text(entry.issuingOffice),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(entry.summary),
                  ),
                  const SizedBox(height: 8),
                  ...entry.steps.map((step) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.circle, size: 8),
                        title: Text(step),
                      )),
                  if (entry.reminders.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Things to check',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...entry.reminders.map((reminder) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.info_outline, size: 18),
                          title: Text(reminder),
                        )),
                  ],
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildTemplatesCard(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.description_outlined),
        title: const Text('Scholarship Application Templates'),
        subtitle:
            const Text('Reference formats to adapt to provider instructions'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
                'Templates are examples only. Edit placeholders and confirm whether the provider requires the document.'),
          ),
          ...applicationTemplates.map((template) => ExpansionTile(
                title: Text(template.name),
                subtitle: Text(template.purpose),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  ...template.usageNotes.map((note) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text(note),
                      )),
                  SelectableText(template.body),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: template.body));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Template copied.')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy template'),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage(text: question, fromStudent: true));
      _messages.add(const _ChatMessage(text: '', fromStudent: false));
      _questionController.clear();
      _sending = true;
    });
    _scrollChatToBottom();

    try {
      _chat ??= await AiGuidanceChatService.create(widget.state.scholarships);
      final response = StringBuffer();
      await for (final chunk in _chat!.sendMessage(question)) {
        response.write(chunk);
        if (!mounted) return;
        setState(() {
          _messages[_messages.length - 1] =
              _ChatMessage(text: response.toString(), fromStudent: false);
        });
        _scrollChatToBottom();
      }
      if (response.isEmpty && mounted) {
        setState(_messages.removeLast);
        _showChatError('Gemini returned an empty answer. Please try again.');
      }
    } catch (error) {
      if (!mounted) return;
      debugPrint('AI guidance request failed: $error');
      final message = _aiErrorMessage(error);
      setState(_messages.removeLast);
      _showChatError(message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showChatError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  String _aiErrorMessage(Object error) {
    if (error is FirebaseAIException) {
      final message = error.message.toLowerCase();
      if (message.contains('enable firebase ai logic')) {
        return 'Firebase AI Logic is not fully enabled yet. Open the Firebase AI '
            'Logic page for this project and select “Get started”.';
      }
      if (message.contains('app check') ||
          message.contains('appcheck') ||
          message.contains('attestation') ||
          message.contains('debug token')) {
        return 'This Android debug install is not authorized by App Check. '
            'Register its debug token in Firebase Console under App Check > Apps.';
      }
      if (message.contains('quota') || message.contains('resource_exhausted')) {
        return 'The AI service has reached its current usage limit. Please try again later.';
      }
      return 'AI guidance is temporarily unavailable. Please try again later.';
    }
    if (error is FirebaseException) {
      final message = error.message?.toLowerCase() ?? '';
      if (message.contains('app check') ||
          message.contains('appcheck') ||
          message.contains('attestation') ||
          message.contains('debug token')) {
        return 'This Android debug install is not authorized by App Check. '
            'Register its debug token in Firebase Console under App Check > Apps.';
      }
      return 'Could not connect to the guidance service. Please try again.';
    }
    if (error is SocketException) {
      return 'No network connection is available. Reconnect and try again.';
    }
    return 'Could not get an answer. Please check your connection and try again.';
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScrollController.hasClients) return;
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }
}

class _ChatMessage {
  final String text;
  final bool fromStudent;

  const _ChatMessage({required this.text, required this.fromStudent});
}
