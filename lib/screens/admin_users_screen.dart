import 'package:flutter/material.dart';
import '../main.dart';
import '../models/user.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<AppUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await AppServices.instance.auth.getAllUsers();
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios registrados')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('Aún no hay usuarios.'))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final user = _users[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : '?'),
                      ),
                      title:
                          Text(user.name.isNotEmpty ? user.name : '(sin nombre)'),
                      subtitle: Text(user.email),
                      trailing: user.isAdmin
                          ? const Chip(
                              label: Text('Admin'),
                              visualDensity: VisualDensity.compact,
                            )
                          : null,
                    );
                  },
                ),
    );
  }
}
