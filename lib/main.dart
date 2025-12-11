import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'note_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter());
  await Hive.openBox<Note>('notes');
  runApp(const NoteHubApp());
}

class NoteHubApp extends StatelessWidget {
  const NoteHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NoteHub',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1B1C1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F2022),
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final Box<Note> noteBox = Hive.box<Note>('notes');

  void addNote() {
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController();
        final contentController = TextEditingController();

        return AlertDialog(
          backgroundColor: const Color(0xFF26282B),
          title: const Text('Add Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Content'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty ||
                    contentController.text.isNotEmpty) {
                  final newNote = Note(
                    title: titleController.text,
                    content: contentController.text,
                    createdAt: DateTime.now(),
                    orderIndex: noteBox.length,
                  );
                  noteBox.add(newNote);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void reorderNotes(int oldIndex, int newIndex) async {
    final notes = noteBox.values.toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    if (newIndex > oldIndex) newIndex--;
    final movedNote = notes.removeAt(oldIndex);
    notes.insert(newIndex, movedNote);

    for (int i = 0; i < notes.length; i++) {
      notes[i].orderIndex = i;
      await notes[i].save();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NoteHub',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: noteBox.listenable(),
        builder: (context, Box<Note> box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text(
                "No notes yet — tap + to create one!",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          final notes = box.values.toList()
            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

          return ReorderableListView.builder(
            onReorder: reorderNotes,
            padding: const EdgeInsets.all(12),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                key: ValueKey(note.key),
                color: const Color(0xFF2B2D31),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    note.title.isEmpty ? "(Untitled)" : note.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoteDetailPage(note: note),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => note.delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addNote,
        shape: const CircleBorder(),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class NoteDetailPage extends StatelessWidget {
  final Note note;
  const NoteDetailPage({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(note.title.isEmpty ? "(Untitled)" : note.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          note.content,
          style: const TextStyle(fontSize: 16, height: 1.4),
        ),
      ),
    );
  }
}
