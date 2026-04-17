import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'pokemon_model.dart';

class PokemonProvider extends ChangeNotifier {
  List<Pokemon> _pokemonList = [];
  bool _isLoading = false;
  String _searchQuery = ''; 
  
  // Lista para guardar los IDs de los favoritos
  final List<int> _favoriteIds = [];

  // --- NUEVO: Variable para saber quién inició sesión ---
  String? _currentUserId;
  String? _currentUserEmail; // <-- 1. Agregamos esta variable

  // <-- 2. Agregamos este "getter" para poder leer el correo desde las pantallas
  String get userEmail => _currentUserEmail ?? 'Entrenador';

  bool get isLoading => _isLoading;
  List<Pokemon> get pokemonList => _pokemonList;

  // Getter para obtener solo los Pokémon favoritos
  List<Pokemon> get favoritePokemonList {
    return _pokemonList.where((p) => _favoriteIds.contains(p.id)).toList();
  }

  List<Pokemon> get filteredPokemonList {
    if (_searchQuery.isEmpty) {
      return _pokemonList;
    }
    return _pokemonList.where((pokemon) {
      final nameMatches = pokemon.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final idMatches = pokemon.id.toString() == _searchQuery;
      return nameMatches || idMatches;
    }).toList();
  }

  Future<void> fetchPokemon() async {
    _isLoading = true;
    notifyListeners(); 

    try {
      final url = Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=151');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        _pokemonList = results.map((json) => Pokemon.fromJson(json)).toList();
      } else {
        debugPrint('Error en la API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error de conexión: $e');
    }

    _isLoading = false;
    notifyListeners(); 
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners(); 
  }

  // --- NUEVO: Guarda los datos del usuario al hacer Login ---
  void setUser(String id, String email, List<dynamic> apiFavorites) {
    _currentUserId = id;
    _currentUserEmail = email; // <-- 4. Lo guardamos
    _favoriteIds.clear();
    _favoriteIds.addAll(apiFavorites.cast<int>());
    notifyListeners();
  }

  // Verifica si un Pokémon específico ya es favorito
  bool isFavorite(int id) {
    return _favoriteIds.contains(id);
  }

  // --- ACTUALIZADO: Agrega o quita conectándose al Backend ---
  Future<void> toggleFavorite(int id) async {
    // Si no hay nadie logueado, no hace nada
    if (_currentUserId == null) return;

    final isFav = _favoriteIds.contains(id);

    // 1. Cambio visual inmediato (Optimistic UI) para que el usuario no sienta lag
    if (isFav) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();

    // 2. Enviamos el cambio a tu servidor Node.js
    try {
      final url = Uri.parse('http://localhost:3000/api/favoritos');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _currentUserId,
          'pokemonId': id,
        }),
      );

      // Si el servidor falla, tiramos un error para que lo atrape el catch
      if (response.statusCode != 200) {
        throw Exception('El servidor no respondió con éxito');
      }
    } catch (e) {
      // 3. Si hubo un error (ej. se cayó el internet), revertimos el color del corazón
      debugPrint('Error de conexión con el backend: $e');
      if (isFav) {
        _favoriteIds.add(id);
      } else {
        _favoriteIds.remove(id);
      }
      notifyListeners();
    }
  }
}