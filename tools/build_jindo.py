"""Reference-guided Jindo sculpt + actual skinned glTF, generated locally.
Run with numpy/scipy/scikit-image. No image-to-3D service or downloaded mesh.
Coordinates: +X muzzle, +Y up, +Z left. Meters are relative model units.
"""
from pathlib import Path
import json, struct, math
import numpy as np
from scipy.ndimage import gaussian_filter, map_coordinates
from skimage.measure import marching_cubes

OUT=Path(__file__).resolve().parents[1]/'assets/characters/jindo_v4'
OUT.mkdir(parents=True,exist_ok=True)
STEP=.010
LO=np.array([-1.05,-.06,-.46],np.float32)
HI=np.array([1.16,1.86,.46],np.float32)
axes=[np.arange(a,b+STEP,STEP,dtype=np.float32) for a,b in zip(LO,HI)]
X,Y,Z=np.meshgrid(*axes,indexing='ij',sparse=True)
FIELD=np.full(tuple(len(a) for a in axes),10.,np.float32)

def smooth(a,b,k):
 h=np.maximum(k-np.abs(a-b),0)/k
 return np.minimum(a,b)-h*h*k*.25

def ellipsoid(c,r,angle=0):
 x=X-c[0]; y=Y-c[1]; z=Z-c[2]
 if angle:
  x,y=np.cos(angle)*x+np.sin(angle)*y,-np.sin(angle)*x+np.cos(angle)*y
 k0=np.sqrt((x/r[0])**2+(y/r[1])**2+(z/r[2])**2)
 k1=np.sqrt((x/r[0]**2)**2+(y/r[1]**2)**2+(z/r[2]**2)**2)
 return k0*(k0-1)/np.maximum(k1,1e-6)

def ell(c,r,k=.065,angle=0):
 global FIELD
 FIELD=smooth(FIELD,ellipsoid(c,r,angle),k)

def capsule(a,b,ra,rb,k=.04):
 global FIELD
 a=np.asarray(a);b=np.asarray(b); d=b-a
 t=np.clip(((X-a[0])*d[0]+(Y-a[1])*d[1]+(Z-a[2])*d[2])/np.dot(d,d),0,1)
 dist=np.sqrt((X-a[0]-t*d[0])**2+(Y-a[1]-t*d[1])**2+(Z-a[2]-t*d[2])**2)-(ra+(rb-ra)*t)
 FIELD=smooth(FIELD,dist,k)

# Rib cage, tucked loin, haunches, shoulder, stout neck and ruff.
ell((-.12,.80,0),(.58,.255,.235),.08)
ell((-.44,.81,0),(.235,.28,.25),.07)
ell((.25,.79,0),(.265,.34,.255),.10)
ell((.36,.97,0),(.255,.33,.255),.10,angle=-.25)
ell((.43,1.14,0),(.225,.285,.242),.09,angle=-.20)
ell((.40,.89,0),(.17,.25,.22),.08)
# Skull, cheeks, upper muzzle, jaw: continuous with neck.
ell((.55,1.31,0),(.255,.235,.223),.065)
for side in [-1,1]:
 ell((.615,1.235,side*.13),(.16,.17,.145),.04)
ell((.78,1.24,0),(.225,.108,.138),.025)
ell((.86,1.258,0),(.15,.076,.103),.02)
ell((.74,1.145,0),(.21,.075,.12),.025)
# Four limbs, genuine uninterrupted shoulder/thigh-to-paw surface.
for side in [-1,1]:
 z=side*.18
 ell((.285,.69,z),(.14,.26,.132),.07,angle=.12)
 capsule((.30,.64,z),(.31,.35,z),.090,.058,.045)
 capsule((.31,.35,z),(.34,.115,z),.058,.051,.025)
 ell((.385,.063,z),(.127,.062,.083),.024)
 ell((-.45,.68,z),(.19,.26,.15),.075,angle=.36)
 capsule((-.46,.62,z),(-.30,.38,z),.119,.07,.045)
 capsule((-.30,.38,z),(-.48,.19,z),.067,.042,.025)
 capsule((-.48,.19,z),(-.465,.08,z),.043,.044,.02)
 ell((-.41,.060,z),(.12,.059,.079),.024)
