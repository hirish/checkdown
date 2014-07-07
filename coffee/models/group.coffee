Group = Backbone.Model.extend
    initialize: (o) ->
        @set 'name', o.name
        @set 'id', o.id

    toString: ->
        "[Group: #{@get('name')}]"

Groups = Backbone.Collection.extend
    model: Group


module.exports = {Group, Groups}
