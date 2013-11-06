// Generated by CoffeeScript 1.6.3
(function() {
  var Debt, Debts, User, Users, createDebtFromJSON, createUserFromJSON, getDebts, getUsers, users;

  User = Backbone.Model.extend({
    defaults: {
      username: 'None',
      email: 'None'
    },
    toString: function() {
      return "[User: " + this.get('username') + "]";
    }
  });

  Debt = Backbone.Model.extend({
    defaults: {
      debtor: null,
      lendor: null,
      description: 'None',
      created: null,
      paid: false
    },
    toString: function() {
      if (this.get('paid')) {
        return "[Debt: " + this.get('debtor') + " owed " + this.get('lender') + " " + this.get('amount') + "]";
      } else {
        return "[Debt: " + this.get('debtor') + " owes " + this.get('lender') + " " + this.get('amount') + "]";
      }
    }
  });

  Users = Backbone.Collection.extend({
    model: Users
  });

  Debts = Backbone.Collection.extend({
    model: Debt,
    lenderIs: function(user) {
      return this.filter(function(debt) {
        return debt.get('lender').id === user.id;
      });
    },
    debtorIs: function(user) {
      return this.filter(function(debt) {
        return debt.get('debtor').id === user.id;
      });
    }
  });

  getUsers = function() {
    var response, userJSON, users;
    response = $.ajax('/users', {
      async: false
    });
    users = (jQuery.parseJSON(response.responseText)).users;
    return new Users((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = users.length; _i < _len; _i++) {
        userJSON = users[_i];
        _results.push(createUserFromJSON(userJSON));
      }
      return _results;
    })());
  };

  createUserFromJSON = function(json) {
    return new User({
      id: json.id,
      username: json.username,
      email: json.email
    });
  };

  users = getUsers();

  getDebts = function() {
    var debtJSON, debts, response;
    response = $.ajax('/debts', {
      async: false
    });
    debts = (jQuery.parseJSON(response.responseText)).debts;
    return new Debts((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = debts.length; _i < _len; _i++) {
        debtJSON = debts[_i];
        _results.push(createDebtFromJSON(debtJSON));
      }
      return _results;
    })());
  };

  createDebtFromJSON = function(json) {
    var debtor, lender;
    debtor = users.get(json.debtor.id);
    lender = users.get(json.lender.id);
    return new Debt({
      id: json.id,
      debtor: debtor,
      lender: lender,
      description: json.description,
      created: json.created,
      paid: json.paid,
      amount: json.amount
    });
  };

  $(function() {
    window.d = getDebts();
    return window.u = getUsers();
  });

}).call(this);
