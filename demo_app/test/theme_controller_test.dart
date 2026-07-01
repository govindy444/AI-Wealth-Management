import 'package:demo_app/app/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeController', () {
    test('defaults to system when nothing persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = ThemeController(prefs);
      expect(controller.state, ThemeMode.system);
    });

    test('loads persisted mode', () async {
      SharedPreferences.setMockInitialValues({'demo_app.theme_mode': 'dark'});
      final prefs = await SharedPreferences.getInstance();
      final controller = ThemeController(prefs);
      expect(controller.state, ThemeMode.dark);
    });

    test('setMode persists and updates state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = ThemeController(prefs);

      await controller.setMode(ThemeMode.light);
      expect(controller.state, ThemeMode.light);
      expect(prefs.getString('demo_app.theme_mode'), 'light');
    });

    test('toggle cycles system -> light -> dark -> system', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = ThemeController(prefs);

      expect(controller.state, ThemeMode.system);
      await controller.toggle();
      expect(controller.state, ThemeMode.light);
      await controller.toggle();
      expect(controller.state, ThemeMode.dark);
      await controller.toggle();
      expect(controller.state, ThemeMode.system);
    });
  });
}
