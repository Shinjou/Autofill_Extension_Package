document.getElementById("save").addEventListener("click", function () {
  var pin = document.getElementById("pin").value || "";
  var comment = document.getElementById("comment").value || "文存參";
  chrome.runtime.sendMessage({ type: "setPin", pin: pin }, function(){ });
  chrome.runtime.sendMessage({ type: "setComment", comment: comment }, function(){ alert("已儲存設定"); });
});
(function init(){
  chrome.storage.local.get({ pin: "", comment: "文存參" }, function(data){
    document.getElementById("pin").value = data.pin || "";
    document.getElementById("comment").value = data.comment || "文存參";
  });
})();