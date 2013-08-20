
fs             = require 'fs'
path           = require 'path'
jade           = require 'jade'
marked         = require 'marked'
GherkinLexer   = require './GherkinLexer'

module.exports = (env, callback) ->
	# *env* is the current wintersmith environment
	# *callback* should be called when the plugin has finished loading
	
	class GherkinPlugin extends env.ContentPlugin
		
		constructor: (@filepath, @text) ->
			lang = 'en' # TODO: read from configuration
			@lexer = new GherkinLexer lang
		
		getFilename: ->
			feature = @filepath.relative
			ext     = path.extname feature
			name    = path.basename feature, ext
			name + '.html'
		
		getView: -> (env, locals, contents, templates, callback) ->
			rendered = ''
			
			@lexer.on 'feature', (keyword, name, description) ->
				rendered += marked description
			
			@lexer.on 'eof', ->
				callback null, new Buffer(rendered)
			@lexer.scan @text
	
	GherkinPlugin.fromFile = (filepath, callback) ->
		fs.readFile filepath.full, (error, result) ->
			if not error?
				plugin = new GherkinPlugin filepath, result.toString()
			callback error, plugin
	
	env.registerContentPlugin 'gherkin', '**/*.*feature', GherkinPlugin
	
	# tell plugin manager we are done
	callback()
