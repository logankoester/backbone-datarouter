define([
  'jquery',
  'backbone',
  'chai',
  'lib/backbone-datarouter'
], function($, Backbone, chai, Backbone-datarouter) { 
  'use strict';

  var expect = chai.expect;

  describe('Backbone-datarouter', function() {
    it('should have a name attribute by default', function() {      
      expect(new Backbone-datarouter().get('name')).to.equal('');
    });
  });
});