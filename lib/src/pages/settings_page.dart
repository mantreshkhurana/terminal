import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:provider/provider.dart';
import '../models/settings_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalSettings>(
      builder: (context, settings, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Column(
            children: [
              // Window title bar for dragging (empty, just for macOS traffic lights)
              WindowTitleBarBox(
                child: MoveWindow(),
              ),
              // Header with back button and title (below window controls)
              Container(
                height: 44,
                color: Colors.black,
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    // Title
                    const Expanded(
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tab bar
              Container(
                color: const Color(0xFF111111),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.blue,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Appearance'),
                    Tab(text: 'Shell'),
                    Tab(text: 'AI'),
                    Tab(text: 'Key Bindings'),
                    Tab(text: 'About'),
                  ],
                ),
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppearanceTab(settings),
                    _buildShellTab(settings),
                    _buildAITab(settings),
                    _buildKeyBindingsTab(settings),
                    _buildAboutTab(settings),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppearanceTab(TerminalSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Theme'),
        _buildThemeSelector(settings),
        const SizedBox(height: 24),
        _buildSectionHeader('Font'),
        _buildFontSettings(settings),
        const SizedBox(height: 24),
        _buildSectionHeader('Colors'),
        _buildColorSettings(settings),
        const SizedBox(height: 24),
        _buildSectionHeader('Cursor'),
        _buildCursorSettings(settings),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(TerminalSettings settings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: settings.themeName,
            dropdownColor: const Color(0xFF1A1A1A),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Theme',
              labelStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            items: TerminalSettings.themes.keys.map((theme) {
              return DropdownMenuItem(value: theme, child: Text(theme));
            }).toList(),
            onChanged: (value) {
              if (value != null) settings.themeName = value;
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TerminalSettings.themes.entries.map((entry) {
              final isSelected = settings.themeName == entry.key;
              return GestureDetector(
                onTap: () => settings.themeName = entry.key,
                child: Container(
                  width: 60,
                  height: 40,
                  decoration: BoxDecoration(
                    color: entry.value['background'],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Aa',
                      style: TextStyle(
                        color: entry.value['foreground'],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSettings(TerminalSettings settings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Font Size: ', style: TextStyle(color: Colors.white)),
              Expanded(
                child: Slider(
                  value: settings.fontSize,
                  min: 8,
                  max: 32,
                  divisions: 24,
                  label: settings.fontSize.round().toString(),
                  onChanged: (value) => settings.fontSize = value,
                ),
              ),
              Text(
                '${settings.fontSize.round()}px',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: settings.fontFamily,
            dropdownColor: const Color(0xFF1A1A1A),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Font Family',
              labelStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'Cascadia Mono', child: Text('Cascadia Mono')),
              DropdownMenuItem(value: 'monospace', child: Text('Monospace')),
              DropdownMenuItem(value: 'Courier New', child: Text('Courier New')),
              DropdownMenuItem(value: 'Consolas', child: Text('Consolas')),
              DropdownMenuItem(value: 'SF Mono', child: Text('SF Mono')),
              DropdownMenuItem(value: 'Menlo', child: Text('Menlo')),
              DropdownMenuItem(value: 'Monaco', child: Text('Monaco')),
            ],
            onChanged: (value) {
              if (value != null) settings.fontFamily = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorSettings(TerminalSettings settings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildColorPicker('Background', settings.backgroundColor, (color) {
            settings.backgroundColor = color;
          }),
          const SizedBox(height: 12),
          _buildColorPicker('Foreground', settings.foregroundColor, (color) {
            settings.foregroundColor = color;
          }),
          const SizedBox(height: 12),
          _buildColorPicker('Cursor', settings.cursorColor, (color) {
            settings.cursorColor = color;
          }),
        ],
      ),
    );
  }

  Widget _buildColorPicker(
      String label, Color currentColor, ValueChanged<Color> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
        GestureDetector(
          onTap: () async {
            final color = await showColorPickerDialog(
              context,
              currentColor,
              title: Text('Select $label Color',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              width: 40,
              height: 40,
              spacing: 0,
              runSpacing: 0,
              borderRadius: 0,
              wheelDiameter: 165,
              enableOpacity: true,
              showColorCode: true,
              colorCodeHasColor: true,
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.wheel: true,
                ColorPickerType.accent: false,
                ColorPickerType.primary: false,
              },
            );
            onChanged(color);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCursorSettings(TerminalSettings settings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<TerminalCursorStyle>(
            initialValue: settings.cursorStyle,
            dropdownColor: const Color(0xFF1A1A1A),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Cursor Style',
              labelStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            items: const [
              DropdownMenuItem(value: TerminalCursorStyle.block, child: Text('Block')),
              DropdownMenuItem(value: TerminalCursorStyle.underline, child: Text('Underline')),
              DropdownMenuItem(value: TerminalCursorStyle.bar, child: Text('Bar')),
            ],
            onChanged: (value) {
              if (value != null) settings.cursorStyle = value;
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Cursor Blink',
                style: TextStyle(color: Colors.white)),
            value: settings.cursorBlink,
            onChanged: (value) => settings.cursorBlink = value,
            activeThumbColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildShellTab(TerminalSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Shell Configuration'),
        _buildShellConfig(settings),
        const SizedBox(height: 24),
        _buildSectionHeader('Shell Arguments'),
        _buildShellArguments(settings),
        const SizedBox(height: 24),
        _buildSectionHeader('Environment Variables'),
        _buildEnvironmentVariables(settings),
        const SizedBox(height: 24),
        _buildSectionHeader('Shell Aliases'),
        _buildShellAliases(settings),
      ],
    );
  }

  Widget _buildShellConfig(TerminalSettings settings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        initialValue: settings.customShell,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelText: 'Custom Shell Path (leave empty for default)',
          labelStyle: TextStyle(color: Colors.grey),
          hintText: '/bin/zsh or /bin/bash',
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
        ),
        onChanged: (value) => settings.customShell = value,
      ),
    );
  }

  Widget _buildShellArguments(TerminalSettings settings) {
    final controller = TextEditingController(
      text: settings.shellArguments.join(' '),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Shell Arguments (space separated)',
              labelStyle: TextStyle(color: Colors.grey),
              hintText: '-l --login',
              hintStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            onChanged: (value) {
              final args =
                  value.split(' ').where((s) => s.isNotEmpty).toList();
              settings.setShellArguments(args);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentVariables(TerminalSettings settings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ...settings.shellEnvironmentVariables.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entry.key}=${entry.value}',
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        settings.removeShellEnvironmentVariable(entry.key),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Environment Variable'),
            onPressed: () => _showAddEnvVarDialog(settings),
          ),
        ],
      ),
    );
  }

  void _showAddEnvVarDialog(TerminalSettings settings) {
    final keyController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title:
            const Text('Add Environment Variable', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Variable Name',
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
            TextField(
              controller: valueController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Value',
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (keyController.text.isNotEmpty) {
                settings.setShellEnvironmentVariable(
                  keyController.text,
                  valueController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildShellAliases(TerminalSettings settings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ...settings.shellAliases.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entry.key} -> ${entry.value}',
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => settings.removeShellAlias(entry.key),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Alias'),
            onPressed: () => _showAddAliasDialog(settings),
          ),
        ],
      ),
    );
  }

  void _showAddAliasDialog(TerminalSettings settings) {
    final aliasController = TextEditingController();
    final commandController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Add Shell Alias', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: aliasController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Alias',
                labelStyle: TextStyle(color: Colors.grey),
                hintText: 'e.g., ll',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
            TextField(
              controller: commandController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Command',
                labelStyle: TextStyle(color: Colors.grey),
                hintText: 'e.g., ls -la',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (aliasController.text.isNotEmpty &&
                  commandController.text.isNotEmpty) {
                settings.setShellAlias(
                  aliasController.text,
                  commandController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildAITab(TerminalSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('AI Provider'),
        _buildAIProviderSelector(settings),
        const SizedBox(height: 24),
        if (settings.aiProvider != AIProvider.none) ...[
          _buildSectionHeader('API Configuration'),
          _buildAIConfig(settings),
        ],
      ],
    );
  }

  Widget _buildAIProviderSelector(TerminalSettings settings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildAIProviderTile(
            settings,
            AIProvider.none,
            'None',
            'AI features disabled',
          ),
          _buildAIProviderTile(
            settings,
            AIProvider.ollama,
            'Ollama',
            'Local AI - Free, runs on your machine',
          ),
          _buildAIProviderTile(
            settings,
            AIProvider.openai,
            'OpenAI',
            'GPT models - Requires API key',
          ),
          _buildAIProviderTile(
            settings,
            AIProvider.gemini,
            'Gemini',
            'Google AI - Requires API key',
          ),
        ],
      ),
    );
  }

  Widget _buildAIProviderTile(
    TerminalSettings settings,
    AIProvider provider,
    String title,
    String subtitle,
  ) {
    final isSelected = settings.aiProvider == provider;
    return ListTile(
      leading: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: 2,
          ),
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                ),
              )
            : null,
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      onTap: () => settings.aiProvider = provider,
      selected: isSelected,
    );
  }

  Widget _buildAIConfig(TerminalSettings settings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (settings.aiProvider != AIProvider.ollama)
            TextFormField(
              initialValue: settings.aiApiKey,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
              onChanged: (value) => settings.aiApiKey = value,
            ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: settings.aiApiEndpoint,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'API Endpoint (optional)',
              labelStyle: const TextStyle(color: Colors.grey),
              hintText: _getDefaultEndpoint(settings.aiProvider),
              hintStyle: const TextStyle(color: Colors.grey),
              border: const OutlineInputBorder(),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            onChanged: (value) => settings.aiApiEndpoint = value,
          ),
          const SizedBox(height: 12),
          _buildModelSelector(settings),
        ],
      ),
    );
  }

  String _getDefaultEndpoint(AIProvider provider) {
    switch (provider) {
      case AIProvider.ollama:
        return 'http://localhost:11434';
      case AIProvider.openai:
        return 'https://api.openai.com/v1';
      case AIProvider.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta';
      case AIProvider.none:
        return '';
    }
  }

  Widget _buildModelSelector(TerminalSettings settings) {
    switch (settings.aiProvider) {
      case AIProvider.ollama:
        return TextFormField(
          initialValue: settings.ollamaModel,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Model',
            labelStyle: TextStyle(color: Colors.grey),
            hintText: 'llama2, codellama, mistral, etc.',
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
          onChanged: (value) => settings.ollamaModel = value,
        );
      case AIProvider.openai:
        return DropdownButtonFormField<String>(
          initialValue: settings.openaiModel,
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Model',
            labelStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'gpt-3.5-turbo', child: Text('GPT-3.5 Turbo')),
            DropdownMenuItem(value: 'gpt-4', child: Text('GPT-4')),
            DropdownMenuItem(value: 'gpt-4-turbo', child: Text('GPT-4 Turbo')),
            DropdownMenuItem(value: 'gpt-4o', child: Text('GPT-4o')),
            DropdownMenuItem(value: 'gpt-4o-mini', child: Text('GPT-4o Mini')),
          ],
          onChanged: (value) {
            if (value != null) settings.openaiModel = value;
          },
        );
      case AIProvider.gemini:
        return DropdownButtonFormField<String>(
          initialValue: settings.geminiModel,
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Model',
            labelStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'gemini-pro', child: Text('Gemini Pro')),
            DropdownMenuItem(value: 'gemini-1.5-pro', child: Text('Gemini 1.5 Pro')),
            DropdownMenuItem(value: 'gemini-1.5-flash', child: Text('Gemini 1.5 Flash')),
          ],
          onChanged: (value) {
            if (value != null) settings.geminiModel = value;
          },
        );
      case AIProvider.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildKeyBindingsTab(TerminalSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Key Bindings'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: settings.keyBindings.entries.map((entry) {
              return ListTile(
                title: Text(
                  _formatKeyBindingName(entry.key),
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: TextButton(
                  onPressed: () => _showEditKeyBindingDialog(settings, entry.key),
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatKeyBindingName(String key) {
    return key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    ).trim().replaceFirstMapped(
      RegExp(r'^.'),
      (match) => match.group(0)!.toUpperCase(),
    );
  }

  void _showEditKeyBindingDialog(TerminalSettings settings, String action) {
    showDialog(
      context: context,
      builder: (context) => _KeyBindingRecorderDialog(
        action: action,
        actionLabel: _formatKeyBindingName(action),
        currentBinding: settings.keyBindings[action] ?? '',
        onSave: (binding) {
          settings.setKeyBinding(action, binding);
        },
      ),
    );
  }

  Widget _buildAboutTab(TerminalSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('About Terminal'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terminal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A simple yet customizable terminal emulator written in Flutter.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Version: 1.0.0',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await settings.resetToDefaults();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings reset to defaults')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Reset All Settings'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyBindingRecorderDialog extends StatefulWidget {
  final String action;
  final String actionLabel;
  final String currentBinding;
  final Function(String) onSave;

  const _KeyBindingRecorderDialog({
    required this.action,
    required this.actionLabel,
    required this.currentBinding,
    required this.onSave,
  });

  @override
  State<_KeyBindingRecorderDialog> createState() =>
      _KeyBindingRecorderDialogState();
}

class _KeyBindingRecorderDialogState extends State<_KeyBindingRecorderDialog> {
  late String _recordedBinding;
  bool _isRecording = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _recordedBinding = widget.currentBinding;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _formatKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return '';

    final List<String> parts = [];

    if (HardwareKeyboard.instance.isControlPressed) {
      parts.add('Ctrl');
    }
    if (HardwareKeyboard.instance.isAltPressed) {
      parts.add('Alt');
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      parts.add('Shift');
    }
    if (HardwareKeyboard.instance.isMetaPressed) {
      parts.add('Meta');
    }

    final key = event.logicalKey;

    // Skip if only modifier keys are pressed
    if (key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight) {
      return '';
    }

    // Get the key label
    String keyLabel = key.keyLabel;
    if (keyLabel.isEmpty) {
      keyLabel = key.debugName ?? 'Unknown';
    }

    // Format special keys
    keyLabel = _formatSpecialKey(keyLabel);

    parts.add(keyLabel);

    return parts.join('+');
  }

  String _formatSpecialKey(String keyLabel) {
    final Map<String, String> specialKeys = {
      'Space': 'Space',
      'Enter': 'Enter',
      'Escape': 'Esc',
      'Backspace': 'Backspace',
      'Delete': 'Delete',
      'Tab': 'Tab',
      'Arrow Up': 'Up',
      'Arrow Down': 'Down',
      'Arrow Left': 'Left',
      'Arrow Right': 'Right',
      'Home': 'Home',
      'End': 'End',
      'Page Up': 'PageUp',
      'Page Down': 'PageDown',
      'Insert': 'Insert',
    };

    return specialKeys[keyLabel] ?? keyLabel.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      title: Text(
        'Edit ${widget.actionLabel}',
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Current binding:',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          KeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: (event) {
              if (_isRecording) {
                final binding = _formatKeyEvent(event);
                if (binding.isNotEmpty) {
                  setState(() {
                    _recordedBinding = binding;
                    _isRecording = false;
                  });
                }
              }
            },
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isRecording = true;
                });
                _focusNode.requestFocus();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _isRecording
                      ? const Color(0xFF1E3A5F)
                      : const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isRecording ? Colors.blue : Colors.grey.shade700,
                    width: _isRecording ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isRecording)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    Text(
                      _isRecording ? 'Press any key...' : _recordedBinding,
                      style: TextStyle(
                        color: _isRecording ? Colors.blue : Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isRecording
                ? 'Press the key combination you want to use'
                : 'Click the box above to record a new key binding',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _recordedBinding = widget.currentBinding;
              _isRecording = false;
            });
          },
          child: const Text('Reset'),
        ),
        ElevatedButton(
          onPressed: _isRecording
              ? null
              : () {
                  if (_recordedBinding.isNotEmpty) {
                    widget.onSave(_recordedBinding);
                    Navigator.pop(context);
                  }
                },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
