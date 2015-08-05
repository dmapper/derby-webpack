var defaultClientOptions = {
  base: '/channel',
  reconnect: true,
  browserChannelOnly: false,
  srvPort: undefined,
  srvSecurePort: undefined,
  timeout: 10000,
  timeoutIncrement: 10000
};

module.exports = function(source) {
  this.cacheable();
  return source.replace('{{clientOptions}}', JSON.stringify(defaultClientOptions));
}
