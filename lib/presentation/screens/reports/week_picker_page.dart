import 'dart:io';

import 'package:flutter/material.dart';

import 'package:excel/excel.dart' as xcel;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_date_pickers/flutter_date_pickers.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:satelite_peru_mibus/data/services/cars_service.dart';
import 'package:satelite_peru_mibus/domains/models/autos_models/ReportsReponse.dart';
import 'package:satelite_peru_mibus/presentation/components/buttons/rounded_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

import '../color_picker_dialog.dart';
import '../color_selector_btn.dart';
import '../event.dart';

/// Page with the [WeekPicker].
class WeekPickerPage extends StatefulWidget {
  /// Custom events.
  final List<Event> events;

  ///
  const WeekPickerPage({Key? key, this.events = const []}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WeekPickerPageState();
}

class _WeekPickerPageState extends State<WeekPickerPage> {
  DateTime _selectedDate = DateTime.now();
  // final DateTime _firstDate = DateTime.now().subtract(Duration(days: 45));
  DateTime _firstDate =
      DateTime.now().subtract(Duration(days: 365)); // 1 año atrás
  // final DateTime _lastDate = DateTime.now().add(Duration(days: 45));
  DateTime _lastDate = DateTime.now(); // Hoy

  DatePeriod? _selectedPeriod;

  Color selectedPeriodStartColor = Colors.blue;
  Color selectedPeriodLastColor = Colors.green;
  Color selectedPeriodMiddleColor = Colors.blue;

  CarsService carsService = CarsService();
  List<Map<String, dynamic>> reportData = [];
  bool _isLoading = false;

  bool _isTableVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // defaults for styles
    selectedPeriodLastColor = Colors.lightGreen.withOpacity(0.8);
    selectedPeriodMiddleColor = Colors.lightGreen.withOpacity(0.4);
    selectedPeriodStartColor = Colors.lightGreen.withOpacity(0.8);
  }

