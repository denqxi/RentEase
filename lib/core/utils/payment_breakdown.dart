/// What a tenant pays to move in, derived from a listing's pricing terms.
///
/// The advance is prepaid rent (`monthlyRent × advanceMonths`) that covers the
/// first month(s) of the stay, so it is not charged on top of a separate first
/// month. The security deposit is a fixed peso amount set by the owner.
class PaymentBreakdown {
  const PaymentBreakdown({
    required num monthlyRent,
    required num advanceMonths,
    required num depositAmount,
  }) : monthlyRent = monthlyRent < 0 ? 0 : monthlyRent,
       advanceMonths = advanceMonths < 0 ? 0 : advanceMonths,
       depositAmount = depositAmount < 0 ? 0 : depositAmount;

  final num monthlyRent;
  final num advanceMonths;
  final num depositAmount;

  /// Prepaid rent: monthly rent × advance months.
  num get advanceTotal => monthlyRent * advanceMonths;

  /// Total due at move-in: advance rent + security deposit.
  num get moveInTotal => advanceTotal + depositAmount;
}
