import 'package:flutter/material.dart';
import 'admin_users_screen.dart';
import 'admin_featured_places_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  final VoidCallback onChanged;

  const AdminHomeScreen({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Panel de administrador',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.people, color: Color.fromARGB(255, 58, 71, 185)),
            title: const Text('Usuarios registrados'),
            subtitle: const Text('Ver quién se ha registrado en este dispositivo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.push_pin, color: Color(0xFF3AA6B9)),
            title: const Text('Lugares destacados'),
            subtitle: const Text(
                'Agregar o quitar lugares que verán todos los usuarios'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const AdminFeaturedPlacesScreen()),
              );
              onChanged();
            },
          ),
        ),
      ],
    );
  }
}
