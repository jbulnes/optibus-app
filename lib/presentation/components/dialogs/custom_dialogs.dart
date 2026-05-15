import 'package:flutter/material.dart';

enum DialogType { error, warning, success, info }

class CustomDialogs {
  static void show(
    BuildContext context, {
    required DialogType type,
    String? title,
    String? message,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🛠️ Configuración parametrizada
    final Map<DialogType, Map<String, dynamic>> config = {
      DialogType.error: {
        'icon': Icons.error_outline,
        'color': Colors.red,
        'defaultTitle': '¡Ocurrió un error!',
      },
      DialogType.warning: {
        'icon': Icons.warning_amber_rounded,
        'color': Colors.orange,
        'defaultTitle': 'Atención',
      },
      DialogType.success: {
        'icon': Icons.check_circle_outline,
        'color': Colors.green,
        'defaultTitle': 'Éxito',
      },
      DialogType.info: {
        'icon': Icons.info_outline,
        'color': Colors.blue,
        'defaultTitle': 'Información',
      },
    };

    final currentConfig = config[type]!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF18191A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
            side: const BorderSide(color: Color(0xff6456FF), width: 2.0),
          ),
          title: Center(
            child: Text(
              title ?? currentConfig['defaultTitle'],
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Icon(
                  currentConfig['icon'],
                  color: currentConfig['color'],
                  size: 55.0,
                ),
                const SizedBox(height: 16.0),
                Center(
                  child: Text(
                    message ?? 'No se pudo procesar la solicitud.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6456FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        );
      },
    );
  }
}