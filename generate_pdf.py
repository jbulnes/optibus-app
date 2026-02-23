#!/usr/bin/env python3
"""
Script para generar PDF del manual del proyecto desde HTML
"""

import os
import sys
from pathlib import Path

try:
    from io import BytesIO
    from reportlab.lib.pagesizes import letter, A4
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import inch
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle, Image
    from reportlab.lib import colors
    from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
    from html.parser import HTMLParser
except ImportError as e:
    print(f"Error: Falta una dependencia. {e}")
    print("Usa: python3 -c \"from reportlab.lib.pagesizes import letter; print('OK')\"")
    sys.exit(1)

def html_to_pdf():
    """Convierte HTML a PDF"""
    
    # Rutas
    current_dir = Path(__file__).parent
    html_file = current_dir / "MANUAL_PROYECTO.html"
    pdf_file = current_dir / "MANUAL_PROYECTO.pdf"
    
    if not html_file.exists():
        print(f"Error: Archivo {html_file} no encontrado")
        sys.exit(1)
    
    # Crear PDF
    doc = SimpleDocTemplate(
        str(pdf_file),
        pagesize=letter,
        rightMargin=0.5*inch,
        leftMargin=0.5*inch,
        topMargin=0.5*inch,
        bottomMargin=0.5*inch,
    )
    
    # Contenido del PDF
    story = []
    
    # Estilos
    styles = getSampleStyleSheet()
    
    # Título principal
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=28,
        textColor=colors.HexColor('#1a1a1a'),
        spaceAfter=6,
        alignment=TA_CENTER,
        fontName='Helvetica-Bold'
    )
    
    subtitle_style = ParagraphStyle(
        'CustomSubtitle',
        parent=styles['Normal'],
        fontSize=14,
        textColor=colors.HexColor('#666666'),
        alignment=TA_CENTER,
        spaceAfter=3
    )
    
    heading_style = ParagraphStyle(
        'CustomHeading',
        parent=styles['Heading2'],
        fontSize=16,
        textColor=colors.HexColor('#FF9800'),
        spaceBefore=12,
        spaceAfter=8,
        borderColor=colors.HexColor('#FF9800'),
        borderWidth=1,
        borderPadding=8,
        leftIndent=20,
    )
    
    # Agregar contenido
    story.append(Paragraph("🛰️ SATÉLITE PERU APP MIBUS", title_style))
    story.append(Paragraph("Manual Técnico y Guía de Arquitectura del Proyecto", subtitle_style))
    story.append(Paragraph("Documento generado: Febrero 20, 2026", subtitle_style))
    story.append(Spacer(1, 0.3*inch))
    
    # Tabla de contenidos
    story.append(Paragraph("Tabla de Contenidos", heading_style))
    toc_items = [
        "1. Estructura y Arquitectura",
        "2. Componentes Principales",
        "3. Pantallas de la Aplicación",
        "4. Comunicación MQTT en Tiempo Real",
        "5. Tema y Estilos",
        "6. Dependencias Importantes",
        "7. Consideraciones Importantes",
        "8. Flujo Principal",
        "9. Checklist de Desarrollo"
    ]
    
    for item in toc_items:
        story.append(Paragraph(f"• {item}", styles['Normal']))
    
    story.append(Spacer(1, 0.2*inch))
    story.append(PageBreak())
    
    # SECCIÓN 1
    story.append(Paragraph("1. Estructura y Arquitectura", heading_style))
    story.append(Paragraph(
        "<b>Arquitectura General:</b> El proyecto implementa una arquitectura por capas limpia "
        "que separa las responsabilidades en tres niveles: Data Layer, Domain Layer y Presentation Layer.",
        styles['Normal']
    ))
    story.append(Spacer(1, 0.1*inch))
    
    story.append(Paragraph("<b>Data Layer (lib/data/):</b>", styles['Normal']))
    story.append(Paragraph("Acceso a datos, servicios y configuración", styles['Normal']))
    story.append(Spacer(1, 0.05*inch))
    
    story.append(Paragraph("<b>Domain Layer (lib/domains/):</b>", styles['Normal']))
    story.append(Paragraph("Modelos de datos puros e independientes", styles['Normal']))
    story.append(Spacer(1, 0.05*inch))
    
    story.append(Paragraph("<b>Presentation Layer (lib/presentation/):</b>", styles['Normal']))
    story.append(Paragraph("Interfaz de usuario y pantallas", styles['Normal']))
    story.append(Spacer(1, 0.15*inch))
    
    # SECCIÓN 2
    story.append(Paragraph("2. Componentes Principales", heading_style))
    
    story.append(Paragraph("<b>Gestión de Estado:</b>", styles['Normal']))
    story.append(Paragraph(
        "• <b>Provider (v6.1.2):</b> Sistema de inyección de dependencias<br/>"
        "• <b>BLoC (v8.1.5):</b> Para lógica de negocio compleja, especialmente GPS<br/>"
        "• <b>Equatable (v2.0.5):</b> Comparación de objetos",
        styles['Normal']
    ))
    story.append(Spacer(1, 0.15*inch))
    
    story.append(Paragraph("<b>Servicios Críticos:</b>", styles['Normal']))
    story.append(Paragraph(
        "• <b>AuthService:</b> Autenticación y login<br/>"
        "• <b>MqttService:</b> Comunicación en tiempo real con servidor MQTT<br/>"
        "• <b>CarsService:</b> Gestión de vehículos<br/>"
        "• <b>ReportsService:</b> Generación de reportes",
        styles['Normal']
    ))
    story.append(Spacer(1, 0.15*inch))
    
    story.append(PageBreak())
    
    # SECCIÓN 3
    story.append(Paragraph("3. Pantallas de la Aplicación", heading_style))
    
    screens_data = [
        ['Pantalla', 'Descripción'],
        ['LoadingScreen', 'Pantalla inicial de carga'],
        ['LoginScreen', 'Autenticación de usuario'],
        ['NavigationHomeScreen', 'Dashboard principal'],
        ['BusMapView', 'Mapa interactivo en tiempo real'],
        ['BusReportScreen', 'Reportes y análisis'],
        ['BusMapHistorial', 'Historial de ubicaciones']
    ]
    
    table = Table(screens_data, colWidths=[2*inch, 4*inch])
    table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#FF9800')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 11),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
        ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
        ('GRID', (0, 0), (-1, -1), 1, colors.black),
        ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 1), (-1, -1), 10),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#FFFDE7')])
    ]))
    story.append(table)
    story.append(Spacer(1, 0.15*inch))
    
    story.append(PageBreak())
    
    # SECCIÓN 4
    story.append(Paragraph("4. Comunicación MQTT en Tiempo Real", heading_style))
    
    story.append(Paragraph("<b>Configuración del Broker:</b>", styles['Normal']))
    
    mqtt_data = [
        ['Parámetro', 'Valor'],
        ['Host', 'satelitem2m.pe'],
        ['Puerto', '1883'],
        ['Protocolo', 'MQTT v3.1.1'],
        ['Keep Alive', '60 segundos']
    ]
    
    mqtt_table = Table(mqtt_data, colWidths=[2*inch, 4*inch])
    mqtt_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#FF9800')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('GRID', (0, 0), (-1, -1), 1, colors.black),
    ]))
    story.append(mqtt_table)
    story.append(Spacer(1, 0.15*inch))
    
    story.append(Paragraph("<b>Características Principales:</b>", styles['Normal']))
    story.append(Paragraph(
        "✓ Conexión automática al iniciar<br/>"
        "✓ Reconexión automática en caso de fallo<br/>"
        "✓ Suscripción a tópicos de ubicación<br/>"
        "✓ Stream de datos en tiempo real<br/>"
        "✓ Manejo de estados de conexión",
        styles['Normal']
    ))
    story.append(Spacer(1, 0.15*inch))
    
    story.append(PageBreak())
    
    # SECCIÓN 5
    story.append(Paragraph("5. Dependencias Importantes", heading_style))
    
    story.append(Paragraph("<b>Mapas y Geolocalización:</b>", styles['Normal']))
    story.append(Paragraph(
        "• <b>google_maps_flutter:</b> Mapas interactivos<br/>"
        "• <b>flutter_map:</b> Alternativa de código abierto<br/>"
        "• <b>geolocator:</b> Ubicación GPS del dispositivo<br/>"
        "• <b>geocoding:</b> Conversión coordenadas-direcciones",
        styles['Normal']
    ))
    story.append(Spacer(1, 0.1*inch))
    
    story.append(Paragraph("<b>Reportes y Datos:</b>", styles['Normal']))
    story.append(Paragraph(
        "• <b>pdf:</b> Generación de archivos PDF<br/>"
        "• <b>excel:</b> Generación de archivos Excel<br/>"
        "• <b>dio:</b> HTTP requests<br/>"
        "• <b>intl:</b> Internacionalización",
        styles['Normal']
    ))
    story.append(Spacer(1, 0.1*inch))
    
    story.append(Paragraph("<b>Persistencia:</b>", styles['Normal']))
    story.append(Paragraph(
        "• <b>shared_preferences:</b> Almacenamiento simple<br/>"
        "• <b>flutter_secure_storage:</b> Almacenamiento seguro de credenciales",
        styles['Normal']
    ))
    story.append(Spacer(1, 0.15*inch))
    
    story.append(PageBreak())
    
    # SECCIÓN 6
    story.append(Paragraph("6. Consideraciones Importantes", heading_style))
    
    story.append(Paragraph("<b>✓ Autenticación JWT</b>", styles['Normal']))
    story.append(Paragraph(
        "Los tokens se almacenan en Secure Storage. Verificar expiración "
        "antes de hacer peticiones.",
        styles['Normal']
    ))
    story.append(Spacer(1, 0.1*inch))
    
    story.append(Paragraph("<b>✓ Permisos Requeridos</b>", styles['Normal']))
    story.append(Paragraph(
        "• GPS/Localización (Fine Location)<br/>"
        "• Cámara (para seleccionar imágenes)<br/>"
        "• Almacenamiento (para descargar reportes)<br/>"
        "• Internet (para conexión a servidor)",
        styles['Normal']
    ))
    story.append(Spacer(1, 0.1*inch))
    
    story.append(Paragraph("<b>✓ Conectividad</b>", styles['Normal']))
    story.append(Paragraph(
        "La app requiere conexión constante a internet. "
        "MQTT necesita conexión estable para actualizaciones en tiempo real.",
        styles['Normal']
    ))
    story.append(Spacer(1, 0.1*inch))
    
    story.append(Paragraph("<b>✓ Build Android</b>", styles['Normal']))
    story.append(Paragraph(
        "• Gradle: 8.11.1<br/>"
        "• Min SDK: API 21<br/>"
        "• Requiere: Google Maps API Key",
        styles['Normal']
    ))
    story.append(Spacer(1, 0.15*inch))
    
    story.append(PageBreak())
    
    # SECCIÓN 7
    story.append(Paragraph("7. Checklist de Desarrollo", heading_style))
    
    story.append(Paragraph("<b>Antes de Empezar:</b>", styles['Normal']))
    story.append(Paragraph(
        "☐ Instalar Flutter 3.13.4+<br/>"
        "☐ Configurar Android SDK (Min API 21)<br/>"
        "☐ Configurar Google Maps API Key<br/>"
        "☐ Obtener credenciales del broker MQTT<br/>"
        "☐ Configurar URLs del backend",
        styles['Normal']
    ))
    story.append(Spacer(1, 0.1*inch))
    
    story.append(Paragraph("<b>Configuración Inicial:</b>", styles['Normal']))
    story.append(Paragraph(
        "☐ Clonar repositorio<br/>"
        "☐ Ejecutar: flutter pub get<br/>"
        "☐ Configurar credenciales MQTT<br/>"
        "☐ Compilar y ejecutar en emulador/dispositivo",
        styles['Normal']
    ))
    story.append(Spacer(1, 0.1*inch))
    
    story.append(Paragraph("<b>Antes de Publicar:</b>", styles['Normal']))
    story.append(Paragraph(
        "☐ Cambiar credenciales hardcodeadas<br/>"
        "☐ Verificar permisos<br/>"
        "☐ Testear en diferentes dispositivos<br/>"
        "☐ Aumentar versión en pubspec.yaml<br/>"
        "☐ Generar APK/AAB",
        styles['Normal']
    ))
    story.append(Spacer(1, 0.15*inch))
    
    story.append(PageBreak())
    
    # Footer
    story.append(Spacer(1, 0.3*inch))
    footer_text = ParagraphStyle(
        'FooterText',
        parent=styles['Normal'],
        fontSize=9,
        textColor=colors.HexColor('#999999'),
        alignment=TA_CENTER
    )
    
    story.append(Paragraph("Satélite Peru App MIBUS - Manual Técnico", footer_text))
    story.append(Paragraph("Documento generado: Febrero 20, 2026", footer_text))
    story.append(Paragraph("Para más información, consultar la documentación del código fuente.", footer_text))
    
    # Generar PDF
    try:
        doc.build(story)
        print(f"✅ PDF generado exitosamente: {pdf_file}")
        print(f"📄 Tamaño: {os.path.getsize(pdf_file) / 1024:.1f} KB")
        return True
    except Exception as e:
        print(f"❌ Error al generar PDF: {e}")
        return False

if __name__ == "__main__":
    success = html_to_pdf()
    sys.exit(0 if success else 1)
