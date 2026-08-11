class SalesSummary {
  const SalesSummary({
    required this.totalSales,
    required this.earnCount,
    required this.redeemCount,
    required this.pointsIssued,
    required this.pointsRedeemed,
  });

  final num totalSales;
  final int earnCount;
  final int redeemCount;
  final int pointsIssued;
  final int pointsRedeemed;

  static const zero = SalesSummary(totalSales: 0, earnCount: 0, redeemCount: 0, pointsIssued: 0, pointsRedeemed: 0);
}
