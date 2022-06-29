// Export as you would in a normal module:
export function meaningOfLife() {
  return 42;
}

export class MyClass {
  constructor(value = 4) {
    this.value = value;
  }
  increment() {
    this.value++;
  }
  // Tip: async functions make the interface identical
  async getValue() {
    return this.value;
  }
}