  @override
  Widget build(BuildContext context) {
    final GoRouterState state = GoRouterState.of(context);
    final Map<String, dynamic> extra = state.extra as Map<String, dynamic>;
    final String placaVehiculo = extra['placa'] as String;
    final int vehiculo_id = extra['vehiculo_id'] as int;

    var brightness = MediaQuery.of(context).platformBrightness;
    bool isLightMode = brightness == Brightness.light;

    DatePickerRangeStyles styles = DatePickerRangeStyles(
      displayedPeriodTitle: TextStyle(
        color: isLightMode ? Colors.black : Colors.white,
      ),
      selectedPeriodLastDecoration: BoxDecoration(
          color: selectedPeriodLastColor,
          borderRadius: const BorderRadiusDirectional.only(
              topEnd: Radius.circular(10.0), bottomEnd: Radius.circular(10.0))),
      selectedPeriodStartDecoration: BoxDecoration(
        color: selectedPeriodStartColor,
        borderRadius: const BorderRadiusDirectional.only(
            topStart: Radius.circular(10.0),
            bottomStart: Radius.circular(10.0)),
      ),
      selectedPeriodMiddleDecoration: BoxDecoration(
        color: selectedPeriodMiddleColor,
        shape: BoxShape.rectangle,
      ),
      dayHeaderStyle: const DayHeaderStyle(
        textStyle: TextStyle(
          color: Color(0xff6456FF),
          fontWeight: FontWeight.bold,
        ),
      ),
      defaultDateTextStyle: TextStyle(
        color: isLightMode ? Colors.black : Colors.white,
      ),
    );

    void _showErrorDialog(BuildContext context, {String? title, String? message}) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      
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
                title ?? '¡Ocurrió un error!', // Título dinámico
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  // Cambiamos el icono a uno de información si no hay datos
                  Icon(
                    title == 'Atención' ? Icons.info_outline : Icons.error, 
                    color: title == 'Atención' ? Colors.orange : Colors.red, 
                    size: 48.0
                  ),
                  const SizedBox(height: 16.0),
                  Center(
                    child: Text(
                      message ?? 'No se pudo obtener el reporte.', // Mensaje dinámico
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6456FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }

    void hanldleVueltasKilometraje(BuildContext context, String placa) async {
      DateTime dateTime = DateTime.parse(_selectedDate.toString());
      String formattedDateStart = DateFormat('yyyy-MM-dd').format(dateTime);

      DateTime dateTimeEnd = DateTime.parse(_selectedPeriod!.end.toString());
      String formattedDateEnd = DateFormat('yyyy-MM-dd').format(dateTimeEnd);

      setState(() {
        _isLoading = true;
      });

      ReportResponse? response = await carsService.getReportBusWeb(
        placa: placa,
        fecha: formattedDateStart,
        fechaEnd: formattedDateEnd,
        type: 'week',
      );

      setState(() {
        _isLoading = false;
      });

      if (response != null && response.success) {
        final reporte = response.reporte;
        setState(() {
          reportData = [
            {
              "placa": reporte.placa,
              "reporte_kilometraje": reporte.reporteKilometraje,
              "nro_vueltas": reporte.nroVueltas,
              "reporte_fecha_desde": reporte.reporteFechaDesde,
              "reporte_fecha_hasta": reporte.reporteFechaHasta,
              "type": reporte.type,
              "km_vuelta": reporte.flota.kmVuelta
            }
          ];
        });
        print('Reporte: ${reporte.toJson()}');
        _isTableVisible = true; // Mostrar la tabla después de cargar los datos
      } else {
        print('No se pudo obtener el reporte.');
        _isTableVisible = false; // Ocultar la tabla si hay error
        _showErrorDialog(
          context, 
          title: 'Atención', 
          message: 'No se verifica información en la fecha indicada.'
        );
      }
    }

    Future<void> exportToExcel() async {
      // Solicitar permisos
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        print('Permiso de almacenamiento denegado');
        return;
      }

      var excel = xcel.Excel.createExcel();
      xcel.Sheet sheetObject = excel['Sheet1'];
      sheetObject.appendRow(["Placa", "Fecha", "Km recorrido", "Vueltas"]);

      for (var item in reportData) {
        sheetObject.appendRow(
          [
            item["placa"],
            '${item["reporte_fecha_desde"].toString().substring(0, 10)}\nhasta\n${_selectedPeriod!.end.toString().substring(0, 10).substring(0, 10)}',
            item["reporte_kilometraje"].toStringAsFixed(2),
            item["km_vuelta"],
          ],
        );
      }

      Directory directory = await getApplicationDocumentsDirectory();
      String filePath = '${directory.path}/report.xlsx';
      File file = File(filePath);
      file.writeAsBytesSync(excel.encode()!);
      OpenFile.open(filePath);
      print("Excel file saved at $filePath");
    }

    // Future<void> exportToPdf() async {
    //   final pdf = pw.Document();

    //   pdf.addPage(
    //     pw.Page(
    //       build: (pw.Context context) {
    //         return pw.Table.fromTextArray(
    //           headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
    //           headers: ["Placa", "Fecha", "Km recorrido", "Vueltas"],
    //           data: reportData
    //               .map(
    //                 (item) => [
    //                   item["placa"],
    //                   '${item["reporte_fecha_desde"].toString().substring(0, 10)}\nhasta\n${_selectedPeriod!.end.toString().substring(0, 10).substring(0, 10)}',
    //                   item["reporte_kilometraje"].toStringAsFixed(2),
    //                   item["km_vuelta"],
    //                 ],
    //               )
    //               .toList(),
    //         );
    //       },
    //     ),
    //   );

    //   Directory directory = await getApplicationDocumentsDirectory();
    //   String filePath = '${directory.path}/report.pdf';
    //   File file = File(filePath);
    //   file.writeAsBytesSync(await pdf.save());
    //   OpenFile.open(filePath);
    //   print("PDF file saved at $filePath");
    // }
    Future<void> exportToPdf({bool share = false}) async {
      final pdf = pw.Document();

      // Obtener placa y fechas para el nombre del archivo
      String placa = reportData.isNotEmpty ? (reportData[0]["placa"] ?? "").toString() : "reporte";
      DateTime fechaIni = reportData.isNotEmpty ? DateTime.parse(reportData[0]["reporte_fecha_desde"].toString()) : _selectedDate;
      DateTime fechaFin = reportData.isNotEmpty ? DateTime.parse(reportData[0]["reporte_fecha_hasta"].toString()) : _selectedDate;
      String fechaIniStr = "${fechaIni.day.toString().padLeft(2, '0')}${fechaIni.month.toString().padLeft(2, '0')}${fechaIni.year}";
      String fechaFinStr = "${fechaFin.day.toString().padLeft(2, '0')}${fechaFin.month.toString().padLeft(2, '0')}${fechaFin.year}";
      String fileName = "${placa}-${fechaIniStr}${fechaFinStr}.pdf";

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ["Placa", "Fecha", "Km recorrido", "Vueltas"],
              cellStyle: pw.TextStyle(fontWeight: pw.FontWeight.normal),
              data: reportData
                  .map(
                    (item) => [
                      item["placa"],
                      '${item["reporte_fecha_desde"].toString().substring(0, 10)} hasta ${item["reporte_fecha_hasta"].toString().substring(0, 10)}',
                      double.tryParse(item["reporte_kilometraje"].toString())?.toStringAsFixed(2) ?? '',
                      double.tryParse(item["nro_vueltas"].toString())?.toStringAsFixed(2) ?? '',
                    ],
                  )
                  .toList(),
            );
          },
        ),
      );

      Directory directory = await getApplicationDocumentsDirectory();
      String filePath = '${directory.path}/$fileName';
      File file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      print("PDF file saved at $filePath");
      if (share) {
        await Share.shareXFiles([XFile(file.path)], text: '¡Mira este archivo PDF!');
      } else {
        OpenFile.open(filePath);
      }
    }

    bool isEqualsDateSelected = reportData.length > 0
        ? reportData[0]["reporte_fecha_desde"].toString().substring(0, 10) ==
            _selectedDate.toString().substring(0, 10)
        : false;

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          WeekPicker(
            selectedDate: _selectedDate,
            onChanged: _onSelectedDateChanged,
            firstDate: _firstDate,
            lastDate: _lastDate,
            datePickerStyles: styles,
            onSelectionError: _onSelectionError,
            eventDecorationBuilder: _eventDecorationBuilder,
            selectableDayPredicate: (DateTime day) {
              // Aquí se establece el predicado para seleccionar semanas.
              // Devuelve `false` para días en semanas futuras.
              return day.isBefore(_lastDate) || day.isAtSameMomentAs(_lastDate);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Text(
                //   "Cambiar estilos",
                //   style: Theme.of(context).textTheme.titleMedium,
                // ),
                // _stylesBlock(),
                // _selectedBlock(),
                RoundedButton(
                  isDisabled: _isLoading || isEqualsDateSelected ? true : false,
                  text: 'Buscar',
                  color: const Color(0xff6456FF),
                  isLoading: _isLoading,
                  press: () {
                    hanldleVueltasKilometraje(context, placaVehiculo);
                  },
                ),
                const SizedBox(height: 10.0),
                _isLoading
                    ? SkeletonLoader(
                        builder: Column(
                        children: List.generate(
                          2, // Número de filas de carga
                          (index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Expanded(child: _buildSkeletonCell()),
                                Expanded(child: _buildSkeletonCell()),
                                Expanded(child: _buildSkeletonCell()),
                                Expanded(child: _buildSkeletonCell()),
                              ],
                            ),
                          ),
                        ),
                      ))
                    : _isTableVisible || isEqualsDateSelected
                        ?
                        // reportData.isNotEmpty
                        Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1.0,
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(4.0),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildHeaderRow(),
                                    ..._buildDataRows(placaVehiculo),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        await exportToPdf(share: false); // Descargar
                                      },
                                      style: ElevatedButton.styleFrom(
                                        iconColor: Colors.blueAccent,
                                        surfaceTintColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      ),
                                      icon: Icon(Icons.download, size: 20),
                                      label: Text(
                                        'Descargar',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        await exportToPdf(share: true); // Compartir
                                      },
                                      style: ElevatedButton.styleFrom(
                                        iconColor: Colors.blueAccent,
                                        surfaceTintColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      ),
                                      icon: Icon(Icons.share, size: 20),
                                      label: Text(
                                        'Compartir',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          )
                        : const Center(
                            child: Text(
                                'Seleccione una fecha y haga click en buscar'),
                          )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCell() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4.0),
      ),
      height: 24.0,
    );
  }

  Widget _buildHeaderRow() {
    const styleTitle = TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold);

    return Row(
      children: [
        _buildCell('Placa', textStyle: styleTitle),
        _buildCell('Fecha', textStyle: styleTitle),
        _buildCell('Km', textStyle: styleTitle),
        _buildCell('Vueltas', textStyle: styleTitle),
      ],
    );
  }

  List<Widget> _buildDataRows(String placaVehiculo) {
    return reportData.map((item) {
      // 1. EXTRAE EL VALOR DIRECTAMENTE (Sin dividir)
      // Usamos double.tryParse para asegurar que sea un número antes de mostrarlo
      double nroVueltas = double.tryParse(item['nro_vueltas'].toString()) ?? 0.0;
      
      // 2. CONVIERTE EL KM A DOUBLE PARA EVITAR EL ERROR DEL /
      double kmRecorrido = double.tryParse(item['reporte_kilometraje'].toString()) ?? 0.0;

      DateTime dateTime = DateTime.parse(item['reporte_fecha_desde'].toString());
      String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);

      const styleCampos = TextStyle(fontSize: 14.0);

      return Row(
        children: [
          _buildCell(placaVehiculo, textStyle: styleCampos, hideBottom: true),
          _buildCell('${formattedDate}\nhasta\n${item['reporte_fecha_hasta'].toString().substring(0, 10)}',
              textStyle: const TextStyle(fontSize: 12.0), hideBottom: true),
          // Mostramos el km convertido correctamente
          _buildCell(kmRecorrido.toStringAsFixed(2),
              textStyle: styleCampos, hideBottom: true),
          // Mostramos las vueltas que ya vienen de la API
          _buildCell(nroVueltas.toStringAsFixed(2),
              textStyle: styleCampos, hideBottom: true),
        ],
      );
    }).toList();
  }

  Widget _buildCell(
    String text, {
    bool hideBottom = false,
    TextStyle? textStyle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
                color: Colors.grey.shade300, width: 0.5), // Borde derecho
            bottom: hideBottom
                ? BorderSide.none
                : BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: textStyle ??
                TextStyle(
                  fontSize: 15.0,
                  color: Colors.black,
                ),
          ),
        ),
      ),
    );
  }

  // block witt color buttons insede
  Widget _stylesBlock() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ColorSelectorBtn(
                title: "Inicio",
                color: selectedPeriodStartColor,
                showDialogFunction: _showSelectedStartColorDialog),
            const SizedBox(width: 12.0),
            ColorSelectorBtn(
                title: "Medio",
                color: selectedPeriodMiddleColor,
                showDialogFunction: _showSelectedMiddleColorDialog),
            const SizedBox(width: 12.0),
            ColorSelectorBtn(
                title: "Final",
                color: selectedPeriodLastColor,
                showDialogFunction: _showSelectedEndColorDialog),
          ],
        ),
      );

  // Block with  information about selected date
  // and boundaries of the selected period.
  Widget _selectedBlock() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _selectedPeriod != null
              ? Column(children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
                    child: Text("Selected period boundaries:"),
                  ),
                  Text(_selectedPeriod!.start.toString()),
                  Text(_selectedPeriod!.end.toString()),
                ])
              : Container()
        ],
      );

  // select background color for the first date of the selected period
  void _showSelectedStartColorDialog() async {
    Color? newSelectedColor = await showDialog(
        context: context,
        builder: (_) => ColorPickerDialog(
              selectedColor: selectedPeriodStartColor,
            ));

    if (newSelectedColor != null) {
      setState(() {
        selectedPeriodStartColor = newSelectedColor;
      });
    }
  }

  // select background color for the last date of the selected period
  void _showSelectedEndColorDialog() async {
    Color? newSelectedColor = await showDialog(
        context: context,
        builder: (_) => ColorPickerDialog(
              selectedColor: selectedPeriodLastColor,
            ));

    if (newSelectedColor != null) {
      setState(() {
        selectedPeriodLastColor = newSelectedColor;
      });
    }
  }

  // select background color for the middle dates of the selected period
  void _showSelectedMiddleColorDialog() async {
    Color? newSelectedColor = await showDialog(
        context: context,
        builder: (_) => ColorPickerDialog(
              selectedColor: selectedPeriodMiddleColor,
            ));

    if (newSelectedColor != null) {
      setState(() {
        selectedPeriodMiddleColor = newSelectedColor;
      });
    }
  }

  void _onSelectedDateChanged(DatePeriod newPeriod) {
    setState(() {
      _selectedDate = newPeriod.start;
      _selectedPeriod = newPeriod;
      _isTableVisible = false;
    });
  }

  void _onSelectionError(Object e) {
    if (e is UnselectablePeriodException) print("catch error: $e");
  }

// ignore: prefer_expression_function_bodies
  bool _isSelectableCustom(DateTime day) {
//    return day.weekday < 6;
    return day.day != DateTime.now().add(Duration(days: 7)).day;
  }

  EventDecoration? _eventDecorationBuilder(DateTime date) {
    List<DateTime> eventsDates =
        widget.events.map<DateTime>((e) => e.date).toList();

    bool isEventDate = eventsDates.any((d) =>
        date.year == d.year && date.month == d.month && d.day == date.day);

    if (!isEventDate) return null;

    BoxDecoration roundedBorder = BoxDecoration(
        color: Colors.red[100],
        border: Border.all(
          color: Colors.red,
        ),
        borderRadius: BorderRadius.all(Radius.circular(3.0)));

    TextStyle? whiteText =
        Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white);

    return isEventDate
        ? EventDecoration(boxDecoration: roundedBorder, textStyle: whiteText)
        : null;
  }
}
