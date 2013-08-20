
fs             = require 'fs'
path           = require 'path'
jade           = require 'jade'
marked         = require 'marked'
GherkinLexer   = require './GherkinLexer'

markedLine = (md) ->
	split  = md.split '\n'
	tokens = marked.lexer split[0]
	if tokens.length > 0
		tokens[0].type = 'html'
	marked.parser tokens

module.exports = (env, callback) ->
	# *env* is the current wintersmith environment
	# *callback* should be called when the plugin has finished loading
	
	class GherkinPlugin extends env.ContentPlugin
		
		constructor: (@filepath, @text) ->
			template  = fs.readFileSync __dirname + '/template.jade' # TODO: read form configuration
			@template = jade.compile template
			
			lang = 'en' # TODO: read from configuration
			@lexer = new GherkinLexer lang
		
		getFilename: ->
			feature = @filepath.relative
			ext     = path.extname feature
			name    = path.basename feature, ext
			name + '.html'
		
		getView: -> (env, locals, contents, templates, callback) ->
			lastScenario = null
			feature =
				scenarios: []
			# see https://github.com/cucumber/gherkin/blob/master/js/example/print.js
			@lexer.on 'feature', (keyword, name, description) ->
				feature.keyword     = keyword
				feature.name        = markedLine name
				feature.description = marked description
				feature.scenarios   = []
			@lexer.on 'scenario', (keyword, name, description) ->
				scenario =
					keyword:     keyword
					name:        markedLine name
					description: marked description
					steps:       []
				feature.scenarios.push scenario
				lastScenario = scenario
			@lexer.on 'step', (keyword, name) ->
				lastScenario.steps.push
					keyword: keyword
					name:    markedLine name
			@lexer.on 'eof', =>
				callback null, new Buffer @template feature
			@lexer.scan @text
	
	GherkinPlugin.fromFile = (filepath, callback) ->
		fs.readFile filepath.full, (error, result) ->
			if not error?
				plugin = new GherkinPlugin filepath, result.toString()
			callback error, plugin
	
	env.registerContentPlugin 'gherkin', '**/*.*feature', GherkinPlugin
	
	# tell plugin manager we are done
	callback()
