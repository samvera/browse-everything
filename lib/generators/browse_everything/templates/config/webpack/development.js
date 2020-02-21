process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const environment = require('./environment')

const exported = environment.toWebpackConfig()
exported['resolve'] = { 'symlinks': false }
module.exports = exported
