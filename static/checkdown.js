/** @jsx React.DOM */;
var Application, Debt, DebtList, DebtView, Debts, Group, GroupList, Groups, Price, Settings, TitleText, User, Users, facebookLoginCallback;

User = Backbone.Model.extend({
  toString: function() {
    return "[User: " + this.get('username') + "]";
  }
});

Debt = Backbone.Model.extend({
  toString: function() {
    if (this.get('paid')) {
      return "[Debt: " + this.get('debtor') + " owed " + this.get('lender') + " " + this.get('amount') + "]";
    } else {
      return "[Debt: " + this.get('debtor') + " owes " + this.get('lender') + " " + this.get('amount') + "]";
    }
  }
});

Group = Backbone.Model.extend({
  initialize: function(o) {
    this.set('name', o.name);
    return this.set('id', o.id);
  },
  toString: function() {
    return "[Group: " + (this.get('name')) + "]";
  }
});

Users = Backbone.Collection.extend({
  url: "users",
  model: User
});

Debts = Backbone.Collection.extend({
  url: "debts",
  model: Debt,
  userInvolved: function(user) {
    return new Debts(this.filter(function(debt) {
      return debt.get('lender_id') === user.id || debt.get('debtor_id') === user.id;
    }));
  },
  lenderIs: function(user) {
    return new Debts(this.filter(function(debt) {
      return debt.get('lender_id') === user.id;
    }));
  },
  debtorIs: function(user) {
    return new Debts(this.filter(function(debt) {
      return debt.get('debtor_id') === user.id;
    }));
  },
  groupIs: function(groupId) {
    return new Debts(this.filter(function(debt) {
      return debt.get('group_id') === groupId;
    }));
  },
  between: function(user1, user2) {
    return new Debts(this.filter(function(debt) {
      return debt.get('debtor').id === user1.id && debt.get('lender').id === user2.id || debt.get('debtor').id === user2.id && debt.get('lender').id === user1.id;
    }));
  },
  groupByUsers: function(user) {
    var grouped;
    grouped = this.groupBy(function(debt) {
      if (debt.get('debtor_id') === user.get('id')) {
        return debt.get('lender_id');
      } else {
        return debt.get('debtor_id');
      }
    });
    for (user in grouped) {
      grouped[user] = new Debts(grouped[user]);
    }
    return grouped;
  },
  groupByDebtor: function() {
    var debtor, grouped;
    grouped = this.groupBy(function(debt) {
      return debt.get('debtor').get('username');
    });
    for (debtor in grouped) {
      grouped[debtor] = new Debts(grouped[debtor]);
    }
    return grouped;
  },
  groupByLender: function() {
    var grouped, lender;
    grouped = this.groupBy(function(debt) {
      return debt.get('lender').get('username');
    });
    for (lender in grouped) {
      grouped[lender] = new Debts(grouped[lender]);
    }
    return grouped;
  },
  totalAmount: function() {
    return this.reduce((function(x, y) {
      return x + y.get('amount');
    }), 0);
  }
});

Groups = Backbone.Collection.extend({
  model: Group
});


/* Views
 */

Application = React.createClass({displayName: 'Application',
  getInitialState: function() {
    return {
      selectedGroup: null
    };
  },
  componentWillMount: function() {
    this.props.groups.on('add remove', (function(_this) {
      return function() {
        return _this.forceUpdate();
      };
    })(this));
    return this.props.debts.on('add remove', (function(_this) {
      return function() {
        return _this.forceUpdate();
      };
    })(this));
  },
  selectGroup: function(id) {
    return this.setState({
      selectedGroup: id
    });
  },
  createDebt: function(debt) {
    return $.post('/debt', debt).done(function() {
      return console.log("Posted");
    }).fail(function() {
      return console.log("Failed");
    });
  },
  render: function() {
    var debts, selectedGroup, titleText, userDebts;
    userDebts = this.props.debts.userInvolved(this.props.user);
    selectedGroup = this.state.selectedGroup != null ? this.state.selectedGroup : userDebts.length > 0 ? userDebts.models[0].get('group_id') : null;
    debts = selectedGroup != null ? this.props.debts.groupIs(selectedGroup).userInvolved(this.props.user) : [];
    titleText = "Welcome to GoDut.ch, " + (this.props.user.get('username'));
    return React.DOM.div(null, 
                TitleText( {text:titleText} ),
                GroupList( {groups:this.props.groups, selectedGroup:selectedGroup, selectGroup:this.selectGroup} ),
                DebtList( {debts:debts, user:this.props.user, users:this.props.users} ),
                Settings( {createDebt:this.createDebt, selectedGroup:selectedGroup} )
            );
  }
});

