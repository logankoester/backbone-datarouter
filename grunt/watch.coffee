# Configure watch operations as grunt tasks

module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-contrib-watch'

  coffee:
    files: ['lib/**/*.coffee', 'test/**/*.coffee']
    tasks: ['default']
