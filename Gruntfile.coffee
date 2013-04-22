module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON "package.json"
    coffee:
      src:
        options:
          join: true
          bare: true
        files:
          "flickable.js": [
            "src/namespace.coffee"
            "src/helper.coffee"
            "src/flickable.coffee"
          ]
      test:
        options:
          join: false
          bare: true
        files:
          "flickable.js": [
            "src/namespace.coffee"
            "src/helper.coffee"
            "src/flickable.coffee"
          ]
    uglify:
      build:
        src:  "flickable.js"
        dest: "flickable.min.js"
      options:
        banner: "// Flickable.js 0.1.2 Copyright (c) 2013 @yuya\n" +
                "// See https://github.com/yhmt/flickable-js\n"
    watch:
      src:
        files: ["src/*.coffee"]
        tasks: "compile"
      test:
        files: ["src/test/*.coffee"]
        tasks: "test"
    jshint:
      src:  ["flickable.js"]
      test: ["test/*.js"]
      options:
        curly:   true
        eqeqeq:  true
        immed:   true
        latedef: true
        newcap:  true
        noarg:   true
        sub:     true
        undef:   true
        boss:    true
        eqnull:  true
        es5:     true
        dojo:    true

  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-contrib-jshint"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-notify"

  grunt.registerTask "compile", ["coffee:src",  "jshint:src"]
  grunt.registerTask "test",    ["coffee:test", "jshint:test"]

  grunt.registerTask "default", ["compile",     "uglify"]
