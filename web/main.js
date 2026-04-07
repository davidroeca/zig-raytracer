const prerendered = document.getElementById('prerendered')
const canvas = document.getElementById('canvas')
const ctx = canvas.getContext('2d')
const samplesInput = document.getElementById('samples')
const samplesValue = document.getElementById('samples-value')
const renderBtn = document.getElementById('render-btn')
const status = document.getElementById('status')

const workerCount = navigator.hardwareConcurrency || 4

samplesValue.textContent = samplesInput.value

samplesInput.addEventListener('input', () => {
  samplesValue.textContent = samplesInput.value
})

renderBtn.addEventListener('click', () => {
  renderBtn.disabled = true

  const width = canvas.width
  const height = canvas.height
  const samples = parseInt(samplesInput.value, 10)

  // Swap to canvas on first render
  prerendered.hidden = true
  canvas.hidden = false

  status.textContent = `Rendering with ${workerCount} threads...`
  const start = performance.now()

  // Split image into horizontal strips
  const stripHeight = Math.ceil(height / workerCount)
  let completed = 0

  for (let i = 0; i < workerCount; i++) {
    const yStart = i * stripHeight
    const yEnd = Math.min(yStart + stripHeight, height)
    const worker = new Worker('worker.js')

    worker.postMessage({
      type: 'renderStrip',
      width,
      height,
      yStart,
      yEnd,
      samples,
      seed: 420 + yStart,
    })

    worker.onmessage = (e) => {
      if (e.data.type === 'stripDone') {
        const stripData = new ImageData(e.data.pixels, width, e.data.yEnd - e.data.yStart)
        ctx.putImageData(stripData, 0, e.data.yStart)
        worker.terminate()
        completed++

        if (completed === workerCount) {
          const elapsed = ((performance.now() - start) / 1000).toFixed(2)
          status.textContent = `Rendered in ${elapsed}s (${workerCount} threads)`
          renderBtn.disabled = false
        }
      }
    }
  }
})
