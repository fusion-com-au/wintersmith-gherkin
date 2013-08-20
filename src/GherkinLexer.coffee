
gherkin        = require 'gherkin'
{EventEmitter} = require 'events'

class GherkinLexer extends EventEmitter
	
	constructor: (lang = 'en') ->
		events = [ 'comment', 'tag', 'feature', 'background', 'scenario',
		           'scenario_outline', 'examples', 'step', 'doc_string',
		           'row', 'eof' ]
		emit = (name) =>
			(args...) =>
				@emit.apply this, [name].concat args
		obj = {}
		for e in events
			obj[e] = emit e
		Lexer = gherkin.Lexer lang
		@lexer = new Lexer obj
	
	scan: (feature) ->
		@lexer.scan feature

module.exports = GherkinLexer
