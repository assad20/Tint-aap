import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/app_preferences.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/search_cubit.dart';
import '../widgets/product_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _controller;
  late final AppPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _preferences = context.read<AppPreferences>();
    context.read<SearchCubit>().search('', preferences: _preferences);
  }

  @override
  Widget build(BuildContext context) {
    return TintPageScaffold(
      title: 'البحث',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            return Column(
              children: [
                TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) =>
                      context.read<SearchCubit>().search(value, preferences: _preferences),
                  decoration: InputDecoration(
                    hintText: 'ابحثي عن عطر، فستان، هدية...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: () {
                        _controller.clear();
                        context.read<SearchCubit>().clear();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_preferences.recentSearches.isNotEmpty) ...[
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'عمليات البحث الأخيرة',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _preferences.clearRecentSearches();
                          setState(() {});
                        },
                        child: const Text('مسح'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _preferences.recentSearches
                        .map(
                          (item) => ActionChip(
                            label: Text(item),
                            onPressed: () {
                              _controller.text = item;
                              context
                                  .read<SearchCubit>()
                                  .search(item, preferences: _preferences);
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          itemCount: state.results.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 260,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) {
                            return ProductCard(product: state.results[index]);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
