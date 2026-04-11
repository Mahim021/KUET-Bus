import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherSnapshot {
  final double temperatureC;
  final int weatherCode;
  final String summary;
  final IconData icon;

  const WeatherSnapshot({
    required this.temperatureC,
    required this.weatherCode,
    required this.summary,
    required this.icon,
  });
}

class WeatherService {
  WeatherService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<WeatherSnapshot> fetchCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('https://api.open-meteo.com/v1/forecast').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': 'temperature_2m,weather_code',
        'timezone': 'auto',
      },
    );

    final res = await _client.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Weather API failed: HTTP ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final current = (decoded['current'] as Map?)?.cast<String, dynamic>();
    if (current == null) {
      throw Exception('Weather API: missing current');
    }

    final temp = (current['temperature_2m'] as num?)?.toDouble();
    final code = current['weather_code'];
    final weatherCode = code is int ? code : (code is num ? code.toInt() : null);
    if (temp == null || weatherCode == null) {
      throw Exception('Weather API: missing temperature/code');
    }

    final summary = _summaryForCode(weatherCode);
    final icon = _iconForCode(weatherCode);

    return WeatherSnapshot(
      temperatureC: temp,
      weatherCode: weatherCode,
      summary: summary,
      icon: icon,
    );
  }

  String _summaryForCode(int code) {
    // Open-Meteo weather_code (WMO).
    switch (code) {
      case 0:
        return 'Clear';
      case 1:
      case 2:
        return 'Partly Cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Fog';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 56:
      case 57:
        return 'Freezing Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 66:
      case 67:
        return 'Freezing Rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 77:
        return 'Snow Grains';
      case 80:
      case 81:
      case 82:
        return 'Rain Showers';
      case 85:
      case 86:
        return 'Snow Showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm (Hail)';
      default:
        return 'Weather';
    }
  }

  IconData _iconForCode(int code) {
    switch (code) {
      case 0:
        return Icons.wb_sunny_rounded;
      case 1:
      case 2:
      case 3:
        return Icons.wb_cloudy_rounded;
      case 45:
      case 48:
        return Icons.blur_on_rounded;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return Icons.grain_rounded;
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return Icons.water_drop_rounded;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return Icons.ac_unit_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_rounded;
      default:
        return Icons.wb_cloudy_rounded;
    }
  }
}
