import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AIProvider { none, ollama, openai, gemini }

enum TerminalCursorStyle { block, underline, bar }

class TerminalSettings extends ChangeNotifier {
  static const String _settingsKey = 'terminal_settings';

  // Font settings
  double _fontSize = 14.0;
  String _fontFamily = 'Cascadia Mono';

  // Color settings
  Color _backgroundColor = Colors.black;
  Color _foregroundColor = Colors.white;
  Color _cursorColor = Colors.white;

  // Theme
  String _themeName = 'Default Dark';

  // Cursor settings
  TerminalCursorStyle _cursorStyle = TerminalCursorStyle.block;
  bool _cursorBlink = true;

  // Shell settings
  String _customShell = '';
  List<String> _shellArguments = [];
  Map<String, String> _shellEnvironmentVariables = {};
  Map<String, String> _shellAliases = {};

  // AI settings
  AIProvider _aiProvider = AIProvider.none;
  String _aiApiKey = '';
  String _aiApiEndpoint = '';
  String _ollamaModel = 'llama2';
  String _openaiModel = 'gpt-3.5-turbo';
  String _geminiModel = 'gemini-pro';

  // Key bindings
  Map<String, String> _keyBindings = {
    'copy': 'Ctrl+Shift+C',
    'paste': 'Ctrl+Shift+V',
    'clear': 'Ctrl+L',
    'newTab': 'Ctrl+T',
    'closeTab': 'Ctrl+W',
  };

  // Getters
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  Color get backgroundColor => _backgroundColor;
  Color get foregroundColor => _foregroundColor;
  Color get cursorColor => _cursorColor;
  String get themeName => _themeName;
  TerminalCursorStyle get cursorStyle => _cursorStyle;
  bool get cursorBlink => _cursorBlink;
  String get customShell => _customShell;
  List<String> get shellArguments => List.unmodifiable(_shellArguments);
  Map<String, String> get shellEnvironmentVariables =>
      Map.unmodifiable(_shellEnvironmentVariables);
  Map<String, String> get shellAliases => Map.unmodifiable(_shellAliases);
  AIProvider get aiProvider => _aiProvider;
  String get aiApiKey => _aiApiKey;
  String get aiApiEndpoint => _aiApiEndpoint;
  String get ollamaModel => _ollamaModel;
  String get openaiModel => _openaiModel;
  String get geminiModel => _geminiModel;
  Map<String, String> get keyBindings => Map.unmodifiable(_keyBindings);

  // Setters with notification
  set fontSize(double value) {
    _fontSize = value;
    notifyListeners();
    _saveSettings();
  }

  set fontFamily(String value) {
    _fontFamily = value;
    notifyListeners();
    _saveSettings();
  }

  set backgroundColor(Color value) {
    _backgroundColor = value;
    notifyListeners();
    _saveSettings();
  }

  set foregroundColor(Color value) {
    _foregroundColor = value;
    notifyListeners();
    _saveSettings();
  }

  set cursorColor(Color value) {
    _cursorColor = value;
    notifyListeners();
    _saveSettings();
  }

  set themeName(String value) {
    _themeName = value;
    _applyTheme(value);
    notifyListeners();
    _saveSettings();
  }

  set cursorStyle(TerminalCursorStyle value) {
    _cursorStyle = value;
    notifyListeners();
    _saveSettings();
  }

  set cursorBlink(bool value) {
    _cursorBlink = value;
    notifyListeners();
    _saveSettings();
  }

  set customShell(String value) {
    _customShell = value;
    notifyListeners();
    _saveSettings();
  }

  void setShellArguments(List<String> args) {
    _shellArguments = List.from(args);
    notifyListeners();
    _saveSettings();
  }

  void setShellEnvironmentVariable(String key, String value) {
    _shellEnvironmentVariables[key] = value;
    notifyListeners();
    _saveSettings();
  }

  void removeShellEnvironmentVariable(String key) {
    _shellEnvironmentVariables.remove(key);
    notifyListeners();
    _saveSettings();
  }

  void setShellAlias(String alias, String command) {
    _shellAliases[alias] = command;
    notifyListeners();
    _saveSettings();
  }

  void removeShellAlias(String alias) {
    _shellAliases.remove(alias);
    notifyListeners();
    _saveSettings();
  }

  set aiProvider(AIProvider value) {
    _aiProvider = value;
    notifyListeners();
    _saveSettings();
  }

  set aiApiKey(String value) {
    _aiApiKey = value;
    notifyListeners();
    _saveSettings();
  }

  set aiApiEndpoint(String value) {
    _aiApiEndpoint = value;
    notifyListeners();
    _saveSettings();
  }

  set ollamaModel(String value) {
    _ollamaModel = value;
    notifyListeners();
    _saveSettings();
  }

  set openaiModel(String value) {
    _openaiModel = value;
    notifyListeners();
    _saveSettings();
  }

  set geminiModel(String value) {
    _geminiModel = value;
    notifyListeners();
    _saveSettings();
  }

  void setKeyBinding(String action, String binding) {
    _keyBindings[action] = binding;
    notifyListeners();
    _saveSettings();
  }

