# 证件照编辑器 + 飞机大战

这是一个运行在NAS上的多功能应用中心。

## 功能

### 1. 飞机大战游戏
- 经典飞机大战游戏

### 2. 证件照编辑器（专业版）
- AI智能抠图
- 背景颜色更换
- 多种证件照尺寸（1寸、2寸、护照、身份证等）
- 精准裁剪框
- 圆角调节
- 多格式下载（JPG、PNG、WebP、BMP、GIF）

## 安装与运行

### 1. 安装Node.js
```bash
# 确保已安装Node.js
node -v
```

### 2. 启动服务器
```bash
cd server
node server.js
```

服务器将在 http://localhost:6060 启动

### 3. 访问应用
- 应用中心：http://localhost:6060
- 证件照编辑器：http://localhost:6060/formal/
- 飞机大战：http://localhost:6060/game/

## 目录结构

```
open/
├── index.html          # 应用中心主页面
├── server/             # Node.js服务器
│   └── server.js
├── formal/             # 证件照编辑器
│   └── index.html
├── game/               # 飞机大战游戏
│   └── 飞机大战.html
└── bg/                 # 背景图片/视频
```

## 技术栈

- **前端**：HTML5, CSS3, JavaScript (ES6+)
- **后端**：Node.js
- **AI抠图**：@imgly/background-removal (浏览器端)

## 注意事项

1. AI抠图功能需要首次加载模型（约40MB），之后会缓存
2. 建议使用现代浏览器（Chrome、Firefox、Edge）
3. 支持拖拽上传图片

## 许可证

MIT License
