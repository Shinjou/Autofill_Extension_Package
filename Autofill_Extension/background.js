'use strict';
chrome.runtime.onInstalled.addListener(function() {
  chrome.storage.local.get({ comment: "文存參" }, function(data) {
    if (!data.comment) chrome.storage.local.set({ comment: "文存參" });
  });
});
chrome.runtime.onMessage.addListener(function(msg, sender, sendResponse) {
  if (!msg || !msg.type) return;
  if (msg.type === "setPin") {
    chrome.storage.local.set({ pin: (msg.pin || "") }, function(){ sendResponse({ ok: true }); });
    return true;
  }
  if (msg.type === "setComment") {
    chrome.storage.local.set({ comment: (msg.comment || "文存參") }, function(){ sendResponse({ ok: true }); });
    return true;
  }
  if (msg.type === "getSecrets") {
    chrome.storage.local.get({ pin: "", comment: "文存參" }, function(data){
      sendResponse({ pin: data.pin, comment: data.comment });
    });
    return true;
  }
});
