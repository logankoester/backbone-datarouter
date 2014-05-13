# Backbone DataRouter

[![Build Status](http://ci.ldk.io/logankoester/backbone-datarouter/badge)](http://ci.ldk.io/logankoester/backbone-datarouter/)
[![Dependency Status](https://david-dm.org/logankoester/backbone-datarouter.png)](https://david-dm.org/logankoester/backbone-datarouter)
[![devDependency Status](https://david-dm.org/logankoester/backbone-datarouter/dev-status.png)](https://david-dm.org/logankoester/backbone-datarouter#info=devDependencies)
[![NPM version](https://badge.fury.io/js/backbone-datarouter.png)](http://badge.fury.io/js/backbone-datarouter)
[![Bower version](https://badge.fury.io/bo/backbone-datarouter.png)](http://badge.fury.io/bo/backbone-datarouter)
[![Gittip](http://img.shields.io/gittip/logankoester.png)](https://www.gittip.com/logankoester/)

[![NPM](https://nodei.co/npm/backbone-datarouter.png?downloads=true)](https://nodei.co/npm/backbone-datarouter/)

**WARNING** This library is in an early, experimental stage at the moment. Don't take it seriously just yet.

-

## Overview

**DataRouter** offers a friendly CoffeeScript-oriented syntax for describing resource-oriented routes in single-page applications.

```coffeescript
A.route '#items': require('items/index'), collection: 'Items' region: (A)-> A.getRegion 'list'
```

Data resources are automatically fetched and cached for you before initializing the view. It works well with [Backbone.Marionette](https://github.com/marionettejs/backbone.marionette) and may even require it in the future.

This library *currently* depends on [jquerymobile-router](https://github.com/azicchetti/jquerymobile-router), but this requirement [will be going away](https://github.com/logankoester/backbone-datarouter/issues/10). DataRouter is ultimately intended for general use.

#### [View Full Documentation](http://coffeedoc.info/github/logankoester/backbone-datarouter/master/)

## Installation

    $ npm install bower -g
    $ bower install backbone-datarouter --save

The `--save` flag will save backbone-datarouter as a dependency in your project's `bower.json` file.

## Getting Started

> **Somebody still needs to write this section. Why not you?**

## LICENSE

Copyright (c) 2013-2014 Logan Koester.
Released under the MIT license. See `LICENSE` for details.

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/logankoester/backbone-datarouter/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

[![status](https://sourcegraph.com/api/repos/github.com/logankoester/backbone-datarouter/badges/status.png)](https://sourcegraph.com/github.com/logankoester/backbone-datarouter)
[![xrefs](https://sourcegraph.com/api/repos/github.com/logankoester/backbone-datarouter/badges/xrefs.png)](https://sourcegraph.com/github.com/logankoester/backbone-datarouter)
[![funcs](https://sourcegraph.com/api/repos/github.com/logankoester/backbone-datarouter/badges/funcs.png)](https://sourcegraph.com/github.com/logankoester/backbone-datarouter)
[![top func](https://sourcegraph.com/api/repos/github.com/logankoester/backbone-datarouter/badges/top-func.png)](https://sourcegraph.com/github.com/logankoester/backbone-datarouter)
[![library users](https://sourcegraph.com/api/repos/github.com/logankoester/backbone-datarouter/badges/library-users.png)](https://sourcegraph.com/github.com/logankoester/backbone-datarouter)
[![authors](https://sourcegraph.com/api/repos/github.com/logankoester/backbone-datarouter/badges/authors.png)](https://sourcegraph.com/github.com/logankoester/backbone-datarouter)
[![Total views](https://sourcegraph.com/api/repos/github.com/logankoester/backbone-datarouter/counters/views.png)](https://sourcegraph.com/github.com/logankoester/backbone-datarouter)
[![Views in the last 24 hours](https://sourcegraph.com/api/repos/github.com/logankoester/backbone-datarouter/counters/views-24h.png)](https://sourcegraph.com/github.com/logankoester/backbone-datarouter)
