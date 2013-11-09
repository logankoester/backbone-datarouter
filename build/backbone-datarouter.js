(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['require', 'underscore', 'backbone', 'cache', 'kinvey', 'backbone-datarouter/authorize_kinvey'], function(require, _, Backbone, Cache, Kinvey, Authorize) {
    var Route;
    Route = (function() {
      Route.defaults = {
        cache: true,
        vibrate: 50,
        spinner: {
          show: function() {
            return $.mobile.loading('show');
          },
          hide: function() {
            return $.mobile.loading('hide');
          }
        },
        authorize: function(route) {
          return $.Deferred().resolve().promise();
        },
        logger: Route.logger,
        online: function() {
          return navigator.onLine;
        }
      };

      Route.logger = console;

      function Route(options) {
        this.options = options;
        this._handler = __bind(this._handler, this);
        _.extend(this, Backbone.Events);
        this.options || (this.options = {});
        this.options = _.extend(this.options, Route.defaults);
        if (this.options.logger) {
          Route.logger = this.options.logger;
        }
        this.on('all', function(event) {
          return Route.logger.debug('Route event', event);
        });
        this.errors = !this.validate(this.options);
        if (this.errors) {
          Route.logger.error("Route has invalid options", this.errors, this);
        }
        this.register(this.options['app'], this.options['pattern']);
      }

      Route.prototype.validate = function(options) {
        var errors, _ref;
        errors = [];
        if (!options['pattern']) {
          errors.push('Missing option "pattern"');
        }
        if (!options['view']) {
          errors.push('Missing option "view"');
        }
        if (!options['app']) {
          errors.push('Missing option "app"');
        }
        if (options['spinner']) {
          if (!_.isFunction(options['spinner']['show'])) {
            errors.push("spinner.show is not a function");
          }
          if (!_.isFunction(options['spinner']['hide'])) {
            errors.push("spinner.hide is not a function");
          }
        }
        if (options['model'] && options['collection']) {
          errors.push('Route does not support fetching both a model and collection');
        }
        return (_ref = _.isEmpty(errors)) != null ? _ref : {
          "false": errors
        };
      };

      Route.prototype.register = function(app, pattern, events, argsre) {
        if (events == null) {
          events = 'bC';
        }
        if (argsre == null) {
          argsre = true;
        }
        app.routes || (app.routes = {});
        return app.routes[pattern] = {
          handler: this._handler,
          route: this,
          events: 'bC',
          argsre: true
        };
      };

      Route.prototype._handler = function(type, match, ui, page, e) {
        var params,
          _this = this;
        e.preventDefault();
        this._eventWrapper(ui);
        this.trigger('before');
        params = this.options.app.router.getParams(match['input']);
        return this.options.authorize(this).done(function() {
          var collection, id, model;
          if (_this.options.collection) {
            if (id = params['id']) {
              model = _this._newCollectionModel(_this.options.collection, id);
              _this.once('model:ready', function(model, response, options) {
                _this._showView({
                  model: model
                });
                return _this.trigger('after');
              });
              _this.once('model:error', function(model, xhr, options) {
                Route.logger.error('model:error', model, xhr, options);
                return _this.trigger('after');
              });
              return _this._fetchModel(model, _this.options.cache);
            } else {
              Route.logger.info('Fetching collection', _this.options.collection);
              collection = new _this.options.app.Data.Collections[_this.options.collection];
              _this.once('collection:ready', function(collection, response, options) {
                _this._showView({
                  collection: collection
                });
                return _this.trigger('after');
              });
              _this.once('collection:error', function(collection, xhr, options) {
                Route.logger.error('collection:error', collection, xhr, options);
                return _this.trigger('after');
              });
              return _this._fetchCollection(collection, _this.options.collection, _this.options.cache);
            }
          } else {
            _this.trigger('after');
            return _this._showView();
          }
        }).fail(function() {
          return Route.logger.info('Router failed authorization');
        });
      };

      Route.prototype._newCollectionModel = function(collection, id) {
        var model;
        if (id == null) {
          id = null;
        }
        return model = new this.options.app.Data.Collections[collection].prototype.model({
          _id: id
        });
      };

      Route.prototype._vibrate = function(ms) {
        if (navigator && navigator.notification) {
          return navigator.notification.vibrate(ms);
        }
      };

      Route.prototype._fetchModel = function(model, useCache) {
        var id,
          _this = this;
        if (useCache) {
          id = model.get(model.idAttribute);
          return this.options.app.Data.cache.getModel(this.options.collection, id, function(model) {
            Route.logger.debug('Model ready', model);
            return _this.trigger('model:ready', model);
          });
        } else {
          return model.fetch({
            success: function(model, response, options) {
              return _this.trigger('model:ready', model, response, options);
            },
            error: function(model, xhr, options) {
              return _this.trigger('model:error', model, xhr, options);
            }
          });
        }
      };

      Route.prototype._fetchCollection = function(collection, collectionName, useCache) {
        var _this = this;
        if (useCache) {
          return this.options.app.Data.cache.fetchCollection(collection, collectionName, function(collection) {
            return _this.trigger('collection:ready', collection);
          });
        } else {
          collection.fetch;
          return {
            success: function(collection, response, options) {
              return _this.trigger('collection:ready', collection, response, options);
            },
            error: function(collection, xhr, options) {
              return _this.trigger('collection:error', model, xhr, options);
            }
          };
        }
      };

      Route.prototype._showView = function(options) {
        var region, view;
        if (options == null) {
          options = null;
        }
        Route.logger.info('Router showing view', this.options.view, options);
        view = new this.options.view(options);
        if (region = this._getRegion()) {
          return region.show(view);
        } else {
          return view.render();
        }
      };

      Route.prototype._getRegion = function() {
        if (this.options.region) {
          return this.options.region(this.options.app);
        } else {
          return void 0;
        }
      };

      Route.prototype._eventWrapper = function(ui) {
        var _this = this;
        this.once('before', function() {
          if (_this.options.vibrate) {
            _this._vibrate(_this.options.vibrate);
          }
          if (_this.options.spinner) {
            _this.options.spinner.show();
          }
          _this._registerEvents();
          return _this.trigger('begin');
        });
        return this.once('after', function() {
          _this.trigger('finish');
          _this._unregisterEvents();
          ui.bCDeferred.resolve();
          if (_this.options.spinner) {
            return _this.options.spinner.hide();
          }
        });
      };

      Route.prototype._registerEvents = function() {
        var _this = this;
        if (!_.isEmpty(this.options.events)) {
          return _.each(this.options.events, function(value, key, list) {
            return _this.listenTo(_this, key, value);
          });
        }
      };

      Route.prototype._unregisterEvents = function() {
        var _this = this;
        if (!_.isEmpty(this.options.events)) {
          return _.each(this.options.events, function(value, key, list) {
            return _this.stopListening(_this, key, value);
          });
        }
      };

      return Route;

    })();
    return {
      Route: Route,
      Cache: Cache,
      Authorize: Authorize,
      route: function(glue, options) {
        if (options == null) {
          options = {};
        }
        glue = _.pairs(glue)[0];
        return new Route(_.extend(options, {
          app: this,
          pattern: glue[0],
          view: glue[1]
        }));
      }
    };
  });

}).call(this);
