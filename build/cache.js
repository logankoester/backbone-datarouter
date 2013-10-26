(function() {
  define(['backbone', 'moment'], function(Backbone) {
    var Cache;
    return Cache = (function() {
      function Cache(app) {
        this.storage = window.localStorage;
        this.monitorConnection();
        this.expired = false;
        this.app = app;
        _.extend(this, Backbone.Events);
      }

      Cache.prototype.monitorConnection = function() {
        var _this = this;
        return $(window).on({
          offline: function() {
            return console.log('Application is now offline');
          },
          online: function() {
            console.log('Application is now online');
            return _this.tryCache();
          }
        });
      };

      Cache.prototype.tryCache = function() {
        var timestamp;
        console.log('Trying cache...');
        timestamp = moment.unix(this.storage.getItem('expireAt'));
        if (moment().diff(timestamp) > 0) {
          console.log('Cache expired!');
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

      Cache.prototype.set = function(key, resource) {
        return this.storage.setItem(key, JSON.stringify(resource.toJSON()));
      };

      Cache.prototype.expiresIn = function() {
        return moment.unix(this.storage.getItem('expireAt')).fromNow();
      };

      Cache.prototype.incrementExpiration = function() {
        var _ref;
        return this.storage.setItem('expireAt', (_ref = moment()).add.apply(_ref, this.app.Settings.cache.lifespan).unix());
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
                _this.set(key, resource);
                console.log('Fetched resource from network', resource);
                _this.expired = false;
                _this.incrementExpiration();
                _this.trigger("miss:" + key + ":success", instance);
                if (callback) {
                  return callback(resource);
                }
              },
              error: function(resource, response, options) {
                console.log('Could not fetch resource.');
                _this.trigger("miss:" + key + ":error", instance);
                if (callback) {
                  return callback(resource);
                }
              }
            });
          } else {
            console.log('Fetched resource from cache');
            instance.set(JSON.parse(this.storage.getItem(key)));
            this.trigger("hit:" + key + ":online", instance);
            if (callback) {
              return callback(instance);
            }
          }
        } else {
          console.log('Fetch called while offline, falling back to cache');
          instance.set(JSON.parse(this.storage.getItem(key)));
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
