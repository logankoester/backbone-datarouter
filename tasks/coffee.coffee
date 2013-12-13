# Configure grunt tasks for CoffeeScript compilation

module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-contrib-coffee'

  coffee:
    expand: true
    cwd: 'lib'
    src: ['**/*.coffee']
    dest: 'build/'
    ext: '.js'
