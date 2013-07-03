handlebars = require("handlebars")
sysPath = require("path")
fs = require("fs")
glob = require("glob")
mkdirp = require("mkdirp")
    
module.exports = class StaticHandlebarsCompiler
  brunchPlugin: true
  type: "template"
  extension: "hbs"

  constructor: (@config) ->
    @extension    = @config.plugins?.static_handlebars?.extension ? "hbs"
    @relAssetPath = @config.plugins?.static_handlebars?.asset ? "app/assets"
    @relPartialPath = @config.plugins?.static_handlebars?.partial ? "app/templates"
    @partials = {}
    glob "#{ @relPartialPath }/_*.#{ @extension }", (err, files) =>
      throw err if err?
      files.forEach (file) =>
        name = sysPath.basename(file, ".#{ @extension }").substr(1)
        fs.readFile file, (err, data) =>
          throw err if err?
          # TODO: Make encoding configurable
          @partials[name] = data.toString('utf8')
    null

  # Copied from current static-jade-brunch
  getHtmlFilePath: (hbsFilePath, relAssetPath) ->
    relativeFilePathParts = hbsFilePath.split sysPath.sep
    relativeFilePathParts.push(
      relativeFilePathParts.pop()[...-@extension.length] + "html" )
    relativeFilePath = sysPath.join.apply this, relativeFilePathParts[1...]
    newpath = sysPath.join relAssetPath, relativeFilePath
    return newpath
    
  compile: (data, path, callback) ->
    try
      basename = sysPath.basename(path, ".hbs")
      handlebars.registerPartial name, template for own name, template of @partials
      template = handlebars.compile(data)
      html = template()
      htmlFilePath = @getHtmlFilePath(path, @relAssetPath)
      
      dirname = sysPath.dirname htmlFilePath
      
      mkdirp dirname, '0775', (err) ->
        throw err if err?
        fs.writeFile htmlFilePath, html, (err) -> throw err if err?

      return result = ''

    catch err
      return error = err
    finally
      callback error, result

