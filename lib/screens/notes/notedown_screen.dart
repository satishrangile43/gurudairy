import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class NoteDownScreen extends StatefulWidget {
  const NoteDownScreen({super.key});

  @override
  State<NoteDownScreen> createState() => _NoteDownScreenState();
}

class _NoteDownScreenState extends State<NoteDownScreen> {
  late QuillController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupEditor();
  }

  /// =========================
  /// LOAD NOTE FROM HIVE
  /// =========================
  Future<void> _setupEditor() async {
    var box = await Hive.openBox('notes_box');
    var savedData = box.get('rich_note_content');

    if (savedData != null) {
      try {
        final doc = Document.fromJson(jsonDecode(savedData));
        _controller = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        _controller = QuillController.basic();
      }
    } else {
      _controller = QuillController.basic();
    }

    _controller.addListener(_saveNote);

    setState(() {
      _isLoading = false;
    });
  }

  /// =========================
  /// SAVE NOTE
  /// =========================
  void _saveNote() async {
    var box = await Hive.openBox('notes_box');

    final content = jsonEncode(_controller.document.toDelta().toJson());

    await box.put('rich_note_content', content);
  }

  @override
  void dispose() {
    _controller.removeListener(_saveNote);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("NoteDown (Rich Editor)"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          /// TOOLBAR
          QuillSimpleToolbar(
            controller: _controller,
            config: const QuillSimpleToolbarConfig(
              showFontSize: true,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showColorButton: true,
              showBackgroundColorButton: true,
              showAlignmentButtons: true,
              showClearFormat: true,
              multiRowsDisplay: false,
            ),
          ),

          const Divider(height: 1),

          /// EDITOR
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: QuillEditor.basic(
                controller: _controller,
                config: const QuillEditorConfig(
                  placeholder:
                      "Likhiye aur text select karke style badaliye...",
                  expands: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
