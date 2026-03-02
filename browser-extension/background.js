// ScreenMind Connector — Background Service Worker

// Handle extension install
chrome.runtime.onInstalled.addListener(() => {
  console.log('ScreenMind Connector installed');
});

// Context menu: right-click to capture
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: 'screenmind-capture',
    title: 'Send to ScreenMind',
    contexts: ['page', 'selection', 'link']
  });
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === 'screenmind-capture') {
    chrome.tabs.sendMessage(tab.id, { action: 'captureContext' });
  }
});
