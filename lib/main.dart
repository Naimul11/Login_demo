import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String kBaseUrl = "http://10.0.2.2:5000";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SU ERP Scraper',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  String? _name;
  String? _sid;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _name = null;
      _sid = null;
      _error = null;
    });

    try {
      final uri = Uri.parse("$kBaseUrl/api/login");
      final resp = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userid": _idCtrl.text.trim(),
          "password": _pwCtrl.text,
        }),
      );

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data["ok"] == true) {
        setState(() {
          _name = data["name"];
          _sid = data["sid"];
        });
      } else {
        setState(() {
          _error = data["error"] ?? "Login failed (HTTP ${resp.statusCode})";
        });
      }
    } catch (e) {
      setState(() => _error = "Network error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultCard = (_name != null && _sid != null)
        ? Card(
            color: Colors.white70,
            child: ListTile(
              title: Text("Name: $_name"),
              subtitle: Text("ID: $_sid"),
            ),
          )
        : (_error != null)
        ? Card(
            color: Colors.white70,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          )
        : const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(134, 180, 231, 255),
        title: const Text(
          "Login",
          style: TextStyle(
            color: Color.fromARGB(255, 0, 89, 183),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bd.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _idCtrl,
                          decoration: const InputDecoration(
                            labelText: "Email / Student ID",
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white70, 
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? "Required"
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pwCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white70,
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? "Required" : null,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _loading ? null : _login,
                            icon: _loading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: Text(_loading ? "Logging in..." : "Login"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  resultCard,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
