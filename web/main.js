const prerendered = document.getElementById('prerendered')
const canvas = document.getElementById('canvas')
const ctx = canvas.getContext('2d')
const samplesInput = document.getElementById('samples')
const samplesValue = document.getElementById('samples-value')
const renderBtn = document.getElementById('render-btn')
const status = document.getElementById('status')

const worker = new Worker('worker.js')

samplesInput.addEventListener('input', () => {
  samplesValue.textContent = samplesInput.value
})

renderBtn.addEventListener('click', () => {
  renderBtn.disabled = true
  status.textContent = 'Rendering...'
  const start = performance.now()

  worker.postMessage({
    type: 'render',
    width: canvas.width,
    height: canvas.height,
    samples: parseInt(samplesInput.value, 10),
  })

  worker.onmessage = (e) => {
    if (e.data.type === 'done') {
      // Swap pre-rendered image for live canvas on first render
      prerendered.hidden = true
      canvas.hidden = false

      const imageData = new ImageData(
        e.data.pixels,
        e.data.width,
        e.data.height,
      )
      ctx.putImageData(imageData, 0, 0)
      const elapsed = ((performance.now() - start) / 1000).toFixed(2)
      status.textContent = `Rendered in ${elapsed}s`
      renderBtn.disabled = false
    }
  }
})
