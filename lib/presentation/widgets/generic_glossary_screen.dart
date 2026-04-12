import 'package:flutter/material.dart';

import '../../core/collection/collection_summary.dart';
import '../../core/collection/collection_tracking_service.dart';

class GenericGlossaryScreen<T> extends StatefulWidget {
  final String title;
  final String searchHint;
  final Future<List<T>> future;
  final List<T> Function(List<T> items, String query) filterAndSort;
  final Widget Function(BuildContext context, T item, int collectedCount)
  itemBuilder;
  final String Function(int count) countLabelBuilder;
  final String emptyMessage;
  final String errorPrefix;
  final List<Widget> Function(BuildContext context, List<T> items)?
  headerControlsBuilder;
  final int Function(T item, Map<String, int> collectedByItemId)?
  collectedCountBuilder;

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
    this.collectedCountBuilder,
  });

  @override
  State<GenericGlossaryScreen<T>> createState() =>
      _GenericGlossaryScreenState<T>();
}

class _GenericGlossaryScreenState<T> extends State<GenericGlossaryScreen<T>> {
  final TextEditingController _searchController = TextEditingController();
  final CollectionTrackingService _collectionTracking =
      CollectionTrackingService();
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
      body: FutureBuilder<_GenericGlossaryData<T>>(
        future: _loadData(),
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

          final data =
              snapshot.data ??
              const _GenericGlossaryData(items: [], collectedByItemId: {});
          final items = data.items;
          final filtered = widget.filterAndSort(items, _query);
          final headerControls =
              widget.headerControlsBuilder?.call(context, items) ??
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
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final collectedCount =
                              widget.collectedCountBuilder?.call(
                                item,
                                data.collectedByItemId,
                              ) ??
                              0;
                          return widget.itemBuilder(
                            context,
                            item,
                            collectedCount,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_GenericGlossaryData<T>> _loadData() async {
    final results = await Future.wait([
      widget.future,
      _collectionTracking.loadSummaries(),
    ]);

    final summaries = results[1] as List<CollectionSummary>;
    final collectedByItemId = <String, int>{};
    for (final summary in summaries) {
      collectedByItemId[summary.latestEntry.itemId] =
          (collectedByItemId[summary.latestEntry.itemId] ?? 0) + summary.count;
    }

    return _GenericGlossaryData(
      items: results[0] as List<T>,
      collectedByItemId: collectedByItemId,
    );
  }
}

class _GenericGlossaryData<T> {
  final List<T> items;
  final Map<String, int> collectedByItemId;

  const _GenericGlossaryData({
    required this.items,
    required this.collectedByItemId,
  });
}
