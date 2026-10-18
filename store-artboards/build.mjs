// Genuine screen captures, proportional composition, exact per-slot export.
import {readFileSync,writeFileSync,mkdirSync,mkdtempSync,existsSync} from 'node:fs';
import {spawn} from 'node:child_process';
import {dirname,join} from 'node:path';
import {fileURLToPath} from 'node:url';
const root=dirname(fileURLToPath(import.meta.url));
const chrome='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const shots=[
 {id:'01-overview',title:"See what's happening<br>in your app.",accent:'#F5F5F5',label:'COMMAND CENTER'},
 {id:'02-errors',title:'Go from error<br>to evidence.',accent:'#CF6679',label:'ERROR DETAILS'},
 {id:'03-sessions',title:'See what happened,<br>step by step.',accent:'#F5F5F5',label:'SESSION TIMELINES'},
 {id:'04-analytics',title:'Know how your<br>app is doing.',accent:'#F5F5F5',label:'ANALYTICS'},
 {id:'05-versions',title:'Keep your app<br>up to date.',accent:'#FFA000',label:'VERSION CONTROLS'},
];
const targets=[
 {id:'01-iPhone-medium-1179x2556',slot:'iphone-medium',w:1179,h:2556,prefix:'phone',type:'phone'},
 {id:'02-iPad-13-2064x2752',slot:'ipad-13',w:2064,h:2752,prefix:'ipad',type:'tablet'},
 {id:'03-Duo-outer-1398x2034',slot:'duo-outer',w:1398,h:2034,prefix:'phone',type:'duo'},
 {id:'04-Duo-inner-2007x2853',slot:'duo-inner',w:2007,h:2853,prefix:'phone',type:'duo'},
 {id:'05-Header-3840x1646',slot:'header',w:3840,h:1646,type:'header'},
 {id:'06-Search-Results-3840x2560',slot:'search-results',w:3840,h:2560,type:'search'},
 {id:'07-Play-phone-1080x1920',slot:'play-phone',w:1080,h:1920,prefix:'android',type:'play'},
 {id:'08-Play-feature-1024x500',slot:'play-feature',w:1024,h:500,type:'feature'},
];
const meta=JSON.parse(readFileSync(join(root,'sources/metadata.json'),'utf8'));
for(const t of targets)mkdirSync(join(root,t.id),{recursive:true});
mkdirSync(join(root,'pages'),{recursive:true});
const css=`@font-face{font-family:Syne;src:url('../fonts/Syne-SemiBold.ttf');font-weight:600}@font-face{font-family:Syne;src:url('../fonts/Syne-Bold.ttf');font-weight:700}@font-face{font-family:Urbanist;src:url('../fonts/Urbanist-Regular.ttf')}@font-face{font-family:Code;src:url('../fonts/SourceCodePro-Regular.ttf')}*{box-sizing:border-box}html,body{margin:0;width:var(--w);height:var(--h);overflow:hidden;background:#050505;color:#F5F5F5}.canvas{position:relative;width:var(--w);height:var(--h);overflow:hidden;background-image:linear-gradient(#ffffff05 1px,transparent 1px),linear-gradient(90deg,#ffffff05 1px,transparent 1px);background-size:calc(var(--w)*.0833) calc(var(--w)*.0833)}.heading{position:absolute;left:7%;right:7%;top:2.3%}.brand{font:700 calc(var(--w)*.033)/1 Syne;letter-spacing:.05em}.index{position:absolute;right:0;top:0;font:calc(var(--w)*.017)/1 Code;color:#888}h1{font:600 calc(var(--w)*.066)/1.12 Syne;letter-spacing:-.022em;margin:calc(var(--w)*.027) 0 0}.frame{position:absolute;left:calc((100% - var(--frame-w))/2);top:var(--frame-top);width:var(--frame-w);border:calc(var(--border)) solid #444;background:#050505}.screen{position:relative;width:100%;height:var(--screen-h);overflow:hidden}.screen img{display:block;position:absolute;width:100%;height:auto;top:var(--crop-top)}.corner{position:absolute;z-index:3;width:calc(var(--w)*.026);height:calc(var(--w)*.026);border-color:var(--accent);border-style:solid}.tl{left:calc(var(--w)*-.008);top:calc(var(--w)*-.008);border-width:2px 0 0 2px}.br{right:calc(var(--w)*-.008);bottom:calc(var(--w)*-.008);border-width:0 2px 2px 0}.duo h1{font-size:calc(var(--w)*.055)}.tablet h1{font-size:calc(var(--w)*.054)}.play h1{font-size:calc(var(--w)*.06)}.brand-art .heading{top:22%;left:9%;width:57%;right:auto}.brand-art h1{font-size:calc(var(--w)*.069);margin-top:calc(var(--w)*.028)}.brand-art .mark{position:absolute;left:68%;top:15%;width:24%;height:70%;object-fit:contain}.search .heading{top:11%;width:48%;left:8%;right:auto}.search h1{font-size:calc(var(--w)*.057)}.search .mark{position:absolute;left:8%;top:55%;width:26%;height:32%;object-fit:contain}.feature .heading{top:21%}.feature h1{font-size:calc(var(--w)*.061)}.feature .mark{left:68%;top:18%;height:66%}`;
writeFileSync(join(root,'pages/style.css'),css);
const profile=mkdtempSync('/tmp/telling-artboards-');const browser=spawn(chrome,['--headless','--disable-gpu','--no-first-run','--remote-debugging-port=0',`--user-data-dir=${profile}`],{stdio:'ignore'});
const portFile=join(profile,'DevToolsActivePort');for(let i=0;!existsSync(portFile);i++){if(i>200)throw Error('Chrome failed to start');await new Promise(r=>setTimeout(r,50));}
const [port,path]=readFileSync(portFile,'utf8').trim().split('\n');const ws=new WebSocket(`ws://127.0.0.1:${port}${path}`);await new Promise((resolve,reject)=>{ws.onopen=resolve;ws.onerror=reject});
let id=0;const pending=new Map();ws.onmessage=event=>{const m=JSON.parse(event.data);if(m.id&&pending.has(m.id)){const p=pending.get(m.id);clearTimeout(p.timer);pending.delete(m.id);m.error?p.reject(Error(JSON.stringify(m.error))):p.resolve(m.result)}};
function cdp(method,params={},sessionId){return new Promise((resolve,reject)=>{const key=++id;const timer=setTimeout(()=>{pending.delete(key);reject(Error(`Timed out: ${method}`))},15000);pending.set(key,{resolve,reject,timer});ws.send(JSON.stringify({id:key,method,params,...sessionId?{sessionId}:{}}))})}
const manifest=[];
function frame(source,target,{width,heightBudget,top,left}={}){
 const m=meta[source];if(!m)throw Error(`Missing source: ${source}`);
 const border=target.w*.0025;
 const maxInner=heightBudget*m.width/m.cropHeight;
 const outer=Math.min(width,maxInner+2*border);const inner=outer-2*border;
 const screenHeight=inner*m.cropHeight/m.width;
 const cropTop=-m.top*inner/m.width;
 const position=left!==undefined?`left:${left}px;`:'';
 return {html:`<div class="frame" style="--frame-w:${outer}px;--frame-top:${top}px;--border:${border}px;--screen-h:${screenHeight}px;--crop-top:${cropTop}px;${position}"><span class="corner tl"></span><div class="screen"><img src="../sources/${source}" alt="Actual Telling app screen"></div><span class="corner br"></span></div>`,outer,screenHeight};
}
async function render(t,shot,source){
 const creative=['header','search','feature'].includes(t.type);const name=creative?t.slot:shot.id;
 let content;
 if(creative){
  const title='See what\'s happening<br>in your app.';
  content=`<header class="heading"><div class="brand">TELLING</div><h1>${title}</h1></header><img class="mark" src="../sources/brand.png" alt="Telling mark">`;
  if(t.type==='search')content+=frame('phone-01-overview.png',t,{width:t.w*.31,heightBudget:t.h*.84,top:t.h*.08,left:t.w*.61}).html;
 }else{
  const top=t.h*(t.type==='tablet'?.205:t.type==='duo'?.185:.17);
  const budget=t.h*(t.type==='tablet'?.735:t.type==='duo'?.77:t.type==='play'?.76:.78);
  content=`<header class="heading"><div class="brand">TELLING</div><div class="index">${shot.id.slice(0,2)} / 05</div><h1>${shot.title}</h1></header>`+frame(source,t,{width:t.w*(t.type==='tablet'?.79:.86),heightBudget:budget,top}).html;
 }
 const file=join(root,`pages/${t.slot}-${name}.html`);writeFileSync(file,`<!doctype html><meta charset="utf-8"><link rel="stylesheet" href="style.css"><style>:root{--w:${t.w}px;--h:${t.h}px;--accent:${shot?.accent||'#F5F5F5'}}</style><body class="${t.type} ${creative?'brand-art':''}"><main class="canvas">${content}</main></body>`);
 const {targetId}=await cdp('Target.createTarget',{url:'about:blank'});const {sessionId}=await cdp('Target.attachToTarget',{targetId,flatten:true});await cdp('Emulation.setDeviceMetricsOverride',{width:t.w,height:t.h,deviceScaleFactor:1,mobile:false},sessionId);await cdp('Page.enable',{},sessionId);await cdp('Page.navigate',{url:`file://${file}`},sessionId);
 for(let i=0;;i++){const r=await cdp('Runtime.evaluate',{expression:`location.href===${JSON.stringify('file://'+file)}&&document.readyState==='complete'`,returnByValue:true},sessionId);if(r.result.value)break;if(i>200)throw Error('Page did not load');await new Promise(r=>setTimeout(r,25))}
 await cdp('Runtime.evaluate',{expression:'document.fonts.ready.then(()=>true)',awaitPromise:true,returnByValue:true},sessionId);
 const r=await cdp('Runtime.evaluate',{expression:`(()=>{const bad=[];for(const el of document.querySelectorAll('.heading h1,.brand,.index,.frame,.mark')){const r=el.getBoundingClientRect();if(r.left<0||r.top<0||r.right>${t.w}+1||r.bottom>${t.h}+1)bad.push('out-of-bounds:'+el.className)}for(const img of document.images){if(!img.naturalWidth)bad.push('image-not-loaded');if(img.closest('.screen')){const b=img.getBoundingClientRect();if(Math.abs(b.width/img.naturalWidth-b.height/img.naturalHeight)>.00001)bad.push('stretched-screen')}}const h=document.querySelector('h1').getBoundingClientRect(),f=document.querySelector('.frame')?.getBoundingClientRect();if(f&&h.bottom>f.top&&h.right>f.left)bad.push('heading-overlap');return {errors:bad,width:innerWidth,height:innerHeight}})()`,returnByValue:true},sessionId);
 if(r.result.value.errors.length)throw Error(JSON.stringify({file,...r.result.value}));
 const captured=await cdp('Page.captureScreenshot',{format:'png',clip:{x:0,y:0,width:t.w,height:t.h,scale:1}},sessionId);
 const output=`${t.id}/${name}-${t.w}x${t.h}.png`;writeFileSync(join(root,output),Buffer.from(captured.data,'base64'));await cdp('Target.closeTarget',{targetId});manifest.push({file:output,slot:t.slot,width:t.w,height:t.h,source:source||'existing-logo',geometry:r.result.value});console.log(`Rendered ${output}`);
}
try{
 for(const t of targets){
  if(['header','search','feature'].includes(t.type))await render(t,null,null);
  else for(const s of shots)await render(t,s,`${t.prefix}-${s.id}.png`);
 }
 writeFileSync(join(root,'manifest.json'),JSON.stringify(manifest,null,2));
 writeFileSync(join(root,'index.html'),`<!doctype html><meta charset="utf-8"><title>Telling · store artboards</title><style>body{background:#050505;color:#f5f5f5;margin:40px;font:16px sans-serif}h1{font-size:36px}p{max-width:800px;line-height:1.6;color:#aaa}.grid{display:grid;grid-template-columns:repeat(5,1fr);gap:18px}.grid img{width:100%}.one{grid-template-columns:1fr;max-width:1100px}h2{margin-top:60px}a{color:inherit}@media(max-width:900px){.grid{grid-template-columns:repeat(2,1fr)}.one{grid-template-columns:1fr}}</style><h1>Telling · store artboards</h1><p>Five populated screens. Original phone references, genuine iPad and Android captures. Exact slot sizes, no stretched screens. Funnels omitted.</p>${targets.map(t=>`<h2>${t.id}</h2><div class="grid ${['header','search','feature'].includes(t.type)?'one':''}">${manifest.filter(m=>m.slot===t.slot).map(m=>`<a href="${m.file}"><img src="${m.file}" alt="${m.file}"></a>`).join('')}</div>`).join('')}<p><a href="UPLOAD-GUIDE.md">Upload guide</a></p>`);
 console.log(`Completed ${manifest.length} artwork PNGs.`);
}finally{try{await cdp('Browser.close')}catch{}ws.close();browser.kill()}
