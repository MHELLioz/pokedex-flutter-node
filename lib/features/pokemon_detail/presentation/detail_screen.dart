import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../pokedex/data/pokemon_model.dart';
import 'package:provider/provider.dart';
import '../../pokedex/data/pokemon_provider.dart';

class DetailScreen extends StatelessWidget {
  final Pokemon pokemon;

  const DetailScreen({super.key, required this.pokemon});

  Future<Map<String, dynamic>> fetchPokemonDetails() async {
    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon/${pokemon.id}/');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar detalles');
    }
  }

  // Función de ayuda para traducir y abreviar los nombres de los stats
  String _formatStatName(String rawName) {
    switch (rawName) {
      case 'hp': return 'HP';
      case 'attack': return 'Ataque';
      case 'defense': return 'Defensa';
      case 'special-attack': return 'Sp. Atk';
      case 'special-defense': return 'Sp. Def';
      case 'speed': return 'Velocidad';
      default: return rawName.toUpperCase();
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        // --- NUEVO: Botón de Favoritos en la esquina ---
        actions: [
          Consumer<PokemonProvider>(
            builder: (context, provider, child) {
              final isFav = provider.isFavorite(pokemon.id);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.yellowAccent : Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  provider.toggleFavorite(pokemon.id);
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchPokemonDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Icon(Icons.catching_pokemon, color: Colors.white, size: 60),
            );
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar datos', style: TextStyle(color: Colors.white)));
          }

          final data = snapshot.data!;
          final weight = data['weight'] / 10.0;
          final height = data['height'] / 10.0;
          final types = data['types'] as List;
          final stats = data['stats'] as List; // <-- Aquí sacamos los stats de la API

          return Column(
            children: [
              Text(
                pokemon.name,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                '#${pokemon.id.toString().padLeft(3, '0')}',
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              
              SizedBox(
                height: 200,
                child: Image.network(pokemon.imageUrl, fit: BoxFit.contain),
              ),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  // Agregamos SingleChildScrollView por si los datos no caben en la pantalla
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tipos
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: types.map<Widget>((t) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                t['type']['name'].toString().toUpperCase(),
                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 30),

                        // Peso y Altura
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoColumn('Peso', '$weight kg', Icons.monitor_weight_outlined),
                            _buildInfoColumn('Altura', '$height m', Icons.height),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // --- NUEVA SECCIÓN: Estadísticas Base ---
                        const Text(
                          'Estadísticas Base',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        
                        // Generamos las barras leyendo la lista de stats
                        ...stats.map<Widget>((s) {
                          return _buildStatRow(
                            _formatStatName(s['stat']['name']), 
                            s['base_stat'],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  // --- NUEVO WIDGET: Fila de la barra de progreso ---
  Widget _buildStatRow(String statName, int statValue) {
    // Calculamos el porcentaje para la barra (basado en un máximo general de 100 para que se vea bien)
    // Algunos Pokémon superan los 100, así que lo limitamos a 1.0 (100%) para que no rompa la barra
    double progress = statValue / 100.0;
    if (progress > 1.0) progress = 1.0; 

    // Cambiamos el color dependiendo de si es bajo (rojo) o bueno (verde)
    Color barColor = statValue < 50 ? Colors.redAccent : Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Nombre del stat (ancho fijo para que alineen bien)
          SizedBox(
            width: 80,
            child: Text(
              statName,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          // Valor numérico
          SizedBox(
            width: 40,
            child: Text(
              statValue.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          // Barra de progreso animada
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                color: barColor,
                minHeight: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}