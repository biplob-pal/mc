import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:http/http.dart' as http;
import 'package:medicine_dispersor/services/database_service.dart';
import 'package:medicine_dispersor/models/medication.dart';

class ConnectivityScreen extends StatefulWidget {
  const ConnectivityScreen({super.key});

  @override
  State<ConnectivityScreen> createState() => _ConnectivityScreenState();
}

class _ConnectivityScreenState extends State<ConnectivityScreen> {
  bool _isWifiEnabled = false;
  List<WifiNetwork> _networks = [];
  String? _connectedSsid;
  String? _ip;
  bool _isSyncing = false;
  bool _isFetching = false;
  List<Medication>? _medications;

  final String _esp32Ip = '192.168.4.1';

  @override
  void initState() {
    super.initState();
    _checkWifiState();
    _getConnectedNetwork();
    _fetchMedications();
  }

  Future<void> _fetchMedications() async {
    setState(() {
      _isFetching = true;
    });

    try {
      final medications = await DatabaseService.getMedications();
      setState(() {
        _medications = medications;
        _isFetching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${medications.length} medication(s) loaded.')),
      );
    } catch (e) {
      setState(() {
        _isFetching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load medications: $e')),
      );
    }
  }

  Future<void> _checkWifiState() async {
    final isEnabled = await WiFiForIoTPlugin.isEnabled();
    setState(() {
      _isWifiEnabled = isEnabled;
    });
  }

  Future<void> _toggleWifi() async {
    await WiFiForIoTPlugin.setEnabled(!_isWifiEnabled);
    _checkWifiState();
  }

  Future<void> _scanNetworks() async {
    if (!_isWifiEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable Wi-Fi to scan for networks.')),
      );
      return;
    }
    final networks = await WiFiForIoTPlugin.loadWifiList();
    setState(() {
      _networks = networks;
    });
  }

  Future<void> _connectToNetwork(WifiNetwork network) async {
    if (network.ssid == null) return;

    final password = await _showPasswordDialog();
    if (password == null) return;

    final security = _getSecurityType(network.capabilities);
    await WiFiForIoTPlugin.connect(network.ssid!, password: password, security: security);
    _getConnectedNetwork();
  }

  NetworkSecurity _getSecurityType(String? capabilities) {
    if (capabilities == null) return NetworkSecurity.NONE;
    if (capabilities.contains('WPA')) return NetworkSecurity.WPA;
    if (capabilities.contains('WEP')) return NetworkSecurity.WEP;
    return NetworkSecurity.NONE;
  }

  Future<void> _getConnectedNetwork() async {
    final ssid = await WiFiForIoTPlugin.getSSID();
    final ip = await WiFiForIoTPlugin.getIP();
    setState(() {
      _connectedSsid = ssid;
      _ip = ip;
    });
  }

  Future<String?> _showPasswordDialog() {
    final passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Password'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, passwordController.text),
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _syncWithEsp32() async {
    if (_medications == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication data not loaded. Please fetch data first.')),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      final schedule = _medications!.map((m) => {
        'name': m.name,
        'dosage': m.dosage,
        'hour': m.time.hour,
        'minute': m.time.minute,
      }).toList();

      final response = await http.post(
        Uri.parse('http://$_esp32Ip/schedule'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'schedule': schedule}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully synced with ESP32.')),
        );
      } else {
        throw Exception('Failed to sync: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error syncing with ESP32: $e')),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connectivity'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWifiControls(),
            const SizedBox(height: 16),
            _buildConnectedInfo(),
            const SizedBox(height: 24),
            _buildDataFetchStatus(),
            const SizedBox(height: 16),
            _buildEsp32Sync(),
            const SizedBox(height: 16),
            Expanded(child: _buildNetworkList()),
          ],
        ),
      ),
    );
  }

    Widget _buildDataFetchStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_isFetching)
              const CircularProgressIndicator()
            else
              Expanded(
                child: Text(
                  _medications == null
                      ? 'Could not load medication data.'
                      : '${_medications!.length} medication(s) loaded.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isFetching ? null : _fetchMedications,
              tooltip: 'Reload Medication Data',
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildWifiControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Wi-Fi is ${_isWifiEnabled ? 'Enabled' : 'Disabled'}'),
        Switch(
          value: _isWifiEnabled,
          onChanged: (_) => _toggleWifi(),
        ),
        ElevatedButton.icon(
          onPressed: _scanNetworks,
          icon: const Icon(Icons.refresh),
          label: const Text('Scan'),
        ),
      ],
    );
  }

  Widget _buildConnectedInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Connected to: ${_connectedSsid ?? 'Not connected'}'),
        Text('IP Address: ${_ip ?? 'Unknown'}'),
      ],
    );
  }

  Widget _buildEsp32Sync() {
    final bool canSync = _medications != null && !_isSyncing;
    return ElevatedButton.icon(
      onPressed: canSync ? _syncWithEsp32 : null,
      icon: _isSyncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            )
          : const Icon(Icons.sync),
      label: Text(_isSyncing ? 'Syncing...' : 'Sync to ESP32'),
    );
  }

  Widget _buildNetworkList() {
    if (_networks.isEmpty) {
      return const Center(child: Text('No networks found. Press "Scan" to search for networks.'));
    }
    return ListView.builder(
      itemCount: _networks.length,
      itemBuilder: (context, index) {
        final network = _networks[index];
        return ListTile(
          title: Text(network.ssid ?? 'Unknown SSID'),
          subtitle: Text(network.capabilities ?? 'Unknown'),
          trailing: const Icon(Icons.wifi),
          onTap: () => _connectToNetwork(network),
        );
      },
    );
  }
}