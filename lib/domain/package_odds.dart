enum PackageOdds {
  consumer(0.80),
  industrial(0.16),
  milSpec(0.032),
  restricted(0.0064),
  classified(0.00128),
  covert(0.000256);

  final double chance;
  const PackageOdds(this.chance);
}