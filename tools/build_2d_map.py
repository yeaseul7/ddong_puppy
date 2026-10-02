"""Build editable 2D scenes from baked sprites. Run explicitly; never on game start."""
from pathlib import Path
import re,json,random
root=Path(__file__).resolve().parents[1]
cat=json.loads((root/'assets/2d/catalog.json').read_text())
source=(root/'scripts/vertical_yard.gd').read_text()
rows=json.loads(re.search(r'const OBSTACLE_BASE := (\[.*?\n\])',source,re.S).group(1))
extras=[json.loads(re.search(r'const '+name+r' := (\[.*?\])',source).group(1)) for name in ['SHORTCUT','CATCH']]
# Standalone asset scenes can be dragged into the 2D editor with collisions included.
for name,data in cat.items():
 if data['path'].startswith('res://assets/2d/dog/'): continue
 w,h=data['width'],data['height']
 (root/f'scenes/2d/{name}.tscn').write_text(f'''[gd_scene load_steps=3 format=3]
[ext_resource type="Texture2D" path="{data['path']}" id="1"]
[sub_resource type="RectangleShape2D" id="shape"]
size = Vector2({w*0.84}, 16)
[node name="{name}" type="StaticBody2D"]
[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("1")
position = Vector2(0, {h/2})
[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("shape")
position = Vector2(0, 8)
''')
placements=[]
for i,(x,top,width,kind) in enumerate(rows+extras):
 variant=int(top/(7 if kind=='cushion' else 6 if kind=='jar' else 5))%3
 name=f'{kind}_{variant}'
 h=30 if kind=='cushion' else (top*100 if top<2 else 66) if kind=='jar' else (240 if top<3 else 120)
 placements.append(dict(name=name,x=x*100,y=-top*100,width=width*100,height=h,route=i<len(rows),kind=kind))
foods=sorted(k for k,v in cat.items() if '/food/' in v['path'])
random.Random(102).shuffle(foods)
x,top=float(rows[-1][0]),float(rows[-1][1]);direction=1
for i,name in enumerate(foods):
 t=i/(len(foods)-1);width=2.3-.9*t
 step=2.3+.5*t
 if abs(x+direction*step)>6.4: direction*=-1
 x+=direction*step; top+=1.8+.25*t
 data=cat[name];h=width*100*data['height']/data['width']
 placements.append(dict(name=name,x=x*100,y=-top*100,width=width*100,height=h,route=True,kind='food'))
parts=['[gd_scene format=3]', '[ext_resource type="Script" path="res://scripts/2d/map.gd" id="map"]','[ext_resource type="Script" path="res://scripts/2d/dog.gd" id="dog"]','[ext_resource type="Texture2D" path="res://assets/environment/map01_vertical_sunset.png" id="bg"]','[ext_resource type="Texture2D" path="res://assets/2d/jindo_cartoon/preview.tres" id="dog_image"]']
for i,p in enumerate(placements):
 parts += [f'[ext_resource type="Texture2D" path="{cat[p["name"]]["path"]}" id="texture{i}"]',f'[sub_resource type="RectangleShape2D" id="shape{i}"]\nsize = Vector2({p["width"]*0.84}, 16)']
parts+=['[sub_resource type="RectangleShape2D" id="ground"]\nsize = Vector2(4000, 1000)','[sub_resource type="CapsuleShape2D" id="dog_shape"]\nradius = 26.0\nheight = 80.0',f'[node name="Map01_2D" type="Node2D"]\nscript = ExtResource("map")\nsummit_height = {top*100}','[node name="Background" type="Sprite2D" parent="."]\nz_index = -100\nposition = Vector2(0,-1955)\nscale = Vector2(2.21,2.21)\ntexture = ExtResource("bg")','[node name="Platforms" type="Node2D" parent="."]']
for i,p in enumerate(placements):
 data=cat[p['name']];node=f'Platforms/{i:02d}_{p["name"]}'
 parts += [f'[node name="{i:02d}_{p["name"]}" type="StaticBody2D" parent="Platforms"]\nposition = Vector2({p["x"]}, {p["y"]})\nmetadata/route = {str(p["route"]).lower()}\nmetadata/kind = "{p["kind"]}"',f'[node name="Sprite2D" type="Sprite2D" parent="{node}"]\ntexture = ExtResource("texture{i}")\nposition = Vector2(0,{p["height"]/2})\nscale = Vector2({p["width"]/data["width"]},{p["height"]/data["height"]})',f'[node name="CollisionShape2D" type="CollisionShape2D" parent="{node}"]\nshape = SubResource("shape{i}")\nposition = Vector2(0,8)']
parts+=['[node name="Ground" type="StaticBody2D" parent="."]','[node name="CollisionShape2D" type="CollisionShape2D" parent="Ground"]\nposition = Vector2(0,500)\nshape = SubResource("ground")','[node name="Soil" type="Polygon2D" parent="Ground"]\npolygon = PackedVector2Array(-2000,0,2000,0,2000,1000,-2000,1000)\ncolor = Color(0.35,0.25,0.16,1)','[node name="Dog" type="CharacterBody2D" parent="."]\nposition = Vector2(-550,-5)\nz_index = 5\nscript = ExtResource("dog")','[node name="CollisionShape2D" type="CollisionShape2D" parent="Dog"]\nposition = Vector2(0,-40)\nshape = SubResource("dog_shape")','[node name="Visual" type="AnimatedSprite2D" parent="Dog"]\nposition = Vector2(0,-44.4)\nscale = Vector2(0.3,0.3)','[node name="EditorPreview" type="Sprite2D" parent="Dog"]\ntexture = ExtResource("dog_image")\nposition = Vector2(0,-44.4)\nscale = Vector2(0.3,0.3)','[node name="Camera2D" type="Camera2D" parent="."]\nposition = Vector2(0,-330)\nzoom = Vector2(0.76,0.76)','[node name="HUD" type="CanvasLayer" parent="."]','[node name="Status" type="Label" parent="HUD"]\noffset_left = 20.0\noffset_top = 18.0\ntheme_override_colors/font_shadow_color = Color(0,0,0,1)\ntheme_override_constants/shadow_offset_x = 2\ntheme_override_constants/shadow_offset_y = 2']
parts = [parts[0]] + [p for p in parts[1:] if p.startswith('[ext_resource')] + [p for p in parts[1:] if p.startswith('[sub_resource')] + [p for p in parts[1:] if p.startswith('[node')]
(root/'map_2d.tscn').write_text('\n\n'.join(parts)+'\n')
print(len(placements),'editable 2D platforms')
