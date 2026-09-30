"""Run with Blender --background --python tools/convert_snack_pack.py."""
import bpy, json
from pathlib import Path
SOURCE = Path('/Users/iyeseul/Downloads/Blender')
OUTPUT = Path('/Users/iyeseul/Documents/yeaseul/ddong_puppy/assets/imported/snack_pack')
report=[]
for source in sorted(SOURCE.glob('*.blend')):
    bpy.ops.wm.open_mainfile(filepath=str(source), load_ui=False)
    used_images=[]
    for mat in bpy.data.materials:
        if not mat.use_nodes: continue
        nodes=mat.node_tree.nodes
        diffuse=next((n for n in nodes if n.type=='BSDF_DIFFUSE'),None)
        glass=next((n for n in nodes if n.type=='BSDF_GLASS'),None)
        old=diffuse or glass
        if not old: continue
        color=tuple(old.inputs['Color'].default_value)
        color_source=old.inputs['Color'].links[0].from_socket if old.inputs['Color'].is_linked else None
        shader=nodes.new('ShaderNodeBsdfPrincipled')
        shader.inputs['Base Color'].default_value=color
        shader.inputs['Roughness'].default_value=0.65 if not glass else 0.12
        if color_source:
            mat.node_tree.links.new(color_source,shader.inputs['Base Color'])
        if glass:
            shader.inputs['Transmission Weight'].default_value=0.9
            shader.inputs['IOR'].default_value=1.45
            shader.inputs['Alpha'].default_value=0.28
            mat.surface_render_method='DITHERED'
        output=next(n for n in nodes if n.type=='OUTPUT_MATERIAL')
        mat.node_tree.links.new(shader.outputs['BSDF'],output.inputs['Surface'])
        nodes.remove(old)
        for n in nodes:
            if n.type=='TEX_IMAGE' and n.image:
                image=n.image
                candidate=SOURCE/'Textures'/Path(image.filepath.replace('\\','/')).name
                if candidate.exists():
                    image=bpy.data.images.load(str(candidate), check_existing=False)
                    n.image=image
                _ = image.pixels[0] if len(image.pixels) else None
                if not image.has_data: raise RuntimeError(f'Missing texture: {source.name}: {image.name}')
                image.colorspace_settings.name='sRGB'
                image.pack()
                used_images.append(image.name)
    if bpy.context.object and bpy.context.object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    for obj in bpy.context.scene.objects: obj.select_set(False)
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    for obj in meshes:
        obj.hide_set(False)
        obj.hide_viewport=False
        obj.select_set(True)
    destination=OUTPUT/(source.stem+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(destination),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False)
    report.append(dict(file=destination.name,meshes=len(meshes),polygons=sum(len(o.data.polygons) for o in meshes),textures=sorted(set(used_images)),bytes=destination.stat().st_size))
(OUTPUT/'conversion_report.json').write_text(json.dumps(report,indent=2))
print('CONVERTED',len(report))
