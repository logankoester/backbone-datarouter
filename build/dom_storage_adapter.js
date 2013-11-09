(function() {
  define(['underscore'], function(_) {
    var DOMStorageAdapter;
    return DOMStorageAdapter = (function() {
      function DOMStorageAdapter(namespace, scope) {
        this.namespace = namespace;
        this.scope = scope;
        this.storage = this._storage(this.scope);
      }

      DOMStorageAdapter.prototype.setItem = function(key, value, serialize) {
        if (serialize == null) {
          serialize = true;
        }
        this._registerKey(key);
        if (serialize) {
          value = JSON.stringify(value.toJSON());
        }
        this.storage.setItem(this._namespacedKey(key), value);
        return this;
      };

      DOMStorageAdapter.prototype.getItem = function(key, deserialize) {
        var str;
        if (deserialize == null) {
          deserialize = true;
        }
        str = this.storage.getItem(this._namespacedKey(key));
        if (str) {
          if (deserialize) {
            return JSON.parse(str);
          } else {
            return str;
          }
        } else {
          return null;
        }
      };

      DOMStorageAdapter.prototype.removeItem = function(key) {
        this.storage.removeItem(this._namespacedKey(key));
        this._unregisterKey(key);
        return this;
      };

      DOMStorageAdapter.prototype.clear = function() {
        _.each(this._getKeys(), function(key) {
          return this.storage.removeItem(this._namespacedKey(key));
        });
        this._setKeys([]);
        return this;
      };

      DOMStorageAdapter.prototype._registerKey = function(key) {
        var keys;
        keys = this._getKeys();
        keys.push(key);
        this._setKeys(_.uniq(keys));
        return this;
      };

      DOMStorageAdapter.prototype._unregisterKey = function(key) {
        var keys;
        keys = _.reject(this._getKeys(), function(i) {
          return i === key;
        });
        this._setKeys(keys);
        return this;
      };

      DOMStorageAdapter.prototype._getKeys = function() {
        var str;
        str = this.storage.getItem(this._keysItem());
        if (str) {
          return JSON.parse(str);
        } else {
          return [];
        }
      };

      DOMStorageAdapter.prototype._setKeys = function(keys) {
        this.storage.setItem(this._keysItem(), JSON.stringify(keys));
        return this;
      };

      DOMStorageAdapter.prototype._storage = function(scope) {
        var root;
        root = typeof window !== "undefined" && window !== null ? window : global;
        switch (scope) {
          case 'local':
            return root.localStorage;
          case 'global':
            return root.globalStorage;
          case 'session':
            return root.sessionStorage;
          default:
            throw new Error('Unknown scope for DOM Storage adapter');
        }
      };

      DOMStorageAdapter.prototype._keysItem = function() {
        return this._namespacedKey('keys');
      };

      DOMStorageAdapter.prototype._namespacedKey = function(key) {
        return "" + this.namespace + "_" + key;
      };

      return DOMStorageAdapter;

    })();
  });

}).call(this);
