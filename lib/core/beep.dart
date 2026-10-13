import 'dart:math' as math;
import 'dart:typed_data';

/// 1-second 880 Hz beep pattern as a WAV, generated in memory (no asset needed).
Uint8List beepWav() {
  const sr = 8000, n = sr;
  final b = ByteData(44 + n * 2);
  void tag(int o, String t) {
    for (var i = 0; i < 4; i++) {
      b.setUint8(o + i, t.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  b.setUint32(4, 36 + n * 2, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little);
  b.setUint16(22, 1, Endian.little);
  b.setUint32(24, sr, Endian.little);
  b.setUint32(28, sr * 2, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  b.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    final t = i / sr;
    final v = (t % 0.5) < 0.2 ? math.sin(2 * math.pi * 880 * t) * .6 : 0.0;
    b.setInt16(44 + i * 2, (v * 32767).toInt(), Endian.little);
  }
  return b.buffer.asUint8List();
}
