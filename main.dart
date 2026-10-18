import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:video_player/video_player.dart';

void main() => runApp(const EditorApp());

class EditorApp extends StatelessWidget {
  const EditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Video Editor Pro',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101018),
        useMaterial3: true,
      ),
      home: const EditorHome(),
    );
  }
}

class EditorHome extends StatefulWidget {
  const EditorHome({super.key});

  @override
  State<EditorHome> createState() => _EditorHomeState();
}

class _EditorHomeState extends State<EditorHome> {
  VideoPlayerController? _video;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _commandController = TextEditingController();
  String _status = 'वीडियो चुनें या एडिटिंग कमांड बोलें';
  String _language = 'hi_IN';
  bool _listening = false;
  double _brightness = 1.0;
  double _saturation = 1.0;
  double _blur = 0.0;
  String _lastCommand = '';

  @override
  void dispose() {
    _video?.dispose();
    _commandController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;

    await _video?.dispose();
    final controller = VideoPlayerController.file(File(result.files.single.path!));
    setState(() => _status = 'वीडियो लोड हो रहा है…');
    await controller.initialize();
    await controller.setLooping(true);
    if (!mounted) return;
    setState(() {
      _video = controller;
      _status = 'वीडियो तैयार है — नीचे कमांड दें';
    });
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final available = await _speech.initialize(
      onStatus: (status) {
        if (mounted && status != 'listening') setState(() => _listening = false);
      },
      onError: (error) {
        if (mounted) setState(() => _status = 'वॉइस इनपुट में समस्या: ${error.errorMsg}');
      },
    );
    if (!available) {
      setState(() => _status = 'इस डिवाइस पर वॉइस रिकग्निशन उपलब्ध नहीं है।');
      return;
    }
    setState(() {
      _listening = true;
      _status = 'सुन रहा हूँ… अब कमांड बोलें';
    });
    await _speech.listen(
      localeId: _language,
      onResult: (result) {
        _commandController.text = result.recognizedWords;
        if (result.finalResult) {
          setState(() => _listening = false);
          _applyCommand(result.recognizedWords);
        }
      },
    );
  }

  void _applyCommand(String raw) {
    final command = raw.toLowerCase();
    setState(() {
      _lastCommand = raw;
      if (command.contains('bright') || command.contains('ब्राइट') ||
          command.contains('উজ্জ্বল') || command.contains('चमक')) {
        _brightness = 1.25;
        _status = 'Preview brightness बढ़ाई गई।';
      } else if (command.contains('dark') || command.contains('डार्क') ||
          command.contains('অন্ধকার')) {
        _brightness = 0.75;
        _status = 'Preview brightness कम की गई।';
      } else if (command.contains('saturation') || command.contains('रंग') ||
          command.contains('colour') || command.contains('color') ||
          command.contains('রং')) {
        _saturation = 1.35;
        _status = 'Preview saturation बढ़ाई गई।';
      } else if (command.contains('blur') || command.contains('ब्लर') ||
          command.contains('ধোঁয়াশা') || command.contains('ধোঁয়াশা') ||
          command.contains('धुंधला')) {
        _blur = _blur == 0 ? 3 : 0;
        _status = 'Preview blur प्रभाव बदला गया। यह पूरे preview पर लागू है।';
      } else if (command.contains('play') || command.contains('चलाओ') ||
          command.contains('চালাও')) {
        _video?.value.isPlaying == true ? _video?.pause() : _video?.play();
        _status = 'वीडियो playback बदला गया।';
      } else if (command.contains('reset') || command.contains('रीसेट') ||
          command.contains('আগের মতো')) {
        _brightness = 1;
        _saturation = 1;
        _blur = 0;
        _status = 'Preview adjustments reset किए गए।';
      } else {
        _status = 'कमांड मिली। इस starter version में यह कमांड अभी समर्थित नहीं है।';
      }
    });
  }

