import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'format.dart';
import 'i18n.dart';
import 'models.dart';
import 'photo_store.dart';
import 'saved.dart';
import 'ui.dart';

/// Your notes on a place: free text, contacts and photos of documents.
/// Everything stays on this device; nothing is uploaded.
class NotesPage extends StatefulWidget {
  const NotesPage({super.key, required this.area});

  final Area area;

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  PlaceNotes? _notes;
  final _text = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    PlaceNotes.load(widget.area.id).then((n) {
      if (!mounted) return;
      _text.text = n.text;
      setState(() => _notes = n);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    final n = _notes;
    if (n != null && n.text != _text.text) {
      n.text = _text.text;
      n.save(widget.area.id);
    }
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final n = _notes;
    if (n == null) return;
    n.text = _text.text;
    await n.save(widget.area.id);
    if (mounted) setState(() {});
  }

  Future<void> _addContact([int? index]) async {
    final n = _notes!;
    final old = index == null ? null : n.contacts[index];
    final name = TextEditingController(text: old?.name);
    final role = TextEditingController(text: old?.role);
    final phone = TextEditingController(text: old?.phone);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(old == null ? t('Add a contact') : t('Edit contact')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: InputDecoration(labelText: t('Name')), autofocus: true),
            TextField(
              controller: role,
              decoration: InputDecoration(labelText: t('Who they are'), hintText: t('Seller, broker, lawyer…')),
            ),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: t('Phone')),
            ),
          ],
        ),
        actions: [
          if (old != null)
            TextButton(
              onPressed: () {
                n.contacts.removeAt(index!);
                Navigator.pop(context, true);
              },
              child: Text(t('Delete')),
            ),
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t('Save'))),
        ],
      ),
    );
    if (ok == true && (name.text.trim().isNotEmpty || phone.text.trim().isNotEmpty)) {
      final c = PlaceContact(name.text.trim(), phone.text.trim(), role: role.text.trim());
      if (old == null) {
        n.contacts.add(c);
      } else if (index! < n.contacts.length && identical(n.contacts[index], old)) {
        n.contacts[index] = c;
      }
    }
    if (ok == true) await _save();
  }

  Future<void> _addPhoto(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 70);
      if (file == null) return;
      final id = await PhotoStore.add(await file.readAsBytes());
      _notes!.photos.add(id);
      await _save();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(kIsWeb
            ? t('Could not keep the photo: the browser\'s storage may be full. The Android app has more room.')
            : t('Could not add the photo.')),
      ));
    }
  }

  Future<void> _removePhoto(String entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Delete this photo?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t('Delete'))),
        ],
      ),
    );
    if (ok != true) return;
    _notes!.photos.remove(entry);
    await PhotoStore.remove(entry.split('\t').first);
    await _save();
  }

  Future<void> _caption(int i) async {
    final n = _notes!;
    final parts = n.photos[i].split('\t');
    final ctl = TextEditingController(text: parts.length > 1 ? parts[1] : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('What is this document?')),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: InputDecoration(hintText: t('e.g. Sale deed, EC, khata, RTC')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t('Save'))),
        ],
      ),
    );
    if (ok != true) return;
    final cap = ctl.text.trim().replaceAll('\t', ' ');
    n.photos[i] = cap.isEmpty ? parts.first : '${parts.first}\t$cap';
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final n = _notes;
    return Scaffold(
      appBar: AppBar(title: Text(t('Notes: {place}', {'place': widget.area.name}))),
      body: n == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  t('Kept only on this device. Nothing here is uploaded or shared, and it is lost if you '
                      'uninstall the app or clear the browser\'s data.'),
                  style: muted,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _text,
                  minLines: 4,
                  maxLines: 12,
                  decoration: InputDecoration(
                    labelText: t('Notes'),
                    hintText: t('Asking price, plot number, road width, what the seller said…'),
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 800), _save);
                  },
                ),
                if (n.updated != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(t('Saved {date}', {'date': dayMonthYear(n.updated!)}), style: muted),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Text(t('Contacts'), style: theme.textTheme.titleMedium)),
                    TextButton.icon(
                      onPressed: () => _addContact(),
                      icon: const Icon(Icons.person_add_alt, size: 18),
                      label: Text(t('Add')),
                    ),
                  ],
                ),
                if (n.contacts.isEmpty) Text(t('Seller, broker or lawyer for this place.'), style: muted),
                for (var i = 0; i < n.contacts.length; i++)
                  Card.outlined(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(n.contacts[i].name.isEmpty ? n.contacts[i].phone : n.contacts[i].name),
                      subtitle: Text([n.contacts[i].role, if (n.contacts[i].name.isNotEmpty) n.contacts[i].phone]
                          .where((s) => s.isNotEmpty)
                          .join(' · ')),
                      trailing: n.contacts[i].phone.isEmpty
                          ? null
                          : IconButton(
                              tooltip: t('Call'),
                              icon: const Icon(Icons.call_outlined),
                              onPressed: () => launchUrl(
                                Uri(scheme: 'tel', path: n.contacts[i].phone.replaceAll(RegExp(r'[^\d+]'), '')),
                              ),
                            ),
                      onTap: () => _addContact(i),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Text(t('Document photos'), style: theme.textTheme.titleMedium)),
                    IconButton(
                      tooltip: t('Take a photo'),
                      icon: const Icon(Icons.photo_camera_outlined),
                      onPressed: () => _addPhoto(ImageSource.camera),
                    ),
                    IconButton(
                      tooltip: t('Choose from gallery'),
                      icon: const Icon(Icons.photo_library_outlined),
                      onPressed: () => _addPhoto(ImageSource.gallery),
                    ),
                  ],
                ),
                if (n.photos.isEmpty)
                  Text(t('Photos of the sale deed, EC, khata or RTC, to check later or show a lawyer.'), style: muted),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (var i = 0; i < n.photos.length; i++)
                      _Thumb(
                        entry: n.photos[i],
                        onOpen: (bytes) => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => _PhotoView(bytes: bytes, caption: _captionOf(n.photos[i])),
                        )),
                        onCaption: () => _caption(i),
                        onDelete: () => _removePhoto(n.photos[i]),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

