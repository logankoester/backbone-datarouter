# Configure files that can be deleted by grunt tasks

module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-contrib-clean'

  build: ["build/*"]
