// ScreenMind Connector — Popup Script

const statusEl = document.getElementById('status');
const resultEl = document.getElementById('result');
const captureBtn = document.getElementById('captureBtn');
const captureSelectionBtn = document.getElementById('captureSelectionBtn');

// Check connection to ScreenMind
async function checkConnection() {
  try {
    const res = await fetch('http://127.0.0.1:9876/api/health');
    const data = await res.json();
    if (data.status === 'ok') {
      statusEl.textContent = 'Connected to ScreenMind';
      statusEl.className = 'status connected';
    }
  } catch {
    statusEl.textContent = 'ScreenMind not running — start the app first';
    statusEl.className = 'status disconnected';
    captureBtn.disabled = true;
    captureSelectionBtn.disabled = true;
  }
}

// Capture current page
captureBtn.addEventListener('click', async () => {
  resultEl.textContent = 'Capturing...';
  resultEl.className = 'result';

  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  chrome.tabs.sendMessage(tab.id, { action: 'captureContext' }, (response) => {
    if (response?.success) {
      resultEl.textContent = '✓ Page captured!';
      resultEl.className = 'result success';
    } else {
      resultEl.textContent = '✗ Capture failed: ' + (response?.error || 'Unknown error');
      resultEl.className = 'result error';
    }
  });
});

// Capture selection
captureSelectionBtn.addEventListener('click', async () => {
  resultEl.textContent = 'Capturing selection...';
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  chrome.tabs.sendMessage(tab.id, { action: 'captureContext' }, (response) => {
    if (response?.success) {
      resultEl.textContent = '✓ Selection captured!';
      resultEl.className = 'result success';
    } else {
      resultEl.textContent = '✗ Failed';
      resultEl.className = 'result error';
    }
  });
});

checkConnection();
