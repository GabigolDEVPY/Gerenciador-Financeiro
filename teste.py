#!/usr/bin/env python3
import sys
import shutil
from pathlib import Path

MARK = "/*UPG_GOLPES2*/"

NEW_BLOCK = r"""/*UPG_GOLPES2*/
const JCV=document.createElement('canvas');JCV.style.cssText='position:fixed;left:0;top:0;width:100%;height:100%;pointer-events:none;display:none';R.domElement.after(JCV);
const JCX=JCV.getContext('2d'),JC={a:0,f:0,L:[],cx:0,cy:0,red:false};
function jcReset(){JC.a=0;JC.f=0;JC.L.length=0;JCV.style.display='none'}
function jcDraw(dt){const w=innerWidth,h=innerHeight;if(JCV.width!=w||JCV.height!=h){JCV.width=w;JCV.height=h}
if(!(p.atk>0&&p.combo==11))JC.a=Math.max(0,JC.a-dt*5);
if(JC.a<.01&&JC.f<.01&&!JC.L.length){JCV.style.display='none';return}
JCV.style.display='block';const x=JCX;x.clearRect(0,0,w,h);
if(JC.a>.01){const c0=JC.red?'70,0,12':'3,8,34',g=x.createRadialGradient(JC.cx,JC.cy,Math.min(w,h)*.12,JC.cx,JC.cy,Math.max(w,h)*.8);g.addColorStop(0,'rgba('+c0+',0)');g.addColorStop(.3,'rgba('+c0+','+(.5*JC.a)+')');g.addColorStop(1,'rgba('+c0+','+(.95*JC.a)+')');x.fillStyle=g;x.fillRect(0,0,w,h)}
x.lineCap='round';
for(let i=JC.L.length-1;i>=0;i--){const s=JC.L[i];s.t+=dt;const gp=Math.min(1,s.t/.07),fd=1-Math.max(0,s.t-s.hold)/s.fade;if(fd<=0){JC.L.splice(i,1);continue}
const ex=s.x1+(s.x2-s.x1)*gp,ey=s.y1+(s.y2-s.y1)*gp;x.shadowColor=s.c;x.shadowBlur=26;x.strokeStyle='rgba(255,255,255,'+fd+')';x.lineWidth=Math.max(1,s.w*fd);x.beginPath();x.moveTo(s.x1,s.y1);x.lineTo(ex,ey);x.stroke()}
x.shadowBlur=0;
if(JC.f>.01){x.fillStyle='rgba(255,255,255,'+JC.f+')';x.fillRect(0,0,w,h);JC.f=Math.max(0,JC.f-dt*3.5)}}
function jcStart(){p.jcA=0;JC.L.length=0;const col=p.dt?0xff2244:0x7fd0ff;ringFx(P.position,col,14,.7);ringFx(P.position,0xffffff,8,.5);beep(160,.5)}
function jcScene(){const col=p.dt?0xff2244:0x7fd0ff,c=E.g.position;
const a=new THREE.Mesh(new THREE.IcosahedronGeometry(7,1),Object.assign(AM(col,.35),{wireframe:true}));a.position.set(c.x,2.4,c.z);fx(a,1.6,.5);
const b=new THREE.Mesh(new THREE.OctahedronGeometry(5,0),Object.assign(AM(0xffffff,.28),{wireframe:true}));b.position.copy(a.position);fx(b,1.6,-.4);
ringFx(c,col,42,1.2);ringFx(c,0xffffff,22,.8);burst(c.clone().setY(2),50,col,9,2);shake=Math.max(shake,.3);beep(120,.6)}
function jcUp(dt,t){p.inv=Math.max(p.inv,.15);
E.flash=Math.max(0,E.flash-dt*3);bodyM.emissive.setRGB((E.rage?.3:0)+E.flash,E.flash*.8,E.flash*.7);
const dx=E.g.position.x-P.position.x,dz=E.g.position.z-P.position.z;
if(t<.7&&Math.hypot(dx,dz)>1){let a=Math.atan2(-dx,-dz)-yaw;a=Math.atan2(Math.sin(a),Math.cos(a));yaw+=a*Math.min(1,5*dt)}
const q=E.g.position.clone();q.y=2.5;q.project(cam);if(q.z<1){JC.cx=(q.x*.5+.5)*innerWidth;JC.cy=(-q.y*.5+.5)*innerHeight}else{JC.cx=innerWidth/2;JC.cy=innerHeight/2}
JC.red=p.dt;const col=p.dt?0xff3050:0x9fd0ff;
if(t<.3){burst(SW.localToWorld(new THREE.Vector3(0,0,rnd(0,2.2))),2,col,1.6,1);if(Math.random()<.4)burst(P.position.clone().add(new THREE.Vector3(rnd(-2,2),rnd(0,2),rnd(-2,2))),1,col,1,2);bl=Math.max(bl,.1)}
if(t>=.3&&!p.jcA){p.jcA=1;jcScene()}
if(t>=.3&&t<.86){JC.a=Math.min(1,JC.a+dt*8);bl=Math.max(bl,.15)}else if(t>=.86)JC.a=Math.max(0,JC.a-dt*5)}
function jcFx(fin){const c=E.g.position.clone();c.y=2.4;const col=p.dt?0xff2244:0xcfe8ff,w=innerWidth,h=innerHeight,n=fin?20:2;
for(let k=0;k<n;k++){const m=new THREE.Mesh(new THREE.BoxGeometry(rnd(16,26),fin?.2:.12,fin?.2:.12),AM(k%3?col:0xffffff,.95));m.position.copy(c).add(new THREE.Vector3(rnd(-2,2),rnd(-2,2),rnd(-2,2)));m.rotation.set(rnd(0,PI),rnd(0,PI),rnd(0,PI));fx(m,fin?.7:.5,.4)}
const nl=fin?7:1,len=Math.max(w,h)*.9;
for(let k=0;k<nl;k++){const an=fin?k/nl*PI+rnd(-.2,.2):rnd(0,PI),ox=JC.cx+rnd(-.2,.2)*w,oy=JC.cy+rnd(-.2,.2)*h;JC.L.push({x1:ox-Math.cos(an)*len,y1:oy-Math.sin(an)*len,x2:ox+Math.cos(an)*len,y2:oy+Math.sin(an)*len,t:0,hold:fin?.12:.5,fade:fin?.35:.4,w:fin?10:4+Math.random()*4,c:p.dt?'#ff2244':'#7fd0ff'})}
burst(c,fin?90:16,col,fin?14:7,2);
if(fin){JC.f=1;ringFx(E.g.position,col,34,.7);ringFx(E.g.position,0xffffff,18,.5);shake=.9;bl=Math.max(bl,1);flashL.color.setHex(0xcfe8ff);flashL.intensity=8;dmgText(c.clone().setY(4.2),'JUDGMENT CUT','g');beep(220,.5)}else beep(rnd(500,900),.1)}
function whirlStart(){const col=p.dt?0xff3050:0x9fe0ff;
for(let k=0;k<3;k++){const m=new THREE.Mesh(new THREE.CylinderGeometry(1.4+k*.5,3.4+k*.6,3.4,28,1,true),AM(col,.22));m.position.y=1.7;m.rotation.y=k*2;fx(m,1.05,.5,P)}
ringFx(P.position,col,22,.6);beep(250,.5)}
function whirlUp(dt,t){P.rotation.y+=dt*PI*4/AT[5].d;const col=p.dt?0xff3050:0x9fe0ff;
if(Math.random()<.5){const g=new THREE.RingGeometry(1.8,4.6,24,1,PI/2,1.7);g.rotateX(PI/2);const m=new THREE.Mesh(g,AM(col,.4));m.position.set(P.position.x,rnd(.5,2.2),P.position.z);m.rotation.y=P.rotation.y;fx(m,.3,.6)}
burst(P.position.clone().add(new THREE.Vector3(rnd(-3,3),rnd(0,2.5),rnd(-3,3))),2,col,2,1);bl=Math.max(bl,.15)}
function whirlHit(){const col=p.dt?0xff3050:0x9fe0ff;ringFx(P.position,col,24,.4);burst(P.position.clone().setY(1.4),24,col,8,2);shake=Math.max(shake,.3);beep(420,.15)}
function swDir(){const d=E.g.position.clone().sub(P.position);d.y=0;if(d.lengthSq()<.01)d.set(Math.sin(P.rotation.y),0,Math.cos(P.rotation.y));return d.normalize()}
function swSlot(s,dir){const rt=new THREE.Vector3(dir.z,0,-dir.x),a=(s.k-3.5)/3.5*1.15;
return new THREE.Vector3(P.position.x-dir.x*2.4+rt.x*Math.sin(a)*2.5,P.position.y+1.9+Math.cos(a)*1.5,P.position.z-dir.z*2.4+rt.z*Math.sin(a)*2.5)}
function summonSwords(){for(let i=0;i<8;i++){const g=mkSword();g.scale.setScalar(.01);g.position.copy(P.position).setY(P.position.y+1.2);S.add(g);SSW.push({g,st:0,a:0,k:i,t:0,l:0,rel:new THREE.Vector3(),j:new THREE.Vector3(rnd(-.7,.7),rnd(-.9,.9),rnd(-.7,.7))})}
ringFx(P.position,0xb060ff,18,.6);ringFx(P.position,0x7a30d0,28,.9);burst(P.position.clone().setY(1.5),40,0xb060ff,6,2);beep(500,.4,'sine',.07)}
function fireSword(s){s.st=1;s.l=0;burst(s.g.position.clone(),8,0xb060ff,3,1);beep(700+s.k*30,.12,'sine',.05)}
function swKey(){if(!playing||p.dodge>0)return;let b=null;
for(const s of SSW)if(s.st==0&&s.a>=.5&&(!b||Math.abs(s.k-3.5)<Math.abs(b.k-3.5)))b=s;
if(b){fireSword(b);return}
if(!SSW.some(s=>s.st==0))spec(12)}
function upSwords(dt){jcDraw(dt);const tg=E.g.position.clone();tg.y+=2.4;const dir=swDir();
for(let i=SSW.length-1;i>=0;i--){const s=SSW[i],g=s.g;s.a+=dt;
if(s.st==0){const pos=swSlot(s,dir);pos.y+=Math.sin(tm*3+s.k)*.1;g.position.lerp(pos,Math.min(1,12*dt));g.scale.setScalar(Math.max(.01,Math.min(1,(s.a-s.k*.04)/.2)));g.lookAt(tg);if(Math.random()<.2)burst(g.position.clone(),1,0xb060ff,.4,.4);if(s.a>9){s.st=3;s.t=.3}}
else if(s.st==1){s.l+=dt;const aim=tg.clone().add(s.j),d=aim.sub(g.position),L=d.length(),sp=Math.min(95,35+s.l*160),stp=Math.min(L,sp*dt);g.lookAt(tg.clone().add(s.j));g.position.addScaledVector(d.normalize(),stp);burst(g.position.clone(),2,0xb060ff,.8,.5);
if(L-stp<.9||s.l>1.8){if(!E.dead&&L-stp<.9){HC=0xb060ff;hitEnemy(10,false,true);HC=0;ringFx(E.g.position,0xb060ff,10,.3);burst(g.position.clone(),16,0xb060ff,7);s.rel=g.position.clone().sub(E.g.position);s.st=2;s.t=.7}else{s.st=3;s.t=.3}}}
else if(s.st==2){s.t-=dt;g.position.copy(E.g.position).add(s.rel);if(s.t<.2)g.scale.setScalar(Math.max(.01,s.t/.2));if(s.t<=0){burst(g.position.clone(),14,0xc080ff,6,2);s.st=4}}
else if(s.st==3){s.t-=dt;g.scale.setScalar(Math.max(.01,s.t/.3));if(s.t<=0)s.st=4}
if(s.st==4){S.remove(g);g.traverse(o=>{if(o.geometry)o.geometry.dispose();if(o.material&&o.material.transparent)o.material.dispose()});SSW.splice(i,1)}}}
"""

