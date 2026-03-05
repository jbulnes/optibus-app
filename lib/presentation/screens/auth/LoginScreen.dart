import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:satelite_peru_mibus/app_theme.dart';
import 'package:satelite_peru_mibus/presentation/components/constant/app_text_style.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:satelite_peru_mibus/data/services/auth_service.dart';
import 'package:satelite_peru_mibus/presentation/components/buttons/rounded_button.dart';
import 'package:satelite_peru_mibus/presentation/components/inputs/rounded_input_field.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:satelite_peru_mibus/data/global/device_info_helper.dart'; 
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  static const nameScreen = "login_screen";

  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;
  bool isChecked = false;
  String deviceId = "Cargando...";

  List<UrlOption> urlOptions = [
    UrlOption(displayName: 'OptiBus', url: 'https://optibus.pe/'),
    //UrlOption(displayName: 'MiBus', url: 'https://mibus.pe/'),
  ];

  String? selectedUrl;
  int selectedIndex = 0; // Índice inicial por defecto (0 para 'FlotaBus')

  @override
  void initState() {
    super.initState();
    _loadSavedUsername();
    _loadSavedUserPassword();
    _loadSavedUrl(); // Cargar URL seleccionada
    _getDeviceId();
  }

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('API_URL_PREF');

    setState(() {
      if (savedUrl != null) {
        // Encuentra el índice de la URL guardada
        selectedIndex =
            urlOptions.indexWhere((option) => option.url == savedUrl);
        // Si no encuentra el índice, selecciona 'MiBus' por defecto
        if (selectedIndex == -1) {
          selectedIndex = 1; // Índice de 'MiBus'
        }
      } else {
        // Si no hay una URL guardada, selecciona 'MiBus' por defecto
        selectedIndex = 1;
      }
      selectedUrl = urlOptions[selectedIndex].url; // URL seleccionada
    });
  }

  void _getDeviceId() async {
    String id = await getUniqueId();
    setState(() {
      deviceId = id;
    });
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    _empresaController.dispose();
    super.dispose();
  }

  void _showUrlDialog(BuildContext context, bool isLightMode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              isLightMode ? AppTheme.white : const Color(0xff18191A),
          title: Text(
            'Configuración',
            style: TextStyle(
                fontSize: 16, color: isLightMode ? Colors.black : Colors.white),
          ),
          content: Column( // Cambiamos a Column para meter ambos widgets
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. El Selector de URL
              SizedBox(
                height: 120, // Ajustamos un poco la altura
                child: CupertinoPicker(
                  itemExtent: 30,
                  scrollController: FixedExtentScrollController(
                    initialItem: selectedIndex,
                  ),
                  onSelectedItemChanged: (int value) {
                    setState(() {
                      selectedIndex = value;
                      selectedUrl = urlOptions[value].url;
                    });
                  },
                  children: urlOptions.map((option) {
                    return Text(
                      option.displayName,
                      style: TextStyle(
                          color: isLightMode ? Colors.black : Colors.white),
                    );
                  }).toList(),
                ),
              ),
              
              const Divider(), // Una línea separadora para que se vea ordenado
              const SizedBox(height: 5),

              // 2. El Identificador de Dispositivo dentro del Modal
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isLightMode ? Colors.grey[100] : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xff6456FF).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "IDENTIFICADOR DE DISPOSITIVO",
                      style: TextStyle(
                        fontSize: 9, // Un poco más pequeño para el modal
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: isLightMode ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.mobile_copy, size: 14, color: const Color(0xff6456FF)),
                        const SizedBox(width: 6),
                        Flexible( // Para que el texto no se corte si es muy largo
                          child: Text(
                            deviceId,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: isLightMode ? Colors.black87 : Colors.white70,
                            ),
                          ),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.only(left: 8),
                          icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xff6456FF)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: deviceId));
                            // Cerramos el modal para que el SnackBar sea visible en el fondo
                            // o usamos el context global.
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("ID copiado al portapapeles"),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón Cancelar - Estilo minimalista
                  TextButton(
                    style: TextButton.styleFrom(
                      // Color de texto rojo claro (ajusta el tono según prefieras, red[300] es suave)
                      foregroundColor: Colors.red[300], 
                      // Un fondo muy sutil opcional para darle un toque
                      backgroundColor: isLightMode ? Colors.red.withOpacity(0.05) : Colors.red.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),

                  // Botón Guardar - Estilo llamativo (acorde a tu botón INGRESAR)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff6456FF), // El violeta de tu app
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Guardar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      if (selectedUrl != null) {
                        _saveUrlToStorage(selectedUrl!);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveUrlToStorage(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('API_URL_PREF', url);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isLightMode = brightness == Brightness.light;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isLightMode ? AppTheme.white : const Color(0xff18191A),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Center(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  Image.asset('assets/icon/sp.png',
                                      width: 100, height: 100),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "OPTIBUS",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Color(0xffDA2C26),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            RoundedInputField(
                              controller: _userController,
                              hintText: "Usuario",
                              icon: Ionicons.person_circle,
                              onChange: (value) {},
                            ),
                            RoundedInputField(
                              isPassword: true,
                              controller: _passwordController,
                              hintText: "Contraseña",
                              icon: Icons.lock_person_sharp,
                              onChange: (value) {},
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Checkbox(
                                  side: const BorderSide(
                                    color: Color(0xff6456FF),
                                    width: 2,
                                  ),
                                  activeColor: const Color(0xff6456FF),
                                  checkColor: Colors.white,
                                  value: isChecked,
                                  onChanged: (bool? value) {
                                    if (value == true) {
                                      _saveUserPassword(
                                        _passwordController.text.trim(),
                                      );
                                    } else {
                                      _deleteUserPassword();
                                    }
                                    setState(() {
                                      isChecked = value!;
                                    });
                                  },
                                ),
                                Text(
                                  'Recordarme',
                                  style: TextStyle(
                                      color: brightness == Brightness.light
                                          ? Colors.black
                                          : Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: RoundedButton(
                                isLoading: isLoading,
                                text: "INGRESAR",
                                press: authService.autenticando && isLoading
                                    ? null
                                    : () async {
                                        setState(() {
                                          isLoading = true;
                                        });
                                        final loginOk =
                                            await authService.signInWeb(
                                          _userController.text.trim(),
                                          _passwordController.text.trim(),
                                        );
                                        setState(() {
                                          isLoading = false;
                                        });
                                        if (loginOk == true) {
                                          _saveUsername(
                                              _userController.text.trim(),
                                              _empresaController.text.trim());
                                          FocusScope.of(context).unfocus();
                                          context.go('/home_screen');
                                          _saveUserPasswordTemp(
                                            _passwordController.text.trim(),
                                          );
                                        } else {
                                          _passwordController.text = "";
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              content: Text(' $loginOk'),
                                              duration: const Duration(
                                                milliseconds: 2000,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                color: const Color(0xff6456FF),
                              ),
                            ),
                            const SizedBox(height: 20),
                            InkWell(
                              onTap: _launchUrl,
                              child: Text(
                                "Desarrollado por Satélite PerúⓇ",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isLightMode
                                      ? const Color(0xff3684CC)
                                      : const Color.fromARGB(255, 63, 145, 221),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  color: brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    _showUrlDialog(context, isLightMode);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl() async {
    final Uri _url = Uri.parse('https://sateliteperu.com/');
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }

  void _loadSavedUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUsername = prefs.getString('username');
    String? savedUserEmpresa = prefs.getString('empresa');

    if (savedUsername != null) {
      setState(() {
        _userController.text = savedUsername;
      });
    }
    if (savedUserEmpresa != null) {
      setState(() {
        _empresaController.text = savedUserEmpresa;
      });
    }
  }

  Future<void> _saveUsername(String username, String empresa) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('empresa', empresa);
  }

  Future<void> _saveUserPassword(String userPassword) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', userPassword);
  }

  void _saveUserPasswordTemp(String userPassword) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('tempPassword', userPassword);
  }

  Future<void> _deleteUserPassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('password');
  }

  void _loadSavedUserPassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedPassword = prefs.getString('password');
    if (savedPassword != null) {
      setState(() {
        _passwordController.text = savedPassword;
        isChecked = true;
      });
    }
  }
}

class UrlOption {
  final String displayName;
  final String url;

  UrlOption({required this.displayName, required this.url});
}
