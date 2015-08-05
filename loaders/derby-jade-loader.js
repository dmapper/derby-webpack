var files = require('derby/lib/files');
var derbyJade = require('derby-jade');
var derbyTemplates = require('derby-templates');
var path = require('path');
var async = require('async');
var loaderUtils = require("loader-utils");
require('derby-parsing');

module.exports = function(source) {

  this.cacheable();
  var cb = this.async();

  var query = loaderUtils.parseQuery(this.query);
  var moduleMode = query.modules || query.module;

  var dummyApp = {
    compilers: [],
    viewExtensions: []
  };
  derbyJade(dummyApp, {globals: {moduleMode: moduleMode}});

  var that = this;
  var locals = {};
  var views;

  async.series([
    // function(cb){
    //   that.resolve(that.context, './index.styl', function(err, cssPath) {
    //     if (cssPath) {
    //       that.loadModule(cssPath, function(err, source) {
    //         cb();
    //       });
    //     } else {
    //       cb();
    //     }
    //   });
    // },
    function(cb){
      var i;
      var data = files.loadViewsSync(dummyApp, that.resourcePath, undefined);
      views = new derbyTemplates.templates.Views();
      views.polyfillMissingViews = true;
      for (i = 0, len = data.views.length; i < len; i++) {
        var item = data.views[i];
        views.register(item.name, item.source, item.options);
      }
      for (i = 0, len = data.files.length; i < len; i++) {
        if (data.files[i] !== that.resourcePath) {
          that.dependency( data.files[i] );
        }
      }
      cb();
    }
  ], function(err){    
    cb(null, 'module.exports = exports = '
        + views.serialize({server: true, minify: true}) + ';'
        + 'exports.filename = \'' + that.resourcePath + '\';');
  });


  //if (/partial\.jade/.test(this.resourcePath)) {
  //  return cb(null, 'module.exports = '
  //      + views.serialize({server: true, minify: true}) + ';');
  //}
  //this.resolve(this.context, './partial.jade', function(err, path) {
  //  that.resolve(that.context, './Topbar/index.styl', function(err, cssPath) {
  //    that.loadModule(cssPath, function(err, cssSource) {
  //      var locals = that.exec(cssSource, cssPath).locals || {};
  //      that.loadModule(path, function(err, source) {
  //        cb(null, 'module.exports = '
  //            + views.serialize({server: true, minify: true}) + ';');
  //      });
  //    });
  //  });
  //});

};

function templateName(filepath) {
  var templateName = path.basename(filepath, path.extname(filepath));
  if (templateName === 'index') {
    templateName = path.basename(path.dirname(filepath));
  }
  return templateName;
}

function addHotReload(src, filepath) {
  var templateName = templateName(filepath);
  var res = src.match(/\.prototype\.init\s*=\s*\{/);
  res = ((res == null) ? res : res[0])
  if (res != null) {
    var pos = src.indexOf(res) + res.length
  }
  if (module.hot) {
    module.hot.accept('./index.jade', function(){

    });
  }
}

function partialTemplate(src, filepath) {
  var templateName = templateName(filepath);
  src = src
      .replace(/^module\.exports = /, '')
      .replace(/;$/, '');
  return '(' + src + ")(derbyTemplates, views, "
      + "(namespace ? namespace + ':' : '')"
      + " + '" + templateName + "'"
      + ');'
}
