###
 * coffeescript-ui - Coffeescript User Interface System (CUI)
 * Copyright (c) 2013 - 2016 Programmfabrik GmbH
 * MIT Licence
 * https://github.com/programmfabrik/coffeescript-ui, http://www.coffeescript-ui.org
###

class FormDemo extends Demo
	display: ->

		multi_input_control = new MultiInputControl
			user_control: true
			preferred_key: "de-DE"
			keys: [
				name: "de-DE"
				tag: "DE"
				enabled: true
			,
				name: "en-US"
				tag: "EN"
			,
				name: "fr-FR"
				tag: "FR"
			]

		@tmpl = t = new Template
			name: "form-demo"
			map:
				form: true
				data: true
				data_button: true

		data =
			simple_input: "Huhu"
			number_input: 12.34
			multiline_input: "This is a multiline input..."
			cb_without: true
			horst: "henk"
			output: "This is simple Output Only."
			its_time_date: "2009-09-19T12:37:27Z"
			multi_output:
				"de-DE": "Deutsch"
				"en-US": "English"
				"fr-FR": "Francais"

			group: [2,3]
			radio2: "B"
			email:
				pop_input: "pop input email"
				pop_cb: true
			data_table: []
			radio: [ "Eriwan" ]
			select: "Republik"

		for i in [0..100]
			data.data_table.push
				HeaderColumnA: "value #{i}"
				HeaderColumnRotated90: Math.random()>0.5

		actionButton = (df) ->

			menu_action_button = new Button
				text: df.getName() or df.__cls
				menu:
					items: [
						text: "hide"
						onClick: (ev, btn) ->
							df.hide()
							CUI.setTimeout ->
								df.show()
							,
								2000
					,
						text: "show"
						onClick: (ev, btn) ->
							df.show()
					,
						text: "disable"
						onClick: (ev, btn) ->
							df.disable()
					,
						text: "enable"
						onClick: (ev, btn) ->
							df.enable()
					,
						text: "getValue"
						onClick: (ev, btn) ->
							alert_dump(df.getValue())
					,
						text: "getInitValue"
						onClick: (ev, btn) ->
							alert_dump(df.getInitValue())
					,
						text: "getLastValue"
						onClick: (ev, btn) ->
							alert_dump(df.getLastValue())
					,
						text: "getValueForCheckChanged"
						onClick: (ev, btn) ->
							alert_dump(df.getValueForCheckChanged())
					,
						text: "reset"
						onClick: (ev, btn) ->
							df.reset()
					,
						text: "undo"
						onClick: (ev, btn) ->
							ret = df.undo()
							if ret == false
								alert("no more")
					,
						text: "redo"
						onClick: (ev, btn) ->
							ret = df.redo()
							if ret == false
								alert("no more")
					,
						text: "reload"
						onClick: (ev, btn) ->
							df.reload()
							alert("done reload:"+form)
					,
						text: "remove"
						onClick: (ev, btn) ->
							df.remove()
							alert("done remove:"+form)
					,
						text: "start"
						onClick: (ev, btn) ->
							df.start()
							alert("done start:"+form)
					,
						text: "render"
						onClick: (ev, btn) ->
							df.render()
							alert("done render:"+form)
					,
						text: "displayValue"
						onClick: (ev, btn) ->
							df.displayValue()
					,
						text: "isChanged"
						onClick: (ev, btn) ->
							alert(df.isChanged())
					,
						text: "getForm"
						onClick: (ev, btn) ->
							alert(df.getForm())
					,
						text: "getRootForm"
						onClick: (ev, btn) ->
							alert(df.getRootForm())
					,
						text: "focus"
						onClick: (ev, btn) ->
							if not df.focus
								alert(df+" has no method .focus")
							else
								df.focus()
					,
						text: "setValue"
						menu_on_hover: true
						menu:
							placement: "es"
							items: [
								text: "true"
								onClick: (ev, btn) ->
									setValue.call(df, true)
							,
								text: "false"
								onClick: (ev, btn) ->
									setValue.call(df, false)
							,
								text: "null"
								onClick: (ev, btn) ->
									setValue.call(df, null)
							,
								text: "\"Henk\""
								onClick: (ev, btn) ->
									setValue.call(df, "Henk")
							]
					]
			menu_action_button

		setValue = (v) ->
			try
				@setValue(v, no_store: true)
			catch err
				alert(err)

		form = new Form
			#REMARKED form should make the design
			# class_table: "demo-table"
			onDataChanged: (data, field) =>
				@log("onDataChanged", field.getName(), field.getLastValue(), field.getValue())
				show_data()
			data: data
			fields: [
				form:
					label: "Simple Input"
					right: actionButton
				placeholder: "INPUT"
				type: Input
				name: "simple_input"
			,
				form:
					label: "Number Input"
					right: actionButton
				placeholder: "INPUT"
				type: NumberInput
				decimalpoint: ","
				symbol: "€"
				separator: "."
				decimals: 2
				name: "number_input"
			,
				form:
					label: "DateTime"
					right: actionButton
				type: DateTime
				name: "its_time"
			,
				form:
					label: "DateTime (Date only)"
					right: actionButton
				type: DateTime
				input_types: ["date"]
				name: "its_time_date"
			,
				type: Form
				form:
					label: "Password Input"
					right: actionButton
				fields: [
					type: Password
					placeholder: "PASSWORD"
					name: "password"
					form:
						right: actionButton
				,
					type: Checkbox
					text: "Show Password"
					name: "show_password"
					tooltip:
						text: "Reveal Password"
					mark_changed: false
					onActivate: (cb) ->
						@log("btn", cb, cb.getForm().getFieldByIdx(0).showPassword())
					onDeactivate: (cb) ->
						@log("btn de", cb, cb.getForm().getFieldByIdx(0).hidePassword())
				]
			,
				form:
					label: "Without"
					right: actionButton
				name: "cb_without"
				onDataChanged: =>
					@log("without onDataChanged called")
				# value: horst: "henk"
				type: Checkbox
			,
				form:
					label: "Single"
					right: actionButton
				name: "cb_single"
				type: Checkbox
				text: "Single"
			,
				form:
					label: "Radio"
					right: actionButton
				type: Options
				name: "radio"
				min_checked: 0
				radio: "tunein"
				options: [
					text: "Moscow"
				,
					text: "Eriwan"
				,
					text: "BBC"
				]
			,
				form:
					label: "Radio (continued)"
					right: actionButton
				type: Options
				name: "radio"
				min_checked: 0
				radio: "tunein"
				options: [
					text: "104.6RTL"
				,
					text: "94.3RS2"
				,
					text: "Fritz"
				]
			,
				form:
					label: "Radio2"
					right: actionButton
				type: Options
				name: "radio2"
				radio: true
				options: [
					text: "A"
				,
					text: "B"
				,
					text: "C"
				,
					text: "D"
				,
					text: "E"
				]
			,
				form:
					label: "Multi Single Line Input"
					right: actionButton
				type: MultiInput
				name: "multi_single_line_input"
				placeholder:
					"de-DE": "INPUT de"
					"en-US": "INPUT en"
					"fr-FR": "INPUT fr"
				control: multi_input_control
			,
				type: Options
				form:
					label: "Empty Group"
					right: actionButton
				name: "empty_group"
				placeholder: "No Options."
				options: []
			,
				type: Options
				form:
					label: "Minimal Group"
					right: actionButton
				name: "minimal_group"
				options: [
					value: "one_cb"
					text: "One Checkbox Only"
				]
			,
				type: Options
				form:
					label: "Sortable Group"
					right: actionButton
				name: "sortable_group"
				sortable: true
				options: [
					value: 1
					text: "One"
				,
					value: 2
					text: "Two"
				,
					value: 3
					text: "Three"
				,
					value: 4
					text: "Four"
				]
			,
				type: Options
				form:
					label: "Group (minimum 1)"
					right: actionButton
				min_checked: 1
				name: "group"
				options: [
					value: 1
					text: "A1"
				,
					value: 2
					text: "B1"
				,
					value: 3
					text: "C1"
				,
					value: 4
					text: "D1"
				,
					value: 5
					text: "E1"
				,
					value: 6
					disabled: true
					text: "E2"
				]
				horizontal: 5
			,
				type: Input
				form:
					label: "Multiline Input"
					right: actionButton
				name: "multiline_input"
				placeholder: "TEXTAREA<&>'\""
				textarea: true
			,
				type: MultiInput
				form:
					label: "Multi Multi Line Input"
					right: actionButton
				name: "multi_multi_line_input"
				textarea: true
				placeholder:
					"de-DE": "TEXTAREA de"
					"en-US": "TEXTAREA en"
					"fr-FR": "TEXTAREA fr"
				control: multi_input_control
			,
				type: Form
				fields: [
					type: Checkbox
					form:
						label: "With Data Field"
						right: actionButton
					name: "cb_with_form"
					text: "Click here"
				,
					type: Form
					fields: [
						type: Input
						name: "horst"
					]
				]
			,
				form:
					label: "Popover Form (Function)"
					right: actionButton
				type: FormPopover
				name: "email"
				button:
					icon: new Icon(icon: "email")
					text: "henk"
				popover:
					pane:
						header_left: "Form Popover"
				renderDisplayContent: (df) ->
					data = df.getData()
					new Label( text: toHtml(data.pop_input+" ["+data.pop_cb+"]") )
				fields: (form) ->
					if not form.getData()
						return []
					[
						form:
							label: "Date"
						type: DateTime
					,
						form:
							label: "Input"
						type: Input
						name: "pop_input"
					,
						form:
							label: "Checkbox"
						type: Checkbox
						name: "pop_cb"
					]
			,
				form:
					label: "Popover Form (Array)"
					right: actionButton
				button:
					icon: new Icon(icon: "email")
					text: "button text"
				type: FormPopover

				popover: {}
				fields: [
					form:
						label: "Date"
					type: Output
					text: ""+(new Date()).toUTCString()
				,
					form:
						label: "DataTable"
						right: actionButton
					type: DataTable
					rowMove: true
					name: "data_table_pop"
					fields: [
						form:
							label: "Horst"
						type: Input
						name: "horst"
					,
						form:
							rotate_90: true
						type: Checkbox
						name: "Vertical Label"
					,
						form:
							rotate_90: true
						type: NumberInput
						name: "int"
					]
				]
			,
				form:
					label: "Modal Form (Function)"
					right: actionButton
				type: FormModal
				name: "modal"
				button:
					icon: new Icon(icon: "email")
					text: "henk"
				modal:
					cancel: true
					pane:
						header_left: "Form Modal"
					apply_button:
						text: "Yo - Custom Text"

				renderDisplayContent: (df) ->
					data = df.getData()
					new Label( text:toHtml(data.pop_input+" ["+data.pop_cb+"]") )
				fields: (form) ->
					if not form.getData()
						return []
					[
						form:
							label: "Date"
						type: DateTime
					,
						form:
							label: "Input"
						type: Input
						name: "pop_input"
					,
						form:
							label: "Checkbox"
						type: Checkbox
						name: "pop_cb"
					]
			,
				form:
					label: "FormButton"
					right: actionButton
				type: FormButton
				onClick: (data, element) ->
					alert "you clicked the form button"
				icon: new Icon(class: "fa-trash-o")
			,
				form:
					label: "Output"
					right: actionButton

				type: Output
				name: "output"
			,
				form:
					label: "MultiOutput"
					right: actionButton

				type: MultiOutput
				control: multi_input_control
				name: "multi_output"
			,
				form:
					label: "Select"
					right: actionButton

				type: Select
				empty_text: "- Pick an Option -"
				name: "select"
				options: -> [
					text: "Banana"
				,
					text: "Republic"
					value: "Republik"
				,
					divider: true
				,
					text: "Really?"
				,
					text: ""+(new Date()).toUTCString()
					disabled: true
				]
			,
				form:
					label: "DataTable"
					right: actionButton
				type: DataTable
				rowMove: true
				name: "data_table"
				fields: [
					form:
						label: "HeaderColumnA Label"
					type: Input
					name: "HeaderColumnA"
				,
					form:
						rotate_90: true

					type: Checkbox
					name: "HeaderColumnRotated90"
				]
			]


		options = [
			value: "_all"
			text: "- all -"
		]

		for f in form.getDataFields()
			options.push
				value: f.getName()
				text: f.getName()+" ["+f.__cls+"]"

		show_data_filter =
			field: "_all"
			reveal_all: false

		data_form = new Form
			data: show_data_filter
			onDataChanged: ->
				show_data()
			fields: [
				type: Select
				form:
					label: "Field"
				mark_changed: false
				name: "field"
				options: options
			,
				type: Checkbox
				form:
					label: "Reveal All"
				mark_changed: false
				name: "reveal_all"
			]

		t.replace(data_form, "data_button")
		data_form.start()

		show_data = ->
			v = show_data_filter.field
			ra = show_data_filter.reveal_all
			if ra
				_d = form.getData()
			else
				_d = form.getValue()

			if v == "_all"
				d = _d
			else
				d = {}
				d[v] = _d[v]
				if ra
					d._undo = {}
					d._undo[v] = _d._undo[v]

			t.replace(dump(d), "data")



		show_data()

		CUI.debug "FORM created", ""+form

		btn = actionButton(form)
		t.replace(btn, "form")
		t.append(form, "form")
		form.start()

		form2 = new Form
			# horizontal: true
			fields: [
				form:
					use_field_as_label: true
				type: Output
				text: "Label with Colspan"
			,
				form:
					label: "B"
				type: Input
			,
				form:
					label: "C"
				type: Input
				textarea: true
			]
		.start()
		t.append(form2, "form")

		Events.listen
			node: @tmpl
			type: "data-changed"
			call: (ev, info) =>
				CUI.debug ev.getType(), info

		t

	log: ->
		s = []
		for a in arguments
			if isString(a)
				s.push("\"#{a}\"")
			else
				s.push(JSON.stringify(a))
		#@tmpl.append($pre().text(s.join(" ")), "log")

		super(s.join(" "))

		#@tmpl


	undisplay: ->


Demo.register(new FormDemo())