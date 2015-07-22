module.exports = function(source) {
  this.cacheable();
  var that = this;
  var res;
  var name = source.match(/module\.exports\s*=\s*(\w+)/);
  name = name && name[1];
  res = [
    source,
    addHotReload(name)
  ].join('\n\n');  
  return res;
}

function addHotReload(name) {
  return ('(' + (function() {

    var recreateComponent = function() {
      window.app.component(__name__);
      window.app.history.refresh();
    }

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
