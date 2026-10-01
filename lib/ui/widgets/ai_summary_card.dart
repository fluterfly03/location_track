import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 450.w),
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.key, color: Colors.amber, size: 24.r),
                    SizedBox(width: 8.w),
                    Text(
                      'Gemini AI Key',
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  'Enter your Gemini API key for LLM-powered visit summaries. Leave blank to use the built-in smart NLP summary engine.',
                  style: TextStyle(fontSize: 12.sp, color: Colors.black87),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: _apiKeyController,
                  style: TextStyle(fontSize: 14.sp),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'AIzaSy...',
                    labelText: 'API Key',
                    labelStyle: TextStyle(fontSize: 13.sp),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
                    ),
                    SizedBox(width: 8.w),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      ),
                      onPressed: () {
                        _saveApiKey(_apiKeyController.text);
                        Navigator.pop(ctx);
                      },
                      child: Text('Save Key', style: TextStyle(fontSize: 14.sp)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Visit Assistant',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Automated Visit Summary & Q&A',
                            style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  size: 22.r,
                  color: _savedApiKey.isNotEmpty ? const Color(0xFF10B981) : Colors.grey,
                ),
                onPressed: _showApiKeyDialog,
                tooltip: 'Configure Gemini API Key',
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Automated Summary Container
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFF1F5F9),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DAILY ACTIVITY SUMMARY',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (_isGeneratingSummary)
                      SizedBox(
                        width: 14.r,
                        height: 14.r,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                      )
                    else
                      InkWell(
                        onTap: _generateAutomatedSummary,
                        child: Row(
                          children: [
                            Icon(Icons.refresh, size: 12.r, color: const Color(0xFF6366F1)),
                            SizedBox(width: 4.w),
                            Text(
                              'Refresh',
                              style: TextStyle(fontSize: 11.sp, color: const Color(0xFF6366F1), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  _automatedSummary,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    height: 1.45,
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Example Questions Section
          Text(
            'Ask AI Questions:',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _exampleQuestions.map((q) {
              return ActionChip(
                backgroundColor: const Color(0xFFEFF6FF),
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                labelStyle: TextStyle(
                  fontSize: 11.5.sp,
                  color: const Color(0xFF1D4ED8),
                  fontWeight: FontWeight.w600,
                ),
                label: Text(q),
                onPressed: () => _askQuestion(q),
              );
            }).toList(),
          ),
          SizedBox(height: 16.h),

          // AI Q&A Response Box (if answered)
          if (_aiAnswer.isNotEmpty)
            Container(
              margin: EdgeInsets.only(bottom: 14.h),
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.smart_toy_outlined, color: const Color(0xFF16A34A), size: 20.r),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      _aiAnswer,
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.4,
                        color: const Color(0xFF14532D),
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
                  style: TextStyle(fontSize: 13.sp),
                  onSubmitted: (val) => _askQuestion(val),
                  decoration: InputDecoration(
                    hintText: 'Ask AI about your visits...',
                    hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  padding: EdgeInsets.all(12.r),
                ),
                icon: _isAnsweringQuestion
                    ? SizedBox(
                        width: 18.r,
                        height: 18.r,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(Icons.send_rounded, color: Colors.white, size: 18.r),
                onPressed: () => _askQuestion(_queryController.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

