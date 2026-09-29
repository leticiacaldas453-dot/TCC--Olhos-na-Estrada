import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ble_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'route_confirmation_screen.dart';
import 'settings_screen.dart';
import '../l10n/generated/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  List<String> _searchHistory = [];
  String _currentLocation = " ";
  List<Map<String, String>> _favorites = [];

  final List<String> _knownPlaces = [
    'Etec Bento Quirino',
    'Shopping Bandeiras',
    'Aeroporto de Congonhas',
  ];

  static const String _favoritesKey = 'favorites_list';
  static const String _historyKey = 'search_history';
  static const Color _primaryRed = Color(0xFFE10600);
  static const Color _textDark = Color(0xFF1F1F1F);
  static const Color _textGrey = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    BleManager.instance.init().then((_) {
      // Tenta reconectar ao último dispositivo
      _tryReconnect();
    });
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
    _fetchCurrentLocation();
    _loadFavorites();
    _loadHistory();
  }

  Future<void> _tryReconnect() async {
    print('>>> [BLE] Tentando reconectar ao último dispositivo...');
    final reconnected = await BleManager.instance.tryReconnect();
    if (reconnected && mounted) {
      print('>>> [BLE] Reconectado com sucesso!');
      setState(() {});
    } else {
      print('>>> [BLE] Não foi possível reconectar. Usuário deve conectar manualmente.');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ==================== HISTÓRICO ====================

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? history = prefs.getStringList(_historyKey);
    print('>>> [HISTORY] Carregando histórico: $history');
    if (history != null && mounted) {
      setState(() {
        _searchHistory = history;
      });
      print('>>> [HISTORY] Histórico carregado com sucesso! Total: ${_searchHistory.length}');
    } else {
      print('>>> [HISTORY] Nenhum histórico salvo.');
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // Salva apenas os 4 últimos destinos
    final limitedHistory = _searchHistory.take(4).toList();
    await prefs.setStringList(_historyKey, limitedHistory);
    print('>>> [HISTORY] Histórico salvo: $limitedHistory');
  }

  // ==================== FAVORITOS ====================

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString(_favoritesKey);
    if (favoritesJson != null) {
      final List<dynamic> decoded = jsonDecode(favoritesJson);
      setState(() {
        _favorites = decoded.map((item) => Map<String, String>.from(item)).toList();
      });
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoritesKey, jsonEncode(_favorites));
  }

  void _showAddFavoriteDialog({int? editIndex, required AppLocalizations t}) {
    final nameController = TextEditingController(
      text: editIndex != null ? _favorites[editIndex]['name'] : '',
    );
    final addressController = TextEditingController(
      text: editIndex != null ? _favorites[editIndex]['address'] : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(editIndex != null ? t.editFavorite : t.newFavorite),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: t.favoriteName,
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: t.favoriteAddress,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.cancel, style: const TextStyle(color: _textGrey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                final address = addressController.text.trim();
                if (name.isEmpty || address.isEmpty) return;
                setState(() {
                  if (editIndex != null) {
                    _favorites[editIndex] = {'name': name, 'address': address};
                  } else {
                    _favorites.add({'name': name, 'address': address});
                  }
                });
                _saveFavorites();
                Navigator.pop(context);
              },
              child: Text(editIndex != null ? t.save : t.add),
            ),
          ],
        );
      },
    );
  }

  void _removeFavorite(int index) {
    setState(() {
      _favorites.removeAt(index);
    });
    _saveFavorites();
  }

  // ==================== NAVEGAÇÃO ====================

  List<String> get _allSuggestions {
    final Set<String> set = {};
    set.addAll(_searchHistory);
    set.addAll(_favorites.map((f) => f['address']!));
    set.addAll(_knownPlaces);
    return set.toList();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final pm = placemarks.first;
        setState(() => _currentLocation = '${pm.street}, ${pm.subLocality}');
      }
    } catch (_) {}
  }

  void _navigateToConfirmation(String destination) {
    final query = destination.trim();
    if (query.isEmpty) return;
    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 4) _searchHistory.removeLast();
    });
    _saveHistory(); // <-- SALVA O HISTÓRICO
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RouteConfirmationScreen(destination: query)),
    );
  }

  // ==================== UI ====================

  Widget _buildHeader(AppLocalizations t, bool isConnected) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      decoration: const BoxDecoration(
        color: _primaryRed,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.two_wheeler, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                t.appTitle,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                  color: isConnected ? const Color(0xFF0D47A1) : Colors.white,
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(history: _searchHistory))),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(history: _searchHistory))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            t.whereTo,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Autocomplete<String>(
              optionsBuilder: (textValue) {
                if (textValue.text.isEmpty) return const Iterable<String>.empty();
                final query = textValue.text.toLowerCase();
                return _allSuggestions.where((opt) => opt.toLowerCase().contains(query));
              },
              onSelected: (selection) => _navigateToConfirmation(selection),
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) => _navigateToConfirmation(value),
                  decoration: InputDecoration(
                    hintText: t.typeDestination,
                    hintStyle: const TextStyle(color: _textGrey),
                    prefixIcon: const Icon(Icons.search, color: _primaryRed),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _primaryRed),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
        ),
      ],
    );
  }

  Widget _buildLocationCard(AppLocalizations t) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.my_location, color: _primaryRed),
        ),
        title: Text(t.yourLocation, style: const TextStyle(fontSize: 12, color: _textGrey)),
        subtitle: Text(
          _currentLocation.isEmpty ? t.locationNotFound : _currentLocation,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.refresh, color: _primaryRed),
          onPressed: _fetchCurrentLocation,
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(int index, AppLocalizations t) {
    final fav = _favorites[index];
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.star, color: Colors.amber),
        ),
        title: Text(fav['name']!, style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
        subtitle: Text(fav['address']!, style: const TextStyle(color: _textGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () => _navigateToConfirmation(fav['address']!),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
              onPressed: () => _showAddFavoriteDialog(editIndex: index, t: t),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () => _removeFavorite(index),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ValueListenableBuilder<bool>(
      valueListenable: BleManager.instance.connectionNotifier,
      builder: (context, isConnected, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) =>
                      CustomPaint(
                          painter: LinhaSPainter(progresso: _animation.value)),
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(t, isConnected),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(t.yourLocation, Icons.location_on),
                          const SizedBox(height: 8),
                          _buildLocationCard(t),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _buildSectionTitle(t.favorites, Icons.star),
                              ),
                              TextButton.icon(
                                onPressed: () => _showAddFavoriteDialog(t: t),
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(t.add),
                                style: TextButton.styleFrom(foregroundColor: _primaryRed),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (_favorites.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.star_border, size: 48,
                                      color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text(t.noFavorites, style: const TextStyle(
                                      color: _textGrey)),
                                  const SizedBox(height: 4),
                                  Text(t.clickToAdd, style: const TextStyle(
                                      color: _textGrey, fontSize: 12)),
                                ],
                              ),
                            )
                          else
                            ..._favorites
                                .asMap()
                                .entries
                                .map((entry) =>
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildFavoriteCard(entry.key, t),
                                )),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LinhaSPainter extends CustomPainter {
  final double progresso;
  LinhaSPainter({required this.progresso});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE10600).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;
    Path path = Path();
    path.moveTo(size.width / 2, size.height + 50);
    path.cubicTo(size.width * 0.2, size.height * 0.7, size.width * 0.8, size.height * 0.5, size.width * 0.5, size.height * 0.4);
    path.cubicTo(size.width * 0.3, size.height * 0.3, size.width * 0.6, size.height * 0.1, size.width * 0.5, size.height * 0.22);
    final metric = path.computeMetrics().first;
    Path pathAnimado = metric.extractPath(0.0, metric.length * progresso);
    canvas.drawPath(pathAnimado, paint);
  }
  @override
  bool shouldRepaint(covariant LinhaSPainter old) => old.progresso != progresso;
}