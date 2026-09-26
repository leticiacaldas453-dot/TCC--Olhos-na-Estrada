import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoConnect = true;
  bool _soundAlerts = true;
  bool _highPrecisionGps = false;

  final List<Map<String, String>> _favorites = [
    {'name': 'Casa', 'address': 'Rua das Flores, 123'},
    {'name': 'Trabalho', 'address': 'Av. Paulista, 1000'},
    {'name': 'Academia', 'address': 'Rua Augusta, 500'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações & Histórico'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Conectividade ESP32'),
          SwitchListTile(
            title: const Text('Reconexão Automática'),
            subtitle: const Text('Conectar ao último dispositivo conhecido ao iniciar'),
            value: _autoConnect,
            activeTrackColor: Colors.indigo.withAlpha(100),
            activeThumbColor: Colors.indigo,
            onChanged: (bool value) {
              setState(() => _autoConnect = value);
            },
          ),
          SwitchListTile(
            title: const Text('Alertas Sonoros'),
            subtitle: const Text('Bipar no celular durante manobras críticas'),
            value: _soundAlerts,
            activeTrackColor: Colors.indigo.withAlpha(100),
            activeThumbColor: Colors.indigo,
            onChanged: (bool value) {
              setState(() => _soundAlerts = value);
            },
          ),
          
          const Divider(),
          _buildSectionHeader('Preferências de GPS'),
          SwitchListTile(
            title: const Text('GPS de Alta Precisão'),
            subtitle: const Text('Aumenta o consumo de bateria'),
            value: _highPrecisionGps,
            activeTrackColor: Colors.indigo.withAlpha(100),
            activeThumbColor: Colors.indigo,
            onChanged: (bool value) {
              setState(() => _highPrecisionGps = value);
            },
          ),

          const Divider(),
          _buildSectionHeader('Locais Favoritos'),
          ..._favorites.map((fav) => ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Icon(Icons.place, color: Colors.white, size: 20),
            ),
            title: Text(fav['name']!),
            subtitle: Text(fav['address']!),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                setState(() {
                  _favorites.remove(fav);
                });
              },
            ),
            onTap: () {
              // Poderia carregar o endereço para busca
            },
          )),
          ListTile(
            leading: const Icon(Icons.add, color: Colors.indigo),
            title: const Text('Adicionar novo favorito', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
            onTap: () {
              // Abrir diálogo para adicionar
            },
          ),

          const Divider(),
          _buildSectionHeader('Sobre'),
          const ListTile(
            title: Text('Versão do Aplicativo'),
            trailing: Text('1.0.0'),
          ),
          ListTile(
            title: const Text('Limpar Histórico de Buscas'),
            leading: const Icon(Icons.history),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Histórico limpo com sucesso!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
