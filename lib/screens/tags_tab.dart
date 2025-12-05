import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TagsTab extends StatefulWidget {
  const TagsTab({super.key});

  @override
  State<TagsTab> createState() => _TagsTabState();
}

class _TagsTabState extends State<TagsTab> {
  List<String> tags = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTags = prefs.getStringList('tags') ?? [];
    setState(() {
      tags = storedTags;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tags'),
      ),
      body: tags.isEmpty
          ? const Center(child: Text('Aucun tag enregistré'))
          : ListView.builder(
              itemCount: tags.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(tags[index]),
                );
              },
            ),
    );
  }
}