# Closed tapered upright ears, grown into skull rather than attached triangles.
for side in [-1,1]:
 for t in np.linspace(0,1,12):
  c=(.45+.025*t,1.45+.225*t,side*(.142+.045*t))
  r=(.086*(1-t)+.009,.062*(1-t)+.013,.089*(1-t)+.01)
  ell(c,r,.020)
# Thick raised tail arcs toward the back; the tip lies over the rump.
last=None
for t in np.linspace(0,1,31):
 a=-math.pi/2-4.25*t
 p=(-.56+.22*math.cos(a),1.235+.27*math.sin(a),.018)
 r=.099*(1-.65*t*t)
 if last is not None: capsule(last[0],p,last[1],r,.014)
 last=(p,r)
# A restrained happy mouth opening, black lining is supplied as a separate mesh.
cut=ellipsoid((.81,1.161,0),(.185,.032,.16),-.04)
FIELD=np.maximum(FIELD,-cut)
FIELD=gaussian_filter(FIELD,.45)
verts,faces,_,_=marching_cubes(FIELD,0,spacing=(STEP,)*3,gradient_direction='ascent',allow_degenerate=False)
verts=verts.astype(np.float32)+LO
# SDF gradients give outward normals and let us validate triangle orientation.
grad=np.gradient(FIELD,STEP)
coords=((verts-LO)/STEP).T
normals=np.stack([map_coordinates(g,coords,order=1) for g in grad],axis=1)
normals/=np.maximum(np.linalg.norm(normals,axis=1,keepdims=True),1e-8)
tri=verts[faces]
if np.mean(np.sum(np.cross(tri[:,1]-tri[:,0],tri[:,2]-tri[:,0])*normals[faces[:,0]],axis=1))<0: faces=faces[:,::-1]
print('Sculpt:',len(verts),'vertices,',len(faces),'triangles',flush=True)

# The root rotates around the torso; subsequent bones remain local hierarchy.
bones=[]
def bone(name,pos,parent=-1):
 bones.append(dict(name=name,pos=np.array(pos,float),parent=parent)); return len(bones)-1
root=bone('Torso',(0,.78,0));neck=bone('Neck',(.31,1.02,0),root);head=bone('Head',(.47,1.24,0),neck)
tail=bone('Tail',(-.56,1.0,0),root)
legs=[]
for side in [-1,1]:
 for front in [True,False]:
  z=side*.18
  h=bone(('Front' if front else 'Hind')+('R' if side<0 else 'L'),(.29,.73,z) if front else (-.46,.73,z),root)
  knee=bone('Knee_'+str(h),(.31,.35,z) if front else (-.30,.38,z),h)
  ankle=bone('Ankle_'+str(h),(.34,.10,z) if front else (-.48,.19,z),knee)
  legs.append((h,knee,ankle,front,side))

def ramp(x,a,b):
 t=np.clip((x-a)/(b-a),0,1);return t*t*(3-2*t)

def skin(v):
 w=np.zeros((len(v),len(bones)),np.float32);x,y,z=v.T
 w[:,root]=1
 # Legs blend into the torso over a wide shoulder/hip band.
 leg_amount=1-ramp(y,.57,.86)
 for h,k,a,front,side in legs:
  region=(ramp(x,-.18,.10) if front else 1-ramp(x,-.18,.10))*(ramp(z,-.06,.06) if side>0 else 1-ramp(z,-.06,.06))
  amount=leg_amount*region
  upper=ramp(y,.31,.56); foot=1-ramp(y,.12,.25)
  w[:,h]+=amount*upper
  w[:,k]+=amount*(1-upper)*(1-foot)
  w[:,a]+=amount*(1-upper)*foot
 w[:,root]=1-leg_amount
 # Upper neck and face blend around throat; eye/muzzle meshes use Head rigidly.
 ha=ramp(y,1.11,1.30)*ramp(x,.22,.42)
 na=ramp(y,.91,1.20)*ramp(x,.18,.4)*(1-ha)
 w*=1-(ha+na)[:,None];w[:,head]+=ha;w[:,neck]+=na
 ta=(1-ramp(x,-.48,-.29))*ramp(y,1.03,1.16)
 w*=1-ta[:,None];w[:,tail]+=ta
 ids=np.argsort(w,axis=1)[:,-4:]
 weights=np.take_along_axis(w,ids,axis=1);weights/=weights.sum(axis=1,keepdims=True)
 return ids.astype(np.uint16),weights.astype(np.float32)

