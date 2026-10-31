import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class NgrokImage extends StatefulWidget {
  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const NgrokImage({super.key, required this.url, this.fit, this.width, this.height});

  @override
  State<NgrokImage> createState() => _NgrokImageState();
}

class _NgrokImageState extends State<NgrokImage> {
  Future<Uint8List>? _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _fetchImage(widget.url);
  }

  @override
  void didUpdateWidget(NgrokImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _imageFuture = _fetchImage(widget.url);
    }
  }

  Future<Uint8List> _fetchImage(String url) async {
    if (url.isEmpty) throw Exception('Empty URL');
    final response = await http.get(Uri.parse(url), headers: {'ngrok-skip-browser-warning': 'true'});
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Failed to load image');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(width: widget.width, height: widget.height, color: Colors.black26, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Container(width: widget.width, height: widget.height, color: Colors.black26, child: const Icon(Icons.image_not_supported, color: Colors.white24));
        }
        return Image.memory(snapshot.data!, fit: widget.fit, width: widget.width, height: widget.height);
      },
    );
  }
}
