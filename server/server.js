const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const https = require('https');
const url = require('url');

const PORT = 6060;
const GAME_PORT = 8888;
const STATIC_DIR = '/vol1/1000/open';
const STATIC_DIR_PHOTO = '/vol1/1000/open/photo';
const STATIC_DIR_GAME = '/vol1/1000/open/game';
const STATIC_DIR_BG = '/vol1/1000/open/bg';
const STATIC_DIR_MAJIANG = '/vol1/1000/open/majiang';
const TV_DIR = '/vol1/1000/open/tv';

let gameServerRunning = false;

function checkGameServer() {
    exec('lsof -i :' + GAME_PORT, (err, stdout) => {
        gameServerRunning = stdout.includes('python3') || stdout.includes('http.server');
    });
}

const server = http.createServer((req, res) => {
    if (req.method === 'GET' && req.url === '/api/status') {
        exec('lsof -i :' + GAME_PORT, (err, stdout) => {
            const running = stdout.includes('python3') || stdout.includes('http.server');
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ running }));
        });
        return;
    }

    if (req.method === 'POST' && req.url === '/api/start') {
        exec('lsof -i :' + GAME_PORT, (err, stdout) => {
            if (!stdout.includes('python3') && !stdout.includes('http.server')) {
                exec(`cd ${STATIC_DIR_GAME} && nohup python3 -m http.server ${GAME_PORT} > /dev/null 2>&1 &`);
            }
        });
        res.writeHead(200);
        res.end('OK');
        return;
    }

    if (req.method === 'POST' && req.url === '/api/stop') {
        exec(`lsof -t -i :${GAME_PORT} | xargs kill 2>/dev/null`);
        res.writeHead(200);
        res.end('OK');
        return;
    }

    // 上传背景图片
    if (req.method === 'POST' && req.url === '/api/upload-bg') {
        const chunks = [];
        req.on('data', chunk => chunks.push(chunk));
        req.on('end', () => {
            const buffer = Buffer.concat(chunks);
            // 解析multipart form data (简化版)
            const boundary = req.headers['content-type'].split('boundary=')[1];
            const parts = buffer.toString().split('--' + boundary);
            
            for (const part of parts) {
                if (part.includes('filename=')) {
                    const match = part.match(/filename="(.+)"/);
                    const filename = match ? match[1] : 'bg.jpg';
                    const ext = filename.split('.').pop();
                    const newFilename = 'background.' + ext;
                    
                    // 找到文件内容开始位置
                    const headerEnd = part.indexOf('\r\n\r\n');
                    const fileContent = part.substring(headerEnd + 4, part.length - 2);
                    const fileBuffer = Buffer.from(fileContent, 'binary');
                    
                    const bgPath = STATIC_DIR_BG + '/' + newFilename;
                    fs.writeFileSync(bgPath, fileBuffer);
                    
                    res.writeHead(200, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ success: true, filename: newFilename }));
                    return;
                }
            }
            res.writeHead(400);
            res.end('No file uploaded');
        });
        return;
    }

    // 获取背景图片列表
    if (req.method === 'GET' && req.url === '/api/bg-list') {
        const files = fs.readdirSync(STATIC_DIR_BG).filter(f => 
            ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.mp4', '.webm', '.ogg'].includes(path.extname(f).toLowerCase())
        );
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(files));
        return;
    }

    // 删除背景图片
    if (req.method === 'POST' && req.url.startsWith('/api/bg-delete?')) {
        const query = new URL(req.url, 'http://localhost').searchParams;
        const filename = query.get('file');
        if (filename) {
            const bgPath = STATIC_DIR_BG + '/' + filename;
            if (fs.existsSync(bgPath)) {
                fs.unlinkSync(bgPath);
            }
        }
        res.writeHead(200);
        res.end('OK');
        return;
    }

    if (req.method === 'GET' && req.url.startsWith('/api/proxy?')) {
        const query = new URL(req.url, 'http://localhost').searchParams;
        const targetUrl = query.get('url');
        if (!targetUrl) {
            res.writeHead(400);
            res.end('Missing url parameter');
            return;
        }
        
        const targetParsed = new URL(targetUrl);
        const options = {
            hostname: targetParsed.hostname,
            port: targetParsed.port || (targetParsed.protocol === 'https:' ? 443 : 80),
            path: targetParsed.pathname + targetParsed.search,
            method: 'GET',
            headers: {
                'User-Agent': 'Mozilla/5.0'
            }
        };
        
        const proxyReq = (targetParsed.protocol === 'https:' ? https : http).request(options, (proxyRes) => {
            res.writeHead(proxyRes.statusCode, {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/vnd.apple.mpegurl'
            });
            proxyRes.pipe(res);
        });
        
        proxyReq.on('error', (e) => {
            res.writeHead(500);
            res.end('Proxy error: ' + e.message);
        });
        
        proxyReq.end();
        return;
    }

    let filePath = req.url === '/' ? '/Center.html' : decodeURIComponent(req.url);
    let fullPath = STATIC_DIR + filePath;
    
    if (!fs.existsSync(fullPath)) {
        fullPath = STATIC_DIR_PHOTO + filePath;
    }
    
    if (!fs.existsSync(fullPath)) {
        fullPath = STATIC_DIR_BG + filePath;
    }
    
    if (!fs.existsSync(fullPath)) {
        fullPath = STATIC_DIR_MAJIANG + filePath;
    }
    
    if (!fs.existsSync(fullPath)) {
        fullPath = TV_DIR + filePath;
    }

    const ext = path.extname(fullPath).toLowerCase();
    const contentTypes = {
        '.html': 'text/html',
        '.js': 'application/javascript',
        '.mjs': 'application/javascript',
        '.css': 'text/css',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.gif': 'image/gif',
        '.webp': 'image/webp',
        '.mp4': 'video/mp4',
        '.webm': 'video/webm',
        '.ogg': 'video/ogg',
        '.apk': 'application/vnd.android.package-archive',
        '.json': 'application/json',
        '.wasm': 'application/wasm'
    };

    fs.readFile(fullPath, (err, data) => {
        if (err) {
            res.writeHead(404);
            res.end('Not Found');
            return;
        }
        res.writeHead(200, { 
            'Content-Type': contentTypes[ext] || 'text/plain',
            'Access-Control-Allow-Origin': '*'
        });
        res.end(data);
    });
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running at http://192.168.3.22:${PORT}/`);
});
