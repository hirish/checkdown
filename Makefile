default:
	gulp coffee
	gulp scss

setup:
	rm -rf bower_components node_modules
	npm install
	bower install

watch:
	gulp watch