  Widget _toolCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      color: const Color(0xFF1C1C2A),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFB8A2FF)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _video;
    Widget preview;
    if (controller != null && controller.value.isInitialized) {
      preview = AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: ClipRect(
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix(<double>[
              _saturation, 0, 0, 0, 0,
              0, _saturation, 0, 0, 0,
              0, 0, _saturation, 0, 0,
              0, 0, 0, 1, 0,
            ]),
            child: Opacity(
              opacity: 1,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
      );
    } else {
      preview = const SizedBox(
        height: 210,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined, size: 52, color: Colors.white38),
              SizedBox(height: 10),
              Text('अपना वीडियो यहाँ खोलें'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Video Editor Pro'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Voice language',
            icon: const Icon(Icons.translate),
            onSelected: (value) => setState(() => _language = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'hi_IN', child: Text('हिंदी')),
              PopupMenuItem(value: 'bn_IN', child: Text('বাংলা')),
              PopupMenuItem(value: 'en_US', child: Text('English')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A27),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                preview,
                if (controller != null && controller.value.isInitialized)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => setState(() {
                          controller.value.isPlaying ? controller.pause() : controller.play();
                        }),
                        icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                      Text('${controller.value.position.inSeconds}s / ${controller.value.duration.inSeconds}s'),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _pickVideo,
                          icon: const Icon(Icons.add),
                          label: const Text('वीडियो चुनें'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('AI कमांड', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _commandController,
            textInputAction: TextInputAction.send,
            onSubmitted: _applyCommand,
            decoration: InputDecoration(
              hintText: 'जैसे: कलर बढ़ाओ / background blur / রং সুন্দর করো',
              filled: true,
              fillColor: const Color(0xFF1C1C2A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              suffixIcon: IconButton(
                onPressed: () => _applyCommand(_commandController.text),
                icon: const Icon(Icons.send),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _toggleVoice,
            icon: Icon(_listening ? Icons.stop_circle : Icons.mic),
            label: Text(_listening ? 'सुनना बंद करें' : 'बोलकर कमांड दें'),
          ),
          const SizedBox(height: 8),
          Text(_status, style: const TextStyle(color: Colors.white70)),
          if (_lastCommand.isNotEmpty)
            Text('आखिरी कमांड: $_lastCommand', style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 18),
          Text('प्रो टूल्स (Preview)', style: Theme.of(context).textTheme.titleLarge),
          _toolCard(Icons.tune, 'Color Grading', 'Brightness और Saturation preview नियंत्रित करें', () {
            showModalBottomSheet(
              context: context,
              builder: (context) => StatefulBuilder(
                builder: (context, setSheetState) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Color Grading', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(children: [
                        const SizedBox(width: 100, child: Text('Brightness')),
                        Expanded(child: Slider(
                          min: 0.5, max: 1.5, value: _brightness,
                          onChanged: (v) {
                            setState(() => _brightness = v);
                            setSheetState(() {});
                          },
                        )),
                      ]),
                      Row(children: [
                        const SizedBox(width: 100, child: Text('Saturation')),
                        Expanded(child: Slider(
                          min: 0, max: 2, value: _saturation,
                          onChanged: (v) {
                            setState(() => _saturation = v);
                            setSheetState(() {});
                          },
                        )),
                      ]),
                      const Text('ये controls अभी preview prototype हैं; final export में लागू नहीं होते।',
                        style: TextStyle(color: Colors.white60)),
                    ],
                  ),
                ),
              ),
            );
          }),
          _toolCard(Icons.blur_on, 'Background Blur', 'Blur preview toggle — अभी पूरे preview पर', () {
            setState(() => _blur = _blur == 0 ? 3 : 0);
          }),
          _toolCard(Icons.content_cut, 'Trim & Split', 'अगले चरण में export-enabled timeline जोड़ी जाएगी', () {
            setState(() => _status = 'Trim/Split UI अगली build में जोड़ी जा सकती है।');
          }),
          _toolCard(Icons.subtitles, 'Auto Subtitles', 'AI speech-to-text service जोड़ना बाकी है', () {
            setState(() => _status = 'Auto subtitles के लिए online speech-to-text backend चाहिए।');
          }),
          const SizedBox(height: 16),
          const Text(
            'Prototype नोट: यह starter app है, तैयार production editor नहीं। AI cloud editing, असली subject/background segmentation, render/export, और सुरक्षित backend API अभी जोड़ने होंगे।',
            style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

