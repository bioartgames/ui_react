## Scene-wide checks for [UiTransactionalGroup] cohorts: coordinator vs mini-host conflict, duplicate roles, pairing warnings.
class_name UiReactTransactionalValidator
extends RefCounted


static func validate_transactional_under_root(root: Node) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if root == null:
		return out
	var cohorts: Dictionary = {}
	_walk_collect(root, root, cohorts)
	_append_pressed_state_warnings(root, root, out)
	for gid in cohorts.keys():
		var bucket: Dictionary = cohorts[gid]
		var coord: Array = bucket.get("coordinators", []) as Array
		var apply_paths: Array = bucket.get("apply", []) as Array
		var cancel_paths: Array = bucket.get("cancel", []) as Array
		if coord.size() > 0 and (apply_paths.size() > 0 or cancel_paths.size() > 0):
			var p: NodePath = coord[0] as NodePath
			var nn: Node = root.get_node_or_null(p)
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.ERROR,
					"UiReactTransactionalActions",
					str(nn.name) if nn else "",
					"UiTransactionalGroup cohort: remove UiReactTransactionalActions or clear transactional_host.role on UiReactButton/UiReactTextureButton (same group).",
					"Use either path-based coordinator or button-hosted transactional_host—not both for one group.",
					p,
					&"transactional_host",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
		if apply_paths.size() > 1:
			for i in range(1, apply_paths.size()):
				var extra: NodePath = apply_paths[i] as NodePath
				var n2: Node = root.get_node_or_null(extra)
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.ERROR,
						"UiReactButton",
						str(n2.name) if n2 else "",
						"Duplicate APPLY_ALL for the same UiTransactionalGroup.",
						"Keep a single Apply button with transactional_host.role APPLY_ALL per group.",
						extra,
						&"transactional_host",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
		if cancel_paths.size() > 1:
			for i in range(1, cancel_paths.size()):
				var extra2: NodePath = cancel_paths[i] as NodePath
				var n3: Node = root.get_node_or_null(extra2)
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.ERROR,
						"UiReactTextureButton",
						str(n3.name) if n3 else "",
						"Duplicate CANCEL_ALL for the same UiTransactionalGroup.",
						"Keep a single Cancel button with transactional_host.role CANCEL_ALL per group.",
						extra2,
						&"transactional_host",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
		if apply_paths.size() == 1 and cancel_paths.size() == 0:
			var ap: NodePath = apply_paths[0] as NodePath
			var na: Node = root.get_node_or_null(ap)
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					"UiReactTransactionalSession",
					str(na.name) if na else "",
					"UiTransactionalGroup has APPLY_ALL but no CANCEL_ALL in this scene.",
					"Add a Cancel button with transactional_host.role CANCEL_ALL or use a coordinator with both paths.",
					ap,
					&"transactional_host",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
		if cancel_paths.size() == 1 and apply_paths.size() == 0:
			var cp: NodePath = cancel_paths[0] as NodePath
			var nc: Node = root.get_node_or_null(cp)
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					"UiReactTransactionalSession",
					str(nc.name) if nc else "",
					"UiTransactionalGroup has CANCEL_ALL but no APPLY_ALL in this scene.",
					"Add an Apply button with transactional_host.role APPLY_ALL or use a coordinator with both paths.",
					cp,
					&"transactional_host",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
	return out


static func _append_pressed_state_warnings(n: Node, root: Node, out: Array[UiReactDiagnosticModel.DiagnosticIssue]) -> void:
	if n is UiReactButton or n is UiReactTextureButton:
		var ps: Variant = n.get(&"pressed_state")
		var th: Variant = n.get(&"transactional_host")
		var host_ok: bool = false
		if th is UiReactTransactionalHostBinding:
			var hb: UiReactTransactionalHostBinding = th as UiReactTransactionalHostBinding
			host_ok = hb.group is UiTransactionalGroup and int(hb.role) != 0
		if ps != null and host_ok:
			var rel: NodePath = root.get_path_to(n)
			var comp := "UiReactButton" if n is UiReactButton else "UiReactTextureButton"
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					comp,
					str(n.name),
					"pressed_state and transactional_host (Apply/Cancel) are both set; both react to presses.",
					"Clear pressed_state for pure Apply/Cancel or use a plain Button.",
					rel,
					&"pressed_state",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
	for c in n.get_children():
		_append_pressed_state_warnings(c, root, out)


static func _walk_collect(n: Node, root: Node, cohorts: Dictionary) -> void:
	if n is UiReactButton or n is UiReactTextureButton:
		var th: Variant = n.get(&"transactional_host")
		if th is UiReactTransactionalHostBinding:
			var hb: UiReactTransactionalHostBinding = th as UiReactTransactionalHostBinding
			var g: Variant = hb.group
			var r := int(hb.role)
			if g is UiTransactionalGroup and r != 0:
				var gid: int = (g as UiTransactionalGroup).get_instance_id()
				_ensure_bucket(cohorts, gid)
				var rel: NodePath = root.get_path_to(n)
				if r == 1:
					(cohorts[gid] as Dictionary)["apply"].append(rel)
				elif r == 2:
					(cohorts[gid] as Dictionary)["cancel"].append(rel)
	elif n is UiReactTransactionalActions:
		var txn := n as UiReactTransactionalActions
		if txn.group != null:
			var gid2: int = txn.group.get_instance_id()
			_ensure_bucket(cohorts, gid2)
			(cohorts[gid2] as Dictionary)["coordinators"].append(root.get_path_to(n))
	for c in n.get_children():
		_walk_collect(c, root, cohorts)


static func _ensure_bucket(cohorts: Dictionary, gid: int) -> void:
	if cohorts.has(gid):
		return
	cohorts[gid] = {"coordinators": [], "apply": [], "cancel": []}
