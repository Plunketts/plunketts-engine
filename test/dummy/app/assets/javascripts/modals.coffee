

## Actions

$(document).on 'click', 'a.modal-with-actions', ->
	tinyModal.showDirect(
		"<h1 class='text-center'>Modal With Actions!</h1>"
		title: 'Modal'
		title_icon: 'gear-a'
		actions: [
			{
				title: 'Submit'
				icon: 'checkmark-round'
				class: 'primary'
				attrs: {data: {id: '123'}}
			}
			{
				title: 'Delete'
				icon: 'close-round'
				class: 'alert'
				end: true
			}
		]
	)


## Reload

$(document).on 'click', 'a.modal-reload', ->
	tinyModal.showDirect(
		"<h1 class='text-center modal-reload'>The page will reload when you close this modal!</h1>"
		title: 'Modal'
		title_icon: 'gear-a'
	)


## No Layout

_noLayoutTemplate = tinyTemplate ->
	div '.no-layout', ->
		p '', 'This modal renders its own layout'
		a '.close-modal', 'Close'

$(document).on 'click', 'a.no-layout-modal', ->
	tinyModal.showDirect(
		_noLayoutTemplate()
		title: 'Modal'
		title_icon: 'gear-a'
		layout: false
	)


## Stacked

_stackTemplate = tinyTemplate (depth) ->
	div ".stack-#{depth}.text-center", ->
		h1 '', "Stack #{depth}"
		a '.stacked-modal', data: {depth: depth+1}, 'Push Stack'


$(document).on 'click', 'a.stacked-modal', ->
	depth = parseInt ($(this).data('depth') || '1')
	tinyModal.showDirect(
		_stackTemplate(depth)
		title: 'Stacked Modal'
		title_icon: 'navicon-round'
		actions: [
			{
				title: 'Push Stack'
				icon: 'chevron-right'
				class: 'stacked-modal'
				attrs: {data: {depth: depth+1}}
			}
			{
				title: 'Pop Stack'
				icon: 'chevron-left'
				class: 'close-modal'
				end: true
			}
		]
	)