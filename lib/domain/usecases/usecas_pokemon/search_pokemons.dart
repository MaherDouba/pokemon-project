import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/pokemon.dart';
import '../../repositories/pokemon_repository.dart';

class SearchPokemons {
  final PokemonRepository repository;

  SearchPokemons(this.repository);

  Future<Either<Failure, List<Pokemon>>> call(String query) async {
    return await repository.searchPokemons(query);
  }
}
