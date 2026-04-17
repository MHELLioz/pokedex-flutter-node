import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/pokemon_provider.dart';
import '../../../core/widgets/pokeball_loader.dart';
import '../../pokemon_detail/presentation/detail_screen.dart';
import '../../favorites/presentation/favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Pedimos los datos a la API en cuanto la pantalla carga
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PokemonProvider>().fetchPokemon();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Un gris muy claro y elegante
      appBar: AppBar(
        title: const Text(
          'PokéDex',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // Sidebar con opciones de navegación
      drawer: Drawer(
        child: Column(
          children: [
            // Encabezado del menú
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.redAccent),
              accountName: const Text("Entrenador Pokémon", style: TextStyle(fontWeight: FontWeight.bold)),
              // --- ACTUALIZADO: Aquí leemos el correo real de tu Provider ---
              accountEmail: Text(context.watch<PokemonProvider>().userEmail),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50, color: Colors.redAccent),
              ),
            ),
            // Opción: Inicio
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Inicio"),
              onTap: () => Navigator.pop(context), // Solo cierra el drawer
            ),
            // Opción: Favoritos
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text("Favoritos"),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                );
              },
            ),
            const Divider(),
            // Opción: Cerrar Sesión
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text("Cerrar Sesión"),
              onTap: () {
                // Aquí podrías limpiar el estado y volver al login
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
            ),
          ],
        ),
      ),
      body: Consumer<PokemonProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: PokeballLoader());
          }

          if (provider.filteredPokemonList.isEmpty && provider.pokemonList.isEmpty) {
            return const Center(child: Text('No hay Pokémon disponibles.'));
          }

          // Usamos una columna para poner la barra de búsqueda y luego la lista
          return Column(
            children: [
              // --- BARRA DE BÚSQUEDA ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (value) {
                    // Cada vez que el usuario teclea, le avisamos al Provider
                    provider.updateSearchQuery(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar Pokémon (ej. Pikachu o 25)',
                    prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none, // Quitamos la línea de borde
                    ),
                    // Sombra sutil
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                    ),
                  ),
                ),
              ),

              // --- CUADRÍCULA DE POKÉMON ---
              // Usamos Expanded para que la cuadrícula tome el resto de la pantalla
              Expanded(
                child: provider.filteredPokemonList.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontró ningún Pokémon 🤔',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        // ¡OJO AQUÍ! Ahora usamos la lista filtrada
                        itemCount: provider.filteredPokemonList.length,
                        itemBuilder: (context, index) {
                          final pokemon = provider.filteredPokemonList[index];
                          
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailScreen(pokemon: pokemon),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    bottom: -20,
                                    right: -20,
                                    child: CircleAvatar(
                                      radius: 70,
                                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Align(
                                          alignment: Alignment.topRight,
                                          child: Text(
                                            '#${pokemon.id.toString().padLeft(3, '0')}',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: Image.network(
                                              pokemon.imageUrl,
                                              fit: BoxFit.contain,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return const CircularProgressIndicator(
                                                  color: Colors.redAccent,
                                                  strokeWidth: 2,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            pokemon.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
}