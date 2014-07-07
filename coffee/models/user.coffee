User = Backbone.Model.extend
    toString: ->
        "[User: " + @get('username') + "]"

Users = Backbone.Collection.extend
    url: "users"
    model: User

module.exports = {User, Users}
