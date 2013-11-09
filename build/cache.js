(function() {
  define(['underscore', 'backbone', 'moment', 'backbone-datarouter/dom_storage_adapter'], function(_, Backbone, moment, DOMStorageAdapter) {
    var Cache;
    return Cache = (function() {
      Cache.defaults = {
        logger: Cache.logger,
        namespace: 'cache'
      };

      Cache.logger = console;

      function Cache(app, options) {
        this.options = options;
        this.options || (this.options = {});
        this.options = _.extend(Cache.defaults, this.options);
        if (this.options.logger) {
          Cache.logger = this.options.logger;
        }
        if (!this.options.storage) {
          this.storage = new DOMStorageAdapter(this.options.namespace, 'local');
        }
        this.expired = false;
        this.app = app;
        _.extend(this, Backbone.Events);
      }

      Cache.prototype.tryCache = function() {
        var timestamp;
        Cache.logger.info('Trying cache...');
        timestamp = moment.unix(this.storage.getItem('expireAt', false));
        if (moment().diff(timestamp) > 0) {
          Cache.logger('Cache expired!');
          return this.expire();
        }
      };

      Cache.prototype.expire = function() {
        this.expired = true;
        return this;
      };

      Cache.prototype.clear = function() {
        this.storage.clear();
        return this;
      };

      Cache.prototype.expiresIn = function() {
        return moment.unix(this.storage.getItem('expireAt', false)).fromNow();
      };

      Cache.prototype.incrementExpiration = function() {
        var expireAt, _ref;
        expireAt = (_ref = moment()).add.apply(_ref, this.app.Settings.cache.lifespan).unix();
        return this.storage.setItem('expireAt', expireAt, false);
      };

      Cache.prototype.preloadFinished = function() {
        var _this = this;
        return _.every(this.app.Settings.cache.preloads, function(resource) {
          return _.contains(_this.preloaded, resource);
        });
      };

      Cache.prototype.preload = function(callback) {
        var _this = this;
        this.preloaded = [];
        _.each(this.app.Settings.cache.preloads, function(resource) {
          _this.once("miss:" + resource + ":success", function() {
            this.preloaded.push(resource);
            if (this.preloadFinished() && callback) {
              return callback.call();
            }
          });
          return _this.fetchCollection(new _this.app.Data.Collections[resource], resource);
        });
        return this;
      };

      Cache.prototype.humanStatus = function() {
        if (this.expired) {
          return 'Data may be out of data.';
        } else {
          return "Checking for updated data in " + (this.expiresIn()) + ".";
        }
      };

      Cache.prototype.getModel = function(collectionName, id, callback) {
        var collection;
        collection = new this.app.Data.Collections[collectionName];
        return this.fetchCollection(collection, collectionName, function(c) {
          if (callback) {
            return callback(c.get(id));
          }
        });
      };

      Cache.prototype.fetchCollection = function(instance, key, callback) {
        var _this = this;
        if (navigator.onLine) {
          this.tryCache();
          if (this.expired) {
            return instance.fetch({
              success: function(resource, response, options) {
                _this.storage.setItem(key, resource);
                Cache.logger.info('Fetched resource from network', resource);
                _this.expired = false;
                _this.incrementExpiration();
                _this.trigger("miss:" + key + ":success", instance);
                if (callback) {
                  return callback(resource);
                }
              },
              error: function(resource, response, options) {
                Cache.logger.info('Could not fetch resource.');
                _this.trigger("miss:" + key + ":error", instance);
                if (callback) {
                  return callback(resource);
                }
              }
            });
          } else {
            Cache.logger.info('Fetched resource from cache');
            instance.set(this.storage.getItem(key));
            this.trigger("hit:" + key + ":online", instance);
            if (callback) {
              return callback(instance);
            }
          }
        } else {
          Cache.logger.info('Fetch called while offline, falling back to cache');
          instance.set(this.storage.getItem(key));
          this.trigger("hit:" + key + ":offline", instance);
          if (callback) {
            return callback(instance);
          }
        }
      };

      return Cache;

    })();
  });

}).call(this);
