// Generated by CoffeeScript 1.12.7
(function() {
  var FrontendConfig, FrontendWatchConfig, _, webpack,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

  _ = require('lodash');

  webpack = require('webpack');

  FrontendConfig = require('./frontend');

  module.exports = FrontendWatchConfig = (function(superClass) {
    extend(FrontendWatchConfig, superClass);

    function FrontendWatchConfig() {
      var ref;
      FrontendWatchConfig.__super__.constructor.apply(this, arguments);
      this.config.cache = true;
      this.config.debug = true;
      if (this.options.unsafeCache !== false) {
        this.config.resolve.unsafeCache = this.options.unsafeCache;
      }
      this.config.devtool = (ref = this.options.frontend.devtool) != null ? ref : this.options.devtool;
      this.config.postcss = this._getPostCss();
      this.config.module.loaders = this.config.module.loaders.concat([
        {
          test: /\.css$/,
          loader: "style!raw!postcss"
        }
      ]);
      this.config.module.loaders = this.config.module.loaders.concat(this._getBeforeStylusLoaders());
      this.config.module.loaders.push(this._getStylusLoader());
      this._initDevConfig();
    }

    FrontendWatchConfig.prototype._getActualStylusLoader = function() {
      var args;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return 'style!' + FrontendWatchConfig.__super__._getActualStylusLoader.apply(this, args);
    };

    FrontendWatchConfig.prototype._initDevConfig = function() {
      var entry, name, ref;
      ref = this.config.entry;
      for (name in ref) {
        entry = ref[name];
        this.config.entry[name] = ["webpack-dev-server/client?" + this.options.webpackUrl, 'webpack/hot/dev-server', __dirname + '/../wdsVisual'].concat(entry || []);
      }
      this.config.plugins = this.config.plugins.concat([
        new webpack.HotModuleReplacementPlugin({
          quiet: true
        })
      ]);
      return this.config.devServer = {
        publicPath: '/build/client/',
        hot: true,
        inline: true,
        lazy: false,
        stats: {
          colors: true
        },
        noInfo: true,
        headers: {
          'Access-Control-Allow-Origin': '*'
        },
        host: '0.0.0.0',
        port: this.options.webpackPort
      };
    };

    return FrontendWatchConfig;

  })(FrontendConfig);

}).call(this);