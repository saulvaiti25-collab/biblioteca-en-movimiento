import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const LibraryApp());

const _blue = Color(0xFF1E5E96);
const _navy = Color(0xFF102A43);
const _mint = Color(0xFFE8F4F2);

class LibraryApp extends StatefulWidget {
  const LibraryApp({super.key});

  @override
  State<LibraryApp> createState() => _LibraryAppState();
}

class _LibraryAppState extends State<LibraryApp> {
  Session? _session;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biblioteca en Movimiento',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _blue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: _navy,
        ),
      ),
      home: _session == null
          ? LoginScreen(
              onLogin: (session) => setState(() => _session = session),
            )
          : HomeScreen(
              session: _session!,
              onLogout: () => setState(() => _session = null),
            ),
    );
  }
}

class Api {
  static const _configured = String.fromEnvironment('API_URL');
  static String get baseUrl {
    if (_configured.isNotEmpty) return _configured;
    return kIsWeb ? Uri.base.origin : 'http://10.0.2.2:8000';
  }

  static Map<String, String> headers(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  static Future<dynamic> request(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    late http.Response response;
    switch (method) {
      case 'POST':
        response = await http.post(
          uri,
          headers: headers(token),
          body: jsonEncode(body),
        );
      case 'PUT':
        response = await http.put(
          uri,
          headers: headers(token),
          body: jsonEncode(body),
        );
      case 'DELETE':
        response = await http.delete(uri, headers: headers(token));
      default:
        response = await http.get(uri, headers: headers(token));
    }
    final decoded = response.body.isEmpty ? {} : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final message = decoded is Map && decoded['detail'] != null
          ? decoded['detail'].toString()
          : 'No se pudo completar la operación';
      throw Exception(message);
    }
    return decoded;
  }
}

class AppUser {
  final int id;
  final String name;
  final String username;
  final String role;
  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
  });
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as int,
    name: json['name'] as String,
    username: json['username'] as String,
    role: json['role'] as String,
  );
  String get roleLabel =>
      {
        'admin': 'Administrador',
        'bibliotecario': 'Bibliotecario',
        'estudiante': 'Estudiante',
      }[role] ??
      role;
}

class Session {
  final String token;
  final AppUser user;
  const Session(this.token, this.user);
}

class Book {
  final int id;
  final String title;
  final String author;
  final String category;
  final String? isbn;
  final String? coverUrl;
  final String? description;
  final bool available;
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    this.isbn,
    this.coverUrl,
    this.description,
    required this.available,
  });
  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'] as int,
    title: json['title'] as String,
    author: json['author'] as String,
    category: json['category'] as String,
    isbn: json['isbn'] as String?,
    coverUrl: json['cover_url'] as String?,
    description: json['description'] as String?,
    available: json['available'] == true || json['available'] == 1,
  );
}

class Loan {
  final int id;
  final String bookTitle;
  final String bookAuthor;
  final String userName;
  final String username;
  final String borrowedAt;
  final String dueAt;
  final String? returnedAt;
  const Loan({
    required this.id,
    required this.bookTitle,
    required this.bookAuthor,
    required this.userName,
    required this.username,
    required this.borrowedAt,
    required this.dueAt,
    this.returnedAt,
  });
  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
    id: json['id'] as int,
    bookTitle: json['book_title'] as String,
    bookAuthor: json['book_author'] as String,
    userName: json['user_name'] as String,
    username: json['username'] as String,
    borrowedAt: json['borrowed_at'] as String,
    dueAt: json['due_at'] as String,
    returnedAt: json['returned_at'] as String?,
  );
  bool get active => returnedAt == null;
}

