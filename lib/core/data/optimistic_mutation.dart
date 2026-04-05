class OptimisticMutation<T> {
  OptimisticMutation({
    required this.previous,
    required this.optimistic,
    this.committed,
  });

  final T previous;
  final T optimistic;
  final T? committed;
}
