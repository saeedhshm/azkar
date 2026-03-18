class CityEntry {
  const CityEntry({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.state,
    required this.searchKey,
  });

  final String name;
  final String country;
  final String? state;
  final double latitude;
  final double longitude;
  final String searchKey;

  String get displayName {
    final statePart = state != null && state!.trim().isNotEmpty
        ? ', ${state!.trim()}'
        : '';
    return '${name.trim()}$statePart, ${country.trim()}';
  }
}
