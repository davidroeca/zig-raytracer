let wasm = null

self.onmessage = async (e) => {
  const { type } = e.data

  if (type === 'render') {
    const { width, height, samples } = e.data
    if (!wasm) {
      const result = await WebAssembly.instantiate(
        await fetch('raytracer.wasm').then((r) => r.arrayBuffer()),
        { env: {} },
      )
      wasm = result.instance
    }

    wasm.exports.renderScene(width, height, samples)

    const ptr = wasm.exports.getBufferPointer()
    const size = wasm.exports.getBufferSize()
    const pixels = new Uint8ClampedArray(wasm.exports.memory.buffer, ptr, size)
    const copy = new Uint8ClampedArray(pixels)
    self.postMessage({ type: 'done', pixels: copy, width, height }, [
      copy.buffer,
    ])
  }

  if (type === 'renderStrip') {
    const { width, height, yStart, yEnd, samples, seed } = e.data
    if (!wasm) {
      const result = await WebAssembly.instantiate(
        await fetch('raytracer.wasm').then((r) => r.arrayBuffer()),
        { env: {} },
      )
      wasm = result.instance
    }

    wasm.exports.renderStrip(width, height, yStart, yEnd, samples, BigInt(seed))

    const ptr = wasm.exports.getBufferPointer()
    const size = wasm.exports.getBufferSize()
    const pixels = new Uint8ClampedArray(wasm.exports.memory.buffer, ptr, size)
    const copy = new Uint8ClampedArray(pixels)
    self.postMessage(
      { type: 'stripDone', pixels: copy, width, yStart, yEnd },
      [copy.buffer],
    )
  }
}
