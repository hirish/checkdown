Settings = React.createClass
    componentDidMount: ->
        $(@refs.paidCutoffDate.getDOMNode()).mask '99 / 99 / 9999'

    updatePaidCutoff: (never) ->
        =>
            newCutoff = Date.parse @refs.paidCutoffDate.getDOMNode().value

            settings = @props.settings
            settings.paidCutoffDate = if never or isNaN(newCutoff) then null else newCutoff

            @props.updateSettings settings

    focusOnCutoff: ->
        $(@refs.paidCutoffDate.getDOMNode()).focus()

    render: ->
        neverPaid = @props.settings.paidCutoffDate?

        `<div className="card settings">
            <h3>Settings</h3>
            <div>Show debts from:</div>
            <div>
                <input type="radio" name="paidCutoff" checked={!neverPaid} onChange={this.updatePaidCutoff(true)} />
                <label>Forever</label>

                <input type="radio" name="paidCutoff" checked={neverPaid} onChange={this.focusOnCutoff} />
                <label>
                  <input type="text" placeholder="MM / DD / YYYY" ref="paidCutoffDate" onKeyUp={this.updatePaidCutoff(false)} />
                </label>
            </div>
        </div>`

module.exports = {Settings}