TitleText = React.createClass({displayName: 'TitleText',
  render: function() {
    return React.DOM.div( {id:"logo"}, React.DOM.h1(null, this.props.text)) ;
  }
});

GroupList = React.createClass({displayName: 'GroupList',
  select: function(e) {
    var $target, groupId;
    $target = $(e.currentTarget);
    groupId = $target.data('group');
    return this.props.selectGroup(groupId);
  },
  render: function() {
    var groups;
    groups = this.props.groups.map((function(_this) {
      return function(group) {
        var select, selected;
        selected = group.get('id') === _this.props.selectedGroup ? 'selected' : '';
        select = _this.select;
        return React.DOM.li( {key:group.get('id'), className:selected, onClick:select, 'data-group':group.get('id')}, 
                    group.get('name'),
                    React.DOM.i( {className:"fa fa-arrow-circle-right"})
                );
      };
    })(this));
    return React.DOM.div( {id:"overview", className:"column narrow"}, 
            React.DOM.ul(null, 
                React.DOM.h2(null, "Combined"),
                React.DOM.li(null, 
                    "3 People Owe ", React.DOM.strong(null, "You"), " $10",
                    React.DOM.i( {className:"fa fa-arrow-circle-right"})
                ),
                React.DOM.li(null, 
                    React.DOM.strong(null, "You"), " Owe 2 People $18",
                    React.DOM.i( {className:"fa fa-arrow-circle-right"})
                ),
                React.DOM.h2(null, "Individual Groups"),
                groups,
                React.DOM.li( {className:"add", onClick:this.select}, 
                    React.DOM.i( {className:"fa fa-plus"})
                )
            )
        );
  }
});

DebtList = React.createClass({displayName: 'DebtList',
  render: function() {
    var debts, first;
    debts = this.props.debts.length > 0 ? (first = true, _.map(this.props.debts.groupByUsers(this.props.user), (function(_this) {
      return function(debts, userId) {
        var groupId, key, open, otherUser, user;
        otherUser = _this.props.users.get(userId);
        user = _this.props.user;
        groupId = _this.props.debts.models[0].get('group_id');
        key = "" + groupId + "." + userId;
        if (first) {
          first = false;
          open = true;
        } else {
          open = false;
        }
        return DebtView( {key:key, user:user, otherUser:otherUser, debts:debts, open:open} );
      };
    })(this))) : React.DOM.h2(null, "There are no debts");
    return React.DOM.div( {id:"details", className:"column wide"}, debts);
  }
});

