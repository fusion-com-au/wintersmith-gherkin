# wintersmith-gherkin

[Wintersmith](https://github.com/jnordberg/wintersmith) gherkin plugin

## Usage

Just place your `.feature` files in the contents folder and they will be parsed
to html files using a template. For an example template see
[`/example/templates/gherkin.jade`](https://github.com/semfact/wintersmith-gherkin/blob/master/example/templates/gherkin.jade).

## Installing

Install globally or locally using npm

```
npm install [-g] wintersmith-gherkin
```

and add `wintersmith-gherkin` to your config.json

```json
{
	"plugins": [
		"wintersmith-gherkin"
	],
	"gherkin": {
		"template": "gherkin.jade"
	}
}
```
