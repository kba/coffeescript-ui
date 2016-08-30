class FileUploadButton extends Button
	constructor: (@opts={}) ->
		super(@opts)
		if @_drop
			@_fileUpload.initDropZone(dropZone: @DOM)


	initOpts: ->
		super()
		@addOpts
			fileUpload:
				mandatory: true
				check: FileUpload
			multiple:
				default: true
				check: Boolean
			directory:
				check: Boolean
			# whether to allow file drop on the button
			drop:
				check: Boolean

	getTemplateName: ->
		@__has_left = true
		@__has_right = true
		return "file-upload-button"

	readOpts: ->
		@__ownClick = @opts.onClick
		@opts.onClick = @__onClick
		super()

	__onClick: (ev, btn) =>

		@__ownClick?.call(@, ev, btn)

		if ev.isDefaultPrevented() or ev.isImmediatePropagationStopped()
			return

		uploadBtn = document.getElementById("cui-file-upload-button")
		uploadBtn.form.reset()

		@_fileUpload.initFilePicker
			directory: (ev.altKey() or ev.shiftKey() and @_multiple) or @_directory
			multiple: @_multiple
			fileUpload: uploadBtn

		return

