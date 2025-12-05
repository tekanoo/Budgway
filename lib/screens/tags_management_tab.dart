import 'package:flutter/material.dart';
import '../services/encrypted_budget_service.dart';
import '../services/data_update_bus.dart';
import 'dart:async';

class TagsManagementTab extends StatefulWidget {
  const TagsManagementTab({super.key});

  @override
  State<TagsManagementTab> createState() => _TagsManagementTabState();
}

class _TagsManagementTabState extends State<TagsManagementTab> {
  final EncryptedBudgetDataService _dataService = EncryptedBudgetDataService();
  List<String> tags = [];
  bool isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  // Mode sélection multiple
  bool _isSelectionMode = false;
  final Set<String> _selectedTags = {};
  bool _isBulkDeleting = false;
  StreamSubscription<String>? _busSub;

  @override
  void initState() {
    super.initState();
    _loadTags();
    _searchController.addListener(_onSearchChanged);
    _busSub = DataUpdateBus.stream.where((e) => e == 'tags' || e == 'all').listen((_) {
      if (!mounted) return;
      if (!isLoading) {
        _loadTags();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
  _busSub?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<String> get filteredTags {
    if (_searchQuery.isEmpty) {
      return tags;
    }
    return tags.where((tag) => tag.toLowerCase().contains(_searchQuery)).toList();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTags.clear();
      }
    });
  }

  void _toggleTagSelection(String tag) {
    if (!_isSelectionMode) return;
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _selectAllFiltered() {
    setState(() {
      final current = filteredTags;
      final allSelected = current.every(_selectedTags.contains);
      if (allSelected) {
        // Tout désélectionner
        for (final t in current) {
          _selectedTags.remove(t);
        }
      } else {
        // Tout sélectionner
        _selectedTags.addAll(current);
      }
    });
  }

  Future<void> _deleteSelectedTags() async {
    if (_selectedTags.isEmpty) return;
    setState(() { _isBulkDeleting = true; });
    try {
      // Compter les usages pour chaque tag sélectionné
      final Map<String, int> usage = {};
      for (final tag in _selectedTags) {
        usage[tag] = await _countTagUsage(tag);
      }

      if (!mounted) return;
      final totalUpdates = usage.values.fold<int>(0, (a,b)=>a+b);

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.delete_forever, color: Colors.red),
                const SizedBox(width: 8),
                Text('Supprimer ${_selectedTags.length} catégories'),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (totalUpdates > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$totalUpdates transaction${totalUpdates>1?'s':''} seront mises à jour vers "Sans catégorie".',
                              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: Scrollbar(
                      child: ListView(
                        children: usage.entries.map((e) => ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.indigo.shade100,
                            child: Text(e.key.isNotEmpty?e.key[0].toUpperCase():'?'),
                          ),
                          title: Text(e.key),
                          trailing: Text(
                            e.value>0 ? '${e.value}×' : '0',
                            style: TextStyle(color: e.value>0? Colors.orange.shade700: Colors.grey),
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Annuler')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: ()=>Navigator.pop(context,true),
                child: Text('Supprimer (${_selectedTags.length})'),
              ),
            ],
          );
        }
      );

      if (confirm == true) {
        // Construire nouvelle liste de tags
        final updated = [...tags]..removeWhere((t) => _selectedTags.contains(t));
        await _dataService.saveTags(updated);

        // Mettre à jour les transactions pour chaque tag utilisé
        for (final entry in usage.entries) {
          if (entry.value > 0) {
            await _updateTransactionsWithNewTag(entry.key, 'Sans catégorie');
          }
        }
        await _loadTags();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ ${_selectedTags.length} catégorie${_selectedTags.length>1?'s':''} supprimée${_selectedTags.length>1?'s':''}'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isSelectionMode = false;
          _selectedTags.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur suppression multiple: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isBulkDeleting = false; });
      }
    }
  }

  Future<void> _loadTags() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await _dataService.getTags();
      setState(() {
        // Tri alphabétique simple pour les tags
        tags = data..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement des catégories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addTag() async {
    final result = await _showTagDialog();
    if (result != null && result.isNotEmpty) {
      // Vérifier si le tag existe déjà
      if (tags.contains(result)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cette catégorie existe déjà'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      try {
        // Ajouter le nouveau tag
        final updatedTags = [...tags, result];
        await _dataService.saveTags(updatedTags);
        await _loadTags();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🏷️ Catégorie ajoutée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editTag(int index) async {
    final oldTag = tags[index];
    final result = await _showTagDialog(
      initialValue: oldTag,
      isEdit: true,
    );

    if (result != null && result != oldTag) {
      // Vérifier si le nouveau nom existe déjà
      if (tags.contains(result)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cette catégorie existe déjà'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      try {
        // Mettre à jour le tag
        final updatedTags = [...tags];
        updatedTags[index] = result;
        await _dataService.saveTags(updatedTags);

        // Mettre à jour toutes les transactions qui utilisent cet ancien tag
        await _updateTransactionsWithNewTag(oldTag, result);

        await _loadTags();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔄 Catégorie modifiée et transactions mises à jour'),
            backgroundColor: Colors.blue,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTag(int index) async {
    final tagToDelete = tags[index];
    
    // Compter les utilisations du tag
    final usageCount = await _countTagUsage(tagToDelete);
    
    // Ajouter une vérification mounted avant d'utiliser context
    if (!mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Supprimer la catégorie'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous vraiment supprimer la catégorie "$tagToDelete" ?'),
            const SizedBox(height: 12),
            if (usageCount > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cette catégorie est utilisée dans $usageCount transaction${usageCount > 1 ? 's' : ''}. '
                        'Ces transactions seront marquées comme "Sans catégorie".',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.green.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cette catégorie n\'est utilisée dans aucune transaction.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Supprimer le tag
        final updatedTags = [...tags];
        updatedTags.removeAt(index);
        await _dataService.saveTags(updatedTags);

        // Mettre à jour les transactions qui utilisent ce tag
        if (usageCount > 0) {
          await _updateTransactionsWithNewTag(tagToDelete, 'Sans catégorie');
        }

        await _loadTags();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              usageCount > 0 
                ? '🗑️ Catégorie supprimée et $usageCount transaction${usageCount > 1 ? 's' : ''} mise${usageCount > 1 ? 's' : ''} à jour'
                : '🗑️ Catégorie supprimée'
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showTagDialog({
    String? initialValue,
    bool isEdit = false,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isEdit ? Icons.edit : Icons.add,
              color: isEdit ? Colors.blue : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(isEdit ? 'Modifier la catégorie' : 'Ajouter une catégorie'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Nom de la catégorie',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
                helperText: 'Restaurant, Shopping, Loisirs...',
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context, value);
                }
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Les catégories vous aident à organiser vos dépenses',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text;
              if (value.isNotEmpty) {
                Navigator.pop(context, value);
              }
            },
            child: Text(isEdit ? 'Modifier' : 'Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<int> _countTagUsage(String tag) async {
    try {
      final plaisirs = await _dataService.getPlaisirs();
      return plaisirs.where((plaisir) => plaisir['tag'] == tag).length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _updateTransactionsWithNewTag(String oldTag, String newTag) async {
    try {
      // Mettre à jour les plaisirs/dépenses
      final plaisirs = await _dataService.getPlaisirs();
      bool needsUpdate = false;

      for (int i = 0; i < plaisirs.length; i++) {
        if (plaisirs[i]['tag'] == oldTag) {
          await _dataService.updatePlaisir(
            index: i,
            amountStr: plaisirs[i]['amount'].toString(), // Changed from amount to amountStr
            tag: newTag,
            date: DateTime.tryParse(plaisirs[i]['date'] ?? '') ?? DateTime.now(),
          );
          needsUpdate = true;
        }
      }

      if (needsUpdate && mounted) {
        // Recharger les données après mise à jour
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      // Vérifier que le widget est toujours monté avant d'utiliser context
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour des transactions: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des catégories...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // En-tête avec recherche
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade400, Colors.purple.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.tag,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gestion des Catégories',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${tags.length} catégorie${tags.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isSelectionMode) ...[
                      IconButton(
                        onPressed: _selectAllFiltered,
                        icon: Icon(
                          _selectedTags.length == filteredTags.length && filteredTags.isNotEmpty
                              ? Icons.select_all
                              : Icons.done_all,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: 'Tout sélectionner / désélectionner',
                      ),
                    ],
                    IconButton(
                      onPressed: _toggleSelectionMode,
                      icon: Icon(
                        _isSelectionMode ? Icons.close : Icons.checklist,
                        color: Colors.white,
                        size: 26,
                      ),
                      tooltip: _isSelectionMode ? 'Quitter la sélection multiple' : 'Sélection multiple',
                    ),
                    IconButton(
                      onPressed: _addTag,
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                      tooltip: 'Ajouter une catégorie',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une catégorie...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.white.withValues(alpha: 0.7)),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.2),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                if (_isSelectionMode) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedTags.isEmpty
                              ? 'Touchez pour sélectionner des catégories'
                              : '${_selectedTags.length} sélectionnée${_selectedTags.length>1?'s':''}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ),
                      if (_selectedTags.isNotEmpty)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: _isBulkDeleting ? null : _deleteSelectedTags,
                          icon: _isBulkDeleting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.delete_forever),
                          label: Text(_isBulkDeleting ? 'Suppression...' : 'Supprimer'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Liste des tags
          Expanded(
            child: filteredTags.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.tag,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _searchQuery.isNotEmpty 
                              ? 'Aucune catégorie trouvée'
                              : 'Aucune catégorie créée',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Essayez un autre terme de recherche'
                              : 'Ajoutez votre première catégorie pour organiser vos dépenses',
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: _addTag,
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter une catégorie'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTags,
                    child: ListView.builder(
                      itemCount: filteredTags.length,
                      itemBuilder: (context, index) {
                        final tag = filteredTags[index];
                        final actualIndex = tags.indexOf(tag);
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: _isSelectionMode
                                ? Checkbox(
                                    value: _selectedTags.contains(tag),
                                    onChanged: (_) => _toggleTagSelection(tag),
                                  )
                                : CircleAvatar(
                                    backgroundColor: Colors.indigo.shade100,
                                    child: Text(
                                      tag.isNotEmpty ? tag[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        color: Colors.indigo.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                            title: Text(
                              tag,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: FutureBuilder<int>(
                              future: _countTagUsage(tag),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                return Text(
                                  count > 0 
                                      ? 'Utilisé dans $count transaction${count > 1 ? 's' : ''}'
                                      : 'Non utilisé',
                                  style: TextStyle(
                                    color: count > 0 ? Colors.green.shade600 : Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!_isSelectionMode) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editTag(actualIndex),
                                    tooltip: 'Modifier',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteTag(actualIndex),
                                    tooltip: 'Supprimer',
                                  ),
                                ] else ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    _selectedTags.contains(tag)
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: _selectedTags.contains(tag) ? Colors.indigo : Colors.grey,
                                  ),
                                ],
                              ],
                            ),
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleTagSelection(tag);
                              } else {
                                _editTag(actualIndex);
                              }
                            },
                            onLongPress: () {
                              if (!_isSelectionMode) {
                                _toggleSelectionMode();
                                _toggleTagSelection(tag);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}