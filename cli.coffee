_ = require 'underscore'
marked = require 'marked'
fs = require 'fs'
readdirp = require 'readdirp'
path = require 'path'
EventEmitter = require('events').EventEmitter
rimraf = require 'rimraf'
ncp = require('ncp').ncp


mkdirp = require 'mkdirp'
cwd = process.cwd()


hasKey = (ob, key) ->
	for i in ob
		if _.has i, key
			return i[key]

	return false


namespace = (base, string, end) ->
	parts = string.split('/')

	for key, index in parts
		res = hasKey base, key
		if not res
			tmp = {}
			tmp[key] = []
			base.push tmp
			base = tmp[key]
		else
			base = res

	base.push end



makeMenu = (ugly) ->

	tree = []

	for item in ugly

		namespace tree, item.parent, item

	return tree

pages = {
	unlinked: [],
	menu: []
}

browse = readdirp({ root: path.join(cwd, 'pages'), fileFilter: ['*.html', '*.md']})

browse.on 'data', (entry) ->

	split = entry.parentDir.split('/')

	if entry.parentDir is ""
		pages.unlinked.push
			name: entry.name
			path: entry.path

	if split[0] is 'menu'
		pages.menu.push
			name: entry.name
			path: entry.path
			parent: entry.parentDir



toHtmlExt = (path) ->
	dots = path.split('.')
	dots.splice dots.length - 1, 1
	name = dots.join('.')
	name += ".html"

	return name



writeFiles = (data) ->
	emitter = new EventEmitter()
	count = 0
	len = data.length
	emitter.on 'increase', ->

	for d in data

		if path.extname(d.path) isnt '.html' then d.path = toHtmlExt(d.path)

		fs.writeFile path.join(cwd, 'static_site', d.path), d.data, do (emitter, len) -> (err) ->
			count++
			if count is len then emitter.emit 'ready'

	return emitter

templetize = (content, templates) -> 

	view = {
		content: content
	}


	page_view = {
		pages: makeMenu(pages.menu)[0]
	}

	# console.log page_view.menu

	for i in templates when i.name isnt 'page'
		templ = _.template(i.data)
		view[i.name] = templ(page_view)



	page = _.findWhere templates, { name: 'page' }
	templ = _.template(page.data)

	return templ view




getTemplates = (cb) ->

	search = readdirp({ root: path.join(cwd, 'scaffolding'), fileFilter: '*.html'})

	templates = []
	paths = []

	search.on 'data', (entry) ->
		paths.push entry.path

	search.on 'end', ->
		len = paths.length

		for fname in paths
			fs.readFile path.join(cwd, 'scaffolding', fname), 'utf8', do (fname, len) -> (err, data) ->

				templates.push
					data: data,
					name: path.basename(fname, '.html')

				if templates.length is len
					cb templates




readFiles = (list) ->

	collection = []

	len = list.length
	emitter = new EventEmitter()

	# emitter.on 'ready', cb

	getTemplates (templates) ->

		for fname in list
			fs.readFile path.join(cwd, 'pages', fname), 'utf8', do (fname, len) -> (err, data) ->
				if (err) then console.log err

				if path.extname(fname) is '.md'
					data = marked data
						

				data = templetize(data, templates)

				collection.push
					path: fname
					data: data

				if collection.length is list.length
					emitter.emit 'ready', collection

	return emitter




createDirs = (list) ->
	len = list.length
	count = 0
	emitter = new EventEmitter()

	# emitter.on 'ready', 

	for d in list
		mkdirp path.join(cwd, 'static_site', d), do (len, emitter) -> (err) ->

			count++

			if count is len
				emitter.emit 'ready'

	return emitter
		



browse.on 'end', ->


	directories = _.uniq(_.pluck(pages.menu, 'parent'))
	files = _.pluck(_.extend(_.clone(pages.menu), pages.unlinked), 'path')

	createDirs(directories).on 'ready', ->
		console.log 'Directories created'
		readFiles(files).on 'ready', (data) ->
			console.log 'Files read'
			writeFiles(data).on 'ready', ->
				fs.lstat path.join(cwd, 'assets'), (err, stats) ->
					if not err and stats.isDirectory()
						ncp path.join(cwd, 'assets'), path.join(cwd, 'static_site/assets'), (err)->
							console.log 'DONE copying assets'

