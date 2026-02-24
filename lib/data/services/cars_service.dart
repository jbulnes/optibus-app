import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:intl/intl.dart';
import 'package:satelite_peru_mibus/data/global/environment.dart';
import 'package:satelite_peru_mibus/domains/models/autos_models/Auto.dart';
import 'package:satelite_peru_mibus/domains/models/autos_models/ReportsReponse.dart';
import 'package:satelite_peru_mibus/data/services/auth_service.dart';

class CarsService with ChangeNotifier {
  bool _isLoading = false;

  List<Auto> autos = [];
  List<Auto> autosHistorial = [];
  Map<String, String> autoAddresses = {};

  late Auto _selectedAuto;

  Auto get selectedAuto => _selectedAuto;

  // Método para establecer el auto seleccionado
  void setSelectedAuto(Auto auto) {
    _selectedAuto = auto;
    notifyListeners(); // Notificar a los escuchadores sobre el cambio
  }

  Future<void> getAutos(String idUsuario) async {
    _isLoading = true;

    final data = {'id_usuario': idUsuario};
    final apiUrl = await Environment.apiUrl; // Resuelve la URL correcta
    try {
      var url = Uri.parse('${apiUrl}api/cars/getAutos');
      final resp = await http.post(
        url,
        body: jsonEncode(data),
        headers: {"Content-Type": "application/json"},
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(resp.body);
        if (responseData['success']) {
          final List<dynamic> autosData = responseData['autos'];
          autos = autosData.map((data) => Auto.fromJson(data)).toList();
          print(' ********************************');
          print('🌈 ${autos.length}🌈🌈🌈🌈🌈🌈');
        } else {
          print('Error: ${responseData['message']}');
          autos = [];
        }
      } else {
        print('Error: ${resp.statusCode}');
        autos.clear();
      }
    } catch (e) {
      print('Error catch getAutos: $e');
      autos.clear();
    } finally {
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> getVehiculosWeb() async {
    _isLoading = true;
    notifyListeners();

    final apiUrl = await Environment.apiUrl;

    try {
      // 🔑 Obtener token guardado (ajusta según tu implementación)
      final token = await AuthService.getToken(); 
      print('FACTORIA getVehiculosWeb token: $token');

      final url = Uri.parse('${apiUrl}api/vehiculos');

      final resp = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(resp.body);

        if (responseData['success'] == true &&
            responseData['data'] is List) {

          final List<dynamic> vehiculosData = responseData['data'];
          print('✅ Vehículos recibidos: ${vehiculosData.length}');

          autos = vehiculosData.map((vehiculo) {
            print('✅ Vehículos recibidos: ${vehiculo}');
            final estado = vehiculo['vehiculoEstado'] ?? {};

            return Auto(
              idVehiculo: vehiculo['id'] ?? 0,
              placa: vehiculo['numeroPlaca'] ?? "",
              codigoInterno: vehiculo['padron'] ?? "",
              
              acc: estado['motorEncendido'] == true ? 1 : 0,
              velocidad: estado['velocidad'] ?? 0,
              terminal: estado['terminal'] ?? "",
              sentido: estado['sentido'] ?? vehiculo['sentido'] ?? "",
              
              kilometrajeAcum: (vehiculo['kilometrajeDia'] ?? 0).toDouble(),
              
              latitud: (estado['latitud'] ?? 0.0).toDouble(),
              longitud: (estado['longitud'] ?? 0.0).toDouble(),
              
              fecha: estado['actualizadoEn'] != null
                  ? DateTime.parse(estado['actualizadoEn'])
                  : DateTime.now(),
              
              fechaEncendido: estado['fechaEncendido'] != null
                  ? DateTime.parse(estado['fechaEncendido'])
                  : DateTime.now(),
              
              fechapagado: estado['fechaApagado'] != null
                  ? DateTime.parse(estado['fechaApagado'])
                  : DateTime.now(),
              
              kilometrajeAcumuladoAyer: 0.0, // no viene en API
              kilometrajeAcumuladoMes: 0.0,  // no viene en API
              
              direccionTramaActual: estado['address'],
              
              nombreConductor: 'Nombre Conductor', // no viene en API
              imagenConductor: null,
              
              imeil: vehiculo['imei'],
              sim: vehiculo['sim'],
              kmgalon: (vehiculo['kmGalon'] ?? 0).toDouble(),
            );
          }).toList();

          // 🔥 Ordenar igual que la web
          autos.sort((a, b) =>
              (a.placa ?? "").compareTo(b.placa ?? ""));

          print("✅ Vehículos cargados: ${autos.length}");
        } else {
          print("⚠️ Respuesta inválida: ${resp.body}");
          autos.clear();
        }
      } else if (resp.statusCode == 401 ||
                resp.statusCode == 403) {
        print("⛔ Token inválido o expirado");
        autos.clear();
        // Aquí puedes hacer logout automático
      } else {
        print("❌ Error HTTP: ${resp.statusCode}");
        autos.clear();
      }
    } catch (e) {
      print("💥 Error getVehiculosWeb: $e");
      autos.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> obtenerDireccion(double lat, double lon) async {
    try {
      // Define la URL y realiza la solicitud GET
      var url = Uri.parse(
          'http://ironmaps.com/nominatim/reverse.php?format=json&limit=1&lat=${lat}&lon=${lon}');
      final response = await http.get(url);

      // Verifica el código de estado de la respuesta
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'];
      } else {
        print('Error en la solicitud HTTP: ${response.statusCode}');
        return '';
      }
    } catch (e) {
      // Captura cualquier excepción que ocurra durante la solicitud
      print('Error al obtener la dirección: $e');
      return '';
    }
  }

  Future<void> getAddressesList() async {
    print('autos lenght ${autos.length}');

    for (var auto in autos) {
      if (auto.latitud != null && auto.longitud != null) {
        try {
          final address = await obtenerDireccion(auto.latitud!, auto.longitud!);
          print('🍺rakim ${auto.codigoInterno} ${auto.placa} $address');

          autoAddresses[auto.placa ?? ''] = '${address}';
          auto.direccionTramaActual = '${address}';
        } catch (e) {
          print('Error obteniendo la dirección: $e');
        }
      }
    }
    notifyListeners();
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // Radio de la Tierra en metros
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // Distancia en metros
  }

  Future<void> updateAutosWithData(Map<String, dynamic> data) async {
    print('🍺h🍺 recibido updateAutosWithData : ${data}');
    String plateStream = data["plate"];

    for (var auto in autos) {
      if (auto.placa == plateStream) {
        int accCapturador = data["accStatus"] == true ? 1 : 0;
        String terminalCapturador = data["terminal"] ?? "";
        String sentido = data["sense"] ?? "";
        double kilometrajeAcumCapturador = data["dailyMileage"]?.toDouble() ?? 0.0;
        // Obtener las nuevas coordenadas de la trama actual
        double latitudCapturador = data["latitude"] ?? 0.0;
        double longitudCapturador = data["longitude"] ?? 0.0;
        int velocidadCapturador = data["speed"] ?? 0;
        String fechaStr = data["timestamp"] ?? '';
        DateTime fechaCapturador = DateTime.parse(fechaStr);

        String formattedTime = DateFormat('HH:mm').format(fechaCapturador);

        DateTime now = DateTime.now();
        Duration difference = now.difference(fechaCapturador);

        // double latitudLast = auto.latitud ?? null;
        // double longitudLast = auto.longitud ?? null;

        // Actualizar las coordenadas y la fecha del auto
        auto.latitud = latitudCapturador;
        auto.longitud = longitudCapturador;
        auto.fecha = fechaCapturador;
        auto.fechaTramaActual = '$formattedTime Hr';
        auto.acc = accCapturador;
        auto.velocidad = velocidadCapturador;
        auto.terminal = terminalCapturador;
        auto.sentido = sentido;
        auto.kilometrajeAcum = kilometrajeAcumCapturador;
        auto.imeil = data["deviceId"];
        auto.direccionTramaActual = data["address"] ?? "";

        String fechaTramaActualStr;
        if (difference.inDays >= 1) {
          int days = difference.inDays;
          int hours = difference.inHours % 24;
          fechaTramaActualStr = '${days} D / ${hours} Hr';
          auto.fechaTramaActual = fechaTramaActualStr;
        }

        autoAddresses[auto.placa ?? ''] = '${auto.direccionTramaActual}';
      }
    }
    // Solo si el idVehiculo del stream coincide con el seleccionado
    if (plateStream == _selectedAuto.placa) {
      print(
          'HB HERNAN - recibiste actualización ${_selectedAuto.velocidad} ${_selectedAuto.fecha} ${_selectedAuto.latitud} ${_selectedAuto.longitud}');

      if (autosHistorial.isNotEmpty) {
        final lastAuto = autosHistorial.last;
        final distance = calculateDistance(
          lastAuto.latitud,
          lastAuto.longitud,
          _selectedAuto.latitud,
          _selectedAuto.longitud,
        );

        print(
            'HB HERNAN Distancia entre la última ubicación y la actual: $distance metros');

        // Solo agregar al historial si la distancia es mayor a 2 metros
        if (distance <= 2) {
          print(
              'HB HERNAN Distancia menor a 2 metros, se ignora esta actualización');
          return; // Salir de la función sin guardar la trama actual
        }
      }
      // Crea una copia del estado actual del `selectedAuto`
      Auto autoCopy = Auto(
        codigoInterno: _selectedAuto.codigoInterno,
        fechaEncendido: _selectedAuto.fechaEncendido,
        fechapagado: _selectedAuto.fechapagado,
        kilometrajeAcumuladoAyer: _selectedAuto.kilometrajeAcumuladoAyer,
        kilometrajeAcumuladoMes: _selectedAuto.kilometrajeAcumuladoMes,
        placa: _selectedAuto.placa,
        idVehiculo: _selectedAuto.idVehiculo,
        latitud: _selectedAuto.latitud,
        longitud: _selectedAuto.longitud,
        fecha: _selectedAuto.fecha,
        fechaTramaActual: _selectedAuto.fechaTramaActual,
        direccionTramaActual: _selectedAuto.direccionTramaActual,
        acc: _selectedAuto.acc,
        velocidad: _selectedAuto.velocidad,
        terminal: _selectedAuto.terminal,
        sentido: _selectedAuto.sentido,
        kilometrajeAcum: _selectedAuto.kilometrajeAcum,
        imeil: _selectedAuto.imeil,
        kmgalon: _selectedAuto.kmgalon,
      );

      // Agrega la copia al historial y limita a los últimos 4 elementos
      if (autosHistorial.length >= 4) {
        autosHistorial.removeAt(0);
      }
      autosHistorial.add(autoCopy);
      print('HB HERNAN  Se guarda ubi');
      notifyListeners();
    }
    // Después de actualizar los datos, llamar a notifyListeners()
    notifyListeners();
  }

  double _calulateKilometrajeAcumulados(
    double latLast,
    double longLast,
    double lat,
    double long,
  ) {
    double theta = latLast - lat;
    double radianLat1 = degToRad(latLast);
    double radianLat2 = degToRad(lat);
    double radianTheta = degToRad(theta);

    double dist = sin(radianLat1) * sin(radianLat2) +
        cos(radianLat1) * cos(radianLat2) * cos(radianTheta);
    dist = acos(dist);
    dist = radToDeg(dist);
    dist = dist * 60 * 1.1515; // Distancia en millas

    return dist * 1.609344; // Convertir a kilómetros
  }

  /// Convierte grados a radianes
  double degToRad(double degree) {
    return degree * pi / 180.0;
  }

  /// Convierte radianes a grados
  double radToDeg(double radian) {
    return radian * 180.0 / pi;
  }

  void resetAutosHistorial() {
    autosHistorial.clear();
    notifyListeners(); // Notifica a los widgets que dependen de autosHistorial para que se actualicen.
  }

  Future<String?> getAddress(double lat, double lng) async {
    final url =
        'http://ironmaps.com/nominatim/reverse.php?format=json&limit=1&lat=${lat}&lon=${lng}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'];
      } else {
        print('Error en la solicitud HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al obtener la dirección: $e');
      return null;
    }
  }

  Future<ReportResponse?> getReportBus({
    required int idVehiculo,
    required String fecha,
    required String type,
    String? fechaEnd,
  }) async {
    // final url = 'https://mibus.pe/api/reportes/vueltasKilometraje'
    final params = {
      'fecha': fecha,
      'vehiculo_id': idVehiculo.toString(),
      'type': type,
      if (fechaEnd != null && fechaEnd.isNotEmpty) 'fecha_end': fechaEnd,
    };
    final apiUrl = await Environment.apiUrl; // Resuelve la URL correcta
    print('FACTORIA getReportBus apiUrl $apiUrl');
    try {
      var url = Uri.parse('${apiUrl}api/reportes/vueltasKilometraje');
      print('FACTORIA getReportBus apiUrl2 $url');
      final response = await http.post(
        url,
        body: params,
      );
      print('FACTORIA getReportBus => $response');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ReportResponse.fromJson(data);
      } else {
        print('Error en la solicitud HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al obtener la dirección: $e');
      return null;
    }
  }

  bool get isLoading => _isLoading;
}
