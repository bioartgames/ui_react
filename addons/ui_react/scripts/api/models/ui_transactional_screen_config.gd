@tool
## Editor data for [UiReactTransactionalSession]: when to call [method UiTransactionalGroup.begin_edit_all] for a transactional screen (first host enters the tree).
## Share one instance between Apply and Cancel buttons: assign the same subresource to [member UiReactTransactionalHostBinding.screen] on each [UiReactButton] / [UiReactTextureButton].
class_name UiTransactionalScreenConfig
extends Resource

## When **true** (default), the first registration for a [code](tree, group)[/code] cohort runs [method UiTransactionalGroup.begin_edit_all] once (deferred to the next frame).
@export var begin_on_ready: bool = true
