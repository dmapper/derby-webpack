var build = require('webpack-build');

build.workers.spawn(1);

// Backend

var doBuild = function() {
  console.log('------> Start building BACKEND', __filename);
};

doBuild();
setTimeout(function(){
  console.log('>>>>>> Do another build!!!');
  doBuild();
}, 60 * 2 * 1000);
