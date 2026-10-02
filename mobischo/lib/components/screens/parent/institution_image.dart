import 'package:flutter/material.dart';

class InstitutionImage extends StatefulWidget {
  final String? imageAsset;
  final String imageUrl;
  final String logoUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final double iconSize;

  const InstitutionImage({
    Key? key,
    this.imageAsset,
    required this.imageUrl,
    required this.logoUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.iconSize = 34,
  }) : super(key: key);

  @override
  State<InstitutionImage> createState() => _InstitutionImageState();
}

class _InstitutionImageState extends State<InstitutionImage> {
  int _urlIndex = 0;
  bool _advanceScheduled = false;
  bool _assetFailed = false;

  List<String> get _imageUrls {
    final urls = <String>[];
    for (final value in [widget.imageUrl, widget.logoUrl]) {
      final url = value.trim();
      final uri = Uri.tryParse(url);
      if (uri != null &&
          (uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host.isNotEmpty &&
          !urls.contains(url)) {
        urls.add(url);
      }
    }
    return urls;
  }

  @override
  void didUpdateWidget(covariant InstitutionImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.logoUrl != widget.logoUrl ||
        oldWidget.imageAsset != widget.imageAsset) {
      _urlIndex = 0;
      _advanceScheduled = false;
      _assetFailed = false;
    }
  }

  void _tryNetworkFallback() {
    if (_advanceScheduled) {
      return;
    }
    _advanceScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _assetFailed = true;
        _advanceScheduled = false;
      });
    });
  }

  void _tryNextUrl() {
    if (_advanceScheduled) {
      return;
    }
    _advanceScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _urlIndex++;
        _advanceScheduled = false;
      });
    });
  }

  Widget _placeholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color(0xffedf7f0),
      alignment: Alignment.center,
      child: Icon(
        Icons.account_balance_rounded,
        size: widget.iconSize,
        color: const Color(0xff3e9760),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = _imageUrls;
    final asset = widget.imageAsset?.trim() ?? '';
    if (asset.isNotEmpty && !_assetFailed) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _placeholder(),
            Image.asset(
              asset,
              fit: widget.fit,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) {
                  return child;
                }
                return const SizedBox.shrink();
              },
              errorBuilder: (context, error, stackTrace) {
                _tryNetworkFallback();
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      );
    }

    if (_urlIndex >= urls.length) {
      return _placeholder();
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _placeholder(),
          Image.network(
            urls[_urlIndex],
            key: ValueKey(urls[_urlIndex]),
            fit: widget.fit,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }
              return const SizedBox.shrink();
            },
            errorBuilder: (context, error, stackTrace) {
              _tryNextUrl();
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
