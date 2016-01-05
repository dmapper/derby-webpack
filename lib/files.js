/*
 * files.js
 * loads templates, configurations and other files from disk
 *
 */

var fs = require('fs');
var path = require('path');
var htmlUtil = require('html-util');
var resolve = require('resolve');

exports.loadViewsSync = loadViewsSync;
exports.htmlCompiler = htmlCompiler;

function loadViewsSync(sourceFilename, namespace, extension, compiler) {
  var compilers = {
    '.html': exports.htmlCompiler
  };
  compilers[extension] = compiler;
  var extensions = Object.keys(compilers);
  var views = [];
  var files = [];
  var resolved = resolve.sync(sourceFilename, {extensions: extensions, packageFilter: deleteMain});
  if (!resolved) {
    throw new Error('View template file not found: ' + sourceFilename);
  }

  var file = fs.readFileSync(resolved, 'utf8');

  var currentExtension = path.extname(resolved);
  var currentCompiler = compilers[currentExtension];
  if (!currentCompiler) {
    throw new Error('Unable to find compiler for: ' + extension);
  }

  var htmlFile = compiler(file, resolved);

  var parsed = parseViews(namespace, htmlFile, resolved, extensions);
  for (var i = 0, len = parsed.imports.length; i < len; i++) {
    var item = parsed.imports[i];
    var imported = loadViewsSync(item.filename, item.namespace, extension, compiler);
    views = views.concat(imported.views);
    files = files.concat(imported.files);
  }
  return {
    views: views.concat(parsed.views)
  , files: files.concat(resolved)
  };
}

function htmlCompiler(file, filename) {
  return file;
}

function parseViews(namespace, file, filename, extensions) {
  var imports = [];
  var views = [];
  var prefix = (namespace) ? namespace + ':' : '';

  htmlUtil.parse(file + '\n', {
    // Force view tags to be treated as raw tags,
    // meaning their contents are not parsed as HTML
    rawTags: /^(?:[^\s=\/!>]+:|style|script)$/i
  , matchEnd: matchEnd
  , start: onStart
  , text: onText
  });

  function matchEnd(tagName) {
    if (tagName.slice(-1) === ':') {
      return /<\/?[^\s=\/!>]+:[\s>]/i;
    }
    return new RegExp('</' + tagName, 'i');
  }

  // These variables pass state from attributes in the start tag to the
  // following view template text
  var name, attrs;

  function onStart(tag, tagName, tagAttrs) {
    var lastChar = tagName.charAt(tagName.length - 1);
    if (lastChar !== ':') {
      throw new Error('Expected tag ending in colon (:) instead of ' + tag);
    }
    name = tagName.slice(0, -1);
    attrs = tagAttrs;
    if (name === 'import') {
      var dir = path.dirname(filename);
      var resolved = resolve.sync(attrs.src, {basedir: dir, extensions: extensions, packageFilter: deleteMain});
      var extension = path.extname(resolved);
      var importNamespace = (attrs.ns == null) ?
        path.basename(attrs.src, extension) : attrs.ns;
      imports.push({
        filename: resolved
      , namespace: (!importNamespace) ? namespace : prefix + importNamespace
      });
    }
  }

  function onText(text, isRawText) {
    if (!name || name === 'import') return;
    views.push({
      name: prefix + name
    , source: text
    , options: attrs
    , filename: filename
    });
  }

  return {
    imports: imports
  , views: views
  };
}

// Resolve will use a main path from a package.json if found. Main is the
// entry point for javascript in a module, so this will mistakenly cause us to
// load the JS file instead of a view or style file in some cases. This package
// filter deletes the main property so that the normal file name lookup happens
function deleteMain(package) {
  delete package.main;
}