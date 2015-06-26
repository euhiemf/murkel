_ = require 'underscore'
marked = require 'marked'
fs = require 'fs'
readdirp = require 'readdirp'
path = require 'path'
EventEmitter = require('events').EventEmitter
rimraf = require 'rimraf'
ncp = require('ncp').ncp

Promise = require('es6-promise').Promise


mkdirp = require 'mkdirp'
cwd = process.cwd()

pages = []

createDirectories = (list) -> new Promise (resolve, reject) ->


	len = list.length
	count = 0

	# emitter.on 'ready', 
	tht = @

	for d in list
		mkdirp path.join(cwd, 'static_site', d), do (len) -> (err) ->

			count++

			if count is len
				resolve()


readFiles = (files) -> new Promise (resolve, reject) ->

	collection = []

	len = files.length
	count = 0

	for file, index in files
		fs.readFile path.join(cwd, 'pages', file.path), 'utf8', do (file, len, index) -> (err, data) ->
			if (err) then console.log err
					
			files[index].raw_data = data

			count++

			if count is files.length
				resolve(files)






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

prettyData = (ugly) ->

	tree = []

	for item in ugly
		namespace tree, item.parent, _.omit(item, 'raw_data', 'content', 'menu')


	return tree

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


compileData = (collection) -> new Promise (resolve, reject) -> getTemplates (templates) ->


	for file, index in collection

		content = file.raw_data
		data = {}

		info_reg = /^-{3}\n((.|\n)*?)\n-{3}/

		if info_reg.test(content)
			json = "{#{info_reg.exec(content)[1]}}"
			data = JSON.parse json
			content = content.replace(info_reg, "").replace(/^\n/, "")

		if path.extname(file.path) is '.md'
			content = marked content
			collection[index].path = toHtmlExt(file.path)

		collection[index].content = content
		collection[index].data = data

		resolve
			collection: collection
			templates: templates


templetize = (collection, templates) -> new Promise (resolve, reject) ->

	page_data = prettyData(_.where(collection, { menu: true }))[0].menu

	for file, index in collection

		view = {
			content: file.content
		}

		page_view = {
			pages: page_data
			page_path: file.path
		}

		if file.data.title
			page_view.page_title = file.data.title
		else
			page_view.page_title = path.basename(file.path, '.html')


		for i in templates when i.name isnt 'page'
			templ = _.template(i.data)
			view[i.name] = templ(page_view)


		page = _.findWhere templates, { name: 'page' }
		templ = _.template(page.data)

		collection[index].content = templ view


	resolve collection


toHtmlExt = (path) ->
	dots = path.split('.')
	dots.splice dots.length - 1, 1
	name = dots.join('.')
	name += ".html"

	return name



writeFiles = (collection) -> new Promise (resolve, reject) ->
	count = 0
	len = collection.length

	for file in collection

		if path.extname(file.path) isnt '.html' then file.path = toHtmlExt(file.path)

		fs.writeFile path.join(cwd, 'static_site', file.path), file.content, do (len) -> (err) ->
			count++
			if count is len then resolve()


cloneAssets = -> new Promise (resolve, reject) ->

	outpath = path.join(cwd, 'static_site/assets')

	rimraf outpath, ->
		fs.lstat path.join(cwd, 'assets'), (err, stats) ->
			if not err and stats.isDirectory()
				ncp path.join(cwd, 'assets'), outpath, (err)->
					resolve()




initialize = ->

	directories = _.uniq(_.pluck(_.where(pages, { menu: true }), 'parent'))
	files = _.extend(_.clone(pages), pages.unlinked)

	createDirectories(directories).then ->
		readFiles(files).then (collection) ->
			compileData(collection).then (data) ->
				templetize(data.collection, data.templates).then (collection) ->
					writeFiles(collection).then ->
						cloneAssets().then ->
							console.log 'done!'




browse = readdirp({ root: path.join(cwd, 'pages'), fileFilter: ['*.html', '*.md']})

browse.on 'data', (entry) ->

	split = entry.parentDir.split('/')

	file = {
		name: entry.name
		path: entry.path
		parent: entry.parentDir
	}

	file.menu = split[0] is 'menu'

	pages.push file

browse.on 'end', -> initialize()