# glTF binary packing with real skin attributes and bind matrices.
binary=bytearray();views=[];accessors=[];meshes=[];nodes=[];materials=[];images=[];textures=[]
def accessor(arr,typ,component=5126):
 arr=np.asarray(arr,dtype={5126:'<f4',5125:'<u4',5123:'<u2'}[component])
 while len(binary)%4:binary.append(0)
 offset=len(binary);binary.extend(arr.tobytes());view=len(views)
 views.append({'buffer':0,'byteOffset':offset,'byteLength':arr.nbytes})
 a={'bufferView':view,'componentType':component,'count':len(arr),'type':typ}
 if typ in ['VEC3','SCALAR']:
  a['min']=np.min(arr,axis=0).reshape(-1).tolist();a['max']=np.max(arr,axis=0).reshape(-1).tolist()
 accessors.append(a);return len(accessors)-1

def mat(name,color,rough=.9,double=False):
 materials.append({'name':name,'pbrMetallicRoughness':{'baseColorFactor':list(color)+[1],'metallicFactor':0,'roughnessFactor':rough},'doubleSided':double})
 return len(materials)-1
fur=mat('Warm white short coat',(1,1,1));black=mat('Soft black nose',(.019,.022,.025),.35)
eye=mat('Dark brown eyes',(.055,.033,.018),.18);mouth=mat('Mouth',(.03,.012,.014),.8)
pink=mat('Tongue',(.57,.24,.27),.65);earmat=mat('Ear inner',(.48,.32,.29),.95);white=mat('Eye catchlight',(.95,.95,.92),.25)
for i,b in enumerate(bones):
 pos=b['pos']-(bones[b['parent']]['pos'] if b['parent']>=0 else 0)
 nodes.append({'name':b['name'],'translation':pos.tolist()})
for i,b in enumerate(bones):
 if b['parent']>=0:nodes[b['parent']].setdefault('children',[]).append(i)

def addmesh(name,v,n,f,material,colors=None,rigid=None):
 v=np.asarray(v,np.float32);n=np.asarray(n,np.float32);f=np.asarray(f,np.uint32)
 j,w=skin(v) if rigid is None else (np.tile([rigid,0,0,0],(len(v),1)).astype(np.uint16),np.tile([1.,0,0,0],(len(v),1)).astype(np.float32))
 attributes={'POSITION':accessor(v,'VEC3'),'NORMAL':accessor(n,'VEC3'),'JOINTS_0':accessor(j,'VEC4',5123),'WEIGHTS_0':accessor(w,'VEC4')}
 if colors is not None:attributes['COLOR_0']=accessor(colors,'VEC3')
 if name=='ContinuousJindoCoat':
  uv=np.stack([v[:,0]*1.6,np.arctan2(v[:,2],v[:,1]-.80)/(2*np.pi)],axis=1)
  attributes['TEXCOORD_0']=accessor(uv,'VEC2')
 primitive={'attributes':attributes,'indices':accessor(f.reshape(-1),'SCALAR',5125),'material':material}
 meshes.append({'name':name,'primitives':[primitive]})
 nodes.append({'name':name,'mesh':len(meshes)-1,'skin':0})

def coat_color(v):
 x,y,z=v.T
 cream=ramp(y,.65,1.4)*.055+np.exp(-((x+.38)/.3)**2)*.014
 rng=np.random.default_rng(41)
 noise=rng.uniform(-.013,.013,len(v))
 return np.clip(np.stack([.86+noise,.85-cream*.65+noise,.81-cream+noise],axis=1),0,1).astype(np.float32)
addmesh('ContinuousJindoCoat',verts,normals,faces,fur,coat_color(verts))

