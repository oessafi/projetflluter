import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';

class VocalPage extends StatefulWidget {
  const VocalPage({super.key});

  @override
  State<VocalPage> createState() => _VocalPageState();
}

class _VocalPageState extends State<VocalPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = "Appuyez sur le micro pour parler...";
  String _assistantReply = "";
  
  // Ta clé API Gemini
  static const String _apiKey = 'AIzaSyBTQCNcOGMPZ0tlL8cPed2XMO2gfMs2J2o';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onError: (e) => print("Erreur micro: $e"),
        onStatus: (status) => print("Status micro: $status"),
      );
      
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: 'fr_FR',
          onResult: (result) async {
            setState(() {
              _recognizedText = result.recognizedWords;
              if (result.finalResult) {
                _assistantReply = "Je réfléchis...";
              }
            });

            if (result.finalResult) {
              final reply = await _askChatbot(result.recognizedWords);
              setState(() => _assistantReply = reply);
            }
          },
        );
      } else {
        setState(() => _recognizedText = "Micro non disponible.");
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<String> _askChatbot(String msg) async {
    if (msg.trim().isEmpty) return "Je n'ai rien entendu.";
    try {
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$_apiKey');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [{"text": "Réponds court en français à : $msg"}]
          }]
        }),
      );
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? "Pas de réponse.";
      }
      return "Erreur API (${resp.statusCode})";
    } catch (e) {
      return "Erreur connexion: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant IA')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16), 
                child: Text(
                  _recognizedText, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            if (_assistantReply.isNotEmpty)
              Card(
                color: Colors.deepPurple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16), 
                  child: Row(
                    children: [
                      const Icon(Icons.smart_toy, color: Colors.deepPurple),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_assistantReply)),
                    ],
                  ),
                ),
              ),
              
            const Spacer(),
            
            FloatingActionButton.large(
              onPressed: _toggleListening,
              backgroundColor: _isListening ? Colors.red : Theme.of(context).primaryColor,
              child: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(_isListening ? "J'écoute..." : "Appuyez pour parler"),
          ],
        ),
      ),
    );
  }
}