REPLACEMENTS = [
    ("V Summoned Swords (golpes especiais gastam mana)",
     "V Summoned Swords (V invoca as espadas atrás de você, V de novo lança uma por vez) (golpes especiais gastam mana)"),
    ("{d:.75,h:[.3,.62],g:13,r:5.4}",
     "{d:1.1,h:[.22,.42,.62,.82],g:11,r:6.4}"),
    ("{d:1.2,h:[.45,.52,.59,.66,.73,.92],g:14,r:9.5}",
     "{d:2.2,h:[.4,.46,.52,.58,.64,.7,.76,.86],g:14,r:90}"),
    ("if(c==11){jcStart();return}if(c==12){beep(500,.3,'sine',.06);summonSwords();return}",
     "if(c==5){whirlStart();return}if(c==11){jcStart();return}if(c==12){summonSwords();return}"),
    ("while(SSW.length)S.remove(SSW.pop().g);",
     "while(SSW.length)S.remove(SSW.pop().g);jcReset();"),
    ("(p.combo==10?18:10)",
     "(p.combo==10?18:p.combo==11||p.combo==12?60:10)"),
    ("function spec(i){if(!playing||p.dodge>0)return;const c=MC[i]||0;",
     "function spec(i){if(!playing||p.dodge>0||(p.atk>0&&p.combo==11))return;const c=MC[i]||0;"),
    ("p.combo==11||p.combo==12?0:",
     "p.combo==11||p.combo==12||p.combo==5?0:"),
    ("SW.position.z=.4;if(c==0)SW.rotation.set(",
     "SW.position.set(.05,1.15,.4);if(c==0)SW.rotation.set("),
    ("else if(c==9)SW.rotation.set(1.5,0,0);else if(c==11)SW.rotation.set(.4,PI*.85,0);else if(c==12)SW.rotation.set(-1.3,0,0);else SW.rotation.set(.2,e*PI*4,0);",
     "else if(c==9)SW.rotation.set(1.5,0,0);else if(c==5){SW.position.set(0,1.4,.5);SW.rotation.set(-1.5,0,0)}else if(c==11)SW.rotation.set(t<.78?.35:-.4,t<.78?PI*.88:-.4,0);else if(c==12)SW.rotation.set(-1.3,0,0);else SW.rotation.set(.2,e*PI*4,0);"),
    ("if(c==11){p.inv=Math.max(p.inv,.1);burst(P.position.clone().setY(rnd(.3,2)),2,p.dt?0xff3050:0x9fd0ff,t<.45?2:6,1);if(t>=.45)bl=Math.max(bl,.25)}",
     "if(c==5)whirlUp(dt,t);if(c==11)jcUp(dt,t);"),
    ("c==4||(c==11&&p.hn<A.h.length));if(c==11)jcFx(p.hn>=A.h.length);",
     "c==4||(c==11&&p.hn<A.h.length)||(c==5&&p.hn<A.h.length));if(c==11)jcFx(p.hn>=A.h.length);if(c==5)whirlHit();"),
    ("SW.rotation.x+=(.25-SW.rotation.x)*Math.min(1,9*dt);",
     "SW.position.set(.05,1.15,.4);SW.rotation.x+=(.25-SW.rotation.x)*Math.min(1,9*dt);"),
    ("upEnemy(dt);upWaves(dt);upSwords(dt)}",
     "if(!(p.atk>0&&p.combo==11)){upEnemy(dt);upWaves(dt)}upSwords(dt)}"),
    ("function dodge(){if(!playing||p.dodge>0)return;",
     "function dodge(){if(!playing||p.dodge>0||(p.atk>0&&p.combo==11))return;"),
    ("if(e.code=='KeyV')spec(12);",
     "if(e.code=='KeyV')swKey();"),
]