class LoginScreen extends StatefulWidget {
  final ValueChanged<Session> onLogin;
  const LoginScreen({super.key, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController(text: 'estudiante');
  final _password = TextEditingController(text: 'Estu123!');
  bool _busy = false;
  bool _hidden = true;

  Future<void> _login() async {
    setState(() => _busy = true);
    try {
      final result = await Api.request(
        'POST',
        '/auth/login',
        body: {'username': _user.text.trim(), 'password': _password.text},
      );
      widget.onLogin(
        Session(
          result['token'] as String,
          AppUser.fromJson(Map<String, dynamic>.from(result['user'] as Map)),
        ),
      );
    } catch (error) {
      if (mounted) _message(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              elevation: 0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.local_library_rounded,
                      color: _blue,
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Biblioteca en Movimiento',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: _navy, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Accede al catálogo y administra préstamos.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _user,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _password,
                      obscureText: _hidden,
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hidden ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _hidden = !_hidden),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: _busy ? null : _login,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login),
                      label: const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Cuentas de prueba\nadmin / Admin123!\nbibliotecario / Biblio123!\nestudiante / Estu123!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Session session;
  final VoidCallback onLogout;
  const HomeScreen({super.key, required this.session, required this.onLogout});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    final staff = widget.session.user.role != 'estudiante';
    final pages = [
      CatalogPage(session: widget.session),
      LoansPage(session: widget.session),
      if (staff) SummaryPage(session: widget.session),
    ];
    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book),
        label: 'Catálogo',
      ),
      const NavigationDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment),
        label: 'Préstamos',
      ),
      if (staff)
        const NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Resumen',
        ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Biblioteca en Movimiento'),
            Text(
              '${widget.session.user.name} · ${widget.session.user.roleLabel}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        destinations: destinations,
        onDestinationSelected: (value) => setState(() => _tab = value),
      ),
    );
  }
}

class CatalogPage extends StatefulWidget {
  final Session session;
  const CatalogPage({super.key, required this.session});
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _search = TextEditingController();
  String _category = 'Todos';
  bool _loading = true;
  List<Book> _books = [];
  List<String> get _categories => [
    'Todos',
    ...{for (final book in _books) book.category},
  ];
  bool get _admin => widget.session.user.role == 'admin';
  bool get _staff => widget.session.user.role != 'estudiante';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final query = <String>[];
      if (_search.text.trim().isNotEmpty) {
        query.add('search=${Uri.encodeQueryComponent(_search.text.trim())}');
      }
      if (_category != 'Todos') {
        query.add('category=${Uri.encodeQueryComponent(_category)}');
      }
      final result = await Api.request(
        'GET',
        '/books${query.isEmpty ? '' : '?${query.join('&')}'}',
        token: widget.session.token,
      ) as List;
      if (mounted) {
        setState(
          () => _books = result
              .map((e) => Book.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList(),
        );
      }
    } catch (error) {
      if (mounted) _message(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
  Future<void> _openBook(Book book) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          BookSheet(book: book, session: widget.session, canLend: _staff),
    );
    await _load();
  }