DebtView = React.createClass({displayName: 'DebtView',
  getInitialState: function() {
    return {
      open: this.props.open || false
    };
  },
  componentDidMount: function() {
    var card, height;
    card = $(this.refs.card.getDOMNode());
    if (!card.hasClass('closed')) {
      height = card.height();
      return card.css('max-height', height);
    } else {
      card.css('transition', '0s');
      card.removeClass('closed');
      height = card.height();
      card.addClass('closed');
      setTimeout((function() {
        return card.css('transition', '1s');
      }), 1);
      return card.css('max-height', height);
    }
  },
  toggleOpen: function() {
    return this.setState({
      open: !this.state.open
    });
  },
  render: function() {
    var cardClass, credits, debits, debtRows, titleText, toggleIconClass, total;
    debits = this.props.debts.debtorIs(this.props.user);
    credits = this.props.debts.lenderIs(this.props.user);
    total = credits.totalAmount() - debits.totalAmount();
    if (total === 0) {
      return ;
    }
    titleText = total > 0 ? React.DOM.span(null, 
                    React.DOM.em(null, this.props.otherUser.get('username')), " owes ", React.DOM.strong(null, "You"), " ", Price( {amount:Math.abs(total), currency:"USD"} )
                ) : React.DOM.span(null, 
                    React.DOM.strong(null, "You"), " owe ", React.DOM.em(null, this.props.otherUser.get('username')), " ", Price( {amount:Math.abs(total), currency:"USD"} )
                );
    cardClass = this.state.open ? "card" : "closed card";
    toggleIconClass = this.state.open ? "fa fa-minus" : "fa fa-plus";
    debtRows = this.props.debts.map((function(_this) {
      return function(debt) {
        var sign;
        sign = debt.get('debtor_id') === _this.props.user.id ? '– ' : '+ ';
        return React.DOM.tr(null, 
                    React.DOM.td(null, "10/01/2014"),
                    React.DOM.td(null, sign, " ", Price( {amount:debt.get('amount'), currency:"USD"} )),
                    React.DOM.td(null, debt.get('description')),
                    React.DOM.td(null, React.DOM.i( {className:"fa fa-times"}))
                );
      };
    })(this));
    return React.DOM.div( {className:cardClass, ref:"card"}, 
            React.DOM.h3( {onClick:this.toggleOpen}, 
                titleText,
                React.DOM.i( {className:toggleIconClass})
            ),
            React.DOM.table(null, 
                React.DOM.tr(null, 
                    React.DOM.th( {className:"date"}, "Date"),
                    React.DOM.th( {className:"amount"}, "Amount"),
                    React.DOM.th(null, "Description"),
                    React.DOM.th(null)
                ),
                debtRows
            ),
            React.DOM.div( {className:"payment"}, 
                React.DOM.button( {className:"green"}, React.DOM.i( {className:"fa fa-check"}),"Pay All ", Price( {amount:Math.abs(total), currency:"USD"} )),
                React.DOM.button(null, "Pay Other")
            )
        );
  }
});

Settings = React.createClass({displayName: 'Settings',
  createDebt: function() {
    var amount, debt, description, getValue, type, user;
    getValue = (function(_this) {
      return function(x) {
        return _this.refs[x].getDOMNode().value;
      };
    })(this);
    user = getValue('who');
    type = getValue('type');
    amount = getValue('amount');
    description = getValue('description');
    debt = {
      user: parseInt(user),
      description: description,
      group: this.props.selectedGroup,
      amount: (parseInt(amount)).toString() === "NaN" ? 0 : type === 'charge' ? parseInt(amount) : 0 - (parseInt(amount))
    };
    this.props.createDebt(debt);
    return false;
  },
  render: function() {
    return React.DOM.div( {id:"user", className:"column"}, 
            React.DOM.div( {id:"new-debt", className:"card"}, 
                React.DOM.h3(null, 
                    "New Debt",
                    React.DOM.i( {className:"fa fa-minus"})
                ),
                React.DOM.form( {onSubmit:this.createDebt}, 
                    React.DOM.div(null, 
                        React.DOM.select( {ref:"type"}, 
                            React.DOM.option( {value:"charge"}, "Charge"),
                            React.DOM.option( {value:"owe"}, "I Owe")
                        ),
                        React.DOM.i( {className:"fa fa-caret-down"}),

                        React.DOM.select( {ref:"who"}, 
                            React.DOM.option( {value:"1"}, "Barnaby Jackson"),
                            React.DOM.option( {value:"2"}, "Lee Woodbridge")
                        ),
                        React.DOM.i( {className:"fa fa-caret-down"}),

                        React.DOM.input( {ref:"amount", name:"amount", type:"text", placeholder:"Amount"} )
                    ),

                    React.DOM.div(null, 
                        React.DOM.input( {ref:"description", name:"description", type:"text", placeholder:"Description",  className:"form-control"})
                    ),

                    React.DOM.div( {className:"create-button"}, 
                        React.DOM.button(null, "Create")
                    )
                )
            ),
            React.DOM.div( {className:"card"}, 
                React.DOM.h3(null, 
                    "Group Members",
                    React.DOM.i( {className:"fa fa-plus"})
                )
            )
        );
  }
});

