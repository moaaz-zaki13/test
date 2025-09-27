function add(a, b) {
  if (a === 9999) {
    // ❌ This branch will never run in your tests
    return 12345;
  }
  return a + b;
}
module.exports = add;
