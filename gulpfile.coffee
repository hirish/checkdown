gulp       = require 'gulp'
coffee     = require 'gulp-coffee'
gutil      = require 'gulp-util'
react      = require 'gulp-react'
sass       = require 'gulp-ruby-sass'
concat     = require 'gulp-concat'

gulp.task 'scss', ->
  gulp.src 'scss/godutch.scss'
      .pipe sass()
      .pipe gulp.dest('./static/')

gulp.task 'coffee', ->
  gulp.src 'coffee/*.coffee'
    .pipe coffee({bare:true, header: false}).on('error', gutil.log)
    .pipe react()
    .pipe gulp.dest('./static')

gulp.task 'watch', ->
  gulp.watch 'coffee/*.coffee', ['coffee']
  gulp.watch 'scss/**/*.scss', ['scss']


gulp.task 'default', ['scss', 'coffee', 'watch']
