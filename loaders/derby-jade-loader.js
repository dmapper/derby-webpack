var files = require('../lib/files');
var derbyJade = require('derby-jade');
var derbyTemplates = require('derby-templates');
var async = require('async');
var loaderUtils = require("loader-utils");
require('derby-parsing');

module.exports = function(source) {

  this.cacheable();
  var cb = this.async();

  var query = loaderUtils.parseQuery(this.query);
  var moduleMode = query.modules || query.module;

  var compiler = function(file, fileName) {
    derbyJade.compiler(file, fileName, undefined, {moduleMode: moduleMode})
  };

  var that = this;
  var views;

  async.series([
    function(cb){
      var i, len;
      var data = files.loadViewsSync(that.resourcePath, undefined, '.jade', compiler);
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

};