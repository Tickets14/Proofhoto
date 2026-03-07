import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/proof_entry.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/utils/app_date_utils.dart';

class ProofThumbnail extends StatefulWidget {
  const ProofThumbnail({
    super.key,
    required this.entry,
    this.onTap,
    this.size = 100,
    this.showDateOverlay = true,
  });

  final ProofEntry entry;
  final VoidCallback? onTap;
  final double size;
  final bool showDateOverlay;

  @override
  State<ProofThumbnail> createState() => _ProofThumbnailState();
}

class _ProofThumbnailState extends State<ProofThumbnail> {
  File? _file;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ProofThumbnail old) {
    super.didUpdateWidget(old);
    if (old.entry.imagePath != widget.entry.imagePath) _load();
  }

  Future<void> _load() async {
    final f = await ImageUtils.fileFromRelativePath(widget.entry.imagePath);
    if (mounted) setState(() => _file = f);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Hero(
        tag: 'proof_${widget.entry.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: _file == null
                ? const _Placeholder()
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        _file!,
                        fit: BoxFit.cover,
                        cacheWidth: (widget.size * 2).toInt(),
                      ),
                      if (widget.showDateOverlay)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.65),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Text(
                              AppDateUtils.formatShortDate(
                                  widget.entry.completedAt),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }
}
