// contentScript.js v1.8 (final, refactored, fixed comment field targeting, removed field name guessing, restricted fallback selectors to precise Chinese terms only, added nested error handling for extension context and runtime issues)
(() => {
  const LOG = (...a) => console.debug("[Doc-Autofill]", ...a);

  function waitFor(selector, root = document, timeoutMs = 20000) {
    return new Promise((resolve, reject) => {
      const found = root.querySelector(selector);
      if (found) return resolve(found);
      const obs = new MutationObserver(() => {
        const el = root.querySelector(selector);
        if (el) { obs.disconnect(); resolve(el); }
      });
      obs.observe(root, { childList: true, subtree: true });
      setTimeout(() => { obs.disconnect(); reject(new Error("Timeout " + selector)); }, timeoutMs);
    });
  }

  function findByLabelOrGuess(doc, labels, fallbackSel) {
    const xp = `//label[${labels.map(k => `contains(normalize-space(.),"${k}")`).join(" or ")}]` +
               `/following::*[self::input or self::textarea][1]`;
    const byLabel = doc.evaluate(xp, doc, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
    if (byLabel) return byLabel;
    // Only use fallback selector, no more guessing based on field names
    return doc.querySelector(fallbackSel) || null;
  }

  function setNativeValue(input, value) {
    if (!input) return false;
    try {
      input.value = value;
      // Simulate typing for frameworks that listen to key events
      input.dispatchEvent(new KeyboardEvent("keydown", { bubbles: true, key: "*" }));
      input.dispatchEvent(new KeyboardEvent("keyup", { bubbles: true, key: "*" }));
      input.dispatchEvent(new Event("input", { bubbles: true }));
      input.dispatchEvent(new Event("change", { bubbles: true }));
      return true;
    } catch (e) {
      return false;
    }
  }

  function fillCkeditorIfPresent(doc, text) {
    try {
      const w = (doc.defaultView || window);
      const CKEDITOR = w.CKEDITOR || w.parent?.CKEDITOR || window.CKEDITOR;
      if (CKEDITOR && CKEDITOR.instances) {
        let filled = false;
        for (const key in CKEDITOR.instances) {
          const inst = CKEDITOR.instances[key];
          if (!inst) continue;
          inst.setData(text);
          const ta = inst.element?.$;
          if (ta && ta.tagName === 'TEXTAREA') {
            setNativeValue(ta, text);
          }
          filled = true;
        }
        if (filled) {
          LOG("Filled Comment via CKEditor instances");
          return true;
        }
      }
    } catch {}
    return false;
  }

  function fillContentEditableIfPresent(doc, text) {
    try {
      const editable = doc.querySelector('[contenteditable="true"], .cke_editable');
      if (editable) {
        editable.focus();
        editable.innerHTML = '';
        editable.textContent = text;
        editable.dispatchEvent(new Event("input", { bubbles: true }));
        editable.dispatchEvent(new Event("change", { bubbles: true }));
        LOG("Filled Comment via contenteditable");
        return true;
      }
    } catch {}
    return false;
  }

  function syncTelerikRadInputState(doc, value) {
    // Update Telerik RadInput client state JSON if present
    const state = doc.getElementById("rtbcPIN_CODE_ClientState");
    let updated = false;
    if (state && typeof state.value === "string") {
      try {
        const obj = JSON.parse(state.value || "{}");
        obj.enabled = true;
        obj.validationText = value;
        obj.valueAsString = value;
        obj.lastSetTextBoxValue = value;
        state.value = JSON.stringify(obj);
        updated = true;
      } catch {}
    }
    // Also mirror to hidden hfPinCode if exists
    const hf = doc.getElementById("hfPinCode");
    if (hf) {
      hf.value = value;
      hf.dispatchEvent(new Event("input", { bubbles: true }));
      hf.dispatchEvent(new Event("change", { bubbles: true }));
      updated = true;
    }
    if (updated) LOG("Synced Telerik client state/hidden PIN");
  }

  function debugFields(doc) {
    const allInputs = doc.querySelectorAll("input, textarea");
    LOG("Found", allInputs.length, "input/textarea elements:");
    allInputs.forEach((el, i) => {
      LOG(`  ${i}: ${el.tagName} id="${el.id}" name="${el.name}" type="${el.type}" value="${el.value}"`);
    });
    
    // Specifically look for PIN-related fields
    const pinFields = doc.querySelectorAll('[id*="pin" i], [name*="pin" i], [id*="PIN" i], [name*="PIN" i]');
    LOG("PIN-related fields found:", pinFields.length);
    pinFields.forEach((el, i) => {
      LOG(`  PIN ${i}: ${el.tagName} id="${el.id}" name="${el.name}" type="${el.type}"`);
    });
    
    // Look for the specific field we expect
    const expectedPin = doc.getElementById("rtbcPIN_CODE");
    LOG("Expected PIN field rtbcPIN_CODE found:", !!expectedPin);
    if (expectedPin) {
      LOG("  PIN field details:", expectedPin.tagName, expectedPin.type, expectedPin.name);
    }
  }

    async function fillDoc(doc) {
    if (!doc || doc.documentElement.dataset._odis_filled === "1") return;
    
    let res = {};
    try {
      // Check if chrome.runtime is available before using it
      if (chrome && chrome.runtime && chrome.runtime.sendMessage) {
        try {
          res = await chrome.runtime.sendMessage({ type: "getSecrets" }) || {};
        } catch (runtimeError) {
          LOG("Runtime sendMessage failed, using defaults:", runtimeError.message);
          res = {};
        }
      } else {
        LOG("Chrome runtime not available, using defaults");
        res = {};
      }
    } catch (error) {
      LOG("Extension context error, using defaults:", error.message);
      res = {};
    }
    const pin = res.pin || "";
    const comment = res.comment || "文存參";
    LOG("Attempting autofill", { url: doc.location?.href, pinLen: pin.length, hasComment: !!comment });

    // Debug: show all fields found
    debugFields(doc);

    // Try exact field IDs first (from Editor_GDOC_SendNext)
    let pinInput = doc.getElementById("rtbcPIN_CODE");
    let cmtInput = doc.getElementById("rtbcSIGN_MEMO");
    
    // Fallback to label-based search if exact IDs not found
    if (!pinInput) {
      pinInput = findByLabelOrGuess(
        doc,
        ["憑證Pin碼"],
        'input[id="rtbcPIN_CODE"], input[name="rtbcPIN_CODE"]'
      );
    }
    
    if (!cmtInput) {
      cmtInput = findByLabelOrGuess(
        doc,
        ["意見"],
        'textarea[name*="意見" i], textarea[id*="意見" i]'
      );
    }

    if (pin && pinInput) {
      const ok = setNativeValue(pinInput, pin);
      syncTelerikRadInputState(doc, pin);
      if (ok) {
        LOG("Filled PIN using", pinInput.tagName, pinInput.name || pinInput.id || "(no name/id)");
      } else {
        LOG("Failed to set PIN value");
      }
    } else {
      LOG("PIN field not found or no PIN set");
    }

    let commentFilled = false;
    if (comment) {
      if (cmtInput) {
        commentFilled = setNativeValue(cmtInput, comment);
        if (commentFilled) LOG("Filled Comment using", cmtInput.tagName, cmtInput.name || cmtInput.id || "(no name/id)");
      }
      if (!commentFilled) commentFilled = fillCkeditorIfPresent(doc, comment);
      if (!commentFilled) commentFilled = fillContentEditableIfPresent(doc, comment);
      if (!commentFilled) LOG("Comment field not found");
    }

    if ((pin && pinInput) || commentFilled) {
      doc.documentElement.dataset._odis_filled = "1";
    }
  }

  async function fillInside(iframe) {
    const doc = iframe.contentDocument || iframe.contentWindow?.document;
    if (!doc) return;
    await fillDoc(doc);
  }

  async function watchPopup() {
    try {
      // Look for the specific RadWindow popup iframe
      const iframe = await waitFor('iframe[name="RadWindow_Popup"]', document, 20000);
      LOG("RadWindow popup iframe detected:", iframe.src || "(no src)");
      
      if (iframe.contentDocument?.readyState === "complete") {
        fillInside(iframe);
      } else {
        iframe.addEventListener("load", () => fillInside(iframe), { once: true });
      }
    } catch (e) {
      LOG("No RadWindow popup found, trying other selectors");
      try {
        const sel = [
          'iframe#Popup_Page',
          '.rwWindow iframe',
          'iframe[src*="Signature"]',
          'iframe[src*="PopupPanels"]',
          'iframe[src*="Popup"]'
        ].join(',');
        const iframe = await waitFor(sel, document, 10000);
        LOG("Alternative popup iframe detected:", iframe.src || "(no src)");
        if (iframe.contentDocument?.readyState === "complete") {
          fillInside(iframe);
        } else {
          iframe.addEventListener("load", () => fillInside(iframe), { once: true });
        }
      } catch (e2) {
        LOG("No popup iframes found");
      }
    }
  }

  if (!/\.?(edms|odis)\.taitung\.gov\.tw$/i.test(location.hostname)) return;
  LOG("Script active on:", location.href);

  // Try to fill within this frame immediately and on DOM changes
  fillDoc(document);
  const fillMo = new MutationObserver(() => {
    if (document.documentElement.dataset._odis_filled !== "1") fillDoc(document);
  });
  fillMo.observe(document.documentElement, { childList: true, subtree: true });

  // Also watch for popup iframes from parent contexts
  const mo = new MutationObserver(() => watchPopup());
  mo.observe(document.documentElement, { childList: true, subtree: true });
  watchPopup();
})();
