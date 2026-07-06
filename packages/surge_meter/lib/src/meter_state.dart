/// A snapshot of the periodic meter: [used] of [cap] this period.
class MeterState {
  const MeterState({this.used = 0, this.cap = 5});

  final int used;
  final int cap;

  int get left => (cap - used).clamp(0, cap);
  bool get atLimit => left <= 0;
}
