import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

import 'src/platform_menu.dart';

void main() {
  runApp(MyApp());

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
    return MaterialApp(
      title: 'Terminal',
      debugShowCheckedModeBanner: false,
      home: AppPlatformMenu(child: Home()),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) _startPty();
    });
  }

  Future<void> _startPty() async {
    if (!await isOhMyZshInstalled()) {
      await installOhMyZsh();
    }

    pty = Pty.start(
      shell,
      columns: terminal.viewWidth,
      rows: terminal.viewHeight,
      workingDirectory: Platform.environment['HOME'] ?? '~',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0).copyWith(top: 30.0),
              child: TerminalView(
                terminal,
                controller: terminalController,
                autofocus: true,
                backgroundOpacity: 0,
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
            Container(
              child: WindowTitleBarBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MoveWindow(
                      child: Container(
                        color: Colors.black,
                        width: MediaQuery.of(context).size.width,
                        height: 30,
                        child: Center(
                          child: Text(
                            'Terminal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
