gulp       = require 'gulp'
browserify = require 'gulp-browserify'
rename     = require 'gulp-rename'
sass       = require 'gulp-ruby-sass'
plumber    = require 'gulp-plumber'

gulp.task 'scss', ->
    gulp.src 'scss/godutch.scss'
        .pipe sass()
        .pipe gulp.dest('./static/')

gulp.task 'coffee', ->
    gulp.src 'coffee/godutch.coffee', read: false
        .pipe plumber()
        .pipe browserify
            transform: ['coffeeify', 'reactify/undoubted']
            extensions: ['*.coffee']
        .pipe rename 'godutch.js'
        .pipe gulp.dest('./static')

gulp.task 'watch', ->
    gulp.watch 'coffee/**/*.coffee', ['coffee']
    gulp.watch 'scss/**/*.scss', ['scss']

gulp.task 'default', ['scss', 'coffee', 'watch']