def uvell(name,c,r,material,rigid=head,rotation=0):
 vs=[];ns=[];fs=[]
 for i in range(17):
  phi=math.pi*i/16
  for j in range(25):
   a=2*math.pi*j/24;u=np.array([math.sin(phi)*math.cos(a),math.cos(phi),math.sin(phi)*math.sin(a)])
   p=u*np.array(r);nn=u/np.array(r)
   if rotation:
    rot=np.array([[math.cos(rotation),-math.sin(rotation),0],[math.sin(rotation),math.cos(rotation),0],[0,0,1]])
    p=rot@p;nn=rot@nn
   vs.append(np.array(c)+p);ns.append(nn/np.linalg.norm(nn))
 for i in range(16):
  for j in range(24):
   a=i*25+j;fs.extend([[a,a+1,a+25],[a+1,a+26,a+25]])
 vs=np.array(vs);ns=np.array(ns);fs=np.array(fs)
 if np.mean(np.sum(np.cross(vs[fs[:,1]]-vs[fs[:,0]],vs[fs[:,2]]-vs[fs[:,0]])*ns[fs[:,0]],axis=1))<0:fs=fs[:,::-1]
 addmesh(name,vs,ns,fs,material,rigid=rigid)

uvell('Nose',(.986,1.266,0),(.055,.052,.075),black)
for side in [-1,1]:
 uvell('Nostril', (1.028,1.263,side*.04),(.012,.014,.012),mouth)
 # Eyes set diagonally on the cheeks, not on top of the snout.
 uvell('Eyelid',(.668,1.365,side*.170),(.078,.043,.026),black)
 uvell('Eye',(.676,1.367,side*.187),(.047,.032,.014),eye)
 uvell('Catchlight',(.687,1.378,side*.198),(.012,.010,.005),white)
 # Inset ear flesh stays small and recessed inside the white silhouette.
 uvell('EarInset',(.496,1.55,side*.157),(.010,.060,.047),earmat,rotation=-.10)
uvell('MouthLining',(.81,1.163,0),(.18,.025,.105),mouth)
uvell('Tongue',(.83,1.143,.0),(.091,.017,.067),pink)
# Paw nails sit at the toe tips, subtle gray, not giant claws.
for x in [.385,-.41]:
 for side in [-1,1]:
  for dz in [-.045,0,.045]:
   uvell('Nail',(x+.105,.048,side*.18+dz),(.022,.011,.010),black,rigid=next(a for h,k,a,front,s in legs if s==side and front==(x>0)))

# Fine normal-map detail replaces discarded silhouette tufts, which aliased.
ff=[]
materials[fur]['doubleSided']=False
# A tiled directional normal map supplies restrained short-coat detail.
from PIL import Image
import io
rng=np.random.default_rng(91)
height=gaussian_filter(rng.random((512,512)),(.65,4.5),mode='wrap')
gy,gx=np.gradient(height)
nm=np.stack([-gx*1.2,-gy*1.2,np.ones_like(gx)],axis=-1)
nm/=np.linalg.norm(nm,axis=-1,keepdims=True)
normal_bytes=io.BytesIO()
Image.fromarray(np.uint8(np.clip(nm*.5+.5,0,1)*255)).save(normal_bytes,format='PNG')
normal_png=normal_bytes.getvalue()
(OUT/'short_coat_normal.png').write_bytes(normal_png)
while len(binary)%4:binary.append(0)
views.append({'buffer':0,'byteOffset':len(binary),'byteLength':len(normal_png)})
binary.extend(normal_png)
images.append({'name':'ShortCoatNormal','bufferView':len(views)-1,'mimeType':'image/png'})
textures.append({'source':0})
materials[fur]['normalTexture']={'index':0,'scale':.35}

ibm=np.repeat(np.eye(4,dtype=np.float32)[None],len(bones),axis=0)
for i,b in enumerate(bones):ibm[i,:3,3]=-b['pos']
ibm_index=accessor(ibm.transpose(0,2,1).reshape(-1,16),'MAT4')
# Six root-motion-free clips; all translation belongs to the game controller.
animations=[]
def quat(axis,angle):
 return list(np.asarray(axis)*math.sin(angle/2))+[math.cos(angle/2)]
