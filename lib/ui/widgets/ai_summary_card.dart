import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/tracking_session.dart';
import '../../services/ai_summary_service.dart';

class AiSummaryCard extends StatefulWidget {
  final List<TrackingSession> sessions;
  final TrackingSession? activeSession;

  const AiSummaryCard({
    super.key,
    required this.sessions,
    this.activeSession,
  });

  @override
  State<AiSummaryCard> createState() => _AiSummaryCardState();
}

class _AiSummaryCardState extends State<AiSummaryCard> {
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  String _automatedSummary = 'Analyzing visit data...';
  String _aiAnswer = '';
  bool _isGeneratingSummary = false;
  bool _isAnsweringQuestion = false;
  String _savedApiKey = '';

  final List<String> _exampleQuestions = [
    'Where did I travel today?',
    'How many kilometres did I travel?',
    'What was my first location?',
    'What was my last location?',
    'How long was I travelling?',
    'Give me a summary of today\'s activity.',
  ];

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void didUpdateWidget(covariant AiSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sessions.length != oldWidget.sessions.length ||
        widget.activeSession != oldWidget.activeSession) {
      _generateAutomatedSummary();
    }
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    _savedApiKey = prefs.getString('gemini_api_key') ?? '';
    _apiKeyController.text = _savedApiKey;
    _generateAutomatedSummary();
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key.trim());
    setState(() {
      _savedApiKey = key.trim();
    });
    _generateAutomatedSummary();
  }

  List<TrackingSession> _getAllRelevantSessions() {
    List<TrackingSession> list = List.from(widget.sessions);
    if (widget.activeSession != null) {
      list.add(widget.activeSession!);
    }
    return list;
  }

  Future<void> _generateAutomatedSummary() async {
    setState(() {
      _isGeneratingSummary = true;
    });

    final all = _getAllRelevantSessions();
    final summary = await AiSummaryService.generateDailySummary(
      all,
      apiKey: _savedApiKey.isNotEmpty ? _savedApiKey : null,
    );

    if (mounted) {
      setState(() {
        _automatedSummary = summary;
        _isGeneratingSummary = false;
      });
    }
  }

  Future<void> _askQuestion(String question) async {
    if (question.trim().isEmpty) return;

    setState(() {
      _isAnsweringQuestion = true;
      _queryController.text = question;
    });

    final all = _getAllRelevantSessions();
    final answer = await AiSummaryService.answerQuestion(
      question,
      all,
      apiKey: _savedApiKey.isNotEmpty ? _savedApiKey : null,
    );

    if (mounted) {
      setState(() {
        _aiAnswer = answer;
        _isAnsweringQuestion = false;
      });
    }
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.key, color: Colors.amber),
            SizedBox(width: 8),
            Text('Gemini AI Key'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Gemini API key for LLM-powered visit summaries. Leave blank to use the built-in smart NLP summary engine.',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'AIzaSy...',
                labelText: 'API Key',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              _saveApiKey(_apiKeyController.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Visit Assistant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Automated Visit Summary & Q&A',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: _savedApiKey.isNotEmpty ? const Color(0xFF10B981) : Colors.grey,
                ),
                onPressed: _showApiKeyDialog,
                tooltip: 'Configure Gemini API Key',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Automated Summary Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF8FAFC),
                  const Color(0xFFF1F5F9),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DAILY ACTIVITY SUMMARY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (_isGeneratingSummary)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                      )
                    else
                      InkWell(
                        onTap: _generateAutomatedSummary,
                        child: const Row(
                          children: [
                            Icon(Icons.refresh, size: 12, color: Color(0xFF6366F1)),
                            SizedBox(width: 4),
                            Text(
                              'Refresh',
                              style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _automatedSummary,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Example Questions Section
          const Text(
            'Ask AI Questions:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _exampleQuestions.map((q) {
              return ActionChip(
                backgroundColor: const Color(0xFFEFF6FF),
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                labelStyle: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF1D4ED8),
                  fontWeight: FontWeight.w600,
                ),
                label: Text(q),
                onPressed: () => _askQuestion(q),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // AI Q&A Response Box (if answered)
          if (_aiAnswer.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.smart_toy_outlined, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _aiAnswer,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF14532D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Search / Ask Input Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  onSubmitted: (val) => _askQuestion(val),
                  decoration: InputDecoration(
                    hintText: 'Ask AI about your visits...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.all(12),
                ),
                icon: _isAnsweringQuestion
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                onPressed: () => _askQuestion(_queryController.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
