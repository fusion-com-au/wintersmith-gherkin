
fs             = require 'fs'
path           = require 'path'
marked         = require 'marked'
GherkinLexer   = require './GherkinLexer'

markedLine = (md) ->
	split  = md.split '\n'
	tokens = marked.lexer split[0]
	if tokens.length > 0
		tokens[0].type = 'html'
	marked.parser tokens

escapePlaceholders = (str) ->
	r = /<[^>]*>/g
	str.replace r, (str) ->
		str = str.substr 1, str.length - 2
		'<span class="placeholder">' + str + '</span>'

nl2br = (str) ->
	str.replace /\n/g, '<br/>'

module.exports = (env, callback) ->
	# *env* is the current wintersmith environment
	# *callback* should be called when the plugin has finished loading
	
	class GherkinPlugin extends env.ContentPlugin
		
		constructor: (@filepath, @text) ->
			configTemplate = env.config.gherkin?.template
			configLang     = env.config.gherkin?.language
			if configTemplate?
				@template = configTemplate
			else
				@template = 'gherkin.jade'
				env.logger.warn 'No template for wintersmith-gherkin set, using ' + @template + ' as default'
			lang = configLang or 'en'
			@lexer = new GherkinLexer lang
		
		getFilename: ->
			@filepath.relative.replace /feature$/, 'html'
		
		getView: -> (env, locals, contents, templates, callback) ->
			template = templates[@template]
			if template is undefined
				callback Error 'Could not find template ' + @template
				return
			lastSeen  = null
			lastTable = null
			lastStep  = null
			feature   =
				scenarios: []
			tags = []
			# see https://github.com/cucumber/gherkin/blob/master/js/example/print.js
			@lexer.on 'feature', (keyword, name, description) ->
				feature.keyword     = keyword
				feature.name        = markedLine name
				feature.description = marked description
				feature.scenarios   = []
				feature.tags        = tags
				tags = []
			@lexer.on 'background', (keyword, name, description) ->
				feature.background =
					keyword:     keyword
					name:        markedLine name
					description: marked description
					steps:       []
					tags:        tags
				tags = []
				lastSeen = feature.background
			@lexer.on 'scenario', (keyword, name, description) ->
				scenario =
					keyword:     keyword
					name:        markedLine name
					description: marked description
					steps:       []
					tags:        tags
					outline:     false
				tags = []
				feature.scenarios.push scenario
				lastSeen = scenario
			@lexer.on 'scenario_outline', (keyword, name, description) ->
				scenarioOutline =
					keyword:     keyword
					name:        markedLine name
					description: marked description
					steps:       []
					tags:        tags
					examples:    []
					outline:     true
				tags = []
				feature.scenarios.push scenarioOutline
				lastSeen = scenarioOutline
			@lexer.on 'step', (keyword, name) ->
				step =
					keyword: keyword
					name:    markedLine escapePlaceholders name
					table:   []
				lastTable = step.table
				lastSeen.steps.push step
				lastStep = step
			@lexer.on 'doc_string', (content_type, string) ->
				lastStep.docString =
					contentType: content_type
					string:      nl2br escapePlaceholders string
			@lexer.on 'examples', (keyword, name, description) ->
				table = []
				lastSeen.examples.push
					keyword:     keyword
					name:        markedLine name
					description: marked description
					table:       table
				lastTable = table
			@lexer.on 'row', (row) ->
				lastTable.push row
			@lexer.on 'tag', (value) ->
				tags.push value.substr 1
			@lexer.on 'eof', =>
				ctx =
					env: env
					contents: contents
				env.utils.extend ctx, locals
				env.utils.extend ctx, feature
				callback null, new Buffer template.fn ctx
			@lexer.scan @text
	
	GherkinPlugin.fromFile = (filepath, callback) ->
		fs.readFile filepath.full, (error, result) ->
			if not error?
				plugin = new GherkinPlugin filepath, result.toString()
			callback error, plugin
	
	env.registerContentPlugin 'pages', '**/*.*feature', GherkinPlugin
	
	# tell plugin manager we are done
	callback()
