# 证件照编辑器 + 飞机大战

在线证件照制作工具，支持AI抠图、背景更换、多种证件照尺寸。

## ✨ 功能特点

### 证件照编辑器
- 🤖 **AI智能抠图** - 一键去除背景
- 🎨 **背景颜色** - 蓝色、白色、红色、渐变等10种
- 📐 **证件尺寸** - 1寸、2寸、护照、身份证、签证等20+种
- ✂️ **精准裁剪** - 固定尺寸裁剪框，支持圆角
- 📥 **多格式下载** - JPG、PNG、WebP、BMP、GIF

### 飞机大战
- 🎮 经典飞机大战小游戏

## 🚀 快速开始

### 方法一：直接下载使用

1. 点击 [Releases](https://github.com/Hong-11/photo-editor/releases) 下载最新版本
2. 解压到任意目录
3. 双击 `index.html` 打开（部分功能需要服务器）

### 方法二：使用Node.js服务器（推荐）

```bash
# 1. 克隆仓库
git clone https://github.com/Hong-11/photo-editor.git
cd photo-editor

# 2. 启动服务器
cd server
node server.js

# 3. 打开浏览器访问
# http://localhost:6060
```

### 方法三：使用Python服务器

```bash
# 克隆仓库
git clone https://github.com/Hong-11/photo-editor.git
cd photo-editor

# Python 3
python -m http.server 6060

# 或 Python 2
python -m SimpleHTTPServer 6060

# 打开浏览器访问 http://localhost:6060
```

## 📁 项目结构

```
photo-editor/
├── index.html          # 应用中心（入口页面）
├── server/
│   └── server.js       # Node.js服务器
├── formal/
│   └── index.html      # 证件照编辑器
├── game/
│   └── 飞机大战.html    # 飞机大战游戏
└── bg/                 # 背景素材
```

## 📖 使用说明

### 证件照编辑器

1. **上传照片** - 点击或拖拽上传
2. **开启AI抠图** - 勾选"启用AI抠图换背景"
3. **选择背景颜色** - 点击颜色块切换
4. **选择证件尺寸** - 下拉菜单选择规格
5. **调整裁剪框** - 拖拽移动，右下角缩放
6. **设置圆角** - 滑块调节（0°方形 ~ 45°圆形）
7. **下载** - 选择格式后点击下载

### AI抠图说明

首次使用需要加载AI模型（约40MB），加载后会缓存，之后使用无需再加载。

## 💻 浏览器兼容性

| 浏览器 | 支持 |
|--------|------|
| Chrome | ✅ 推荐 |
| Firefox | ✅ |
| Edge | ✅ |
| Safari | ✅ |
| IE | ❌ 不支持 |

## 🛠️ 技术栈

- **前端**: HTML5, CSS3, JavaScript (ES6+)
- **后端**: Node.js
- **AI抠图**: @imgly/background-removal

## 📝 更新日志

### v1.0.0 (2026-04-02)
- ✨ 证件照编辑器（AI抠图、背景更换）
- ✨ 多种证件照尺寸支持
- ✨ 精准裁剪框
- ✨ 飞机大战游戏

## 📄 开源协议

MIT License

## 🤝 贡献

欢迎提交Issue和Pull Request！

## ⭐ 支持

如果觉得有用，请给个Star ⭐
