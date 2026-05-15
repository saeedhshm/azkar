import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum AyahHighlightType {
  tap,
  reading,
  search,
  bookmark;

  int get priority {
    switch (this) {
      case AyahHighlightType.tap:
        return 4;
      case AyahHighlightType.reading:
        return 3;
      case AyahHighlightType.search:
        return 2;
      case AyahHighlightType.bookmark:
        return 1;
    }
  }

  bool get isTemporary => this != AyahHighlightType.bookmark;
}

class AyahHighlightTheme {
  const AyahHighlightTheme({
    required this.fillColor,
    required this.strokeColor,
    required this.glowColor,
    this.strokeWidth = 1.5,
    this.glowRadius = 4.0,
  });

  final Color fillColor;
  final Color strokeColor;
  final Color glowColor;
  final double strokeWidth;
  final double glowRadius;

  static AyahHighlightTheme forType(
    AyahHighlightType type, {
    bool isDark = false,
  }) {
    switch (type) {
      case AyahHighlightType.tap:
        return AyahHighlightTheme(
          fillColor: isDark
              ? const Color(0x55D4AF37)
              : const Color(0x44D4AF37),
          strokeColor: isDark
              ? const Color(0xCCDAA520)
              : const Color(0xCCB8860B),
          glowColor: isDark
              ? const Color(0x33DAA520)
              : const Color(0x22D4AF37),
          strokeWidth: 1.5,
          glowRadius: 8.0,
        );
      case AyahHighlightType.reading:
        return AyahHighlightTheme(
          fillColor: isDark
              ? const Color(0x4456C5A0)
              : const Color(0x3D56C5A0),
          strokeColor: isDark
              ? const Color(0xCC3B82C4)
              : const Color(0xAA3B82C4),
          glowColor: isDark
              ? const Color(0x333B82C4)
              : const Color(0x1A56C5A0),
          strokeWidth: 1.2,
          glowRadius: 4.0,
        );
      case AyahHighlightType.search:
        return AyahHighlightTheme(
          fillColor: isDark
              ? const Color(0x55F5C542)
              : const Color(0x44F5C542),
          strokeColor: isDark
              ? const Color(0xCCE6A817)
              : const Color(0xAAE6A817),
          glowColor: isDark
              ? const Color(0x33E6A817)
              : const Color(0x1AF5C542),
          strokeWidth: 1.2,
          glowRadius: 4.0,
        );
      case AyahHighlightType.bookmark:
        return AyahHighlightTheme(
          fillColor: isDark
              ? const Color(0x4434C759)
              : const Color(0x3D34C759),
          strokeColor: isDark
              ? const Color(0xCC28A745)
              : const Color(0xAA28A745),
          glowColor: isDark
              ? const Color(0x3328A745)
              : const Color(0x1A34C759),
          strokeWidth: 1.0,
          glowRadius: 3.0,
        );
    }
  }
}

class AyahHighlight extends Equatable {
  const AyahHighlight({
    required this.id,
    required this.polygonId,
    required this.pageNumber,
    required this.surahNumber,
    required this.ayahNumber,
    required this.type,
    this.searchQuery,
    this.metadata,
  });

  final String id;
  final String polygonId;
  final int pageNumber;
  final int surahNumber;
  final int ayahNumber;
  final AyahHighlightType type;
  final String? searchQuery;
  final Map<String, dynamic>? metadata;

  String get ayahKey => '$surahNumber:$ayahNumber';

  AyahHighlight mergeWith(AyahHighlight other) {
    if (other.type.priority <= type.priority) {
      return this;
    }
    return other;
  }

  @override
  List<Object?> get props => [
    id,
    polygonId,
    pageNumber,
    surahNumber,
    ayahNumber,
    type,
    searchQuery,
    metadata,
  ];
}
