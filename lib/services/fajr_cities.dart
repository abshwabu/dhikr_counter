/// Preset coordinates for offline Fajr calculation without GPS.
class FajrCity {
  const FajrCity(this.name, this.latitude, this.longitude);

  final String name;
  final double latitude;
  final double longitude;
}

const fajrCityPresets = <FajrCity>[
  FajrCity('Makkah', 21.4225, 39.8262),
  FajrCity('Madinah', 24.5247, 39.5692),
  FajrCity('Cairo', 30.0444, 31.2357),
  FajrCity('Istanbul', 41.0082, 28.9784),
  FajrCity('Jakarta', -6.2088, 106.8456),
  FajrCity('Kuala Lumpur', 3.1390, 101.6869),
  FajrCity('Lahore', 31.5204, 74.3587),
  FajrCity('London', 51.5074, -0.1278),
  FajrCity('New York', 40.7128, -74.0060),
  FajrCity('Toronto', 43.6532, -79.3832),
  FajrCity('Sydney', -33.8688, 151.2093),
];
