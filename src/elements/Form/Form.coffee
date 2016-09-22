class CUI.Form extends CUI.DataField

	initOpts: ->
		super()
		@addOpts
			fields:
				mandatory: true
				check: (v) ->
					CUI.isFunction(v) or CUI.isArray(v)
			class_table:
				check: String
			header:
				check: Array
			# true: all fields horizontal
			# int: n fields horizontal
			horizontal:
				default: false
				check: (v) ->
					isBoolean(v) or (isInteger(v) and v > 0)
			appearance:
				default: "normal"
				mandatory: true
				check: ["normal","separators"]
			# passed to underlying vertical layout
			maximize:
				check: Boolean
			maximize_horizontal:
				check: Boolean
			maximize_vertical:
				check: Boolean
			top: {}
			bottom: {}


	readOpts: ->
		super()
		if @_horizontal == 1
			@__horizontal = null
		else
			@__horizontal = @_horizontal

		vl_opts = class: "cui-form cui-padding-reset cui-form-appearance-"+@_appearance

		for k in [
			"maximize"
			"maximize_horizontal"
			"maximize_vertical"
		]
			if @hasSetOpt(k)
				vl_opts[k] = @getSetOpt(k)

		if @hasSetOpt("top")
			vl_opts.top = content: @_top

		if @hasSetOpt("bottom")
			vl_opts.bottom = content: @_bottom

		@__verticalLayout = new VerticalLayout(vl_opts)
		@__verticalLayout

	initTemplate: ->
		@registerTemplate(@__verticalLayout.getLayout())

	getLayout: ->
		@__verticalLayout

	__createFields: ->
		fs = []
		fields = @getArrayFromOpt("fields")
		for field, idx in fields
			if not field
				continue
			if CUI.isFunction(field)
				_field = DataField.new(field(@))
			else
				_field = DataField.new(field)
			_field.setForm(@)
			fs.push(_field)
		fs

	getNameOpt: ->
		name:
			check: String

	init: ->
		@__initUndo()
		@initFields()
		@setFormDepth()

	initFields: ->
		@__fields = @__createFields()

	setData: (data) ->
		if @_name and not CUI.isFunction(data)
			# CUI.debug "init data ", @_name, data, 1
			if isUndef(data[@_name])
				data[@_name] = {}
			super(data[@_name])
		else
			super(data)
		# sometimes fields depend on data, we need to see if
		# that is the case
		# these functions do this:
		#
		# fields: ->
		#    if not df.getData()
		#       return []
		#    else
		#       return [...]
		#
		# it can happen, like in FormPopover, that fields
		# are not yet initialized
		#
		if CUI.isFunction(@_fields) and @__fields and @__fields.length == 0
			# CUI.debug "fields depends on data...", @__data
			@initFields()
			@callOnOthers("setData", @__data)
		@

	# this hides a form row, if all
	# datafields in it are hidden
	__setRowVisibility: (tr) ->
		df = DOM.data(tr[0], "data-field")
		if not df
			CUI.warn("Form.__setRowVisibility", "data-field not found", df, @)
			return

		for _f in df.getAllDataFields()
			if not _f.isHidden()
				tr.css("display", "")
				return
		tr.css("display", "none")

	render: ->
		if CUI.__ng__
			# we need fields rendered before we render
			# us, so that <label for=...> can work, just
			# to be safe, for "ng" only until we know
			# it does not break anything
			super()
			@renderTable()
		else
			@renderTable()
			super()
		@

	getTable: ->
		@table

	renderTable: ->
		@table = $table("cui-form-table")

		if @_horizontal
			@table.addClass("cui-form-table-horizontal")
		else
			@table.addClass("cui-form-table-vertical")

		Events.listen
			node: @table
			type: "form-check-row-visibility"
			call: (ev) =>
				tr = $(ev.getNode()).closest(".cui-form-tr")
				# CUI.debug "form check row visibiltiy", ev, tr
				ev.stopPropagation()
				if not tr.hasClass("cui-form-tr-vertical")
					return
				if tr.length
					@__setRowVisibility(tr)

		if @_class_table
			@table.addClass(@_class_table)

		# add all classes from the top level
		for cls in (@_class or "").split(/\s+/)
			if isEmpty(cls)
				continue
			@table[0].classList.add(cls+"-table")

		if @_horizontal and CUI.__ng__
			td_classes = [
				"cui-padding cui-form-left cui-form-th"
				"cui-padding cui-form-center cui-form-td"
			]
		else
			td_classes = [
				"cui-padding cui-form-left cui-form-td"
				"cui-padding cui-form-center cui-form-td"
			]

		# CUI.error "Form.renderTable", @table[0], @__horizontal, @getFields().length

		getAppend = (v, info=@) =>
			if CUI.isPlainObject(v) # assume a label constructor
				# new Label(v).DOM
				new MultilineLabel(v).DOM
			else if isString(v)
				# new Label(text: v).DOM
				new MultilineLabel(text: v).DOM
			else if v?.DOM
				v.DOM
			else if CUI.isFunction(v)
				getAppend(v(info))
			else if isEmpty(v)
				null
			else
				v

		if @_header
			tr_head = $tr("cui-form-tr-header").appendTo(@table)

			console.error "adding header..", @_header

			assert(not @_horizontal, "Form.renderTable", "opts.header cannot be used with opts.horizontal", opts: @opts)

			for td_class, idx in td_classes
				head = @_header[idx]
				th = $th(td_class).appendTo(tr_head)
				th.append(getAppend(head?.label))

		has_left = false

		_fields = @getFields()
		if @__horizontal > 1
			# re-sort fields
			fields = []
			fields_per_column = Math.ceil(_fields.length / @__horizontal)
			for col_i in [0...@__horizontal]
				for row_i in [0...fields_per_column]
					target_idx = col_i+row_i*@_horizontal
					source_idx = col_i*fields_per_column+row_i
					if source_idx >= _fields.length
						continue
					fields[target_idx] = _fields[source_idx]

		else
			fields = _fields

		for _field, idx in fields

			# _field can be undefined in @__horizontal > 1 tables

			if @__horizontal and (idx == 0 or (@__horizontal > 1 and idx % @__horizontal == 0))
				tr_labels = $tr("cui-form-tr cui-form-tr-horizontal cui-form-tr-labels")

				if not CUI.__ng__
					tr_labels.appendTo(@table)

				tr_fields = $tr("cui-form-tr cui-form-tr-horizontal cui-form-tr-fields").appendTo(@table)
				# tr_rights = $tr("cui-form-tr cui-form-tr-horizontal cui-form-tr-rights").appendTo(@table)

			fopts = _field?._form or {}

			tds = []
			right = null

			if fopts.hasOwnProperty("right")
				right = fopts.right
				# console.error("Form.renderTable: form.right is deprecated. Remove this from your code. Form:", @, "Field:", _field, "Field#", idx, "Right:", right)

			append_content = []
			append_left = []
			use_field_as_label = false

			for app, idx in [fopts, _field, right]

				if idx == 0
					content = null

					if app.label
						if isString(app.label) and CUI.__ng__
							# use a HTML label and link it to the field
							# if possible
							content = CUI.DOM.element("label", for: _field.getUniqueIdForLabel())
							content.textContent = app.label
						else
							content = getAppend(app.label, _field)

					if app.use_field_as_label
						assert(not @_horizontal, "Form.renderTable", "field.form.use_field_as_label is not supported with opts.horizontal.", opts: @opts, field: _field)

						use_field_as_label = true
				else
					content = getAppend(app, _field)

				if content != null
					if use_field_as_label or idx == 0
						append_left.push(content)
					else
						append_content.push(content)

			if append_left.length > 0
				if @_horizontal
					if CUI.__ng__
						console.error("Form.renderTable", "field.form.label in horizontal tables is obsolete.")
					else
						console.error("Form.renderTable", "field.form.label in horizontal tables is deprectated.")

				has_left = true

			if use_field_as_label
				tds.push($td(td_classes[0], colspan: 2).append(append_left))
			else
				td2 = $td(td_classes[1])

				if @_horizontal and CUI.__ng__
					td1 = $th(td_classes[0])
					td1.addClass("cui-form-th")
					if fopts.th_rotate_90
						td1.addClass("cui-form-rotate-90")
						td2.addClass("cui-form-rotate-90")
				else
					td1 = $td(td_classes[0])

				tds.push(td1.append(append_left))
				tds.push(td2.append(append_content))

			if @__horizontal
				tr_labels.append(tds[0])
				tr_fields.append(tds[1])
				# tr_rights.append(tds[2])
			else
				tr = $tr("cui-form-tr cui-form-tr-vertical").appendTo(@table)
				# mark this row special, if our content includes another vertical form
				if getObjectClass(_field) == "Form" and _field instanceof CUI.Form
					if not _field.getOpt("horizontal") or not has_left
						tr.addClass("cui-form-tr-content-is-form-vertical")

				# used to set row visibility
				DOM.data(tr[0], "data-field", _field)

				tr.append(tds)

		if has_left
			@table.addClass("cui-form-table-has-left-column")
		else
			@table.addClass("cui-form-table-has-not-left-column")

		Events.listen
			type: "data-changed"
			node: @table
			call: (ev, info) =>
				if not info.element
					return

				# CUI.debug "Form data-changed", @getData()

				if info.action in ["goto", "reset"]
					return

				@__undo.log[++@__undo.idx] =
					name: info.element.getName()
					undo_idx: info.undo_idx
					action: info.action

				@__undo.log.splice(@__undo.idx+1)
				return

		@getLayout().replace(@table, "center")
		CUI.DOM.setAttribute(@table, "cui-form-depth", CUI.DOM.getAttribute(@DOM, "cui-form-depth"))
		@table


	__initUndo: ->
		if @__undo
			return

		@__undo =
			log: []
			idx: -1


	getLog: ->
		log = []
		for l in @__undo.log
			log.push("#{l.name} #{l.action} #{l.undo_idx}")
		log.join("\n")

	undo: ->
		if @__undo.idx == -1
			return false

		if @__undo.idx == 0
			# we dont exactly know which
			# field we need to tell to
			for df in @getFields()
				df.goto(@__undo.idx--)
			return true

		l = @__undo.log[--@__undo.idx]
		# CUI.debug ""+@getRootForm(), l.name, @getRootForm().getFieldsByName(l.name)
		for f in @getRootForm().getFieldsByName(l.name)
			f.goto(l.undo_idx)
		return true

	redo: ->
		if @__undo.idx == @__undo.log.length - 1
			return false

		l = @__undo.log[++@__undo.idx]
		for f in @getRootForm().getFieldsByName(l.name)
			f.goto(l.undo_idx)
		return true

	getFieldByIdx: (idx) ->
		assert(isInteger(idx) and idx >= 0, "#{@__cls}.getFieldByIdx", "idx must be Integer.", idx: idx)
		@getFields("getFieldByIdx")[idx]

	getFieldsByName: (name, found_fields = []) ->
		assert(isString(name), "#{@__cls}.getFieldsByName", "name must be String.", name: name)

		# CUI.debug @dataFields, @, typeof(@getFields)

		for _field in @getFields("getFieldsByName")
			if _field instanceof Form
				_field.getFieldsByName(name, found_fields)
				continue

			# CUI.debug _field, getObjectClass(_field), name, _field.getName
			if _field.getName() == name
				found_fields.push(_field)
				continue

		# if found_fields.length == 0
		#	CUI.warn("#{@__cls}.getFieldsByName: No field found matching \"#{name}\".")

		return found_fields

	getFields: (func) ->
		# CUI.debug "form get fields", @__fields
		@__fields

	isDataField: ->
		if @_name
			return true
		else
			return false

	hasData: ->
		false

	getValue: ->
		# CUI.debug "getValue FORM", @_name, @__data
		if not @_name
			data = {}
			for field in @getDataFields()
				if k = field.getName()
					data[k] = field.getValue()
			return data
		else
			# CUI.debug "getValue HENK", @_name, @__data
			data = copyObject(@__data, true)
			delete(data._undo)
			return data

	isChanged: ->
		for _field in @getFields()
			if _field.isChanged()
				return true
		return false

	destroy: ->
		if @table
			DOM.remove(@table)
			@table = null
		super()


CUI.Events.registerEvent
	type: "form-check-row-visibility"
	bubble: true

Form = CUI.Form