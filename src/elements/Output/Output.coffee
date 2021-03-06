###
 * coffeescript-ui - Coffeescript User Interface System (CUI)
 * Copyright (c) 2013 - 2016 Programmfabrik GmbH
 * MIT Licence
 * https://github.com/programmfabrik/coffeescript-ui, http://www.coffeescript-ui.org
###

class CUI.Output extends CUI.DataFieldInput
	initOpts: ->
		super()
		@addOpts
			placeholder:
				default: ""
				check: String
			text:
				check: String
			# set to yes for placeholder and text
			markdown:
				mandatory: true
				default: false
				check: Boolean
			getValue:
				check: Function
			multiline:
				check: Boolean
				default: true
				mandatory: true
			allow_delete:
				mandatory: true
				default: false
				check: Boolean

	readOpts: ->
		super()
		for k in ["undo_support", "check_changed", "mark_changed"]
			@removeOpt(k)
			@["_"+k] = false
		@

	init: ->
		@__textSpan = new Label(markdown: @_markdown, multiline: @_multiline, class: "cui-data-field-output-label" ) #"cui-data-field-output-label"
		@setText(@_text)
		@__textSpan

	# WHY is that here, same in DataField...
	# disable: ->
	# 	@addClass("cui-data-field-disabled")

	# enable: ->
	# 	@removeClass("cui-data-field-disabled")

	setText: (txt, markdown = null) ->
		if isEmpty(txt)
			@__textSpan.addClass("cui-output-empty")
			txt = @_placeholder
		else
			@__textSpan.removeClass("cui-output-empty")

		if markdown == null
			@__textSpan.setText(txt, @_markdown)
		else
			@__textSpan.setText(txt, markdown)

	checkValue: ->
		# Output does not care about values

	displayValue: ->
		super()
		if @getName()
			ret = @getValue()
			if not isEmpty(ret)
				@__deleteBtn?.show()
			else
				@__deleteBtn?.hide()
			if isContent(ret)
				@replace(ret)
			else
				@setText(ret, false) # don't use markdown for data driven output
		@

	getValue: ->
		value = super()
		if @_getValue
			@_getValue.call(@, value, @getData())
		else
			value

	render: ->
		super()
		@replace(@__textSpan)
		if @_allow_delete and @hasData()
			@addClass("cui-output--deletable")
			@__deleteBtn = new Button
				icon: "remove"
				appearance: "flat"
				onClick: =>
					@setValue(null, no_trigger: false)
			@append(@__deleteBtn)
		@