def unique_backup(src):
    cand = src.with_name(src.name + ".bak")
    i = 1
    while cand.exists():
        cand = src.with_name(f"{src.name}.bak{i}")
        i += 1
    return cand


def main():
    if len(sys.argv) != 2:
        print("Uso: python atualizar_golpes_v2.py <arquivo.html>", file=sys.stderr)
        return 1

    src = Path(sys.argv[1])
    if not src.is_file():
        print(f"Erro: arquivo não encontrado: {src}", file=sys.stderr)
        return 1

    try:
        with open(src, "r", encoding="utf-8", newline="") as f:
            text = f.read()
    except (OSError, UnicodeDecodeError) as e:
        print(f"Erro ao ler o arquivo: {e}", file=sys.stderr)
        return 1

    original = text
    errors = []

    if MARK in text:
        print("Nenhum arquivo foi gerado: esta atualização já foi aplicada.", file=sys.stderr)
        return 2

    for idx, (old, new) in enumerate(REPLACEMENTS, 1):
        n = text.count(old)
        if n != 1:
            errors.append(f"Correção #{idx}: trecho encontrado {n} vez(es) (esperado 1): {old[:80]!r}")
            continue
        text = text.replace(old, new, 1)

    start = text.find("function summonSwords(")
    end = text.find("function airIdx(){")
    if start < 0 or end < 0 or end < start:
        errors.append("Bloco de funções summonSwords/upSwords/jcStart/jcFx não localizado.")
    else:
        text = text[:start] + NEW_BLOCK + text[end:]

    if errors:
        print("Nenhum arquivo foi gerado. Problemas encontrados:", file=sys.stderr)
        for e in errors:
            print(" -", e, file=sys.stderr)
        return 2

    if text == original:
        print("Nenhum arquivo foi gerado: nenhuma alteração aplicada.", file=sys.stderr)
        return 2

    backup = unique_backup(src)
    out = src.with_name(src.stem + "_novos_golpes" + src.suffix)

    try:
        shutil.copy2(src, backup)
        with open(out, "w", encoding="utf-8", newline="") as f:
            f.write(text)
    except OSError as e:
        print(f"Erro ao gravar arquivos: {e}", file=sys.stderr)
        return 1

    print(f"Backup: {backup}")
    print(f"Gerado: {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())