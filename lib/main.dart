import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';

import 'src/models/settings_model.dart';
import 'src/pages/settings_page.dart';
import 'src/platform_menu.dart';
import 'src/services/ai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = TerminalSettings();
  await settings.loadSettings();

  runApp(
    ChangeNotifierProvider.value(
      value: settings,
      child: MyApp(),
    ),
  );

  doWhenWindowReady(() {
    const initialSize = Size(600, 450);
    appWindow
      ..minSize = initialSize
      ..size = initialSize
      ..alignment = Alignment.center
      ..title = 'Terminal'
      ..show();
  });
}

bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalSettings>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Terminal',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: settings.backgroundColor,
          ),
          home: AppPlatformMenu(child: Home()),
        );
      },
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Terminal terminal = Terminal(maxLines: 10000);
  final TerminalController terminalController = TerminalController();

  late Pty pty;
  bool _isHoveringTerminal = false;
  bool _isHoveringButtons = false;
  bool _showAIChat = false;
  final TextEditingController _aiInputController = TextEditingController();
  final List<Map<String, String>> _aiMessages = [];
  bool _isAILoading = false;

  bool get _shouldShowButtons => _isHoveringTerminal || _isHoveringButtons || _showAIChat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) _startPty();
    });
  }

  @override
  void dispose() {
    _aiInputController.dispose();
    super.dispose();
  }

  Future<void> _startPty() async {
    final settings = context.read<TerminalSettings>();

    if (!await isOhMyZshInstalled()) {
      await installOhMyZsh();
    }

    // Build environment with custom variables
    final environment = Map<String, String>.from(Platform.environment);
    environment.addAll(settings.shellEnvironmentVariables);

    // Add aliases to environment if on Unix
    if (Platform.isMacOS || Platform.isLinux) {
      final aliases = settings.shellAliases.entries
          .map((e) => 'alias ${e.key}="${e.value}"')
          .join('; ');
      if (aliases.isNotEmpty) {
        environment['BASH_ENV'] = aliases;
      }
    }

    final shellPath = settings.customShell.isNotEmpty
        ? settings.customShell
        : shell;

    pty = Pty.start(
      shellPath,
      arguments: settings.shellArguments,
      columns: terminal.viewWidth,
      rows: terminal.viewHeight,
      workingDirectory: Platform.environment['HOME'] ?? '~',
      environment: environment,
    );

    pty.output.cast<List<int>>().transform(utf8.decoder).listen(terminal.write);

    pty.exitCode.then((code) {
      terminal.write('the process exited with exit code $code');
    });

    terminal
      ..onOutput = (data) {
        pty.write(utf8.encode(data));
      }
      ..onResize = (w, h, pw, ph) {
        pty.resize(h, w);
      };
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  Future<void> _sendAIMessage() async {
    final settings = context.read<TerminalSettings>();
    final message = _aiInputController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _aiMessages.add({'role': 'user', 'content': message});
      _isAILoading = true;
    });
    _aiInputController.clear();

    final aiService = AIService(settings);
    final response = await aiService.sendMessage(message);

    setState(() {
      _aiMessages.add({'role': 'assistant', 'content': response});
      _isAILoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalSettings>(
      builder: (context, settings, child) {
        return Scaffold(
          backgroundColor: settings.backgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                // Terminal
                MouseRegion(
                  onEnter: (_) => setState(() => _isHoveringTerminal = true),
                  onExit: (_) => setState(() => _isHoveringTerminal = false),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0).copyWith(top: 30.0),
                    child: TerminalView(
                      terminal,
                      controller: terminalController,
                      autofocus: true,
                      backgroundOpacity: 0,
                      textStyle: TerminalStyle(
                        fontSize: settings.fontSize,
                        fontFamily: settings.fontFamily,
                      ),
                      cursorType: _getCursorType(settings.cursorStyle),
                      onSecondaryTapDown: (details, offset) async {
                        final selection = terminalController.selection;
                        if (selection != null) {
                          final text = terminal.buffer.getText(selection);
                          terminalController.clearSelection();
                          await Clipboard.setData(ClipboardData(text: text));
                        } else {
                          final data = await Clipboard.getData('text/plain');
                          final text = data?.text;
                          if (text != null) {
                            terminal.paste(text);
                          }
                        }
                      },
                    ),
                  ),
                ),

                // Title bar
                WindowTitleBarBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MoveWindow(
                        child: Container(
                          color: settings.backgroundColor,
                          width: MediaQuery.of(context).size.width,
                          height: 30,
                          child: Center(
                            child: Text(
                              'Terminal',
                              style: TextStyle(
                                color: settings.foregroundColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Settings button (visible on hover)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  top: 35,
                  right: _shouldShowButtons ? 12 : -50,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringButtons = true),
                    onExit: (_) => setState(() => _isHoveringButtons = false),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _shouldShowButtons ? 1.0 : 0.0,
                      child: Column(
                        children: [
                          _buildHoverButton(
                            icon: Icons.settings,
                            tooltip: 'Settings',
                            onTap: _openSettings,
                            settings: settings,
                          ),
                          const SizedBox(height: 8),
                          if (settings.aiProvider != AIProvider.none)
                            _buildHoverButton(
                              icon: Icons.smart_toy,
                              tooltip: 'AI Assistant',
                              onTap: () => setState(() => _showAIChat = !_showAIChat),
                              settings: settings,
                              isActive: _showAIChat,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // AI Chat Panel
                if (_showAIChat && settings.aiProvider != AIProvider.none)
                  Positioned(
                    right: 60,
                    top: 35,
                    bottom: 20,
                    width: 320,
                    child: _buildAIChatPanel(settings),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHoverButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required TerminalSettings settings,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive
            ? Colors.blue.withValues(alpha: 0.3)
            : settings.backgroundColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: settings.foregroundColor.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              icon,
              color: settings.foregroundColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIChatPanel(TerminalSettings settings) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Assistant (${AIService(settings).providerName})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                  onPressed: () => setState(() => _showAIChat = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _aiMessages.length + (_isAILoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _aiMessages.length && _isAILoading) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Thinking...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final message = _aiMessages[index];
                final isUser = message['role'] == 'user';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.blue.withValues(alpha: 0.2)
                        : const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    message['content'] ?? '',
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.grey[300],
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _aiInputController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Ask AI...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _sendAIMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue, size: 20),
                  onPressed: _sendAIMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TerminalCursorType _getCursorType(TerminalCursorStyle style) {
    switch (style) {
      case TerminalCursorStyle.block:
        return TerminalCursorType.block;
      case TerminalCursorStyle.underline:
        return TerminalCursorType.underline;
      case TerminalCursorStyle.bar:
        return TerminalCursorType.verticalBar;
    }
  }

  String get shell {
    if (Platform.isMacOS || Platform.isLinux) {
      return Platform.environment['SHELL'] ?? 'zsh';
    } else if (Platform.isWindows) {
      return 'cmd.exe';
    }
    return 'sh';
  }

  Future<bool> isOhMyZshInstalled() async {
    final homeDir = Platform.environment['HOME'];
    if (homeDir != null) {
      final ohMyZshDir = Directory('$homeDir/.oh-my-zsh');
      return ohMyZshDir.existsSync();
    }
    return false;
  }

  Future<void> installOhMyZsh() async {
    final homeDir = Platform.environment['HOME'];
    if (homeDir != null) {
      final ohMyZshDir = Directory('$homeDir/.oh-my-zsh');
      if (!ohMyZshDir.existsSync()) {
        try {
          final result = await Process.run(
            'sh',
            [
              '-c',
              'sh -c "\$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
            ],
            environment: {'HOME': homeDir},
          );

          if (result.exitCode != 0) {
            print('Oh My Zsh installation failed: ${result.stderr}');
          } else {
            print('Oh My Zsh installed successfully.');
          }
        } catch (e) {
          print('Error during Oh My Zsh installation: $e');
        }
      } else {
        print('Oh My Zsh is already installed.');
      }
    } else {
      print('HOME environment variable is not set.');
    }
  }
}
