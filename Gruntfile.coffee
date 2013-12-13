#global module:false
module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

  # Inject project configuration from files under 'grunt/'
  require('grunt-config-dir')(grunt)

  grunt.registerTask 'build', [
    'clean',
    'coffee'
  ]

  grunt.registerTask 'default', ['build']
