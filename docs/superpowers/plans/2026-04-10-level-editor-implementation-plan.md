# 关卡编辑器 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `editor.html` — a standalone, zero-dependency level editor for 弹弹河豚 MVP.

**Architecture:** Single HTML file with embedded CSS and JS. Canvas-based rendering. Edit mode and Play mode share the same canvas but use different render/update loops. Export generates a JS object copyable into `index.html`, plus JSON save/load.

**Tech Stack:** Pure HTML5 Canvas 2D, vanilla JS, no external libraries.

---

## File Map

```
pufferfish-mvp/
  index.html          ← 游戏（不修改）
  editor.html         ← 编辑器（新，全部自包含）
```

---

## Task 1: 骨架 — HTML结构 + 初始状态

**Files:**
- Create: `editor.html`

- [ ] **Step 1: 创建 HTML 骨架**

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>弹弹河豚 - 关卡编辑器</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { background: #1a1a1a; overflow: hidden; font-family: Arial, sans-serif; }
  canvas { display: block; position: fixed; top: 0; left: 0; }
  /* 工具栏 */
  #toolbar {
    position: fixed; top: 0; left: 0; right: 0; height: 44px;
    background: #222; border-bottom: 2px solid #0af;
    display: flex; align-items: center; padding: 0 10px; gap: 4px; z-index: 10;
  }
  .toolbar-group { display: flex; gap: 4px; align-items: center; }
  .toolbar-sep { width: 1px; height: 28px; background: #555; margin: 0 6px; }
  .tool-btn {
    padding: 5px 10px; background: #333; color: #ccc; border: 1px solid #555;
    border-radius: 4px; cursor: pointer; font-size: 13px;
  }
  .tool-btn:hover { background: #444; color: #fff; }
  .tool-btn.active { background: #0af; color: #000; border-color: #0af; font-weight: bold; }
  .tool-btn.danger { background: #a22; color: #fff; border-color: #a22; }
  .tool-btn.primary { background: #0a6; color: #fff; border-color: #0a6; }
  /* 模态框 */
  #modal {
    display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.7);
    z-index: 100; justify-content: center; align-items: center;
  }
  #modal.show { display: flex; }
  #modal-content {
    background: #222; border: 2px solid #0af; border-radius: 8px;
    padding: 20px; min-width: 500px; max-width: 700px; color: #fff;
  }
  #modal-content h3 { margin-bottom: 12px; color: #0af; }
  #export-code {
    width: 100%; height: 300px; background: #111; color: #0f0;
    border: 1px solid #444; border-radius: 4px; font-family: monospace;
    font-size: 12px; padding: 8px; resize: none;
  }
  #modal-actions { display: flex; gap: 8px; margin-top: 12px; justify-content: flex-end; }
</style>
</head>
<body>
<canvas id="canvas"></canvas>
<div id="toolbar">
  <div class="toolbar-group">
    <button class="tool-btn active" id="btn-select" data-tool="select">🖱️ 选择</button>
    <button class="tool-btn" id="btn-circle" data-tool="circle">🔴 圆形</button>
    <button class="tool-btn" id="btn-rect" data-tool="rect">🟦 方块</button>
    <button class="tool-btn" id="btn-start" data-tool="start">🟢 起点</button>
    <button class="tool-btn" id="btn-end" data-tool="end">🔵 终点</button>
  </div>
  <div class="toolbar-sep"></div>
  <div class="toolbar-group">
    <button class="tool-btn" id="btn-undo">↩️ 撤销</button>
    <button class="tool-btn" id="btn-redo">↪️ 重做</button>
  </div>
  <div class="toolbar-sep"></div>
  <div class="toolbar-group">
    <button class="tool-btn primary" id="btn-play">▶️ 试玩</button>
    <button class="tool-btn" id="btn-export">📋 导出</button>
    <button class="tool-btn" id="btn-load">📂 加载</button>
  </div>
</div>
<div id="modal">
  <div id="modal-content">
    <h3>复制关卡代码</h3>
    <textarea id="export-code" readonly></textarea>
    <div id="modal-actions">
      <button class="tool-btn" id="modal-close">关闭</button>
    </div>
  </div>
</div>
<script>
// === 状态 ===
const state = {
  worldWidth: 2200,
  worldHeight: 750,
  fishScale: 1.0,
  objects: [],
  history: [],
  historyIndex: -1,
  mode: 'edit',       // 'edit' | 'play'
  selectedId: null,
  activeTool: 'select',
  viewOffset: { x: 0, y: 0 },
  viewScale: 1.0,
  dragState: null,    // { type, id?, startX, startY, origX, origY, corner? }
  nextId: 1,
  // 试玩模式
  playFish: null,
  playInput: null,
  playCamera: null,
};
// === 入口 ===
const canvas = document.getElementById('canvas');
const ctx = canvas.getContext('2d');
function resizeCanvas() { /* 全屏自适应 */ }
resizeCanvas();
window.addEventListener('resize', resizeCanvas);
function init() { render(); }
init();
</script>
</body>
</html>
```

- [ ] **Step 2: 确认文件创建成功，在浏览器打开无报错**

Open: `file:///C:/Users/jack/.qclaw/workspace/pufferfish-mvp/editor.html`

- [ ] **Step 3: 提交**

```bash
git add editor.html
git commit -m "feat: 关卡编辑器骨架 - HTML结构 + 初始状态"
```

---

## Task 2: 画布渲染 — 网格 + 世界边界 + 物体

**Files:**
- Modify: `editor.html`（render 函数部分）

- [ ] **Step 1: 实现 resizeCanvas + 世界坐标转换函数**

```javascript
function resizeCanvas() {
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;
}

function screenToWorld(sx, sy) {
  return {
    x: (sx - canvas.width / 2) / state.viewScale + state.viewOffset.x,
    y: (sy - canvas.height / 2) / state.viewScale + state.viewOffset.y
  };
}

function worldToScreen(wx, wy) {
  return {
    x: (wx - state.viewOffset.x) * state.viewScale + canvas.width / 2,
    y: (wy - state.viewOffset.y) * state.viewScale + canvas.height / 2
  };
}
```

- [ ] **Step 2: 实现 render() 函数**

```javascript
function render() {
  ctx.fillStyle = '#111';
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  const ox = canvas.width / 2 - state.viewOffset.x * state.viewScale;
  const oy = canvas.height / 2 - state.viewOffset.y * state.viewScale;

  ctx.save();
  ctx.translate(ox, oy);
  ctx.scale(state.viewScale, state.viewScale);

  drawGrid();
  drawWorldBounds();
  drawObjects();

  ctx.restore();
  requestAnimationFrame(render);
}

function drawGrid() {
  const gs = 50; // 网格大小
  const sx = state.viewOffset.x - canvas.width / state.viewScale / 2;
  const sy = state.viewOffset.y - canvas.height / state.viewScale / 2;
  const ex = sx + canvas.width / state.viewScale;
  const ey = sy + canvas.height / state.viewScale;
  ctx.strokeStyle = 'rgba(255,255,255,0.06)';
  ctx.lineWidth = 0.5;
  for (let x = Math.floor(sx / gs) * gs; x <= ex; x += gs) {
    ctx.beginPath(); ctx.moveTo(x, sy); ctx.lineTo(x, ey); ctx.stroke();
  }
  for (let y = Math.floor(sy / gs) * gs; y <= ey; y += gs) {
    ctx.beginPath(); ctx.moveTo(sx, y); ctx.lineTo(ex, y); ctx.stroke();
  }
}

function drawWorldBounds() {
  ctx.strokeStyle = 'rgba(0,100,200,0.5)';
  ctx.lineWidth = 2;
  ctx.strokeRect(0, 0, state.worldWidth, state.worldHeight);
}

function drawObjects() {
  for (const obj of state.objects) {
    ctx.save();
    if (obj.id === state.selectedId) {
      ctx.shadowColor = '#0af';
      ctx.shadowBlur = 10;
    }
    if (obj.type === 'circle') {
      ctx.fillStyle = '#f44';
      ctx.beginPath();
      ctx.arc(obj.x, obj.y, obj.radius, 0, Math.PI * 2);
      ctx.fill();
    } else if (obj.type === 'rect') {
      ctx.fillStyle = 'rgba(0,80,180,0.25)';
      ctx.fillRect(obj.x, obj.y, obj.w, obj.h);
      ctx.strokeStyle = 'rgba(0,100,200,0.4)';
      ctx.lineWidth = 2;
      ctx.strokeRect(obj.x, obj.y, obj.w, obj.h);
    } else if (obj.type === 'start') {
      ctx.fillStyle = '#0f0';
      ctx.beginPath();
      ctx.arc(obj.x, obj.y, 15, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = '#fff';
      ctx.font = '10px Arial';
      ctx.textAlign = 'center';
      ctx.fillText('START', obj.x, obj.y + 25);
    } else if (obj.type === 'end') {
      ctx.fillStyle = '#08f';
      ctx.beginPath();
      ctx.arc(obj.x, obj.y, obj.radius || 40, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = '#fff';
      ctx.font = '10px Arial';
      ctx.textAlign = 'center';
      ctx.fillText('END', obj.x, obj.y + (obj.radius || 40) + 15);
    }
    ctx.restore();
  }
}
```

- [ ] **Step 3: 刷新浏览器，验证：网格背景 + 蓝色边框 + 无物体时空白画面**

Expected: 灰色/深色画布，中央有世界蓝色边框，空白

- [ ] **Step 4: 提交**

```bash
git add editor.html
git commit -m "feat: 画布渲染 - 网格 + 世界边界 + 物体"
```

---

## Task 3: 放置物体 — 圆形 + 方块 + 起点 + 终点

**Files:**
- Modify: `editor.html`（事件 + 状态逻辑）

- [ ] **Step 1: 保存/恢复历史（撤销重做基础）**

```javascript
function saveHistory() {
  // 裁剪历史（保留当前位置之后）
  state.history = state.history.slice(0, state.historyIndex + 1);
  // 深拷贝 objects
  state.history.push(JSON.parse(JSON.stringify(state.objects)));
  state.historyIndex = state.history.length - 1;
  // 限制历史条数
  if (state.history.length > 50) {
    state.history.shift();
    state.historyIndex--;
  }
}

function undo() {
  if (state.historyIndex > 0) {
    state.historyIndex--;
    state.objects = JSON.parse(JSON.stringify(state.history[state.historyIndex]));
    state.selectedId = null;
  }
}

function redo() {
  if (state.historyIndex < state.history.length - 1) {
    state.historyIndex++;
    state.objects = JSON.parse(JSON.stringify(state.history[state.historyIndex]));
    state.selectedId = null;
  }
}
```

- [ ] **Step 2: 找到物体的点击检测函数**

```javascript
function hitTest(wx, wy) {
  // 从后往前（后放的在上层）
  for (let i = state.objects.length - 1; i >= 0; i--) {
    const o = state.objects[i];
    if (o.type === 'circle') {
      const dx = wx - o.x, dy = wy - o.y;
      if (Math.sqrt(dx*dx + dy*dy) <= o.radius + 4) return o;
    } else if (o.type === 'rect') {
      if (wx >= o.x && wx <= o.x + o.w && wy >= o.y && wy <= o.y + o.h) return o;
    } else if (o.type === 'start' || o.type === 'end') {
      const dx = wx - o.x, dy = wy - o.y;
      const r = o.type === 'end' ? (o.radius || 40) : 15;
      if (Math.sqrt(dx*dx + dy*dy) <= r + 4) return o;
    }
  }
  return null;
}
```

- [ ] **Step 3: 实现鼠标事件**

```javascript
canvas.addEventListener('mousedown', e => {
  if (state.mode !== 'edit') return;
  const wp = screenToWorld(e.clientX, e.clientY);

  if (state.activeTool === 'select') {
    const hit = hitTest(wp.x, wp.y);
    if (hit) {
      state.selectedId = hit.id;
      state.dragState = {
        type: 'move',
        id: hit.id,
        startX: wp.x,
        startY: wp.y,
        origX: hit.x,
        origY: hit.y,
        origW: hit.w,
        origH: hit.h,
      };
    } else {
      state.selectedId = null;
    }
  } else {
    // 放置模式
    if (state.activeTool === 'start') {
      // 删除旧的起点
      state.objects = state.objects.filter(o => o.type !== 'start');
      state.objects.push({ id: 's' + state.nextId++, type: 'start', x: wp.x, y: wp.y });
    } else if (state.activeTool === 'end') {
      state.objects = state.objects.filter(o => o.type !== 'end');
      state.objects.push({ id: 'e' + state.nextId++, type: 'end', x: wp.x, y: wp.y, radius: 40 });
    } else if (state.activeTool === 'circle') {
      state.objects.push({ id: 'c' + state.nextId++, type: 'circle', x: wp.x, y: wp.y, radius: 30 });
    } else if (state.activeTool === 'rect') {
      state.objects.push({ id: 'r' + state.nextId++, type: 'rect', x: wp.x, y: wp.y, w: 80, h: 20 });
    }
    saveHistory();
  }
});

canvas.addEventListener('mousemove', e => {
  if (state.mode !== 'edit' || !state.dragState) return;
  const wp = screenToWorld(e.clientX, e.clientY);
  const ds = state.dragState;

  if (ds.type === 'move') {
    const obj = state.objects.find(o => o.id === ds.id);
    if (obj) {
      obj.x = ds.origX + (wp.x - ds.startX);
      obj.y = ds.origY + (wp.y - ds.startY);
    }
  } else if (ds.type === 'pan') {
    state.viewOffset.x = ds.origOffsetX - (wp.x - ds.startX);
    state.viewOffset.y = ds.origOffsetY - (wp.y - ds.startY);
  }
});

canvas.addEventListener('mouseup', e => {
  if (state.dragState && state.dragState.type === 'move') {
    saveHistory();
  }
  state.dragState = null;
});

canvas.addEventListener('mousedown', e => {
  if (e.button === 1 || (e.button === 0 && state.activeTool === 'select' && !hitTest(screenToWorld(e.clientX, e.clientY)))) {
    // 中键或空地处平移
    if (state.mode === 'edit') {
      const wp = screenToWorld(e.clientX, e.clientY);
      state.dragState = {
        type: 'pan',
        startX: wp.x, startY: wp.y,
        origOffsetX: state.viewOffset.x, origOffsetY: state.viewOffset.y,
      };
    }
  }
});
```

- [ ] **Step 4: 实现滚轮缩放**

```javascript
canvas.addEventListener('wheel', e => {
  e.preventDefault();
  const factor = e.deltaY > 0 ? 0.9 : 1.1;
  state.viewScale = Math.max(0.1, Math.min(5, state.viewScale * factor));
}, { passive: false });
```

- [ ] **Step 5: 实现工具栏按钮切换 + 撤销重做**

```javascript
document.querySelectorAll('.tool-btn[data-tool]').forEach(btn => {
  btn.addEventListener('click', () => {
    state.activeTool = btn.dataset.tool;
    document.querySelectorAll('.tool-btn[data-tool]').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
  });
});

document.getElementById('btn-undo').addEventListener('click', undo);
document.getElementById('btn-redo').addEventListener('click', redo);
```

- [ ] **Step 6: 实现 Delete 删除选中物体**

```javascript
document.addEventListener('keydown', e => {
  if (e.key === 'Delete' || e.key === 'Backspace') {
    if (state.selectedId && state.mode === 'edit') {
      state.objects = state.objects.filter(o => o.id !== state.selectedId);
      state.selectedId = null;
      saveHistory();
    }
  }
  if (e.ctrlKey && e.key === 'z') undo();
  if (e.ctrlKey && (e.key === 'y' || (e.shiftKey && e.key === 'Z'))) redo();
});
```

- [ ] **Step 7: 初始化历史**

```javascript
// 在 init() 之前调用
saveHistory();
```

- [ ] **Step 8: 测试 — 点击放置圆形/方块/起点/终点，拖拽移动，撤销重做，Delete删除**

Expected: 所有放置和移动操作正常，撤销重做工作

- [ ] **Step 9: 提交**

```bash
git add editor.html
git commit -m "feat: 放置物体 + 拖拽移动 + 撤销重做"
```

---

## Task 4: 导出功能 — 复制代码 + JSON保存

**Files:**
- Modify: `editor.html`（导出逻辑）

- [ ] **Step 1: 实现导出代码生成**

```javascript
function generateExportCode() {
  const startObj = state.objects.find(o => o.type === 'start');
  const endObj = state.objects.find(o => o.type === 'end');
  const circles = state.objects.filter(o => o.type === 'circle').map(o => ({
    x: Math.round(o.x), y: Math.round(o.y), radius: o.radius
  }));
  const rects = state.objects.filter(o => o.type === 'rect').map(o => ({
    type: 'rect', x: Math.round(o.x), y: Math.round(o.y), w: Math.round(o.w), h: Math.round(o.h)
  }));

  const lines = [];
  lines.push('const level = {');
  if (startObj) {
    lines.push(`  startX: ${Math.round(startObj.x)}, startY: ${Math.round(startObj.y)},`);
  }
  if (endObj) {
    lines.push(`  endX: ${Math.round(endObj.x)}, endY: ${Math.round(endObj.y)}, endRadius: ${endObj.radius || 40},`);
  }
  lines.push('  obstacles: [');
  for (const c of circles) {
    lines.push(`    { x: ${c.x}, y: ${c.y}, radius: ${c.radius} },`);
  }
  for (const r of rects) {
    lines.push(`    { type: 'rect', x: ${r.x}, y: ${r.y}, w: ${r.w}, h: ${r.h} },`);
  }
  lines.push('  ]');
  lines.push('};');
  return lines.join('\n');
}

function exportJSON() {
  return JSON.stringify({
    worldWidth: state.worldWidth,
    worldHeight: state.worldHeight,
    fishScale: state.fishScale,
    objects: state.objects,
  }, null, 2);
}
```

- [ ] **Step 2: 实现模态框 + 导出按钮**

```javascript
document.getElementById('btn-export').addEventListener('click', () => {
  const code = generateExportCode();
  const ta = document.getElementById('export-code');
  ta.value = code;
  document.getElementById('modal').classList.add('show');
});

document.getElementById('modal-close').addEventListener('click', () => {
  document.getElementById('modal').classList.remove('show');
});

document.getElementById('modal').addEventListener('click', e => {
  if (e.target === document.getElementById('modal')) {
    document.getElementById('modal').classList.remove('show');
  }
});

// 在模态框actions里加两个按钮（通过innerHTML重新渲染actions区域）
// 复制代码按钮
const modalActions = document.getElementById('modal-actions');
modalActions.innerHTML = `
  <button class="tool-btn" id="modal-copy">📋 复制代码</button>
  <button class="tool-btn" id="modal-save-json">💾 保存JSON</button>
  <button class="tool-btn" id="modal-close2">关闭</button>
`;
document.getElementById('modal-copy').addEventListener('click', () => {
  const ta = document.getElementById('export-code');
  ta.select();
  navigator.clipboard.writeText(ta.value).then(() => {
    alert('已复制到剪贴板！');
  });
});
document.getElementById('modal-save-json').addEventListener('click', () => {
  const blob = new Blob([exportJSON()], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = 'level.json'; a.click();
  URL.revokeObjectURL(url);
});
document.getElementById('modal-close2').addEventListener('click', () => {
  document.getElementById('modal').classList.remove('show');
});
```

- [ ] **Step 3: 实现加载JSON**

```javascript
document.getElementById('btn-load').addEventListener('click', () => {
  const input = document.createElement('input');
  input.type = 'file';
  input.accept = '.json';
  input.onchange = e => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = ev => {
      try {
        const data = JSON.parse(ev.target.result);
        state.worldWidth = data.worldWidth || 2200;
        state.worldHeight = data.worldHeight || 750;
        state.fishScale = data.fishScale || 1.0;
        state.objects = data.objects || [];
        state.selectedId = null;
        state.nextId = 1;
        for (const o of state.objects) {
          const num = parseInt(o.id.replace(/[^0-9]/g, '')) || 0;
          if (num >= state.nextId) state.nextId = num + 1;
        }
        saveHistory();
        alert('关卡已加载！');
      } catch (err) {
        alert('加载失败：' + err.message);
      }
    };
    reader.readAsText(file);
  };
  input.click();
});
```

- [ ] **Step 4: 测试 — 放置几个物体，点击导出，验证生成的代码格式正确**

Expected: 弹出模态框显示代码，可复制，可下载JSON；加载JSON可还原关卡

- [ ] **Step 5: 提交**

```bash
git add editor.html
git commit -m "feat: 导出功能 - 复制代码 + JSON保存/加载"
```

---

## Task 5: 试玩模式

**Files:**
- Modify: `editor.html`（试玩逻辑）

- [ ] **Step 1: 实现试玩状态的 fish/input/camera 初始化**

```javascript
function enterPlayMode() {
  const startObj = state.objects.find(o => o.type === 'start');
  const endObj = state.objects.find(o => o.type === 'end');
  if (!startObj) { alert('请先放置起点！'); return; }
  if (!endObj) { alert('请先放置终点！'); return; }

  state.mode = 'play';
  state.playFish = {
    x: startObj.x, y: startObj.y,
    vx: 0, vy: 0,
    radius: 20 * state.fishScale,
    scale: 1.0,
    maxInflate: 1.0 * state.fishScale,
    inflate: 0,
    rotation: -Math.PI / 2,
    rotSpeed: 6,
    hp: 100, maxHp: 100,
    invincible: 0,
    launchVel: 900, friction: 0.992,
    waveAmp: 0, waveOffset: 0,
    launchScale: 1.0, launchTime: 0,
  };
  state.playInput = { mouseDown: false, mouseX: 0, mouseY: 0, clicking: false, lastClick: false };
  state.playCamera = { x: startObj.x, y: startObj.y };
  document.getElementById('toolbar').style.display = 'none';
}

function exitPlayMode() {
  state.mode = 'edit';
  state.playFish = null;
  state.playInput = null;
  state.playCamera = null;
  document.getElementById('toolbar').style.display = '';
}
```

- [ ] **Step 2: 实现试玩模式的 checkCollision（从游戏代码复制）**

```javascript
function playCheckCollision() {
  const f = state.playFish;
  const r = f.radius * f.scale;
  const isInflatingMax = f.scale >= 1.8 * 0.95;
  const endObj = state.objects.find(o => o.type === 'end');
  const endR = endObj ? (endObj.radius || 40) : 40;

  for (const o of state.objects) {
    if (o.type === 'rect') {
      const cx = Math.max(o.x, Math.min(f.x, o.x + o.w));
      const cy = Math.max(o.y, Math.min(f.y, o.y + o.h));
      const dx = f.x - cx, dy = f.y - cy;
      const dist = Math.sqrt(dx*dx + dy*dy);
      if (dist < r) {
        const overlap = r - dist;
        const nx = dist > 0 ? dx/dist : 1, ny = dist > 0 ? dy/dist : 0;
        f.x += nx * overlap; f.y += ny * overlap;
        const speed = Math.sqrt(f.vx*f.vx + f.vy*f.vy);
        f.vx = nx * speed * 0.8; f.vy = ny * speed * 0.8;
      }
    } else if (o.type === 'circle') {
      const dx = f.x - o.x, dy = f.y - o.y;
      const dist = Math.sqrt(dx*dx + dy*dy);
      if (dist < r + o.radius) {
        const overlap = r + o.radius - dist;
        const nx = dx/dist, ny = dy/dist;
        f.x += nx * overlap; f.y += ny * overlap;
        const speed = Math.sqrt(f.vx*f.vx + f.vy*f.vy);
        f.vx = nx * speed * 0.8; f.vy = ny * speed * 0.8;
        if (f.invincible <= 0 && !isInflatingMax) {
          f.hp -= 10;
          f.invincible = 0.5;
          if (f.hp <= 0) { f.hp = 0; }
        }
      }
    }
  }
  // 终点检测
  if (endObj) {
    const dx = f.x - endObj.x, dy = f.y - endObj.y;
    if (Math.sqrt(dx*dx + dy*dy) < endR) {
      exitPlayMode();
      alert('🎉 通关！');
    }
  }
}
```

- [ ] **Step 3: 实现试玩模式的 update + render**

```javascript
function playUpdate(dt) {
  const f = state.playFish, inp = state.playInput;
  if (!f) return;
  if (f.invincible > 0) f.invincible -= dt;

  const released = inp.lastClick && !inp.clicking;
  inp.lastClick = inp.clicking;

  const maxScale = 1.8;
  const inflateRate = (maxScale - 1) / 1.0;
  const deflateRate = (maxScale - 1) / 0.5;

  if (inp.clicking) {
    f.scale = Math.min(f.scale + inflateRate * dt, maxScale);
    f.rotation += f.rotSpeed * dt;
  } else {
    f.scale = Math.max(f.scale - deflateRate * dt, 1.0);
  }

  f.inflate = (f.scale - 1) / (maxScale - 1) * f.maxInflate;

  if (released && f.inflate > 0.2) {
    const power = f.inflate / f.maxInflate;
    const dir = f.rotation + Math.PI;
    f.vx = Math.cos(dir) * f.launchVel * power;
    f.vy = Math.sin(dir) * f.launchVel * power;
    f.launchScale = f.scale;
    f.launchTime = 0;
    f.waveAmp = power * 25;
    f.inflate = 0;
    f.scale = 1.0;
  }

  if (f.launchScale > 1.01 && f.launchTime < 2.0) {
    f.launchTime += dt;
    const progress = Math.min(f.launchTime / 2.0, 1.0);
    if (!inp.clicking) {
      f.scale = f.launchScale * (1 - progress) + 1.0 * progress;
    } else {
      f.launchScale = 1.0; f.launchTime = 2.0;
    }
  }

  if (f.waveAmp > 0) {
    f.waveOffset += dt * 30;
    const wave = Math.sin(f.waveOffset) * f.waveAmp;
    const speed = Math.sqrt(f.vx*f.vx + f.vy*f.vy);
    if (speed > 10) {
      f.x += (-f.vy / speed) * wave * dt;
      f.y += (f.vx / speed) * wave * dt;
    }
    f.waveAmp *= 0.97;
    if (f.waveAmp < 0.5) f.waveAmp = 0;
  }

  f.vx *= f.friction; f.vy *= f.friction;
  const speed = Math.sqrt(f.vx*f.vx + f.vy*f.vy);
  if (speed < 5) { f.vx = 0; f.vy = 0; }

  if (speed > 10 && !inp.clicking) {
    const targetRot = Math.atan2(f.vy, f.vx);
    let diff = targetRot - f.rotation;
    while (diff > Math.PI) diff -= Math.PI * 2;
    while (diff < -Math.PI) diff += Math.PI * 2;
    f.rotation += diff * 5 * dt;
  }

  f.x += f.vx * dt; f.y += f.vy * dt;

  // 世界边界
  const m = f.radius * f.scale;
  if (f.x < m) { f.x = m; f.vx = Math.abs(f.vx) * 0.8; }
  if (f.x > state.worldWidth - m) { f.x = state.worldWidth - m; f.vx = -Math.abs(f.vx) * 0.8; }
  if (f.y < m) { f.y = m; f.vy = Math.abs(f.vy) * 0.8; }
  if (f.y > state.worldHeight - m) { f.y = state.worldHeight - m; f.vy = -Math.abs(f.vy) * 0.8; }

  // 镜头平滑跟随
  state.playCamera.x += (f.x - state.playCamera.x) * 0.08;
  state.playCamera.y += (f.y - state.playCamera.y) * 0.08;
}

function playRender() {
  const f = state.playFish;
  const cam = state.playCamera;
  const ox = canvas.width / 2 - cam.x;
  const oy = canvas.height / 2 - cam.y;

  ctx.fillStyle = '#001030';
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  ctx.save();
  ctx.translate(ox, oy);

  // 世界边界
  ctx.strokeStyle = 'rgba(0,100,200,0.4)'; ctx.lineWidth = 2;
  ctx.strokeRect(0, 0, state.worldWidth, state.worldHeight);

  // 物体
  for (const o of state.objects) {
    if (o.type === 'circle') {
      ctx.fillStyle = '#f00';
      ctx.beginPath(); ctx.arc(o.x, o.y, o.radius, 0, Math.PI*2); ctx.fill();
    } else if (o.type === 'rect') {
      ctx.fillStyle = 'rgba(0,80,180,0.25)';
      ctx.fillRect(o.x, o.y, o.w, o.h);
      ctx.strokeStyle = 'rgba(0,100,200,0.4)'; ctx.lineWidth = 2;
      ctx.strokeRect(o.x, o.y, o.w, o.h);
    }
  }

  // 终点
  const endObj = state.objects.find(o => o.type === 'end');
  if (endObj) {
    ctx.fillStyle = '#08f';
    ctx.beginPath();
    ctx.arc(endObj.x, endObj.y, endObj.radius || 40, 0, Math.PI*2);
    ctx.fill();
  }

  // 鱼
  if (f) {
    ctx.save();
    ctx.translate(f.x, f.y);
    ctx.rotate(f.rotation);
    const r = f.radius * f.scale;
    if (f.invincible > 0 && Math.floor(f.invincible * 10) % 2 === 0) ctx.globalAlpha = 0.5;
    ctx.fillStyle = f.hp <= 0 ? '#888' : '#0f0';
    ctx.beginPath(); ctx.ellipse(0, 0, r*1.3, r, 0, 0, Math.PI*2); ctx.fill();
    ctx.beginPath();
    ctx.moveTo(-r*0.8, 0); ctx.lineTo(-r*1.8, -r*0.5); ctx.lineTo(-r*1.8, r*0.5); ctx.closePath(); ctx.fill();
    ctx.restore();
  }

  ctx.restore();

  // HP条
  if (f) {
    ctx.fillStyle = '#333';
    ctx.fillRect(20, 20, 120, 12);
    ctx.fillStyle = f.hp > 30 ? '#0f0' : '#f00';
    ctx.fillRect(20, 20, 120 * f.hp / f.maxHp, 12);
    ctx.fillStyle = '#fff';
    ctx.font = '12px Arial';
    ctx.fillText(`HP: ${Math.round(f.hp)}`, 24, 30);
    ctx.fillText('ESC退出试玩', 20, 50);
  }
}
```

- [ ] **Step 4: 修改主 render 循环支持试玩模式**

在 render() 中:
```javascript
function render() {
  if (state.mode === 'play') {
    playRender();
  } else {
    // 原有编辑渲染
    ...
  }
  requestAnimationFrame(render);
}

// 试玩输入事件
canvas.addEventListener('mousedown', e => {
  if (state.mode === 'play') {
    state.playInput.mouseDown = true;
    state.playInput.clicking = true;
  }
});
canvas.addEventListener('mouseup', e => {
  if (state.mode === 'play') {
    state.playInput.mouseDown = false;
    state.playInput.clicking = false;
  }
});

// 游戏循环
let lastPlayTime = 0;
function gameLoop(ts) {
  if (state.mode === 'play') {
    const dt = Math.min((ts - lastPlayTime) / 1000, 0.05);
    lastPlayTime = ts;
    playUpdate(dt);
    playCheckCollision();
  }
  requestAnimationFrame(gameLoop);
}
requestAnimationFrame(ts => { lastPlayTime = ts; gameLoop(ts); });

// 试玩按钮
document.getElementById('btn-play').addEventListener('click', enterPlayMode);

// ESC退出
document.addEventListener('keydown', e => {
  if (e.key === 'Escape' && state.mode === 'play') exitPlayMode();
});
```

- [ ] **Step 5: 测试 — 放置起点终点，放置几个圆形障碍，点击试玩，操作鱼到达终点**

Expected: 试玩模式正常，碰撞有效，可到达终点弹出通关提示，ESC返回编辑

- [ ] **Step 6: 提交**

```bash
git add editor.html
git commit -m "feat: 试玩模式 - 内置游戏验证"
```

---

## Task 6: 世界尺寸拖拽调整

**Files:**
- Modify: `editor.html`

- [ ] **Step 1: 在 mouseDown 中检测是否点击在世界边缘区域**

```javascript
// 在 screenToWorld 函数之后添加
function hitWorldEdge(wx, wy) {
  const margin = 8;
  const w = state.worldWidth, h = state.worldHeight;
  // 四边
  if (Math.abs(wx - 0) < margin) return 'left';
  if (Math.abs(wx - w) < margin) return 'right';
  if (Math.abs(wy - 0) < margin) return 'top';
  if (Math.abs(wy - h) < margin) return 'bottom';
  // 四角
  if (Math.abs(wx - 0) < margin && Math.abs(wy - 0) < margin) return 'tl';
  if (Math.abs(wx - w) < margin && Math.abs(wy - 0) < margin) return 'tr';
  if (Math.abs(wx - 0) < margin && Math.abs(wy - h) < margin) return 'bl';
  if (Math.abs(wx - w) < margin && Math.abs(wy - h) < margin) return 'br';
  return null;
}
```

- [ ] **Step 2: 在 mouseDown 事件中处理边缘拖拽**

```javascript
// 在 state.activeTool === 'select' 的分支里，hitTest 之后:
const edge = hitWorldEdge(wp.x, wp.y);
if (edge) {
  state.dragState = {
    type: 'resize',
    edge,
    startX: wp.x,
    startY: wp.y,
    origW: state.worldWidth,
    origH: state.worldHeight,
  };
}
```

- [ ] **Step 3: 在 mousemove 中处理 resize 拖拽**

```javascript
// 在 ds.type === 'pan' 的 if 之后添加:
if (ds.type === 'resize') {
  const dx = wp.x - ds.startX;
  const dy = wp.y - ds.startY;
  if (ds.edge === 'right') state.worldWidth = Math.max(400, ds.origW + dx);
  if (ds.edge === 'bottom') state.worldHeight = Math.max(300, ds.origH + dy);
  if (ds.edge === 'br') {
    state.worldWidth = Math.max(400, ds.origW + dx);
    state.worldHeight = Math.max(300, ds.origH + dy);
  }
}
```

- [ ] **Step 4: 测试 — 拖拽画布右边缘和下边缘，验证世界尺寸变化**

- [ ] **Step 5: 提交**

```bash
git add editor.html
git commit -m "feat: 世界尺寸拖拽调整"
```

---

## Task 7: 鱼大小滑块

**Files:**
- Modify: `editor.html`（添加滑块 UI）

- [ ] **Step 1: 在 toolbar 里添加鱼大小滑块**

在 toolbar HTML 中，工具栏右侧添加：
```html
<div class="toolbar-sep"></div>
<div class="toolbar-group" style="color:#ccc;font-size:13px;">
  🐡 鱼大小
  <input type="range" id="fish-scale-slider" min="50" max="200" value="100"
    style="width:100px;vertical-align:middle;">
  <span id="fish-scale-label">1.0x</span>
</div>
```

- [ ] **Step 2: 实现滑块逻辑**

```javascript
const slider = document.getElementById('fish-scale-slider');
const label = document.getElementById('fish-scale-label');
slider.addEventListener('input', () => {
  state.fishScale = slider.value / 100;
  label.textContent = state.fishScale.toFixed(1) + 'x';
});
```

- [ ] **Step 3: 测试 — 拖动滑块，在试玩模式验证鱼大小变化**

- [ ] **Step 4: 提交**

```bash
git add editor.html
git commit -m "feat: 鱼大小等比缩放滑块"
```

---

## Task 8: 验收测试 + 推送到仓库

- [ ] **Step 1: 验收检查清单**

1. 编辑器 `editor.html` 可直接在浏览器打开（file:// 或本地服务器）
2. 可放置圆形、方块、起点、终点
3. 可拖拽移动物体
4. 撤销（Ctrl+Z）/ 重做（Ctrl+Y）正常工作
5. Delete 删除选中物体
6. 滚轮缩放画布
7. 拖拽世界边缘调整尺寸
8. 试玩模式：鱼可以弹射，圆形障碍造成伤害，方块不造成伤害
9. 到达终点弹出通关提示，ESC 返回编辑
10. 导出代码格式正确，粘贴到游戏后可运行
11. JSON 保存/加载正常
12. 鱼大小滑块影响试玩时的鱼尺寸

- [ ] **Step 2: 推送到 feature/level-starry-river**

```bash
git add editor.html
git commit -m "feat: 关卡编辑器 MVP 完成 - Phase1+2"
git push origin feature/level-starry-river
```
