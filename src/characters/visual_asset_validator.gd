class_name AethelVisualAssetValidator
extends RefCounted
## Inspector-authored scenes only. No import/download or inventory ownership.
static func inspect(model: Node3D, definition: AethelCharacterVisualDefinition) -> Dictionary:
	var errors: Array[String]=[]
	var materials: Dictionary={}
	var triangles := 0
	var bones := 0
	var skinned_meshes := 0
	var animations: Dictionary={}
	var bounds := AABB()
	var has_bounds := false
	var nodes: Array[Node]=[model]
	nodes.append_array(model.find_children("*","",true,false))
	for node: Node in nodes:
		if node is CollisionObject3D or node is CollisionShape3D or node is NavigationAgent3D:
			errors.append("Gameplay/physics node in visual: "+str(node.name))
		if node is Camera3D or node is Light3D: errors.append("Scene lighting/camera in visual: "+str(node.name))
		if node is Node3D:
			var s: Vector3=node.scale
			if not s.is_finite() or not s.is_equal_approx(Vector3.ONE): errors.append("Apply scale before export: "+str(node.name))
		if node is Skeleton3D:
			bones+=node.get_bone_count()
			for bone in node.get_bone_count():
				var parent: int=node.get_bone_parent(bone)
				if parent>=bone: errors.append("Invalid bone hierarchy: "+node.get_bone_name(bone))
				if not node.get_bone_rest(bone).basis.get_scale().is_equal_approx(Vector3.ONE): errors.append("Apply bone rest scale: "+node.get_bone_name(bone))
		if node is MeshInstance3D and node.mesh!=null:
			if node.skin!=null: skinned_meshes+=1
			var transform:=Transform3D.IDENTITY
			var cursor: Node3D=node
			while cursor!=model and cursor!=null:
				transform=cursor.transform*transform
				cursor=cursor.get_parent() as Node3D
			var mesh_bounds: AABB=transform*node.mesh.get_aabb()
			bounds=bounds.merge(mesh_bounds) if has_bounds else mesh_bounds
			has_bounds=true
			for surface in node.mesh.get_surface_count():
				if node.mesh.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES:
					errors.append("Only triangles accepted: "+str(node.name));continue
				var arrays: Array=node.mesh.surface_get_arrays(surface)
				var indices: Variant=arrays[Mesh.ARRAY_INDEX]
				triangles+=int(indices.size()/3) if indices!=null and indices.size()>0 else int(arrays[Mesh.ARRAY_VERTEX].size()/3)
				var weights: Variant=arrays[Mesh.ARRAY_WEIGHTS]
				if weights!=null and weights.size()>0:
					var per_vertex: int=weights.size()/maxi(1,arrays[Mesh.ARRAY_VERTEX].size())
					for offset in range(0,weights.size(),per_vertex):
						var influences:=0
						for i in per_vertex:
							if weights[offset+i]>0.0001: influences+=1
						if influences>definition.max_influences: errors.append("Skin influence budget: "+str(node.name));break
				var material: Material=node.material_override if node.material_override!=null else node.get_active_material(surface)
				if material!=null:
					materials[material.get_instance_id()]=true
					if material is BaseMaterial3D:
						for slot in BaseMaterial3D.TEXTURE_MAX:
							var texture: Texture2D=material.get_texture(slot)
							if texture!=null and maxi(texture.get_width(),texture.get_height())>definition.max_texture_size: errors.append("Texture budget exceeded: "+str(node.name))
		if node is AnimationPlayer:
			for id: StringName in node.get_animation_list():
				var animation: Animation=node.get_animation(id)
				animations[str(id)]={"duration":animation.length,"loop":animation.loop_mode!=Animation.LOOP_NONE}
				for track in animation.get_track_count():
					var track_path: NodePath=animation.track_get_path(track)
					if track_path.is_empty():
						errors.append("Empty animation target: "+str(id));continue
					var animation_root: Node=node.get_node_or_null(node.root_node)
					var target: Node=animation_root.get_node_or_null(NodePath(track_path.get_concatenated_names())) if animation_root!=null else null
					if target==null or (target!=model and not model.is_ancestor_of(target)): errors.append("Animation target outside model: "+str(id))
					if animation.track_get_type(track) not in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D,Animation.TYPE_BLEND_SHAPE]: errors.append("Non-transform animation track rejected: "+str(id))
					# Root motion is not part of this contract. Root bones may rotate, never translate.
					if animation.track_get_type(track)==Animation.TYPE_POSITION_3D and str(animation.track_get_path(track)).get_slice(":",1).to_lower() in ["root","hips"]: errors.append("Root motion rejected: "+str(id))
					if animation.track_get_type(track)==Animation.TYPE_POSITION_3D and target is Skeleton3D and track_path.get_subname_count()>0:
						var bone_id: int=target.find_bone(track_path.get_subname(0))
						if bone_id>=0 and target.get_bone_parent(bone_id)<0: errors.append("Root bone translation rejected: "+str(id))
	if not model.transform.is_equal_approx(Transform3D.IDENTITY): errors.append("Model root transform must be identity")
	if not has_bounds or bounds.size.y<definition.min_height or bounds.size.y>definition.max_height or maxf(bounds.size.x,bounds.size.z)>definition.max_width: errors.append("Model dimensions outside proposed integration envelope")
	if has_bounds and absf(bounds.position.y)>0.08: errors.append("Feet must rest at Y=0")
	if bones==0 or bones>definition.max_deforming_bones: errors.append("Missing rig or bone budget exceeded")
	if skinned_meshes==0: errors.append("No skinned meshes")
	if triangles>definition.max_triangles: errors.append("Triangle budget exceeded")
	if materials.size()>definition.max_materials: errors.append("Material budget exceeded")
	for id: String in definition.required_animations:
		if not animations.has(id): errors.append("Missing animation: "+id)
	for id: String in definition.socket_names:
		var socket: Node=model.find_child(id,true,false)
		if not socket is Node3D: errors.append("Missing socket: "+id)
		elif id in ["SocketMain","SocketOffhand"]:
			if not socket is BoneAttachment3D or not socket.get_parent() is Skeleton3D:
				errors.append("Hand socket must be a bone attachment: "+id)
			elif socket.get_parent().find_bone(socket.bone_name)<0: errors.append("Socket bone missing: "+id)
	var forward: Node3D=model.find_child("Forward",true,false) as Node3D
	if forward==null or not forward.position.is_equal_approx(Vector3.FORWARD): errors.append("Forward marker must indicate local -Z")
	if definition.provenance_status=="PENDING" or not FileAccess.file_exists(definition.provenance_path): errors.append("Provenance documentation pending")
	return {"valid":errors.is_empty(),"errors":errors,"triangles":triangles,"bones":bones,"materials":materials.size(),"height":bounds.size.y,"width":bounds.size.x,"depth":bounds.size.z,"animations":animations,"budget_includes":"all mesh surfaces, including hidden equipment variants; conservative"}
