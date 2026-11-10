
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const NekoApp());
}

class NekoApp extends StatelessWidget {
  const NekoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Neko AI Studio',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF100C18),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB66CFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const StudioHome(),
    );
  }
}

class StudioHome extends StatefulWidget {
  const StudioHome({super.key});

  @override
  State<StudioHome> createState() => _StudioHomeState();
}

class _StudioHomeState extends State<StudioHome> {
  final prompt = TextEditingController();
  final negative = TextEditingController();
  final picker = ImagePicker();

  static const String apiUrl =
      'https://neko-ai-backend.closerskusuo.workers.dev/generate';

  int tab = 0;
  String style = 'Anime';
  String ratio = '1:1';
  XFile? sourceImage;
  bool loading = false;
  String? errorMessage;
  List<int>? generatedImage;

  Future<void> chooseImage() async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      setState(() => sourceImage = image);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> generateImage() async {
    if (prompt.text.trim().isEmpty) {
      showMessage('Isi prompt terlebih dahulu!');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
      generatedImage = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'prompt': prompt.text.trim(),
              'negativePrompt': negative.text.trim(),
              'style': style,
              'ratio': ratio,
            }),
          )
          .timeout(const Duration(seconds: 180));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 ||
          data['success'] != true ||
          data['image'] == null) {
        throw Exception(
          data['error'] ?? 'Gagal menghasilkan gambar.',
        );
      }

      setState(() {
        generatedImage = base64Decode(data['image']);
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    prompt.dispose();
    negative.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = tab == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFD49BFF)),
            SizedBox(width: 9),
            Text(
              'NEKO AI STUDIO',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => showMessage('Riwayat segera hadir!'),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF48255F),
                    Color(0xFF191523),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF704A91),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IMAGINATION STARTS HERE',
                    style: TextStyle(
                      color: Color(0xFFE3BFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Create something\namazing.',
                    style: TextStyle(
                      fontSize: 29,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your personal anime AI studio.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Generate'),
                  icon: Icon(Icons.auto_awesome),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Edit'),
                  icon: Icon(Icons.edit),
                ),
              ],
              selected: {tab},
              onSelectionChanged: (value) {
                setState(() => tab = value.first);
              },
            ),
            const SizedBox(height: 18),
            if (editing) ...[
              const Text(
                'EDIT MODE BELUM TERSEDIA',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Backend saat ini mendukung text-to-image. '
                'Fitur edit gambar akan ditambahkan nanti.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'PROMPT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: prompt,
              minLines: 4,
              maxLines: 7,
              decoration: InputDecoration(
                hintText: 'Describe your dream anime character...',
                filled: true,
                fillColor: const Color(0xFF20192A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'NEGATIVE PROMPT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: negative,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'blurry, low quality, extra fingers...',
                filled: true,
                fillColor: const Color(0xFF20192A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ART STYLE',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in [
                  'Anime',
                  'Manga',
                  'Chibi',
                  'Fantasy',
                  'Realistic anime',
                ])
                  ChoiceChip(
                    label: Text(item),
                    selected: style == item,
                    onSelected: (_) {
                      setState(() => style = item);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'IMAGE RATIO',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final item in [
                  '1:1',
                  '3:4',
                  '4:3',
                  '9:16',
                  '16:9',
                ])
                  ChoiceChip(
                    label: Text(item),
                    selected: ratio == item,
                    onSelected: (_) {
                      setState(() => ratio = item);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: loading || editing ? null : generateImage,
                icon: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  loading ? 'GENERATING...' : 'GENERATE IMAGE',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9855D5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 18),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
            if (generatedImage != null) ...[
              const SizedBox(height: 22),
              const Text(
                'GENERATED IMAGE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.memory(
                  generatedImage!,
                  fit: BoxFit.contain,
                ),
              ),
            ],
            const SizedBox(height: 18),
            const Text(
              'NEKO AI STUDIO • EARLY DEVELOPMENT',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white38,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
