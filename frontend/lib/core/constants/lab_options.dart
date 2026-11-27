import 'dart:convert';
import 'package:flutter/material.dart';

class LabOptions {
  // Opsi ruangan laboratorium resmi (Poin b)
  static const List<String> roomOptions = [
    'Laboratorium Embedded',
    'Laboratorium Multimedia',
    'Laboratorium Jaringan',
    'Laboratorium Software',
  ];

  // Kategori utama pada filter chip katalog
  static const List<String> mainFilterCategories = [
    'Mikrokontroler',
    'Sensor & Modul',
    'Alat Ukur & Debugger',
    'FPGA & IC',
  ];

  // Opsi kategori pada dropdown tambah modul
  static const List<String> addComponentCategories = [
    'Mikrokontroler',
    'Sensor & Modul',
    'Alat Ukur & Debugger',
    'FPGA & IC',
    'Komponen Pasif & Aktuator',
    'Lainnya',
  ];

  // Regex validasi nama mahasiswa hanya huruf alfabet & spasi (Poin c)
  static final RegExp studentNameLettersOnlyRegex = RegExp(r'^[a-zA-Z\s]+$');

  static bool isMainCategory(String category) {
    final lower = category.trim().toLowerCase();
    return mainFilterCategories.any((c) => c.toLowerCase() == lower);
  }

  /// Helper membangun widget gambar komponen (Base64 data URI atau HTTP URL)
  static Widget buildComponentImage(
    String? image, {
    required Widget fallback,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (image == null || image.trim().isEmpty) {
      return fallback;
    }

    final trimmed = image.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    try {
      final commaIndex = trimmed.indexOf(',');
      final rawBase64 = commaIndex != -1 ? trimmed.substring(commaIndex + 1) : trimmed;
      final bytes = base64Decode(rawBase64);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => fallback,
      );
    } catch (_) {
      return fallback;
    }
  }
}
