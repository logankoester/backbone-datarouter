#global module:false
module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

  # Inject project configuration from files under 'tasks/'
  require('grunt-config-dir') grunt, {
    configDir: require('path').resolve('tasks')
    fileExtensions: ['js', 'coffee']
  }, (err) -> grunt.log.error(err)

  grunt.registerTask 'build', [
    'clean',
    'coffee'
  ]

  grunt.registerTask 'default', ['build']
