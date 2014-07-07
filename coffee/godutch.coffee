`/** @jsx React.DOM */`

{Group, Groups} = require './models/group.coffee'
{Debt, Debts} = require './models/debt.coffee'
{User, Users} = require './models/user.coffee'
{Application} = require './views/application.coffee'
{TitleText} = require './views/titletext.coffee'
{Price} = require './views/utils/price.coffee'
{GroupList} = require './views/grouplist.coffee'
{DebtList} = require './views/debtlist.coffee'
{DebtView} = require './views/debtview.coffee'
{RightPanel} = require './views/rightpanel.coffee'
{Settings} = require './views/settings.coffee'

facebookLoginCallback = (response) ->

    groups = new Groups()
    debts = new Debts()
    users = new Users()

    groups.on 'add', (group) =>
        id = group.get('id')

        $.getJSON "/group/#{id}/debts", (response) ->
            returned_debts = _.map response.debts, (debt) -> new Debt debt
            debts.add returned_debts

        $.getJSON "/group/#{id}/users", (response) ->
            returned_users = _.map response.users, (user) -> new User user
            users.add returned_users

    $.getJSON '/user', (response) ->
        user = new User response.user
        users.add user

        for id in response.user.groups
            $.getJSON "/group/#{id}", (response) =>
                groups.add(new Group response.group)


        window.app = React.renderComponent Application(user: user, users: users, groups: groups, debts: debts), $('#main')[0], ->
            setTimeout (->$('body').addClass 'logged-in'), 50


$ ->
    window.fbAsyncInit = ->
        FB.init
          appId      : '422041944562938'
          status     : true
          cookie     : true
          xfbml      : true

        $('#facebook-login').click ->
            FB.login facebookLoginCallback, scope: 'email'

        FB.Event.subscribe 'auth.authResponseChange', (response) ->
          if response.status == 'connected'
              facebookLoginCallback()
          else if response.status == 'not_authorized'
              FB.login (->), scope: 'email'
          else
              FB.login (->), scope: 'email'
    ((d) ->
        id = 'facebook-jssdk'
        ref = d.getElementsByTagName('script')[0]
        if d.getElementById(id) then return
        js = d.createElement('script')
        js.id = id
        js.async = true
        js.src = "//connect.facebook.net/en_US/all.js"
        ref.parentNode.insertBefore js, ref
    )(document)

  window.f = ->
    facebookLoginCallback()
