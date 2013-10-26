# Configure file copy operations as grunt tasks

module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-contrib-copy'

  vendor:
    files: [
      src: ['vendor/**/*']
      dest: 'build'
      expand: true
    ]
