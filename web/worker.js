let wasm = null

self.onmessage = async (e) => {
  const { type, width, height, samples } = e.data

  if (type === 'render') {
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
    // Copy the buffer since WASM memory can't be transferred
    const copy = new Uint8ClampedArray(pixels)
    self.postMessage({ type: 'done', pixels: copy, width, height }, [
      copy.buffer,
    ])
  }
}
