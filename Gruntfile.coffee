module.exports = (grunt) ->
  copyright = "// <%= pkg.title %> <%= pkg.version %> Copyright (c) 2013 <%= pkg.author %>\n" +
              "// See <%= pkg.url %>\n"
  config    =
    pkg: grunt.file.readJSON "package.json"
    exec:
      mocha:
        cmd: -> "mocha-phantomjs test/index.html"
    coffee:
      src:
        options:
          join: true
        files:
          "flickable.js": [
            "src/namespace.coffee"
            "src/helper.coffee"
            "src/flickable.coffee"
          ]
      test:
        options:
          bare: true
        files:
          "test/helper.js":    "src/test/helper.coffee"
          "test/flickable.js": "src/test/flickable.coffee"
    concat:
      dist:
        options:
          banner: copyright
        files:
          "<%= pkg.name %>.js": ["<%= pkg.name %>.js"]

    uglify:
      dist:
        options:
          mangle: true
          banner: copyright
        files:
          "<%= pkg.name %>.min.js": ["<%= pkg.name %>.js"]

    watch:
      src:
        files: ["src/*.coffee"]
        tasks: "compile"
      test:
        files: ["src/test/*.coffee"]
        tasks: "test"
      prod:
        files: ["**/*.coffee"]
        tasks: "prod"

    jshint:
      src:  ["flickable.js"]
      test: ["test/*.js"]
      options:
        curly   : true
        eqeqeq  : true
        immed   : true
        latedef : true
        newcap  : true
        noarg   : true
        sub     : true
        undef   : true
        boss    : true
        eqnull  : true
        es5     : true
        browser : true
        devel   : true
        globals:
          "global"    : true
          "namespace" : true
          "Flickable" : true

  grunt.initConfig config

  grunt.loadNpmTasks "grunt-exec"
  grunt.loadNpmTasks "grunt-notify"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-jshint"
  grunt.loadNpmTasks "grunt-contrib-concat"
  grunt.loadNpmTasks "grunt-contrib-uglify"

  grunt.registerTask "compile", ["coffee:src", "jshint:src"]
  grunt.registerTask "test",    ["coffee:test", "exec:mocha"]
  grunt.registerTask "prod",    ["compile", "test", "concat", "uglify"]

  grunt.registerTask "default", ["prod"]

