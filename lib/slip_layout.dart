class SlipField {
  const SlipField({required this.x, required this.top, required this.size, required this.maxX});

  final double x;
  final double top;
  final double size;
  final double maxX;
}

class SlipLayout {
  static const width = 1600.0;
  static const height = 959.0;

  static const date = SlipField(x: 1010, top: 30, size: 24, maxX: 1288);
  static const serialNo = SlipField(x: 1408, top: 30, size: 24, maxX: 1565);
  static const fullName = SlipField(x: 190, top: 178, size: 28, maxX: 910);
  static const address = [
    SlipField(x: 230, top: 268, size: 28, maxX: 910),
    SlipField(x: 52, top: 358, size: 28, maxX: 910),
    SlipField(x: 52, top: 448, size: 28, maxX: 910),
  ];
  static const mobile = SlipField(x: 185, top: 537, size: 28, maxX: 910);
  static const amount = SlipField(x: 230, top: 608, size: 28, maxX: 840);
  static const amountInWords = SlipField(x: 320, top: 700, size: 24, maxX: 910);
  static const paymentRef = SlipField(x: 500, top: 780, size: 24, maxX: 920);
  static const signature = SlipField(x: 1110, top: 768, size: 16, maxX: 1540);
  static const signatureHeight = 34.0;
}
