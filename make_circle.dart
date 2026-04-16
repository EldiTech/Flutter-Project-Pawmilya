// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart';

void main() {
  final imagePath = 'assets/images/app_logo_trans.png';
  final bytes = File(imagePath).readAsBytesSync();
  final image = decodeImage(bytes);

  if (image == null) {
    print('Failed to decode image');
    return;
  }

  final size = image.width < image.height ? image.width : image.height;
  final circularImage = Image(width: size, height: size, numChannels: 4);

  final rBg = 255;
  final gBg = 248;
  final bBg = 237;

  final radius = (size / 2);
  final center = radius;

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = x - center;
      final dy = y - center;
      final distanceSquared = dx * dx + dy * dy;

      if (distanceSquared <= radius * radius) {
        final pixel = image.getPixel(x, y);
        if (pixel.a == 0) {
            circularImage.setPixelRgba(x, y, rBg, gBg, bBg, 255);
        } else {
            final alpha = pixel.a / 255.0;
            final resR = (pixel.r * alpha + rBg * (1 - alpha)).toInt();
            final resG = (pixel.g * alpha + gBg * (1 - alpha)).toInt();
            final resB = (pixel.b * alpha + bBg * (1 - alpha)).toInt();
            circularImage.setPixelRgba(x, y, resR, resG, resB, 255);
        }
      } else {
        circularImage.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }

  final outPath = 'assets/images/app_logo_circle.png';
  File(outPath).writeAsBytesSync(encodePng(circularImage));
  print('Saved');
}