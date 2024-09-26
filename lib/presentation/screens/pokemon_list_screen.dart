import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/scroll_helper/visibility_detector.dart';
import '../bloc/pokemons_bloc/pokemon_bloc.dart';
import '../widgets/pokemon_error_widget.dart';
import '../widgets/shimmer_post.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/app_drawer.dart';
import 'pokemon_detail_screen.dart';

class PokemonListScreen extends StatefulWidget {
  @override
  _PokemonListScreenState createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool isLoadingMore = false;
  bool isLoadingPrevious = false;
  String? _lastVisiblePokemonName;

  @override
  void initState() {
    super.initState();
    context.read<PokemonBloc>().add(GetPokemonsEvent());
    _scrollController.addListener(_onScroll);
  }

  Future<void> _onScroll() async {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    if (currentScroll >= maxScroll && !isLoadingMore) {
      setState(() {
        isLoadingMore = true;
      });
      context.read<PokemonBloc>().add(LoadMorePokemonsEvent());
    }
    if (currentScroll <= 0.0 && !isLoadingPrevious) {
      setState(() {
        isLoadingPrevious = true;
      });
      context.read<PokemonBloc>().add(LoadPreviousPokemonsEvent());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text("Pokemons".toLowerCase().tr()),
      ),
      body: BlocConsumer<PokemonBloc, PokemonState>(
        listener: (context, state) {
          if (state is PokemonLoaded) {
            setState(() {
              isLoadingMore = false;
              isLoadingPrevious = false;
            });
            _scrollToSavedPosition(state);
          }
        },
        builder: (context, state) {
          if (state is PokemonLoading) {
            return ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) => ShimmerPostWidget(),
            );
          } else if (state is PokemonLoaded) {
            return _buildPokemonGrid(state);
          } else if (state is PokemonError) {
            return PokemonErrorWidget(message: state.message);
          } else {
            return Center(child: Text('Something went wrong.'.toLowerCase().tr()));
          }
        },
      ),
    );
  }

  Widget _buildPokemonGrid(PokemonLoaded state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final crossAxisCount = screenWidth < 600 ? 2 : 4;
        final childAspectRatio = screenWidth < 600 ? 3 / 4 : 2 / 3;
        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: GridView.builder(
            controller: _scrollController,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: state.hasReachedMax
                ? state.pokemons.length
                : state.pokemons.length + 1,
            itemBuilder: (context, index) {
              if (index < state.pokemons.length) {
                final pokemon = state.pokemons[index];
                return VisibilityDetector(
                  key: Key(pokemon.name),
                  onVisibilityChanged: (VisibilityInfo info) {
                    if (info.visibleFraction > 0.5 &&
                        _lastVisiblePokemonName != pokemon.name) {
                      _lastVisiblePokemonName = pokemon.name;
                      context.read<PokemonBloc>().add(SaveScrollPositionEvent(
                            pokemonName: pokemon.name,
                          ));
                    }
                  },
                  child: PokemonCard(
                    pokemon: pokemon,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PokemonDetailPage(pokemon: pokemon),
                      ),
                    ),
                  ),
                );
              } else {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  void _scrollToSavedPosition(PokemonLoaded state) {
    if (state.scrollPokemonName != null) {
      final index = state.pokemons.indexWhere((pokemon) => pokemon.name == state.scrollPokemonName);
      if (index != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            final itemPosition = index ~/ 2;
            _scrollController.jumpTo(itemPosition * (MediaQuery.of(context).size.width/2));
          }
        });
      }
    }
  }
}
