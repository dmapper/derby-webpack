(function(){
  require('./index.css');

  var showBar = function() {
    document.documentElement.classList.add('-wds');
    document.documentElement.classList.add('-wds-show');
  };
  var hideBar = function() {
    document.documentElement.classList.remove('-wds-show');
  };
  var showSpinner = function() {
    document.documentElement.classList.add('-wds-spinner');
  };
  var hideSpinner = function() {
    document.documentElement.classList.remove('-wds-spinner');
  };
  var setType = function(type) {
    document.documentElement.dataset.wdstype = type;
    if (type === 'error') {
      showBar();
      hideSpinner();
    } else if (type === 'warning') {
      showBar();
      showSpinner();
    } else if (type === 'success') {
      hideBar();
      hideSpinner();
    }
  };

  var consoleLogOrig = console.log;
  console.log = function(msg) {
    consoleLogOrig.apply(console, arguments);

    if (typeof msg == 'string' || msg instanceof String) {
      if (/^\[WDS\]/.test(msg)) {
        document.documentElement.dataset.wds = msg;
      }

      /* Handle Webpack Dev Server info logs */
      switch (msg) {
        case '[WDS] Nothing changed.':
        case '[WDS] App updated. Reloading...':
        case '[WDS] App hot update...':
          setType('success');
          break;
        case '[WDS] App updated. Recompiling...':
          setType('warning');
          break;
        case '[WDS] Errors while compiling.':
        case '[WDS] Warnings while compiling.':
        case '[WDS] Proxy error.':
        case '[WDS] Disconnected!':
          setType('error');
          break;
      }
    }

  };

})();