  // Theme presets
  static final Map<String, Map<String, Color>> themes = {
    'Default Dark': {
      'background': Colors.black,
      'foreground': Colors.white,
      'cursor': Colors.white,
    },
    'Dracula': {
      'background': const Color(0xFF282A36),
      'foreground': const Color(0xFFF8F8F2),
      'cursor': const Color(0xFFFF79C6),
    },
    'Solarized Dark': {
      'background': const Color(0xFF002B36),
      'foreground': const Color(0xFF839496),
      'cursor': const Color(0xFF93A1A1),
    },
    'Solarized Light': {
      'background': const Color(0xFFFDF6E3),
      'foreground': const Color(0xFF657B83),
      'cursor': const Color(0xFF586E75),
    },
    'Monokai': {
      'background': const Color(0xFF272822),
      'foreground': const Color(0xFFF8F8F2),
      'cursor': const Color(0xFFF92672),
    },
    'Nord': {
      'background': const Color(0xFF2E3440),
      'foreground': const Color(0xFFD8DEE9),
      'cursor': const Color(0xFF88C0D0),
    },
    'One Dark': {
      'background': const Color(0xFF282C34),
      'foreground': const Color(0xFFABB2BF),
      'cursor': const Color(0xFF528BFF),
    },
    'Gruvbox Dark': {
      'background': const Color(0xFF282828),
      'foreground': const Color(0xFFEBDBB2),
      'cursor': const Color(0xFFFE8019),
    },
  };

  void _applyTheme(String name) {
    final theme = themes[name];
    if (theme != null) {
      _backgroundColor = theme['background']!;
      _foregroundColor = theme['foreground']!;
      _cursorColor = theme['cursor']!;
    }
  }

  // Persistence
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);

    if (settingsJson != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(settingsJson);

        _fontSize = (data['fontSize'] as num?)?.toDouble() ?? 14.0;
        _fontFamily = data['fontFamily'] as String? ?? 'Cascadia Mono';
        _backgroundColor = Color(data['backgroundColor'] as int? ?? 0xFF000000);
        _foregroundColor = Color(data['foregroundColor'] as int? ?? 0xFFFFFFFF);
        _cursorColor = Color(data['cursorColor'] as int? ?? 0xFFFFFFFF);
        _themeName = data['themeName'] as String? ?? 'Default Dark';
        _cursorStyle = TerminalCursorStyle.values[data['cursorStyle'] as int? ?? 0];
        _cursorBlink = data['cursorBlink'] as bool? ?? true;
        _customShell = data['customShell'] as String? ?? '';
        _shellArguments =
            List<String>.from(data['shellArguments'] as List? ?? []);
        _shellEnvironmentVariables = Map<String, String>.from(
            data['shellEnvironmentVariables'] as Map? ?? {});
        _shellAliases =
            Map<String, String>.from(data['shellAliases'] as Map? ?? {});
        _aiProvider =
            AIProvider.values[data['aiProvider'] as int? ?? 0];
        _aiApiKey = data['aiApiKey'] as String? ?? '';
        _aiApiEndpoint = data['aiApiEndpoint'] as String? ?? '';
        _ollamaModel = data['ollamaModel'] as String? ?? 'llama2';
        _openaiModel = data['openaiModel'] as String? ?? 'gpt-3.5-turbo';
        _geminiModel = data['geminiModel'] as String? ?? 'gemini-pro';
        _keyBindings = Map<String, String>.from(
            data['keyBindings'] as Map? ?? _keyBindings);

        notifyListeners();
      } catch (e) {
        debugPrint('Error loading settings: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'fontSize': _fontSize,
      'fontFamily': _fontFamily,
      'backgroundColor': _backgroundColor.toARGB32(),
      'foregroundColor': _foregroundColor.toARGB32(),
      'cursorColor': _cursorColor.toARGB32(),
      'themeName': _themeName,
      'cursorStyle': _cursorStyle.index,
      'cursorBlink': _cursorBlink,
      'customShell': _customShell,
      'shellArguments': _shellArguments,
      'shellEnvironmentVariables': _shellEnvironmentVariables,
      'shellAliases': _shellAliases,
      'aiProvider': _aiProvider.index,
      'aiApiKey': _aiApiKey,
      'aiApiEndpoint': _aiApiEndpoint,
      'ollamaModel': _ollamaModel,
      'openaiModel': _openaiModel,
      'geminiModel': _geminiModel,
      'keyBindings': _keyBindings,
    };
    await prefs.setString(_settingsKey, jsonEncode(data));
  }

  Future<void> resetToDefaults() async {
    _fontSize = 14.0;
    _fontFamily = 'Cascadia Mono';
    _backgroundColor = Colors.black;
    _foregroundColor = Colors.white;
    _cursorColor = Colors.white;
    _themeName = 'Default Dark';
    _cursorStyle = TerminalCursorStyle.block;
    _cursorBlink = true;
    _customShell = '';
    _shellArguments = [];
    _shellEnvironmentVariables = {};
    _shellAliases = {};
    _aiProvider = AIProvider.none;
    _aiApiKey = '';
    _aiApiEndpoint = '';
    _ollamaModel = 'llama2';
    _openaiModel = 'gpt-3.5-turbo';
    _geminiModel = 'gemini-pro';
    _keyBindings = {
      'copy': 'Ctrl+Shift+C',
      'paste': 'Ctrl+Shift+V',
      'clear': 'Ctrl+L',
      'newTab': 'Ctrl+T',
      'closeTab': 'Ctrl+W',
    };
    notifyListeners();
    await _saveSettings();
  }
}
