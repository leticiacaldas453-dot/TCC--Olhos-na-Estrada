import 'package:flutter/material.dart';
import 'route_confirmation_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isScanning = false;
  bool _isConnected = false;
  String? _connectedDeviceName;
  final List<String> _foundDevices = [];
  
  // Simulação de endereço atual via GPS
  String _currentAddress = "Carregando localização...";

  @override
  void initState() {
    super.initState();
    _simulateGpsLocation();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _simulateGpsLocation() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _currentAddress = "Av. Paulista, 1000 - Bela Vista, São Paulo - SP";
      });
    }
  }

  void _toggleScan() async {
    setState(() {
      _isScanning = true;
      _foundDevices.clear();
    });

    // Simulação de busca Bluetooth
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _foundDevices.addAll(['ESP32-OLHOS-01', 'ESP32-OLHOS-02', 'ESP32-DISP-34']);
        _isScanning = false;
      });
    }
  }

  void _connectToDevice(String deviceName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Simulação de conexão
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      Navigator.pop(context); // Fecha o loading
      setState(() {
        _isConnected = true;
        _connectedDeviceName = deviceName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conectado a $deviceName')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Olhos na Estrada'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Ícone de status da conexão
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: _isConnected ? Colors.lightGreenAccent : Colors.white70,
            ),
          ),
          // Botão para abrir busca de dispositivos
          IconButton(
            icon: const Icon(Icons.bluetooth_searching),
            onPressed: _toggleScan,
            tooltip: 'Buscar Dispositivos',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de Busca de Endereço (Autocomplete Simulado)
              const Text(
                'Para onde vamos?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  // Simulação de sugestões do Google Places
                  return ['Parque do Ibirapuera', 'Aeroporto de Congonhas', 'Estação da Luz', 'Museu do Ipiranga'].where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RouteConfirmationScreen(destination: selection),
                    ),
                  );
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Digite o destino...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),

              // Card de Localização Atual
              const Text(
                'Sua localização atual',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.my_location, color: Colors.indigo),
                  title: Text(
                    _currentAddress,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text('Precisão GPS: Alta'),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      setState(() => _currentAddress = "Atualizando...");
                      _simulateGpsLocation();
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Lista de Dispositivos ESP32 (ListView.builder)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dispositivos Próximos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (_isScanning)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _foundDevices.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            _isScanning ? 'Buscando dispositivos...' : 'Nenhum dispositivo encontrado.\nToque no ícone de busca Bluetooth.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _foundDevices.length,
                        itemBuilder: (context, index) {
                          final device = _foundDevices[index];
                          final isThisConnected = _isConnected && _connectedDeviceName == device;
                          
                          return ListTile(
                            leading: Icon(
                              Icons.developer_board,
                              color: isThisConnected ? Colors.indigo : Colors.grey,
                            ),
                            title: Text(device),
                            subtitle: Text(isThisConnected ? 'Conectado' : 'Disponível'),
                            trailing: isThisConnected
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : ElevatedButton(
                                    onPressed: () => _connectToDevice(device),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Parear'),
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Atalho rápido: Exemplo, centrar no mapa ou comando de voz
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Atalho: Iniciando comando de voz...')),
          );
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.mic, color: Colors.white),
      ),
    );
  }
}
