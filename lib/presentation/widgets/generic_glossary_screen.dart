import 'package:flutter/material.dart';

class GenericGlossaryScreen<T> extends StatefulWidget {
  final String title;
  final String searchHint;
  final Future<List<T>> future;
  final List<T> Function(List<T> items, String query) filterAndSort;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String Function(int count) countLabelBuilder;
  final String emptyMessage;
  final String errorPrefix;
  final List<Widget> Function(BuildContext context)? headerControlsBuilder;

  const GenericGlossaryScreen({
    super.key,
    required this.title,
    required this.searchHint,
    required this.future,
    required this.filterAndSort,
    required this.itemBuilder,
    required this.countLabelBuilder,
    required this.emptyMessage,
    required this.errorPrefix,
    this.headerControlsBuilder,
  });

  @override
  State<GenericGlossaryScreen<T>> createState() =>
      _GenericGlossaryScreenState<T>();
}

class _GenericGlossaryScreenState<T> extends State<GenericGlossaryScreen<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<T>>(
        future: widget.future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${widget.errorPrefix}\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final items = snapshot.data ?? <T>[];
          final filtered = widget.filterAndSort(items, _query);
          final headerControls = widget.headerControlsBuilder?.call(context) ??
              const <Widget>[];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear',
                                onPressed: _searchController.clear,
                                icon: const Icon(Icons.clear),
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    if (headerControls.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...headerControls,
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.countLabelBuilder(filtered.length),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            widget.emptyMessage,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        cacheExtent: 1200,
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            widget.itemBuilder(context, filtered[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
