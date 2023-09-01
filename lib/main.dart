import 'dart:convert';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';

import 'src/platform_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

void main() {
  runApp(MyApp());

  doWhenWindowReady(() {
    const initialSize = Size(600, 450);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.title = 'Terminal';
    appWindow.show();
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
      // shortcuts: ,
    );
  }
}

class Home extends StatefulWidget {
  Home({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final terminal = Terminal(
    maxLines: 10000,
  );

  final terminalController = TerminalController();

  late final Pty pty;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.endOfFrame.then(
      (_) {
        if (mounted) _startPty();
      },
    );
  }

  void _startPty() {
    pty = Pty.start(
      shell,
      columns: terminal.viewWidth,
      rows: terminal.viewHeight,
      workingDirectory: Platform.environment['HOME'] ?? '~',
    );

    pty.output
        .cast<List<int>>()
        .transform(Utf8Decoder())
        .listen(terminal.write);

    pty.exitCode.then((code) {
      terminal.write('the process exited with exit code $code');
    });

    terminal.onOutput = (data) {
      pty.write(const Utf8Encoder().convert(data));
    };

    terminal.onResize = (w, h, pw, ph) {
      pty.resize(h, w);
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 30.0,
                left: 8,
                right: 8,
                bottom: 8,
              ),
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
              child: WindowTitleBarBox(child: MoveWindow()),
            ),
          ],
        ),
      ),
    );
  }
}

String get shell {
  if (Platform.isMacOS || Platform.isLinux) {
    return Platform.environment['SHELL'] ?? 'zsh';
  }

  if (Platform.isWindows) {
    return 'cmd.exe';
  }

  return 'sh';
}
