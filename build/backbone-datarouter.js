(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['require', 'underscore', 'backbone', 'cache', 'kinvey', 'backbone-datarouter/authorize_kinvey'], function(require, _, Backbone, Cache, Kinvey, Authorize) {
    var Route;
    Route = (function() {
      Route.defaults = {
        cache: true,
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
        var errors;
        this.options = options;
        this._handler = __bind(this._handler, this);
        _.extend(this, Backbone.Events);
        this.options || (this.options = {});
        this.options = _.extend(_.clone(Route.defaults), this.options);
        if (this.options.logger) {
          Route.logger = this.options.logger;
        }
        this.on('all', function(event) {
          return Route.logger.debug("Route event " + event);
        });
        if (errors = !this.validate(this.options)) {
          Route.logger.error("Route has invalid options", errors, this);
        }
        this.register(this.options['app'], this.options['pattern']);
      }

      Route.prototype.getErrors = function() {
        return this.errors || (this.errors = []);
      };

      Route.prototype.pushError = function(error) {
        return this.getErrors().push(error);
      };

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
        var params;
        e.preventDefault();
        this._eventWrapper(ui);
        this.trigger('before');
        params = this.options.app.router.getParams(match['input']);
        return this.options.authorize(this).done((function(_this) {
          return function() {
            var collection, id, model;
            if (_this.options.collection) {
              if (id = params['id']) {
                model = _this._newCollectionModel(_this.options.collection, id);
                _this.once('model:ready', function(model, response, options) {
                  _this._showView({
                    model: model,
                    params: params
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
                    collection: collection,
                    params: params
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
              return _this._showView({
                params: params
              });
            }
          };
        })(this)).fail((function(_this) {
          return function() {
            Route.logger.error('Router failed authorization');
            _this.trigger('after');
            return _this._showView({
              params: params
            });
          };
        })(this));
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

      Route.prototype._fetchModel = function(model, useCache) {
        var id;
        if (useCache) {
          id = model.get(model.idAttribute);
          return this.options.app.Data.cache.getModel(this.options.collection, id, (function(_this) {
            return function(model) {
              Route.logger.debug('Model ready', model);
              return _this.trigger('model:ready', model);
            };
          })(this));
        } else {
          return model.fetch({
            success: (function(_this) {
              return function(model, response, options) {
                return _this.trigger('model:ready', model, response, options);
              };
            })(this),
            error: (function(_this) {
              return function(model, xhr, options) {
                return _this.trigger('model:error', model, xhr, options);
              };
            })(this)
          });
        }
      };

      Route.prototype._fetchCollection = function(collection, collectionName, useCache) {
        if (useCache) {
          return this.options.app.Data.cache.fetchCollection(collection, collectionName, (function(_this) {
            return function(collection) {
              return _this.trigger('collection:ready', collection);
            };
          })(this));
        } else {
          collection.fetch;
          return {
            success: (function(_this) {
              return function(collection, response, options) {
                return _this.trigger('collection:ready', collection, response, options);
              };
            })(this),
            error: (function(_this) {
              return function(collection, xhr, options) {
                return _this.trigger('collection:error', model, xhr, options);
              };
            })(this)
          };
        }
      };

      Route.prototype._showView = function(opts) {
        var error, region, view;
        if (opts == null) {
          opts = null;
        }
        try {
          view = new this.options.view(opts);
          if (region = this._getRegion()) {
            return region.show(view);
          } else {
            return view.render();
          }
        } catch (_error) {
          error = _error;
          if (error.name === 'TemplateNotFoundError') {
            Route.logger.debug("View (instance of '" + view.constructor.name + "') attempted to render without a template.");
          }
          return Route.logger.error(error.name, error.message);
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
        this.once('before', (function(_this) {
          return function() {
            if (_this.options.spinner) {
              _this.options.spinner.show();
            }
            _this._registerEvents();
            return _this.trigger('begin');
          };
        })(this));
        return this.once('after', (function(_this) {
          return function() {
            _this.trigger('finish');
            _this._unregisterEvents();
            ui.bCDeferred.resolve();
            if (_this.options.spinner) {
              return _this.options.spinner.hide();
            }
          };
        })(this));
      };

      Route.prototype._registerEvents = function() {
        if (!_.isEmpty(this.options.events)) {
          return _.each(this.options.events, (function(_this) {
            return function(value, key, list) {
              return _this.listenTo(_this, key, value);
            };
          })(this));
        }
      };

      Route.prototype._unregisterEvents = function() {
        if (!_.isEmpty(this.options.events)) {
          return _.each(this.options.events, (function(_this) {
            return function(value, key, list) {
              return _this.stopListening(_this, key, value);
            };
          })(this));
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
