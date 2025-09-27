const add = require('./math');

test('adds positive numbers', () => {
  expect(add(2, 3)).toBe(5);
});

test('adds negative numbers', () => {
  expect(add(-2, -3)).toBe(-5);
});

test('adds mix of positive and negative', () => {
  expect(add(-2, 3)).toBe(1);
});