  Future<void> _addBook() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddBookSheet(session: widget.session),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _admin
          ? FloatingActionButton.extended(
              onPressed: _addBook,
              icon: const Icon(Icons.add),
              label: const Text('Agregar libro'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Buscar por título, autor o categoría',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.search),
                ),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(item),
                          selected: _category == item,
                          onSelected: (_) {
                            setState(() => _category = item);
                            _load();
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_books.isEmpty)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(
                  child: Text('No encontramos libros con esos filtros.'),
                ),
              )
            else
              ..._books.map(
                (book) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BookCard(book: book, onTap: () => _openBook(book)),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  const BookCard({super.key, required this.book, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 76,
                color: _mint,
                child: book.coverUrl?.isNotEmpty == true
                    ? Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.menu_book, color: _blue),
                      )
                    : const Icon(Icons.menu_book, color: _blue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(book.author),
                    const SizedBox(height: 6),
                    Text(
                      book.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(book.available ? 'Disponible' : 'Prestado'),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: book.available
                      ? Colors.teal.shade800
                      : Colors.red.shade700,
                ),
                backgroundColor: book.available
                    ? const Color(0xFFDDF3EA)
                    : const Color(0xFFFDE8E7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookSheet extends StatefulWidget {
  final Book book;
  final Session session;
  final bool canLend;
  const BookSheet({
    super.key,
    required this.book,
    required this.session,
    required this.canLend,
  });
  @override
  State<BookSheet> createState() => _BookSheetState();
}

class _BookSheetState extends State<BookSheet> {
  final _borrower = TextEditingController(text: 'estudiante');
  final _days = TextEditingController(text: '14');
  bool _busy = false;

  bool get _admin => widget.session.user.role == 'admin';
  Future<void> _lend() async {
    setState(() => _busy = true);
    try {
      await Api.request(
        'POST',
        '/loans',
        token: widget.session.token,
        body: {
          'book_id': widget.book.id,
          'borrower_username': _borrower.text.trim(),
          'due_days': int.tryParse(_days.text) ?? 14,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préstamo registrado correctamente.')),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteBook() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar libro'),
        content: Text('¿Quieres eliminar “${widget.book.title}” del catálogo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await Api.request(
        'DELETE',
        '/books/${widget.book.id}',
        token: widget.session.token,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Libro eliminado del catálogo.')),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editBook() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddBookSheet(session: widget.session, book: widget.book),
    );
    // Al guardar, cerramos este detalle para que el catálogo cargue los datos
    // actualizados al volver a la pantalla principal.
    if (saved == true && mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _borrower.dispose();
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          22,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 110,
                  height: 150,
                  color: _mint,
                  child: book.coverUrl?.isNotEmpty == true
                      ? Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.menu_book,
                            size: 44,
                            color: _blue,
                          ),
                        )
                      : const Icon(Icons.menu_book, size: 44, color: _blue),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                book.title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: _navy),
              ),
              Text(book.author, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(book.available ? 'Disponible' : 'Prestado'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                book.description?.isNotEmpty == true
                    ? book.description!
                    : 'Sin descripción disponible.',
              ),
              if (_admin) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _editBook,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar libro'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _deleteBook,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar libro'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
              ],
              if (widget.canLend && book.available) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Registrar préstamo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _borrower,
                  decoration: const InputDecoration(
                    labelText: 'Usuario del estudiante',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _days,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Días de préstamo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _busy ? null : _lend,
                  icon: const Icon(Icons.assignment_turned_in),
                  label: const Text('Registrar préstamo'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AddBookSheet extends StatefulWidget {
  final Session session;
  final Book? book;
  const AddBookSheet({super.key, required this.session, this.book});
  @override
  State<AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends State<AddBookSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _category;
  late final TextEditingController _cover;
  late final TextEditingController _description;
  bool _busy = false;

  bool get _editing => widget.book != null;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _title = TextEditingController(text: book?.title ?? '');
    _author = TextEditingController(text: book?.author ?? '');
    _category = TextEditingController(text: book?.category ?? '');
    _cover = TextEditingController(text: book?.coverUrl ?? '');
    _description = TextEditingController(text: book?.description ?? '');
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await Api.request(
        _editing ? 'PUT' : 'POST',
        _editing ? '/books/${widget.book!.id}' : '/books',
        token: widget.session.token,
        body: {
          'title': _title.text.trim(),
          'author': _author.text.trim(),
          'category': _category.text.trim(),
          'cover_url': _cover.text.trim().isEmpty ? null : _cover.text.trim(),
          'description': _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
        },
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generateDescription() async {
    // Título, autor y categoría son necesarios para que la IA tenga contexto.
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final result = await Api.request(
        'POST',
        '/ai/book-description',
        token: widget.session.token,
        body: {
          'title': _title.text.trim(),
          'author': _author.text.trim(),
          'category': _category.text.trim(),
        },
      );
      if (mounted) {
        setState(
          () => _description.text = (result['description'] as String).trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['source'] == 'gemini'
                  ? 'Descripción generada con IA.'
                  : 'Gemini está ocupado: se creó un borrador automático que puedes editar.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _category.dispose();
    _cover.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        22,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _editing ? 'Editar libro' : 'Agregar libro',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: _navy),
              ),
              const SizedBox(height: 18),
              _field(_title, 'Título'),
              _field(_author, 'Autor'),
              _field(_category, 'Categoría'),
              _field(_cover, 'URL de portada (opcional)', required: false),
              OutlinedButton.icon(
                onPressed: _busy ? null : _generateDescription,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generar descripción con IA'),
              ),
              const SizedBox(height: 12),
              _field(
                _description,
                'Descripción generada (puedes editarla)',
                required: false,
                lines: 3,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(_editing ? 'Guardar cambios' : 'Guardar libro'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: lines,
      validator: required
          ? (value) =>
                value == null || value.trim().isEmpty ? 'Escribe $label' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

class LoansPage extends StatefulWidget {
  final Session session;
  const LoansPage({super.key, required this.session});
  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  bool _loading = true;
  List<Loan> _loans = [];
  bool get _staff => widget.session.user.role != 'estudiante';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await Api.request(
        'GET',
        '/loans',
        token: widget.session.token,
      ) as List;
      if (mounted) {
        setState(
          () => _loans = result
              .map((e) => Loan.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList(),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _returnLoan(Loan loan) async {
    try {
      await Api.request(
        'POST',
        '/loans/${loan.id}/return',
        token: widget.session.token,
        body: {},
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Devolución registrada.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _staff ? 'Préstamos registrados' : 'Mis préstamos',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: _navy, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_loans.isEmpty)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: Text('No hay préstamos para mostrar.')),
          )
        else
          ..._loans.map(
            (loan) => Card(
              elevation: 0,
              child: ListTile(
                leading: Icon(
                  loan.active ? Icons.assignment : Icons.assignment_turned_in,
                  color: loan.active ? _blue : Colors.teal,
                ),
                title: Text(loan.bookTitle),
                subtitle: Text(
                  '${loan.bookAuthor}\n${_staff ? '${loan.userName} (${loan.username})\n' : ''}Límite: ${_date(loan.dueAt)}',
                ),
                isThreeLine: _staff,
                trailing: loan.active && _staff
                    ? IconButton(
                        tooltip: 'Registrar devolución',
                        onPressed: () => _returnLoan(loan),
                        icon: const Icon(Icons.keyboard_return),
                      )
                    : Chip(label: Text(loan.active ? 'Activo' : 'Devuelto')),
              ),
            ),
          ),
        const SizedBox(height: 80),
      ],
    ),
  );
  String _date(String source) => source.replaceFirst('T', ' ').split('+').first;
}

class SummaryPage extends StatefulWidget {
  final Session session;
  const SummaryPage({super.key, required this.session});
  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  Map<String, dynamic>? _data;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await Api.request(
        'GET',
        '/dashboard',
        token: widget.session.token,
      );
      if (mounted) {
        setState(() => _data = Map<String, dynamic>.from(value as Map));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Resumen de biblioteca',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: _navy, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _metric(
            'Libros activos',
            data['total_books'],
            Icons.menu_book,
            _blue,
          ),
          _metric(
            'Préstamos activos',
            data['active_loans'],
            Icons.assignment,
            Colors.orange,
          ),
          _metric('Usuarios', data['users'], Icons.people, Colors.teal),
          _metric(
            'Atrasos',
            data['overdue_loans'],
            Icons.warning_amber,
            Colors.red,
          ),
          const SizedBox(height: 12),
          const Text(
            'Los datos se actualizan desde la API.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, dynamic value, IconData icon, Color color) =>
      Card(
        elevation: 0,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(icon, color: color),
          ),
          title: Text(label),
          trailing: Text(
            '$value',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
        ),
      );
}
