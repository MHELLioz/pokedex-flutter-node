class Pokemon {
  final int id;
  final String name;
  final String imageUrl;

  Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  // Este 'factory' transforma el JSON de internet en nuestro objeto Dart
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    // La API nos da algo como: "https://pokeapi.co/api/v2/pokemon/1/"
    final url = json['url'] as String;
    // Extraemos el número dividiendo la URL por las diagonales
    final parts = url.split('/');
    final idString = parts[parts.length - 2];
    final id = int.parse(idString);

    return Pokemon(
      id: id,
      // Capitalizamos la primera letra del nombre
      name: json['name'][0].toUpperCase() + json['name'].substring(1),
      // Usamos el ID para obtener el arte oficial en alta calidad
      imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png',
    );
  }
}