String? _captionOf(String entry) {
  final parts = entry.split('\t');
  return parts.length > 1 ? parts[1] : null;
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.entry, required this.onOpen, required this.onCaption, required this.onDelete});

  final String entry;
  final void Function(Uint8List bytes) onOpen;
  final VoidCallback onCaption;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = _captionOf(entry);
    return FutureBuilder<Uint8List?>(
      future: PhotoStore.read(entry.split('\t').first),
      builder: (context, snap) {
        final bytes = snap.data;
        return InkWell(
          onTap: bytes == null ? null : () => onOpen(bytes),
          onLongPress: () => showModalBottomSheet<void>(
            context: context,
            builder: (context) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ListTile(
                  leading: const Icon(Icons.label_outline),
                  title: Text(t('Name this document')),
                  onTap: () {
                    Navigator.pop(context);
                    onCaption();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(t('Delete')),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
              ]),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (bytes != null)
                  Image.memory(bytes, fit: BoxFit.cover, cacheWidth: 300)
                else
                  ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: snap.connectionState == ConnectionState.done
                        ? const Icon(Icons.broken_image_outlined)
                        : const SizedBox.shrink(),
                  ),
                if (caption != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ColoredBox(
                      color: Colors.black54,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PhotoView extends StatelessWidget {
  const _PhotoView({required this.bytes, this.caption});

  final Uint8List bytes;
  final String? caption;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(caption ?? ''),
        ),
        body: InteractiveViewer(maxScale: 6, child: Center(child: Image.memory(bytes))),
      );
}
