module.exports = function(source) {
  this.cacheable();
  var that = this;
  var res;
  var match;
  var name = source.match(/module\.exports\s*=\s*([A-Z]\w*)/);
  name = name && name[1];

  // Preprocess 'view' and 'style' field from __dirname into require()
  source = source.replace(/(.*\.prototype\.view\s*=\s*)(__dirname)/,
      "$1require('./index.jade')");
  source = source.replace(/(.*\.prototype\.style\s*=\s*)(__dirname)/,
      "$1require('./index.styl')");

  // If class is being exported we treat it as a component and handle hot reload
  if (name) {
    res = [
      source,
      addHotReload(name)
    ].join('\n\n');
  // otherwise just pipe the source code
  } else {
    res = source;
  }

  return res;
};

function addHotReload(name) {
  return ('(' + (function() {

    var recreateComponent = function() {
      window.app.component(__name__);
      window.app.history.refresh();
    };

    if (module.hot) {
      module.hot.accept();
      module.hot.accept('./index.jade', function(){
        __name__.prototype.view = require('./index.jade');
        recreateComponent();
      });
      module.hot.dispose = function(data) {
        data.restart = true;
      };
      if (module.hot.data) {
        recreateComponent();
      }
    }

  }).toString() + ')();' ).replace(/__name__/g, name)
}
