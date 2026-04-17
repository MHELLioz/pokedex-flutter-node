import 'package:flutter/material.dart';

class PokeballLoader extends StatefulWidget {
  const PokeballLoader({super.key});

  @override
  State<PokeballLoader> createState() => _PokeballLoaderState();
}

class _PokeballLoaderState extends State<PokeballLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Configuramos la animación para que dé una vuelta cada 2 segundos
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(); // El .repeat() hace que el giro sea infinito
  }

  @override
  void dispose() {
    _controller.dispose(); // Limpiamos la memoria al cerrar el widget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotationTransition(
        turns: _controller,
        // Aquí usamos un icono nativo de Flutter, pero luego puedes cambiarlo 
        // por un Image.asset('assets/pokeball.png') si descargas una imagen.
        child: const Icon(
          Icons.catching_pokemon, 
          color: Colors.red,
          size: 60,
        ),
      ),
    );
  }
}