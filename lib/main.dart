import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:typed_data';

Database? _appDatabase;

Future<void> _initAppDatabase() async {
  final dbPath = await getApplicationDocumentsDirectory();
  final path = "${dbPath.path}/quicknotes.db";
  _appDatabase = await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {

      await db.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          username TEXT UNIQUE,
          password_hash TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE notes (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          title TEXT,
          content TEXT,
          image_path TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          priority TEXT DEFAULT 'low',
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      
      if (oldVersion < 1 && newVersion >= 1) {
      }
    },
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initAppDatabase();

  final List<Map<String, dynamic>> users = await _appDatabase!.query('users');
  final bool hasUsers = users.isNotEmpty;

  runApp(QuickNotesApp(initialScreen: hasUsers ? const LoginScreen() : const RegistrationScreen()));
}

enum NotePriority {
  low,
  medium,
  high,
}

extension NotePriorityExtension on NotePriority {
  String toDisplayString() {
    switch (this) {
      case NotePriority.low:
        return 'Niski';
      case NotePriority.medium:
        return 'Średni';
      case NotePriority.high:
        return 'Wysoki';
    }
  }

  Color toColor() {
    switch (this) {
      case NotePriority.low:
        return Colors.green;
      case NotePriority.medium:
        return Colors.orange;
      case NotePriority.high:
        return Colors.red;
    }
  }
}

String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

class QuickNotesApp extends StatelessWidget {
  final Widget initialScreen;

  const QuickNotesApp({required this.initialScreen, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickNotes',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: initialScreen,
    );
  }
}

// Login Screen 
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  void _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wprowadź nazwę użytkownika i hasło')),
      );
      return;
    }

    final hashedPassword = _hashPassword(password);

    final users = await _appDatabase!.query(
      'users',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, hashedPassword],
    );

    if (users.isNotEmpty) {
      final userId = users.first['id'] as String;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => NotesScreen(userId: userId)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nieprawidłowa nazwa użytkownika lub hasło')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickNotes - Logowanie'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: Tween(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: Image.asset('assets/logo.png', width: 150),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Witamy w QuickNotes',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Nazwa użytkownika'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Hasło'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _login,
                    child: const Text('Zaloguj się'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                      );
                    },
                    child: const Text('Zarejestruj się'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// Registration Screen 
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _register() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wypełnij wszystkie pola')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasła nie pasują do siebie')),
      );
      return;
    }

    final existingUsers = await _appDatabase!.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (existingUsers.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nazwa użytkownika już zajęta')),
      );
      return;
    }

    final hashedPassword = _hashPassword(password);
    final userId = const Uuid().v4();

    try {
      await _appDatabase!.insert('users', {
        'id': userId,
        'username': username,
        'password_hash': hashedPassword,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rejestracja zakończona sukcesem! Możesz się zalogować.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      print('Błąd rejestracji: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Błąd rejestracji. Spróbuj ponownie.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickNotes - Rejestracja'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Utwórz nowe konto',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Nazwa użytkownika'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Hasło'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(labelText: 'Potwierdź hasło'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _register,
                    child: const Text('Zarejestruj się'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

//  Pogoda OpenWeather
class WeatherService {
  final String apiKey = '7796e9a0ae7a39e864cb7d9ef16011cc'; // Klucz API
  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Map<String, dynamic>> getCurrentWeatherByCity(String city) async {
    final url = '$baseUrl?q=$city&appid=$apiKey&units=metric&lang=pl';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Błąd pobierania pogody dla $city: ${response.statusCode}, body: ${response.body}');
        return {'error': 'Błąd pobierania danych pogodowych dla $city: ${response.statusCode}'};
      }
    } catch (e) {
      print('Wystąpił błąd podczas żądania HTTP dla $city: $e');
      return {'error': 'Wystąpił błąd podczas pobierania pogody dla $city.'};
    }
  }
}


//  Notes Screen 
class NotesScreen extends StatefulWidget {
  final String userId;
  const NotesScreen({required this.userId, super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> _notes = [];
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  String? _weatherError;
  final TextEditingController _cityController = TextEditingController(text: 'Wrocław');

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadWeatherData();
  }

  Future<void> _loadNotes() async {
    final notes = await _appDatabase!.query( 
      'notes',
      where: 'user_id = ?',
      whereArgs: [widget.userId],
      orderBy: 'created_at DESC',
    );
    setState(() {
      _notes = notes;
    });
  }

  Future<void> _viewNote(Map<String, dynamic> note) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(note: note),
      ),
    );
  }

  Future<void> _addOrEditNote({Map<String, dynamic>? note}) async {
    final titleController = TextEditingController(text: note?['title'] ?? '');
    final contentController = TextEditingController(text: note?['content'] ?? '');
    String? imagePath = note?['image_path'];
    NotePriority selectedPriority = note != null && note['priority'] != null
        ? NotePriority.values.firstWhere((e) => e.toString().split('.').last == note['priority'],
          orElse: () => NotePriority.low)
        : NotePriority.low;

    final isNew = note == null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isNew ? 'Dodaj notatkę' : 'Edytuj notatkę'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Tytuł'),
                    ),
                    TextField(
                      controller: contentController,
                      decoration: const InputDecoration(labelText: 'Treść'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<NotePriority>(
                      value: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priorytet',
                        border: OutlineInputBorder(),
                      ),
                      items: NotePriority.values.map((priority) {
                        return DropdownMenuItem<NotePriority>(
                          value: priority,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: priority.toColor(),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(priority.toDisplayString()),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedPriority = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker(); 
                              final image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                final directory = await getApplicationDocumentsDirectory();
                                final filePath = '${directory.path}/${const Uuid().v4()}.png';
                                await File(image.path).copy(filePath);
                                setState(() {
                                  imagePath = filePath;
                                });
                              }
                            },
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Z galerii'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker(); 
                              final image = await picker.pickImage(source: ImageSource.camera);
                              if (image != null) {
                                final directory = await getApplicationDocumentsDirectory();
                                final filePath = '${directory.path}/${const Uuid().v4()}.png';
                                await File(image.path).copy(filePath);
                                setState(() {
                                  imagePath = filePath;
                                });
                              }
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Zrób zdjęcie'),
                          ),
                        ),
                      ],
                    ),
                    if (imagePath != null) ...[
                      const SizedBox(height: 16),
                      Image.file(File(imagePath!), height: 100),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Anuluj'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Zapisz'),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final content = contentController.text.trim();

                    if (title.isEmpty || content.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tytuł i treść nie mogą być puste')),
                      );
                      return;
                    }

                    final noteData = {
                      'title': title,
                      'content': content,
                      'image_path': imagePath,
                      'priority': selectedPriority.toString().split('.').last,
                      'user_id': widget.userId,
                    };

                    try {
                      if (isNew) {
                        noteData['id'] = const Uuid().v4();
                        await _appDatabase!.insert('notes', noteData);
                      } else {
                        await _appDatabase!.update(
                          'notes',
                          noteData,
                          where: 'id = ? AND user_id = ?',
                          whereArgs: [note!['id'], widget.userId],
                        );
                      }
                      await _loadNotes();
                      Navigator.of(context).pop();
                    } catch (e) {
                      print('Błąd bazy danych podczas zapisywania: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Wystąpił błąd podczas zapisywania notatki.')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadWeatherData() async {
    final city = _cityController.text.trim();
    if (city.isNotEmpty) {
      final weather = await _weatherService.getCurrentWeatherByCity(city);
      setState(() {
        if (weather.containsKey('error')) {
          _weatherError = weather['error'];
          _weatherData = null;
        } else {
          _weatherData = weather;
          _weatherError = null;
        }
      });
    } else {
      setState(() {
        _weatherError = 'Podaj nazwę miasta';
        _weatherData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickNotes'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeatherData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
            tooltip: 'Wyloguj',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'Miasto'),
              onSubmitted: (_) => _loadWeatherData(),
            ),
            const SizedBox(height: 16),
            if (_weatherData != null)
              Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pogoda w ${_weatherData!['name']}, ${_weatherData!['sys']['country']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Temperatura: ${_weatherData!['main']['temp']} °C',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Opis: ${_weatherData!['weather'][0]['description']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else if (_weatherError != null)
              Text('Błąd pobierania pogody: $_weatherError')
            else
              const Text('Wpisz miasto i naciśnij ikonę odświeżania'),
            Expanded(
              child: ListView.builder(
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  final notePriority = NotePriority.values.firstWhere(
                    (e) => e.toString().split('.').last == (note['priority'] ?? 'low'),
                    orElse: () => NotePriority.low,
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: note['image_path'] != null
                            ? Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(File(note['image_path'])),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : null,
                        title: Text(
                          note['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(note['content']),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: notePriority.toColor(),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Priorytet: ${notePriority.toDisplayString()}',
                                  style: TextStyle(
                                    color: notePriority.toColor(),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _addOrEditNote(note: note),
                        ),
                        onTap: () => _viewNote(note),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditNote(),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }
}

class NoteDetailScreen extends StatelessWidget {
  final Map<String, dynamic> note;

  const NoteDetailScreen({required this.note, super.key});

  @override
  Widget build(BuildContext context) {
    final notePriority = NotePriority.values.firstWhere(
      (e) => e.toString().split('.').last == (note['priority'] ?? 'low'),
      orElse: () => NotePriority.low,
    );

    return Scaffold(
      appBar: AppBar(title: Text(note['title'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note['image_path'] != null) Image.file(File(note['image_path'])),
            const SizedBox(height: 16),
            Text(note['content'], style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: notePriority.toColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Priorytet: ${notePriority.toDisplayString()}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: notePriority.toColor(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}