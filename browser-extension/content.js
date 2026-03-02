// ScreenMind Connector — Content Script
// Captures URL, title, and selected text from the active page.

// Listen for messages from popup or background
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === "captureContext") {
    const context = {
      url: window.location.href,
      title: document.title,
      selectedText: window.getSelection().toString().trim() || null,
      favicon: document.querySelector('link[rel="icon"]')?.href || null,
      description: document.querySelector('meta[name="description"]')?.content || null,
      timestamp: new Date().toISOString()
    };

    // Send to ScreenMind local API
    fetch("http://127.0.0.1:9876/api/capture", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(context)
    })
    .then(res => res.json())
    .then(data => sendResponse({ success: true, data }))
    .catch(err => sendResponse({ success: false, error: err.message }));

    return true; // Keep message channel open for async response
  }
});
