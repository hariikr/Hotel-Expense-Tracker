import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import '../../services/ai_service.dart';
import '../../services/tts_service.dart';
import '../../utils/app_theme.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final AiService _aiService = AiService(Supabase.instance.client);
  final TtsService _ttsService = TtsService();

  // Voice features
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isTtsSpeaking = false;
  bool _hasUserInteracted = false; // Track if user has interacted (for web TTS)
  Timer? _voiceTimeout;

  // Auto-clear timer
  Timer? _autoClearTimer;
  static const Duration _autoClearDuration = Duration(minutes: 10);
  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeVoice();
    _loadChatHistory();
    _startAutoClearTimer();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _autoClearTimer?.cancel();
    _voiceTimeout?.cancel();
    _ttsService.stop();
    _speech.stop();
    super.dispose();
  }

  /// Initialize voice input and TTS output
  Future<void> _initializeVoice() async {
    _speech = stt.SpeechToText();

    // Initialize TTS service for Malayalam
    await _ttsService.initialize();
  }

  /// Start auto-clear timer
  void _startAutoClearTimer() {
    _autoClearTimer?.cancel();
    _autoClearTimer = Timer(_autoClearDuration, () {
      if (_messages.isNotEmpty && mounted) {
        _autoClearChat();
      }
    });
  }

  /// Reset auto-clear timer on user activity
  void _resetAutoClearTimer() {
    _startAutoClearTimer();
  }

  /// Auto-clear chat silently
  Future<void> _autoClearChat() async {
    try {
      await _aiService.clearChatHistory();
      if (mounted) {
        setState(() {
          _messages.clear();
        });
      }
    } catch (e) {
      print('Auto-clear error: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    setState(() => _isInitializing = true);

    try {
      // Get current user ID
      final userId = Supabase.instance.client.auth.currentUser?.id;

      final history =
          await _aiService.getChatHistory(userId: userId, limit: 20);

      setState(() {
        _messages.clear();
        for (final item in history) {
          _messages.add(ChatMessage(text: item.message, isUser: true));
          _messages.add(ChatMessage(text: item.response, isUser: false));
        }
      });
    } catch (e) {
      print('Error loading chat history: $e');
    } finally {
      setState(() => _isInitializing = false);
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Mark user interaction (enables auto-TTS for web)
    if (!_hasUserInteracted) {
      setState(() => _hasUserInteracted = true);
    }

    _resetAutoClearTimer(); // Reset timer on user activity

    final userMessage = ChatMessage(text: text, isUser: true);

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      // Get current user ID
      final userId = Supabase.instance.client.auth.currentUser?.id;

      // Get last 5 messages for conversation context (exclude current message)
      final conversationHistory = _getConversationHistory();

      // Send message with user ID and conversation context
      final response = await _aiService.sendMessage(
        text,
        userId: userId,
        conversationHistory: conversationHistory,
      );

      final botReply = response.reply;

      setState(() {
        _messages.add(ChatMessage(
          text: botReply,
          isUser: false,
          hasError: response.hasError,
        ));
        _isLoading = false;
      });

      _scrollToBottom();

      // Automatically speak the AI response (after user interaction)
      if (_hasUserInteracted && !response.hasError && botReply.isNotEmpty) {
        final cleanedText = _removeEmojiDescriptions(botReply);
        if (cleanedText.isNotEmpty) {
          try {
            setState(() => _isTtsSpeaking = true);
            await _ttsService.speak(cleanedText);
            if (mounted) {
              setState(() => _isTtsSpeaking = false);
            }
          } catch (e) {
            print('TTS error: $e');
            if (mounted) {
              setState(() => _isTtsSpeaking = false);
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'ക്ഷമിക്കണം, എന്തോ തെറ്റ് സംഭവിച്ചു. വീണ്ടും ശ്രമിക്കൂ.',
          isUser: false,
          hasError: true,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  /// Send message from voice (text already extracted)
  Future<void> _sendMessageFromVoice(String text) async {
    if (text.isEmpty || _isLoading) return;

    // Mark user interaction (enables auto-TTS for web)
    if (!_hasUserInteracted) {
      setState(() => _hasUserInteracted = true);
    }

    _resetAutoClearTimer(); // Reset timer on user activity

    final userMessage = ChatMessage(text: text, isUser: true);

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Get current user ID
      final userId = Supabase.instance.client.auth.currentUser?.id;

      // Get last 5 messages for conversation context (exclude current message)
      final conversationHistory = _getConversationHistory();

      // Send message with user ID and conversation context
      final response = await _aiService.sendMessage(
        text,
        userId: userId,
        conversationHistory: conversationHistory,
      );

      final botReply = response.reply;

      setState(() {
        _messages.add(ChatMessage(
          text: botReply,
          isUser: false,
          hasError: response.hasError,
        ));
        _isLoading = false;
      });

      _scrollToBottom();

      // Automatically speak the AI response (after user interaction)
      if (_hasUserInteracted && !response.hasError && botReply.isNotEmpty) {
        final cleanedText = _removeEmojiDescriptions(botReply);
        if (cleanedText.isNotEmpty) {
          try {
            setState(() => _isTtsSpeaking = true);
            await _ttsService.speak(cleanedText);
            if (mounted) {
              setState(() => _isTtsSpeaking = false);
            }
          } catch (e) {
            print('TTS error: $e');
            if (mounted) {
              setState(() => _isTtsSpeaking = false);
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'ക്ഷമിക്കണം, എന്തോ തെറ്റ് സംഭവിച്ചു. വീണ്ടും ശ്രമിക്കൂ.',
          isUser: false,
          hasError: true,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  /// Get last 5 messages for conversation context
  /// Returns list of message pairs (user message + AI response)
  List<Map<String, String>> _getConversationHistory() {
    final history = <Map<String, String>>[];

    // Get messages before the current one (exclude the just-added user message)
    final previousMessages = _messages.length > 1
        ? _messages.sublist(0, _messages.length - 1)
        : <ChatMessage>[];

    // Take last 10 messages (5 pairs of user + AI)
    final recentMessages = previousMessages.length > 10
        ? previousMessages.sublist(previousMessages.length - 10)
        : previousMessages;

    // Build conversation history in pairs
    for (int i = 0; i < recentMessages.length; i += 2) {
      if (i + 1 < recentMessages.length) {
        final userMsg = recentMessages[i];
        final aiMsg = recentMessages[i + 1];

        if (userMsg.isUser && !aiMsg.isUser && !aiMsg.hasError) {
          history.add({
            'user': userMsg.text,
            'assistant': aiMsg.text,
          });
        }
      }
    }

    return history;
  }

  /// Speak AI response aloud - REMOVED
  // Future<void> _speakResponse(String text) async {
  //   try {
  //     await _flutterTts.speak(text);
  //   } catch (e) {
  //     print('TTS error: $e');
  //   }
  // }

  /// Start listening to voice input
  Future<void> _startListening() async {
    if (_isLoading) return;

    // Stop any ongoing TTS before starting recording
    await _ttsService.stop();

    bool available = await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          // User stopped speaking - auto-send after 1.5 seconds
          _voiceTimeout?.cancel();
          _voiceTimeout = Timer(const Duration(milliseconds: 1500), () {
            if (_messageController.text.trim().isNotEmpty && mounted) {
              // Send message and clear immediately
              final textToSend = _messageController.text.trim();
              setState(() {
                _isListening = false;
                _messageController.clear(); // Clear before sending
              });
              _sendMessageFromVoice(textToSend);
            } else {
              setState(() => _isListening = false);
            }
          });
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
          _messageController.clear();
        });
        _voiceTimeout?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('മൈക്രോഫോൺ പ്രവർത്തിക്കുന്നില്ല'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _messageController.clear(); // FIX: Clear previous text immediately
      });

      _speech.listen(
        localeId: 'ml_IN', // Malayalam locale
        listenMode:
            stt.ListenMode.confirmation, // Auto-stop when user stops speaking
        pauseFor: const Duration(seconds: 3), // Wait 3 seconds of silence
        onResult: (result) {
          setState(() {
            _messageController.text = result.recognizedWords;
          });
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('മൈക്രോഫോൺ അനുമതി നൽകേണ്ടതാണ്'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Stop listening
  Future<void> _stopListening() async {
    _voiceTimeout?.cancel();
    await _speech.stop();

    // Get text before clearing
    final textToSend = _messageController.text.trim();

    // Clear immediately
    setState(() {
      _messageController.clear();
      _isListening = false;
    });

    // Auto-send if there's text
    if (textToSend.isNotEmpty && mounted) {
      await _sendMessageFromVoice(textToSend);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('സ്ഥിരീകരിക്കുക'),
        content: const Text('ചാറ്റ് ഹിസ്റ്ററി മായ്ക്കണോ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('വേണ്ട'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final userId = Supabase.instance.client.auth.currentUser?.id;
              await _aiService.clearChatHistory(userId: userId);
              setState(() {
                _messages.clear();
              });
              _resetAutoClearTimer();
            },
            child: const Text(
              'മായ്ക്കുക',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Soft blue-gray background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI സഹായി',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'നിങ്ങളുടെ സാമ്പത്തിക സഹായി',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _messages.isEmpty ? null : _clearChat,
            tooltip: 'ചാറ്റ് മായ്ക്കുക',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF5F7FA), // Soft light blue
              const Color(0xFFE8EEF7), // Very light purple tint
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: SafeArea(
                bottom: false,
                child: _isInitializing
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemBuilder: (context, index) {
                              return _buildMessageBubble(_messages[index]);
                            },
                            itemCount: _messages.length,
                          ),
              ),
            ),

            // Typing Indicator (WhatsApp-style)
            if (_isLoading)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      // AI Avatar
                      Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667EEA).withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      // Typing bubble
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Animated dots
                            _buildTypingDot(0),
                            const SizedBox(width: 4),
                            _buildTypingDot(1),
                            const SizedBox(width: 4),
                            _buildTypingDot(2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Voice listening indicator (Gemini Live style)
              if (_isListening)
                Flexible(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF667EEA).withOpacity(0.08),
                            const Color(0xFF764BA2).withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated waveform circles (Gemini style) - Compact version
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer ripple
                              _buildRippleCircle(
                                  80, 0, Colors.deepPurple.shade100),
                              _buildRippleCircle(
                                  60, 200, Colors.deepPurple.shade200),

                              // Center microphone
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          const Color(0xFF667EEA).withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.mic,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Status text
                          const Text(
                            'ശ്രദ്ധിക്കുന്നു...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF667EEA),
                              letterSpacing: 0.5,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'സംസാരിക്കൂ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          // Recognized text display
                          if (_messageController.text.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              constraints: const BoxConstraints(maxHeight: 80),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF667EEA).withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  _messageController.text,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF2D3748),
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Stop button
                          TextButton.icon(
                            onPressed: _stopListening,
                            icon: const Icon(Icons.stop_circle, size: 18),
                            label: const Text(
                              'നിർത്തുക',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade600,
                              backgroundColor: Colors.red.shade50,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Input Area with Voice
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Voice button (Gemini Live style)
                        Container(
                          decoration: BoxDecoration(
                            gradient: _isListening
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFF5252),
                                      Color(0xFFE53935)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFF667EEA),
                                      Color(0xFF764BA2)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: _isListening
                                    ? Colors.red.withOpacity(0.3)
                                    : const Color(0xFF667EEA).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading
                                  ? null
                                  : (_isListening
                                      ? _stopListening
                                      : _startListening),
                              borderRadius: BorderRadius.circular(28),
                              child: Container(
                                width: 56,
                                height: 56,
                                alignment: Alignment.center,
                                child: Icon(
                                  _isListening
                                      ? Icons.stop_rounded
                                      : Icons.mic_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _messageController,
                              enabled: !_isLoading && !_isListening,
                              decoration: const InputDecoration(
                                hintText: 'സന്ദേശം ടൈപ്പ് ചെയ്യുക...',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Send button (Gemini Live style)
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667EEA).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: (_isLoading || _isListening)
                                  ? null
                                  : _sendMessage,
                              borderRadius: BorderRadius.circular(28),
                              child: Container(
                                width: 56,
                                height: 56,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.mic,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'സ്വാഗതം! ഞാൻ നിങ്ങളെ സഹായിക്കാം',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'മൈക്രോഫോൺ ബട്ടൺ അമർത്തി സംസാരിക്കൂ\nഅല്ലെങ്കിൽ ടൈപ്പ് ചെയ്യൂ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildSuggestionChip('ഇന്നത്തെ ലാഭം എത്ര?'),
            const SizedBox(height: 8),
            _buildSuggestionChip('ഇന്നത്തെ വരുമാനം എത്ര?'),
            const SizedBox(height: 8),
            _buildSuggestionChip('ഈ ആഴ്ചയിലെ ചെലവ് കാണിക്കൂ'),
            const SizedBox(height: 8),
            _buildSuggestionChip('ഏറ്റവും കൂടുതൽ ചെലവ് എവിടെ?'),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return InkWell(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lightbulb_outline,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI Avatar
          if (!message.isUser)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
            ),
          // Message Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? const LinearGradient(
                        colors: [Color(0xFFDCF8C6), Color(0xFFD1F4BD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: message.isUser
                    ? null
                    : (message.hasError ? Colors.red.shade50 : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message.isUser ? 18 : 2),
                  bottomRight: Radius.circular(message.isUser ? 2 : 18),
                ),
                border: message.isUser
                    ? null
                    : Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: message.isUser
                        ? const Color(0xFF25D366).withOpacity(0.15)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message Text
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.hasError
                          ? Colors.red.shade700
                          : const Color(0xFF303030),
                      fontSize: 15.5,
                      height: 1.4,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Time + Status Row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Speaker icon for AI messages (replay audio)
                      if (!message.isUser && !message.hasError) ...[
                        InkWell(
                          onTap: () async {
                            try {
                              setState(() => _isTtsSpeaking = true);
                              final cleanedText =
                                  _removeEmojiDescriptions(message.text);
                              await _ttsService.speak(cleanedText);
                              if (mounted) {
                                setState(() => _isTtsSpeaking = false);
                              }
                            } catch (e) {
                              print('TTS error: $e');
                              if (mounted) {
                                setState(() => _isTtsSpeaking = false);
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.volume_up_outlined,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Timestamp
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: message.isUser
                              ? const Color(0xFF667781)
                              : Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Double checkmark for sent messages
                      if (message.isUser) ...[
                        const SizedBox(width: 3),
                        Icon(
                          Icons.done_all,
                          size: 16,
                          color: const Color(0xFF53BDEB), // WhatsApp blue
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'ഇപ്പോൾ';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} മിനിറ്റ്';
    } else if (difference.inDays < 1) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Remove emoji descriptions and clean text for TTS
  String _removeEmojiDescriptions(String text) {
    // Remove emoji and their Unicode representations
    String cleaned = text
        // Remove all emoji Unicode ranges (comprehensive)
        .replaceAll(
            RegExp(
                r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F000}-\u{1F02F}]|[\u{1F0A0}-\u{1F0FF}]|[\u{1F100}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F900}-\u{1F9FF}]|[\u{1FA00}-\u{1FA6F}]|[\u{1FA70}-\u{1FAFF}]|[\u{2300}-\u{23FF}]|[\u{2B00}-\u{2BFF}]|[\u{FE00}-\u{FE0F}]|[\u{1F200}-\u{1F2FF}]',
                unicode: true),
            '')
        // Remove emoji descriptions in square brackets [smiling face]
        .replaceAll(RegExp(r'\[.*?\]'), '')
        // Remove asterisks used for emphasis (*word* or **word**)
        .replaceAll(RegExp(r'\*+'), '')
        // Remove extra whitespace
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned;
  }

  // WhatsApp-style typing indicator dot
  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        // Stagger animation for each dot
        final delay = index * 0.2;
        final animValue = ((value + delay) % 1.0);
        final opacity = 0.3 + (animValue * 0.7);
        final scale = 0.8 + (animValue * 0.4);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(opacity),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        // Loop animation
        if (mounted && _isLoading) {
          setState(() {});
        }
      },
    );
  }

  // Gemini Live style ripple circle animation
  Widget _buildRippleCircle(double size, int delay, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        // Delayed start for each ripple
        final delayedValue = (value - (delay / 1500)).clamp(0.0, 1.0);
        final opacity = (1.0 - delayedValue) * 0.6;
        final scale = 0.5 + (delayedValue * 0.5);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2.5,
                ),
              ),
            ),
          ),
        );
      },
      onEnd: () {
        // Loop animation
        if (mounted && _isListening) {
          setState(() {});
        }
      },
    );
  }
}

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool hasError;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.hasError = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// WhatsApp-style background pattern painter
class WhatsAppBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD9D9D9).withOpacity(0.08)
      ..style = PaintingStyle.fill;

    const patternSize = 40.0;

    // Draw diagonal lines pattern like WhatsApp
    for (double y = -patternSize;
        y < size.height + patternSize;
        y += patternSize) {
      for (double x = -patternSize;
          x < size.width + patternSize;
          x += patternSize) {
        // Draw small decorative shapes
        final path = Path();

        // Top-left to bottom-right diagonal line
        path.moveTo(x, y);
        path.lineTo(x + 15, y + 15);

        // Small circle
        canvas.drawCircle(
          Offset(x + 25, y + 10),
          1.5,
          paint,
        );

        // Tiny dash
        path.moveTo(x + 10, y + 25);
        path.lineTo(x + 15, y + 25);

        canvas.drawPath(
            path,
            paint
              ..strokeWidth = 0.8
              ..style = PaintingStyle.stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
