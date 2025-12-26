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

class TerminalTab {
  final String id;
  final Terminal terminal;
  final TerminalController controller;
  late Pty pty;
  String title;
  String workingDirectory;
  String currentProcess;

  TerminalTab({
    required this.id,
    required this.terminal,
    required this.controller,
    this.title = 'zsh',
    this.workingDirectory = '~',
    this.currentProcess = 'zsh',
  });

  String get displayTitle {
    // Format like Linux terminals: "process: directory"
    final dirName = workingDirectory.split('/').last;
    final displayDir = dirName.isEmpty ? '~' : dirName;
    return '$currentProcess: $displayDir';
  }
}

class WindowButtons extends StatelessWidget {
  final Color backgroundColor;
  final Color foregroundColor;

  const WindowButtons({
    Key? key,
    required this.backgroundColor,
    required this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonColors = WindowButtonColors(
      iconNormal: foregroundColor.withValues(alpha: 0.8),
      mouseOver: foregroundColor.withValues(alpha: 0.1),
      mouseDown: foregroundColor.withValues(alpha: 0.2),
      iconMouseOver: foregroundColor,
      iconMouseDown: foregroundColor,
    );

    final closeButtonColors = WindowButtonColors(
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: foregroundColor.withValues(alpha: 0.8),
      iconMouseOver: Colors.white,
      iconMouseDown: Colors.white,
    );

    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<TerminalTab> _tabs = [];
  int _currentTabIndex = 0;
  int _tabCounter = 0;

  bool _isHoveringTerminal = false;
  bool _isHoveringButtons = false;
  bool _showAIChat = false;
  final TextEditingController _aiInputController = TextEditingController();
  final List<Map<String, String>> _aiMessages = [];
  bool _isAILoading = false;
  final FocusNode _keyboardFocusNode = FocusNode();

  bool get _shouldShowButtons => _isHoveringTerminal || _isHoveringButtons || _showAIChat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) _createNewTab();
    });
  }

  @override
  void dispose() {
    _aiInputController.dispose();
    _keyboardFocusNode.dispose();
    for (final tab in _tabs) {
      tab.pty.kill();
    }
    super.dispose();
  }

  // Check if a key event matches a key binding string (e.g., "Ctrl+Shift+T")
  bool _matchesKeyBinding(KeyEvent event, String binding) {
    if (binding.isEmpty) return false;

    final parts = binding.split('+').map((s) => s.trim().toLowerCase()).toList();
    final keyPart = parts.last;
    final modifiers = parts.sublist(0, parts.length - 1);

    // Check modifiers
    final needsCtrl = modifiers.contains('ctrl');
    final needsShift = modifiers.contains('shift');
    final needsAlt = modifiers.contains('alt');
    final needsMeta = modifiers.contains('meta') || modifiers.contains('cmd');

    final hasCtrl = HardwareKeyboard.instance.isControlPressed;
    final hasShift = HardwareKeyboard.instance.isShiftPressed;
    final hasAlt = HardwareKeyboard.instance.isAltPressed;
    final hasMeta = HardwareKeyboard.instance.isMetaPressed;

    // On macOS, treat Ctrl in binding as Cmd for convenience
    final ctrlOrMeta = Platform.isMacOS ? (hasMeta || hasCtrl) : hasCtrl;

    if (needsCtrl && !ctrlOrMeta) return false;
    if (needsShift && !hasShift) return false;
    if (needsAlt && !hasAlt) return false;
    if (needsMeta && !hasMeta) return false;

    // Match the key
    final logicalKey = event.logicalKey;

    // Map of key names to LogicalKeyboardKey
    final keyMap = <String, LogicalKeyboardKey>{
      'a': LogicalKeyboardKey.keyA,
      'b': LogicalKeyboardKey.keyB,
      'c': LogicalKeyboardKey.keyC,
      'd': LogicalKeyboardKey.keyD,
      'e': LogicalKeyboardKey.keyE,
      'f': LogicalKeyboardKey.keyF,
      'g': LogicalKeyboardKey.keyG,
      'h': LogicalKeyboardKey.keyH,
      'i': LogicalKeyboardKey.keyI,
      'j': LogicalKeyboardKey.keyJ,
      'k': LogicalKeyboardKey.keyK,
      'l': LogicalKeyboardKey.keyL,
      'm': LogicalKeyboardKey.keyM,
      'n': LogicalKeyboardKey.keyN,
      'o': LogicalKeyboardKey.keyO,
      'p': LogicalKeyboardKey.keyP,
      'q': LogicalKeyboardKey.keyQ,
      'r': LogicalKeyboardKey.keyR,
      's': LogicalKeyboardKey.keyS,
      't': LogicalKeyboardKey.keyT,
      'u': LogicalKeyboardKey.keyU,
      'v': LogicalKeyboardKey.keyV,
      'w': LogicalKeyboardKey.keyW,
      'x': LogicalKeyboardKey.keyX,
      'y': LogicalKeyboardKey.keyY,
      'z': LogicalKeyboardKey.keyZ,
      '1': LogicalKeyboardKey.digit1,
      '2': LogicalKeyboardKey.digit2,
      '3': LogicalKeyboardKey.digit3,
      '4': LogicalKeyboardKey.digit4,
      '5': LogicalKeyboardKey.digit5,
      '6': LogicalKeyboardKey.digit6,
      '7': LogicalKeyboardKey.digit7,
      '8': LogicalKeyboardKey.digit8,
      '9': LogicalKeyboardKey.digit9,
      '0': LogicalKeyboardKey.digit0,
      'tab': LogicalKeyboardKey.tab,
      'enter': LogicalKeyboardKey.enter,
      'escape': LogicalKeyboardKey.escape,
      'esc': LogicalKeyboardKey.escape,
      'space': LogicalKeyboardKey.space,
      'backspace': LogicalKeyboardKey.backspace,
      'delete': LogicalKeyboardKey.delete,
      'up': LogicalKeyboardKey.arrowUp,
      'down': LogicalKeyboardKey.arrowDown,
      'left': LogicalKeyboardKey.arrowLeft,
      'right': LogicalKeyboardKey.arrowRight,
      'pageup': LogicalKeyboardKey.pageUp,
      'pagedown': LogicalKeyboardKey.pageDown,
      'home': LogicalKeyboardKey.home,
      'end': LogicalKeyboardKey.end,
    };

    final expectedKey = keyMap[keyPart];
    return expectedKey != null && logicalKey == expectedKey;
  }

  // Handle keyboard shortcuts for tab navigation
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final settings = context.read<TerminalSettings>();
    final bindings = settings.keyBindings;

    // New tab
    if (_matchesKeyBinding(event, bindings['newTab'] ?? '')) {
      _createNewTab();
      return KeyEventResult.handled;
    }

    // Close tab
    if (_matchesKeyBinding(event, bindings['closeTab'] ?? '')) {
      _closeTab(_currentTabIndex);
      return KeyEventResult.handled;
    }

    // Next tab
    if (_matchesKeyBinding(event, bindings['nextTab'] ?? '')) {
      _selectTab((_currentTabIndex + 1) % _tabs.length);
      return KeyEventResult.handled;
    }

    // Previous tab
    if (_matchesKeyBinding(event, bindings['previousTab'] ?? '')) {
      _selectTab((_currentTabIndex - 1 + _tabs.length) % _tabs.length);
      return KeyEventResult.handled;
    }

    // Tab 1-9
    for (int i = 1; i <= 9; i++) {
      if (_matchesKeyBinding(event, bindings['tab$i'] ?? '')) {
        if (i - 1 < _tabs.length) {
          _selectTab(i - 1);
          return KeyEventResult.handled;
        }
      }
    }

    return KeyEventResult.ignored;
  }

  void _reorderTabs(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final tab = _tabs.removeAt(oldIndex);
      _tabs.insert(newIndex, tab);

      // Update current tab index if needed
      if (_currentTabIndex == oldIndex) {
        _currentTabIndex = newIndex;
      } else if (oldIndex < _currentTabIndex && newIndex >= _currentTabIndex) {
        _currentTabIndex--;
      } else if (oldIndex > _currentTabIndex && newIndex <= _currentTabIndex) {
        _currentTabIndex++;
      }
    });
  }

  void _createNewTab() {
    final tabId = 'tab_${_tabCounter++}';
    final terminal = Terminal(maxLines: 10000);
    final controller = TerminalController();
    final homeDir = Platform.environment['HOME'] ?? '~';
    final shellName = shell.split('/').last;

    final tab = TerminalTab(
      id: tabId,
      terminal: terminal,
      controller: controller,
      title: shellName,
      workingDirectory: homeDir,
      currentProcess: shellName,
    );

    setState(() {
      _tabs.add(tab);
      _currentTabIndex = _tabs.length - 1;
    });

    _startPtyForTab(tab);
  }

  void _closeTab(int index) {
    if (_tabs.length <= 1) return; // Keep at least one tab

    final tab = _tabs[index];
    tab.pty.kill();

    setState(() {
      _tabs.removeAt(index);
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.length - 1;
      } else if (_currentTabIndex > index) {
        _currentTabIndex--;
      }
    });
  }

  void _selectTab(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  Future<void> _startPtyForTab(TerminalTab tab) async {
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

    tab.pty = Pty.start(
      shellPath,
      arguments: settings.shellArguments,
      columns: tab.terminal.viewWidth,
      rows: tab.terminal.viewHeight,
      workingDirectory: Platform.environment['HOME'] ?? '~',
      environment: environment,
    );

    tab.pty.output.cast<List<int>>().transform(utf8.decoder).listen(tab.terminal.write);

    tab.pty.exitCode.then((code) {
      tab.terminal.write('the process exited with exit code $code');
    });

    tab.terminal
      ..onOutput = (data) {
        tab.pty.write(utf8.encode(data));
      }
      ..onResize = (w, h, pw, ph) {
        tab.pty.resize(h, w);
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
        final currentTab = _tabs.isNotEmpty ? _tabs[_currentTabIndex] : null;

        return Focus(
          focusNode: _keyboardFocusNode,
          onKeyEvent: _handleKeyEvent,
          child: Scaffold(
            backgroundColor: settings.backgroundColor,
            body: SafeArea(
              child: Stack(
                children: [
                // Terminal
                if (currentTab != null)
                  MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringTerminal = true),
                    onExit: (_) => setState(() => _isHoveringTerminal = false),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0).copyWith(top: 60.0),
                      child: TerminalView(
                        currentTab.terminal,
                        controller: currentTab.controller,
                        autofocus: true,
                        backgroundOpacity: 0,
                        textStyle: TerminalStyle(
                          fontSize: settings.fontSize,
                          fontFamily: settings.fontFamily,
                        ),
                        cursorType: _getCursorType(settings.cursorStyle),
                        onSecondaryTapDown: (details, offset) async {
                          final selection = currentTab.controller.selection;
                          if (selection != null) {
                            final text = currentTab.terminal.buffer.getText(selection);
                            currentTab.controller.clearSelection();
                            await Clipboard.setData(ClipboardData(text: text));
                          } else {
                            final data = await Clipboard.getData('text/plain');
                            final text = data?.text;
                            if (text != null) {
                              currentTab.terminal.paste(text);
                            }
                          }
                        },
                      ),
                    ),
                  ),

                // Title bar
                WindowTitleBarBox(
                  child: Row(
                    children: [
                      Expanded(
                        child: MoveWindow(
                          child: Container(
                            color: settings.backgroundColor,
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
                      ),
                      WindowButtons(
                        backgroundColor: settings.backgroundColor,
                        foregroundColor: settings.foregroundColor,
                      ),
                    ],
                  ),
                ),

                // Tab bar (below title bar)
                Positioned(
                  top: 30,
                  left: 0,
                  right: 0,
                  height: 30,
                  child: Container(
                    color: settings.backgroundColor,
                    child: Row(
                      children: [
                        // Tabs (reorderable)
                        Expanded(
                          child: ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            buildDefaultDragHandles: false,
                            onReorder: _reorderTabs,
                            proxyDecorator: (child, index, animation) {
                              return Material(
                                color: Colors.transparent,
                                elevation: 4,
                                child: child,
                              );
                            },
                            itemCount: _tabs.length,
                            itemBuilder: (context, index) {
                              final tab = _tabs[index];
                              final isSelected = index == _currentTabIndex;
                              return ReorderableDragStartListener(
                                key: ValueKey(tab.id),
                                index: index,
                                child: GestureDetector(
                                  onTap: () => _selectTab(index),
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 120,
                                      maxWidth: 180,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? settings.backgroundColor.withValues(alpha: 0.8)
                                          : Colors.transparent,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: isSelected
                                              ? Colors.blue
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.terminal,
                                          size: 14,
                                          color: isSelected
                                              ? settings.foregroundColor
                                              : settings.foregroundColor.withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            tab.displayTitle,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? settings.foregroundColor
                                                  : settings.foregroundColor.withValues(alpha: 0.6),
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (_tabs.length > 1)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8),
                                            child: GestureDetector(
                                              onTap: () => _closeTab(index),
                                              child: MouseRegion(
                                                cursor: SystemMouseCursors.click,
                                                child: Icon(
                                                  Icons.close,
                                                  size: 14,
                                                  color: settings.foregroundColor.withValues(alpha: 0.6),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Add tab button
                        GestureDetector(
                          onTap: _createNewTab,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(
                                Icons.add,
                                size: 18,
                                color: settings.foregroundColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Settings button (visible on hover)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  top: 65,
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
                    top: 65,
                    bottom: 20,
                    width: 320,
                    child: _buildAIChatPanel(settings),
                  ),
                ],
              ),
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
