import ctypes as C, os, pathlib
os.environ['EGL_PLATFORM']='surfaceless'
E=C.CDLL('libEGL.so.1'); P=C.c_void_p; I=C.c_int; U=C.c_uint

def fun(lib,n,restype,*args):
 if lib is None:
  addr=E.eglGetProcAddress(n.encode()); assert addr,n; return C.CFUNCTYPE(restype,*args)(addr)
 f=getattr(lib,n); f.restype=restype; f.argtypes=list(args); return f
E.eglGetProcAddress.restype=P; E.eglGetProcAddress.argtypes=[C.c_char_p]; G=None
get=fun(E,'eglGetDisplay',P,P); init=fun(E,'eglInitialize',U,P,C.POINTER(I),C.POINTER(I)); bind=fun(E,'eglBindAPI',U,U); choose=fun(E,'eglChooseConfig',U,P,C.POINTER(I),C.POINTER(P),I,C.POINTER(I)); create=fun(E,'eglCreateContext',P,P,P,P,C.POINTER(I)); surf=fun(E,'eglCreatePbufferSurface',P,P,P,C.POINTER(I)); make=fun(E,'eglMakeCurrent',U,P,P,P,P)
d=get(None); major=I(); minor=I(); assert init(d,C.byref(major),C.byref(minor)); assert bind(0x30a0); config=P(); num=I(); a=(I*5)(0x3033,1,0x3040,0x40,0x3038); assert choose(d,a,C.byref(config),1,C.byref(num)) and num.value
ctx=create(d,config,None,(I*3)(0x3098,3,0x3038)); surface=surf(d,config,(I*5)(0x3057,8,0x3056,8,0x3038)); assert make(d,surface,surface,ctx)
cs=fun(G,'glCreateShader',U,U); source=fun(G,'glShaderSource',None,U,I,C.POINTER(C.c_char_p),C.POINTER(I)); compile=fun(G,'glCompileShader',None,U); getiv=fun(G,'glGetShaderiv',None,U,U,C.POINTER(I)); log=fun(G,'glGetShaderInfoLog',None,U,I,C.POINTER(I),C.c_char_p); program=fun(G,'glCreateProgram',U); attach=fun(G,'glAttachShader',None,U,U); link=fun(G,'glLinkProgram',None,U); getp=fun(G,'glGetProgramiv',None,U,U,C.POINTER(I)); plog=fun(G,'glGetProgramInfoLog',None,U,I,C.POINTER(I),C.c_char_p)
def shader(kind,code):
 s=cs(kind); v=C.c_char_p(code); source(s,1,C.byref(v),None); compile(s); ok=I(); getiv(s,0x8b81,C.byref(ok)); buf=C.create_string_buffer(4096); log(s,4096,None,buf); assert ok.value,buf.value; return s
# ES 3 matching modern Hyprland interface.
v=shader(0x8b31,b'#version 300 es\nprecision highp float; in vec2 position; out vec2 v_texcoord; void main(){v_texcoord=position*0.5+0.5;gl_Position=vec4(position,0.0,1.0);}')
for p in sorted((pathlib.Path(__file__).resolve().parents[3]/'themes/swirldesk-matrix/visual/crt').glob('*.frag')):
 f=shader(0x8b30,p.read_bytes()); pr=program(); attach(pr,v); attach(pr,f); link(pr); ok=I(); getp(pr,0x8b82,C.byref(ok)); buf=C.create_string_buffer(4096); plog(pr,4096,None,buf); assert ok.value,buf.value; print(p.name,'GLSL compile + link OK')
