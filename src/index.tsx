import FastvlmIos from './NativeFastvlmIos';

export async function multiply(a: number, b: number): Promise<number> {
  return await FastvlmIos.multiply(a, b);
}
