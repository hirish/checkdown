Debt = Backbone.Model.extend
  toString: ->
    if @get('paid')
      "[Debt: " + @get('debtor') + " owed " + @get('lender') + " " + @get('amount') + "]"
    else
      "[Debt: " + @get('debtor') + " owes " + @get('lender') + " " + @get('amount') + "]"

Debts = Backbone.Collection.extend
    url: "debts"
    model: Debt

    userInvolved: (user) ->
        return new Debts @filter (debt) ->
            debt.get('lender_id') is user.id or debt.get('debtor_id') is user.id

    lenderIs: (user) ->
        return new Debts @filter (debt) ->
          debt.get('lender_id') is user.id

    debtorIs: (user) ->
        return new Debts @filter (debt) ->
          debt.get('debtor_id') is user.id

    groupIs: (group) ->
        groupId = group.get 'id'
        return new Debts @filter (debt) ->
          debt.get('group_id') is groupId

    between: (user1, user2) ->
        return new Debts @filter (debt) ->
          debt.get('debtor').id == user1.id and debt.get('lender').id == user2.id or debt.get('debtor').id == user2.id and debt.get('lender').id == user1.id

    groupByUsers: (user) ->
        grouped = @groupBy (debt) ->
            if debt.get('debtor_id') is user.get('id')
                debt.get('lender_id')
            else
                debt.get('debtor_id')
        for user of grouped
            grouped[user] = new Debts grouped[user]

        grouped

    groupByDebtor: ->
        grouped = @groupBy (debt) ->
          debt.get('debtor').get('username')
        for debtor of grouped
          grouped[debtor] = new Debts grouped[debtor]
        return grouped

    groupByLender: ->
        grouped = @groupBy (debt) ->
          debt.get('lender').get('username')
        for lender of grouped
          grouped[lender] = new Debts grouped[lender]
        return grouped

    totalAmount: ->
        @reduce ((x, y) ->
            # if y.get('paid') then x else x + y.get('amount')
            x + y.get('amount')
        ), 0

module.exports = {Debt, Debts}
