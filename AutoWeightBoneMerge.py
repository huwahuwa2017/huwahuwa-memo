# Ver7 2023/08/13 12:53

import bpy

selected_armatures = [obj for obj in bpy.context.selected_objects if obj.type == 'ARMATURE']

for armature in selected_armatures:
    remove_bones = []
    selected_meshes = [obj for obj in armature.children if obj.type == 'MESH']
    
    for mesh in selected_meshes:
        bpy.ops.object.mode_set(mode='OBJECT')
        vertex_groups = mesh.vertex_groups
        bpy.context.view_layer.objects.active = armature
        bpy.ops.object.mode_set(mode='EDIT')
        
        for bone in armature.data.edit_bones:
            if bone.name.split('.')[0] == 'AutoWeight':
                remove_bones.append(bone)
                src = vertex_groups.get(bone.name)
                
                if src:
                    flag_0 = True
                    parent_bone = bone
                    target_bone = None
                    
                    while(flag_0):
                        parent_bone = parent_bone.parent
                        
                        if parent_bone:
                            if parent_bone.name.split('.')[0] != 'AutoWeight':
                                target_bone = parent_bone
                                flag_0 = False
                        else:
                            flag_0 = False
                    
                    if target_bone:
                        target_bone.use_deform = True
                        dst = vertex_groups.get(target_bone.name)
                        
                        if dst == None:
                            dst = vertex_groups.new(name = target_bone.name)
                        
                        for vertex in mesh.data.vertices:
                            try:
                                dst_weight = dst.weight(vertex.index)
                            except RuntimeError:
                                dst_weight = 0.0
                            
                            try:
                                src_weight = src.weight(vertex.index)
                                dst.add([vertex.index], dst_weight + src_weight, 'REPLACE')
                            except RuntimeError:
                                temp = 0
                    
                    vertex_groups.remove(src)
    
    for bone in armature.data.edit_bones:
        if bone.name.split('.')[0] == 'AutoWeight':
            armature.data.edit_bones.remove(bone)

bpy.ops.object.mode_set(mode='OBJECT')
