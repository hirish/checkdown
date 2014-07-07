Price = React.createClass
  render: ->
    switch @props.currency
      when 'USD'
        code = 'USD'
        symbol = String.fromCharCode 36
      when 'EUR'
        code = 'EUR'
        symbol = String.fromCharCode 8364
      when 'GBP'
        code = 'GBP'
        symbol = String.fromCharCode 163
      else
        code = 'USD'
        symbol = String.fromCharCode 36

		# Amount is passed in cents
    amount = Number(@props.amount/100).toFixed(2)

    code = ' ' + code

    if @props.hideCurrency? then code = ''

    `<span>{symbol}{amount}{code}</span>`

module.exports = {Price}
