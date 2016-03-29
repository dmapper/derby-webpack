var SourceNode = require('source-map').SourceNode;
var SourceMapConsumer = require('source-map').SourceMapConsumer;
var makeIdentitySourceMap = require('../lib/makeIdentitySourceMap');
var fs = require('fs');
var path = require('path');
var loaderUtils = require("loader-utils");

module.exports = function(source, map) {

  if (this.cacheable) this.cacheable();

  var query = loaderUtils.parseQuery(this.query);
  var separator = '\n\n';

  // Class Name is the name of exported class
  var className = source.match(/module\.exports\s*=\s*([A-Z]\w*)/);
  className = className && className[1];
  var ns = query.ns;

  // View Name is the explicitely defined component name or the name of file/folder
  var viewName = source.match(/.*\.prototype\.name\s*=\s*['"]([^'"]*)['"]/);
  viewName = viewName && viewName[1];
  if (!viewName) {
    viewName = path.basename(this.resourcePath, path.extname(this.resourcePath))
    if (viewName === 'index') viewName = path.basename(path.dirname(this.resourcePath));
  }

  // Preprocess 'view' and 'style' field from __dirname into require()
  source = source.replace(/(.*\.prototype\.view\s*=\s*)(__dirname)/,
      "$1require('./index.jade')");
  source = source.replace(/(.*\.prototype\.style\s*=\s*)(__dirname)/,
      "$1require('./index.styl')");

  // Preprocess 'components' array to require components using derby loader
  source = source.replace(/(.*\.prototype\.components\s*=\s*\[\s*)([^\]]*)(\])/g,
      function(match, p1, p2, p3) {
        p2 = p2.replace(/(require\(\s*['"])([^'"]*)(['"]\s*\))/g,
            "$1" + JSON.parse(loaderUtils.stringifyRequest(this, require.resolve('./derby-component-loader'))) +
            // Pipe ns into nested component to support hot reloading of views
            '?ns=' + (ns ? (ns + ':') : '') + viewName +
            '!$2$3');
        return '' + p1 + p2 + p3;
      });

  // If class is being exported we treat it as a component and handle hot reload
  if (className) {
    var loadView = fs.existsSync( path.dirname( this.resourcePath ) + '/index.jade' );
    var appendText = addHotReload(className, loadView, ns);

    if (this.sourceMap === false) {
      return this.callback(null, [
        source,
        appendText
      ].join(separator));
    }


    if (!map) map = makeIdentitySourceMap(source, this.resourcePath);

    var node = new SourceNode(null, null, null, [
      SourceNode.fromStringWithSourceMap(source, new SourceMapConsumer(map)),
      new SourceNode(null, null, this.resourcePath, appendText)
    ]).join(separator);

    var result = node.toStringWithSourceMap();

    //console.log(this.resourcePath, 'map');

    return this.callback(null, result.code, result.map.toString());
  }

  return this.callback(null, source, map);
};

function addHotReload(className, loadView, ns) {
  return ('(' + (function() {

    var recreateComponent = function() {
      console.log('----> RELOAD WITH', __className__, __ns__);
      window.app.component(null, __className__, __ns__);
      window.app.history.refresh();
    };

    if (module.hot) {
      module.hot.accept();
      __reloadView__
      module.hot.dispose = function(data) {
        data.restart = true;
      };
      if (module.hot.data) {
        recreateComponent();
      }
    }

  }).toString() + ')();' )
    .replace(/__reloadView__/g, loadView
      ? [
          "module.hot.accept('./index.jade', function() {"
        + "  __className__.prototype.view = require('./index.jade');"
        + "  recreateComponent();"
        + "});"
        ].join('')
      : ''
    ).replace(/__className__/g, className)
    .replace(/__ns__/g, JSON.stringify(ns))
}