Price = React.createClass({displayName: 'Price',
  render: function() {
    var amount, code, symbol;
    switch (this.props.currency) {
      case 'USD':
        code = 'USD';
        symbol = String.fromCharCode(36);
        break;
      case 'EUR':
        code = 'EUR';
        symbol = String.fromCharCode(8364);
        break;
      case 'GBP':
        code = 'GBP';
        symbol = String.fromCharCode(163);
        break;
      default:
        code = 'USD';
        symbol = String.fromCharCode(36);
    }
    console.log(this.props.amount);
    amount = Number(this.props.amount / 100).toFixed(2);
    code = ' ' + code;
    if (this.props.hideCurrency != null) {
      code = '';
    }
    return React.DOM.span(null, symbol,amount,code);
  }
});

facebookLoginCallback = function(response) {
  var debts, groups, users;
  groups = new Groups();
  debts = new Debts();
  users = new Users();
  groups.on('add', (function(_this) {
    return function(group) {
      var id;
      id = group.get('id');
      $.getJSON("/group/" + id + "/debts", function(response) {
        var debt, _i, _len, _ref, _results;
        _ref = response.debts;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          debt = _ref[_i];
          _results.push(debts.add(new Debt(debt)));
        }
        return _results;
      });
      return $.getJSON("/group/" + id + "/users", function(response) {
        var user, _i, _len, _ref, _results;
        _ref = response.users;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          user = _ref[_i];
          _results.push(users.add(new User(user)));
        }
        return _results;
      });
    };
  })(this));
  return $.getJSON('/user', function(response) {
    var id, user, _i, _len, _ref;
    user = new User(response.user);
    users.add(user);
    _ref = response.user.groups;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      id = _ref[_i];
      $.getJSON("/group/" + id, (function(_this) {
        return function(response) {
          return groups.add(new Group(response.group));
        };
      })(this));
    }
    return React.renderComponent(Application({
      user: user,
      users: users,
      groups: groups,
      debts: debts
    }), $('#main')[0], function() {
      return setTimeout((function() {
        return $('body').addClass('logged-in');
      }), 50);
    });
  });
};

$(function() {
  window.fbAsyncInit = function() {
    FB.init({
      appId: '422041944562938',
      status: true,
      cookie: true,
      xfbml: true
    });
    $('#facebook-login').click(function() {
      return FB.login(facebookLoginCallback, {
        scope: 'email'
      });
    });
    return FB.Event.subscribe('auth.authResponseChange', function(response) {
      if (response.status === 'connected') {
        return facebookLoginCallback();
      } else if (response.status === 'not_authorized') {
        return FB.login((function() {}), {
          scope: 'email'
        });
      } else {
        return FB.login((function() {}), {
          scope: 'email'
        });
      }
    });
  };
  return (function(d) {
    var id, js, ref;
    id = 'facebook-jssdk';
    ref = d.getElementsByTagName('script')[0];
    if (d.getElementById(id)) {
      return;
    }
    js = d.createElement('script');
    js.id = id;
    js.async = true;
    js.src = "//connect.facebook.net/en_US/all.js";
    return ref.parentNode.insertBefore(js, ref);
  })(document);
});
