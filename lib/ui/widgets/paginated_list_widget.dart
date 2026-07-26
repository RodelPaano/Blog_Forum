import 'package:flutter/material.dart';

class PaginatedList<T> extends StatefulWidget {
  const PaginatedList({
    super.key,
    required this.items,
    required this.builder,
    required this.loadInitialData,
    this.emptyMessage = 'No items yet.',
    this.floatingActionButton,
    this.appBar,
    this.shrinkWrap = false,
    this.padding,
  });

  final List<T> items;
  final Future<void> Function() loadInitialData;
  final Widget Function(BuildContext context, T item, int index, int total)
  builder;
  final String emptyMessage;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;

  @override
  State<PaginatedList<T>> createState() => _PaginatedListState<T>();
}

class _PaginatedListState<T> extends State<PaginatedList<T>> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await widget.loadInitialData();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      floatingActionButton: widget.floatingActionButton,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    final items = widget.items;

    if (items.isEmpty) {
      return Center(
        child: Text(
          widget.emptyMessage,
          style: TextStyle(color: Theme.of(context).disabledColor),
        ),
      );
    }

    return ListView.builder(
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return widget.builder(context, items[index], index, items.length);
      },
    );
  }
}