for clip,duration in [('idle',2.4),('run',.65),('jump',.5),('double_jump',.4),('fall',.8),('land',.24)]:
 times=np.linspace(0,duration,round(duration*30)+1,dtype=np.float32)
 samplers=[];channels=[]
 rotations={i:[] for i in range(len(bones))};positions=[]
 for t in times:
  phase=float(t/duration*2*math.pi);angles={i:0. for i in range(len(bones))};offset=0.
  if clip=='idle':
   angles[neck]=.012*math.sin(phase);angles[head]=-.018*math.sin(phase);offset=.004*math.sin(phase)
  elif clip=='run':
   offset=.013*math.sin(phase*2);angles[neck]=-.035
   for h,k,a,front,side in legs:
    stride=phase+(math.pi if (front and side>0) or (not front and side<0) else 0)
    angles[h]=math.sin(stride)*.46
    angles[k]=(-.55 if front else .45)*max(0,math.sin(stride))
    angles[a]=-angles[k]*.45
  elif clip in ['jump','double_jump']:
   angles[root]=.30+.08*math.exp(-float(t)*14);angles[neck]=.08;angles[head]=.06
   for h,k,a,front,side in legs:
    angles[h]=-.65 if front else .48
    angles[k]=1.0 if front else -.85
    angles[a]=-.25 if front else .25
  elif clip=='fall':
   angles[root]=.08;angles[head]=-.10
   for h,k,a,front,side in legs: angles[h]=-.10 if front else .12
  else:
   squash=max(0,1-float(t)/duration);offset=-.06*squash
   for h,k,a,front,side in legs:angles[h]=-.3*squash;angles[k]=.6*squash
  for i in rotations:
   rotations[i].append(quat([1,0,0],.10*math.sin(phase)) if i==tail else quat([0,0,1],angles[i]))
  positions.append(bones[0]['pos']+np.array([0,offset,0]))
 timeacc=accessor(times,'SCALAR')
 for i,values in rotations.items():
  samplers.append({'input':timeacc,'output':accessor(values,'VEC4'),'interpolation':'LINEAR'})
  channels.append({'sampler':len(samplers)-1,'target':{'node':i,'path':'rotation'}})
 samplers.append({'input':timeacc,'output':accessor(positions,'VEC3'),'interpolation':'LINEAR'})
 channels.append({'sampler':len(samplers)-1,'target':{'node':0,'path':'translation'}})
 animations.append({'name':clip,'samplers':samplers,'channels':channels})
scene_roots=[0]+list(range(len(bones),len(nodes)))
doc={'asset':{'version':'2.0','generator':'ddong_puppy local reference-guided sculpt v4'},'scene':0,'scenes':[{'nodes':scene_roots}], 'nodes':nodes,'meshes':meshes,'materials':materials,'images':images,'textures':textures,'skins':[{'name':'JindoSkeleton','joints':list(range(len(bones))),'skeleton':0,'inverseBindMatrices':ibm_index}],'animations':animations,'accessors':accessors,'bufferViews':views,'buffers':[{'byteLength':len(binary)}]}
js=json.dumps(doc,separators=(',',':')).encode();js+=b' '*((-len(js))%4);binary+=b'\0'*((-len(binary))%4)
blob=struct.pack('<III',0x46546C67,2,12+8+len(js)+8+len(binary))+struct.pack('<II',len(js),0x4E4F534A)+js+struct.pack('<II',len(binary),0x004E4942)+binary
(OUT/'jindo_v4.glb').write_bytes(blob)
# OBJ is also provided as an editable sculpt base, without skeleton/material details.
with (OUT/'jindo_sculpt.obj').open('w') as f:
 for v in verts:f.write('v %.6f %.6f %.6f\n'%tuple(v))
 for face in faces:f.write('f %d %d %d\n'%tuple(face+1))
(OUT/'build_stats.json').write_text(json.dumps({'body_vertices':len(verts),'body_triangles':len(faces),'fur_tufts':len(ff),'bones':len(bones),'clips':[a['name'] for a in animations],'glb_bytes':len(blob)},indent=2))
print('Saved',OUT/'jindo_v4.glb',len(blob),'bytes',flush=True)
