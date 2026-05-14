import 'dart:io';

import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:satelite_peru_mibus/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:satelite_peru_mibus/data/services/auth_service.dart';
import 'package:satelite_peru_mibus/data/services/mqtt_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pdfx/pdfx.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer(
      {Key? key,
      this.screenIndex,
      this.iconAnimationController,
      this.callBackIndex})
      : super(key: key);

  final AnimationController? iconAnimationController;
  final DrawerIndex? screenIndex;
  final Function(DrawerIndex)? callBackIndex;

  @override
  _HomeDrawerState createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  List<DrawerList>? drawerList;
  @override
  void initState() {
    setDrawerListArray();
    super.initState();
  }

  void setDrawerListArray() {
    drawerList = <DrawerList>[
      DrawerList(
        index: DrawerIndex.HOME,
        labelName: 'Inicio',
        icon: Icon(Icons.home),
      ),
      DrawerList(
        index: DrawerIndex.Instructions,
        labelName: 'Instrucciones',
        icon: Icon(Icons.info_outline_rounded, color: Colors.deepPurple),
      ),
      DrawerList(
        index: DrawerIndex.WhatsApp,
        labelName: 'Soporte WhatsApp',
        icon: const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Color(0xFF25D366),
                  size: 20,
                ),
      ),
      // DrawerList(
      //   index: DrawerIndex.Help,
      //   labelName: 'Historial',
      //   // isAssetsImage: true,
      //   // imageName: 'assets/images/supportIcon.png',
      //   icon: Icon(Icons.history),
      // ),
      // DrawerList(
      //   index: DrawerIndex.FeedBack,
      //   labelName: 'Reporte Avanzado',
      //   icon: Icon(Icons.file_copy),
      // ),
      // DrawerList(
      //   index: DrawerIndex.Invite,
      //   labelName: 'Invite Friend',
      //   icon: Icon(Icons.group),
      // ),
      // DrawerList(
      //   index: DrawerIndex.Share,
      //   labelName: 'Rate the app',
      //   icon: Icon(Icons.share),
      // ),
      // DrawerList(
      //   index: DrawerIndex.About,
      //   labelName: 'About Us',
      //   icon: Icon(Icons.info),
      // ),
    ];
  }

  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _showBottomSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Abrir Cámara'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Abrir Galería'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> navigationtoScreen(DrawerIndex indexScreen) async {
    if (indexScreen == DrawerIndex.WhatsApp) {
      // Configuración de WhatsApp
      const String phoneNumber = "51942414926"; // Con código de país
      const String message = "Necesito ayuda con el app de Optibus";
      final Uri whatsappUri = Uri.parse(
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}"
      );
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        print("No se pudo abrir WhatsApp");
      }
    } else if (indexScreen == DrawerIndex.Instructions) {
      // Navegar a la pantalla de instrucciones
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => InstructionsScreen()),
      );
    } else {
      widget.callBackIndex!(indexScreen);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      // Aquí puedes guardar la imagen en el almacenamiento local
      // usando paquetes como path_provider si es necesario.
    }
  }

  void _logoutInApp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idEmpresa = prefs.getString('idEmpresa');

    AuthService.deleteToken();
    context.go('/login_screen');
    _deleteUserPassword();

    MqttService().unsubscribe(
      'gps-location-topic',
    );
    MqttService().dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: true);
    final email = authService.email;

    var brightness = MediaQuery.of(context).platformBrightness;
    bool isLightMode = brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLightMode == true ? AppTheme.white : Color(0xff18191A),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/app/costa_verde.jpg'),
                // image: NetworkImage(
                //   'https://blog.sebastiano.dev/content/images/2019/07/1_l3wujEgEKOecwVzf_dqVrQ.jpeg',
                // ),
                fit: BoxFit.cover,
              ),
            ),
            width: double.infinity,
            padding: const EdgeInsets.only(top: 100.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  AnimatedBuilder(
                    animation: widget.iconAnimationController!,
                    builder: (BuildContext context, Widget? child) {
                      return ScaleTransition(
                        scale: AlwaysStoppedAnimation<double>(1.0 -
                            (widget.iconAnimationController!.value) * 0.2),
                        child: RotationTransition(
                          turns: AlwaysStoppedAnimation<double>(
                              Tween<double>(begin: 0.0, end: 24.0)
                                      .animate(
                                        CurvedAnimation(
                                            parent:
                                                widget.iconAnimationController!,
                                            curve: Curves.fastOutSlowIn),
                                      )
                                      .value /
                                  360),
                          child: GestureDetector(
                            onTap: () {
                              _showBottomSheet(context);
                            },
                            child: Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                      color: Colors.grey.withOpacity(0.6),
                                      offset: const Offset(2.0, 4.0),
                                      blurRadius: 8),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(60.0)),
                                child: _image == null
                                    ? Image.asset(
                                        // 'assets/images/userImage.png',
                                        'assets/images/supportIcon.png',
                                      ) // Imagen por defecto
                                    : Image.file(_image!,
                                        fit: BoxFit
                                            .cover), // Imagen seleccionada
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      '${email ?? ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isLightMode ? AppTheme.white : AppTheme.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 1),
          Divider(
            height: 1,
            color: AppTheme.grey.withOpacity(0.6),
          ),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(0.0),
              itemCount: drawerList?.length,
              itemBuilder: (BuildContext context, int index) {
                return inkwell(drawerList![index], isLightMode);
              },
            ),
          ),
          Divider(
            height: 1,
            color: AppTheme.grey.withOpacity(0.6),
          ),
          Column(
            children: <Widget>[
              ListTile(
                title: Text(
                  'Salir',
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color:
                        isLightMode == true ? AppTheme.darkText : Colors.white,
                  ),
                  textAlign: TextAlign.left,
                ),
                trailing: const Icon(
                  Icons.power_settings_new,
                  color: Colors.red,
                ),
                onTap: () {
                  _showLogoutConfirmationDialog(context);
                },
              ),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom,
              )
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    if (widget.iconAnimationController != null) {
      showPlatformDialog(
        context: context,
        builder: (BuildContext context) {
          return PlatformAlertDialog(
            title: Text('Confirmación'),
            content: Text('¿Realmente desea cerrar sesión?'),
            actions: <Widget>[
              PlatformDialogAction(
                child: PlatformText('Cancelar'),
                onPressed: () {
                  context.pop();
                },
              ),
              PlatformDialogAction(
                child: PlatformText(
                  'Cerrar sesión',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  context.pop();
                  _logoutInApp();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _deleteUserPassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('passwordTemp');
  }

  Widget inkwell(DrawerList listData, isLightMode) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: Colors.grey.withOpacity(0.1),
        highlightColor: Colors.transparent,
        onTap: () {
          navigationtoScreen(listData.index!);
        },
        child: Stack(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 6.0,
                    height: 46.0,
                    decoration: BoxDecoration(
                      color: widget.screenIndex == listData.index
                          ? Colors.blue
                          : Colors.transparent,
                      borderRadius: new BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(4.0),
                  ),
                  listData.isAssetsImage
                      ? Container(
                          width: 24,
                          height: 24,
                          child: Image.asset(
                            listData.imageName,
                            color: widget.screenIndex == listData.index
                                ? Colors.blue
                                : isLightMode
                                    ? AppTheme.nearlyBlack
                                    : Colors.white,
                          ),
                        )
                      : Icon(listData.icon?.icon,
                          color: widget.screenIndex == listData.index
                              ? Colors.blue
                              : isLightMode
                                  ? AppTheme.nearlyBlack
                                  : AppTheme.grey),
                  const Padding(
                    padding: EdgeInsets.all(4.0),
                  ),
                  Text(
                    listData.labelName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: isLightMode ? Colors.black : Colors.white,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
            widget.screenIndex == listData.index
                ? AnimatedBuilder(
                    animation: widget.iconAnimationController!,
                    builder: (BuildContext context, Widget? child) {
                      return Transform(
                        transform: Matrix4.translationValues(
                          (MediaQuery.of(context).size.width * 0.75 - 64) *
                              (1.0 -
                                  widget.iconAnimationController!.value -
                                  1.0),
                          0.0,
                          0.0,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Container(
                            width:
                                MediaQuery.of(context).size.width * 0.75 - 64,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: new BorderRadius.only(
                                topLeft: Radius.circular(0),
                                topRight: Radius.circular(28),
                                bottomLeft: Radius.circular(0),
                                bottomRight: Radius.circular(28),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : const SizedBox()
          ],
        ),
      ),
    );
  }

}

enum DrawerIndex {
  HOME,
  FeedBack,
  Help,
  Share,
  About,
  Invite,
  Testing,
  WhatsApp,
  Instructions,
}



class InstructionsScreen extends StatefulWidget {
  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  final String youtubeUrl = "https://www.youtube.com/watch?v=WApuhOWVu7g";
  final Color mainBlue = Color(0xFF6456FF);

  late final WebViewController youtubeController;
  // 2. Controlador para el PDF
  late PdfControllerPinch pdfController;

  @override
  void initState() {
    super.initState();

    // Inicializar el controlador con el archivo de tus assets
    pdfController = PdfControllerPinch(
      document: PdfDocument.openAsset('assets/pdfs/manual_usuario.pdf'),
    );

    // Configuración para YouTube
    final videoUri = Uri.parse(youtubeUrl);
    final videoId = videoUri.queryParameters.containsKey('v') 
        ? videoUri.queryParameters['v'] 
        : videoUri.pathSegments.last;
    
    youtubeController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36")
      ..loadRequest(Uri.parse('https://www.youtube.com/embed/$videoId'));
  }

  @override
  void dispose() {
    pdfController.dispose(); // Importante limpiar el controlador
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Guía de Uso", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              "¡Bienvenido!",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: mainBlue),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Icon(Icons.picture_as_pdf, color: Colors.red),
              label: Text("Ver Manual"),
              onPressed: () => _showPdfDialog(context),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.ondemand_video, color: mainBlue),
              label: Text("Video Tutorial"),
              onPressed: () => _showYoutubeDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showPdfDialog(BuildContext context) {
    // Creamos el controlador JUSTO ANTES de mostrar el diálogo
    final PdfControllerPinch tempPdfController = PdfControllerPinch(
      document: PdfDocument.openAsset('assets/pdfs/manual_usuario.pdf'),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(10),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              AppBar(
                title: Text("Manual de Usuario"),
                backgroundColor: mainBlue,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: Icon(Icons.close), 
                    onPressed: () {
                      // Cerramos el controlador al cerrar el diálogo
                      tempPdfController.dispose();
                      Navigator.pop(context);
                    }
                  )
                ],
              ),
              Expanded(
                child: PdfViewPinch(
                  controller: tempPdfController,
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // Esto asegura que si el usuario toca fuera del diálogo para cerrar,
      // el controlador también se libere.
      tempPdfController.dispose();
    });
  }

  void _showYoutubeDialog(BuildContext context) {
    // 1. Extraer el ID del video (ejemplo: WApuhOWVu7g)
    final String videoId = YoutubePlayer.convertUrlToId(youtubeUrl)!;

    // 2. Inicializar el controlador específico para YouTube
    final YoutubePlayerController _ytController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        child: Container(
          width: double.infinity,
          color: Colors.black, // Fondo negro para el video
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text("Video Tutorial"),
                backgroundColor: mainBlue,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              // 3. El reproductor especializado
              YoutubePlayer(
                controller: _ytController,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.amber,
                onReady: () {
                  print('Reproductor listo.');
                },
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // 4. Liberar recursos al cerrar
      _ytController.dispose();
    });
  }
}

class DrawerList {
  DrawerList({
    this.isAssetsImage = false,
    this.labelName = '',
    this.icon,
    this.index,
    this.imageName = '',
  });

  String labelName;
  Icon? icon;
  bool isAssetsImage;
  String imageName;
  DrawerIndex? index;
}
