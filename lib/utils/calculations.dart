double calculateGrandTotal(List items) {
  return items.fold(0.0, (sum, item) => sum + item.total);
}
