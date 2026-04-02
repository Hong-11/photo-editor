#!/bin/bash

echo "安装飞机大战游戏..."

mkdir -p /vol1/1000/open

cat > /vol1/1000/open/飞机大战.html << 'GAMEEOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>星际射击 - 打飞机游戏</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { background: #000; min-height: 100vh; display: flex; justify-content: center; align-items: center; font-family: 'Microsoft YaHei', sans-serif; overflow: hidden; }
        #gameContainer { position: relative; }
        canvas { display: block; border: 2px solid #00ff88; box-shadow: 0 0 30px rgba(0, 255, 136, 0.3); }
        #startScreen, #gameOverScreen { position: absolute; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0, 0, 0, 0.95); display: flex; flex-direction: column; justify-content: center; align-items: center; color: #fff; z-index: 10; }
        #gameOverScreen { display: none; }
        h1 { font-size: 48px; color: #00ff88; text-shadow: 0 0 20px #00ff88; margin-bottom: 20px; }
        .intro { max-width: 500px; text-align: center; padding: 20px; line-height: 1.8; color: #aaa; }
        .intro h2 { color: #00ff88; margin-bottom: 15px; }
        .intro ul { text-align: left; margin: 15px 0; }
        .intro li { margin: 8px 0; }
        .score-display { font-size: 36px; color: #ff0; margin: 20px 0; }
        button { padding: 15px 50px; font-size: 24px; background: linear-gradient(135deg, #00ff88, #00cc6a); border: none; color: #000; cursor: pointer; border-radius: 30px; margin-top: 20px; transition: transform 0.2s, box-shadow 0.2s; }
        button:hover { transform: scale(1.1); box-shadow: 0 0 30px rgba(0, 255, 136, 0.6); }
        #scoreBoard { position: absolute; top: 10px; left: 10px; color: #fff; font-size: 20px; z-index: 5; text-shadow: 2px 2px 4px #000; }
        #levelDisplay { position: absolute; top: 10px; right: 10px; color: #0ff; font-size: 20px; z-index: 5; text-shadow: 2px 2px 4px #000; }
        #powerDisplay { position: absolute; top: 35px; left: 10px; color: #ffaa00; font-size: 16px; z-index: 5; text-shadow: 2px 2px 4px #000; }
    </style>
</head>
<body>
    <div id="gameContainer">
        <canvas id="gameCanvas" width="600" height="700"></canvas>
        <div id="scoreBoard">生存时间: <span id="score">0</span>秒</div>
        <div id="levelDisplay">等级: <span id="level">1</span></div>
        <div id="powerDisplay">火力: <span id="power">1</span>档 | 僚机: <span id="wingman">0</span>架</div>
        
        <div id="startScreen">
            <h1>星际射击</h1>
            <div class="intro">
                <h2>游戏介绍</h2>
                <p>驾驶战机，消灭来犯的敌人！</p>
                <ul>
                    <li><strong>方向键 或 WASD</strong>：上下左右移动</li>
                    <li><strong>空格键</strong>：发射子弹</li>
                    <li><strong>蓝色运输机</strong>：增加火力（最高3档）</li>
                    <li><strong>红色运输机</strong>：获得僚机支援</li>
                    <li><strong>生存时间</strong>：越长等级越高</li>
                </ul>
                <p style="color: #ff6b6b;">警告：被敌机撞击游戏结束！</p>
            </div>
            <button onclick="startGame()">开始游戏</button>
        </div>
        
        <div id="gameOverScreen">
            <h1>游戏结束</h1>
            <div class="score-display">生存时间: <span id="finalScore">0</span>秒</div>
            <div style="color: #aaa; margin-bottom: 20px;">最高生存时间: <span id="highScore">0</span>秒</div>
            <button onclick="startGame()">再玩一次</button>
            <button onclick="showStartScreen()">返回主页</button>
        </div>
    </div>

    <script>
        const canvas = document.getElementById('gameCanvas');
        const ctx = canvas.getContext('2d');
        
        let gameRunning = false;
        let score = 0;
        let startTime = 0;
        let level = 1;
        let highScore = localStorage.getItem('airplaneHighScore') || 0;
        let frames = 0;
        
        let firePower = 1;
        
        const player = {
            x: 275, y: 600, width: 50, height: 60, speed: 7,
            bullets: [], bulletCooldown: 0
        };
        
        const wingmen = [];
        
        let enemies = [];
        let enemyBullets = [];
        let particles = [];
        
        const keys = { left: false, right: false, up: false, down: false, space: false };
        
        function drawPlayer() {
            ctx.fillStyle = '#00ff88';
            ctx.beginPath();
            ctx.moveTo(player.x + player.width / 2, player.y);
            ctx.lineTo(player.x + player.width, player.y + player.height);
            ctx.lineTo(player.x + player.width / 2, player.y + player.height - 15);
            ctx.lineTo(player.x, player.y + player.height);
            ctx.closePath();
            ctx.fill();
            
            ctx.fillStyle = '#ff6600';
            ctx.beginPath();
            ctx.moveTo(player.x + player.width / 2 - 8, player.y + player.height - 10);
            ctx.lineTo(player.x + player.width / 2, player.y + player.height + 10);
            ctx.lineTo(player.x + player.width / 2 + 8, player.y + player.height - 10);
            ctx.closePath();
            ctx.fill();
            
            ctx.fillStyle = '#00aaff';
            ctx.beginPath();
            ctx.arc(player.x + player.width / 2, player.y + 25, 10, 0, Math.PI * 2);
            ctx.fill();
        }
        
        function drawWingmen() {
            wingmen.forEach(wm => {
                ctx.fillStyle = '#00cc66';
                ctx.beginPath();
                ctx.moveTo(wm.x + wm.width / 2, wm.y);
                ctx.lineTo(wm.x + wm.width, wm.y + wm.height);
                ctx.lineTo(wm.x + wm.width / 2, wm.y + wm.height - 10);
                ctx.lineTo(wm.x, wm.y + wm.height);
                ctx.closePath();
                ctx.fill();
            });
        }
        
        function drawBullet(bullet) {
            if (bullet.angle) {
                ctx.fillStyle = '#ffff00';
                ctx.save();
                ctx.translate(bullet.x, bullet.y);
                ctx.rotate(bullet.angle);
                ctx.fillRect(-2, -8, 4, 16);
                ctx.restore();
            } else {
                ctx.fillStyle = bullet.isEnemy ? '#ff4444' : '#ffff00';
                ctx.fillRect(bullet.x - 2, bullet.y, 4, bullet.isEnemy ? 10 : 15);
            }
        }
        
        function drawEnemy(enemy) {
            if (enemy.type === 'blue') {
                ctx.fillStyle = '#2288ff';
                ctx.beginPath();
                ctx.ellipse(enemy.x + enemy.width/2, enemy.y + enemy.height/2, enemy.width/2, enemy.height/2, 0, 0, Math.PI * 2);
                ctx.fill();
                ctx.fillStyle = '#1155cc';
                ctx.beginPath();
                ctx.ellipse(enemy.x + enemy.width/2, enemy.y + enemy.height/2, enemy.width/2 - 8, enemy.height/2 - 8, 0, 0, Math.PI * 2);
                ctx.fill();
                ctx.fillStyle = '#88bbff';
                ctx.fillRect(enemy.x + 10, enemy.y + 8, enemy.width - 20, 8);
            } else if (enemy.type === 'red') {
                ctx.fillStyle = '#ff4444';
                ctx.beginPath();
                ctx.ellipse(enemy.x + enemy.width/2, enemy.y + enemy.height/2, enemy.width/2, enemy.height/2, 0, 0, Math.PI * 2);
                ctx.fill();
                ctx.fillStyle = '#cc2222';
                ctx.beginPath();
                ctx.ellipse(enemy.x + enemy.width/2, enemy.y + enemy.height/2, enemy.width/2 - 8, enemy.height/2 - 8, 0, 0, Math.PI * 2);
                ctx.fill();
                ctx.fillStyle = '#ff8888';
                ctx.fillRect(enemy.x + 10, enemy.y + 8, enemy.width - 20, 8);
            } else if (enemy.type === 'general') {
                ctx.fillStyle = '#9933ff';
                ctx.beginPath();
                ctx.moveTo(enemy.x + enemy.width / 2, enemy.y);
                ctx.lineTo(enemy.x + enemy.width, enemy.y + enemy.height);
                ctx.lineTo(enemy.x + enemy.width / 2, enemy.y + enemy.height - 10);
                ctx.lineTo(enemy.x, enemy.y + enemy.height);
                ctx.closePath();
                ctx.fill();
                ctx.fillStyle = '#ffcc00';
                ctx.beginPath();
                ctx.arc(enemy.x + enemy.width/2, enemy.y + enemy.height/2, 8, 0, Math.PI*2);
                ctx.fill();
                ctx.fillStyle = '#fff';
                ctx.fillRect(enemy.x + 12, enemy.y + 18, 10, 10);
                ctx.fillRect(enemy.x + 28, enemy.y + 18, 10, 10);
            } else {
                const gradient = ctx.createLinearGradient(enemy.x, enemy.y, enemy.x + enemy.width, enemy.y + enemy.height);
                gradient.addColorStop(0, '#ff4444');
                gradient.addColorStop(1, '#aa0000');
                ctx.fillStyle = gradient;
                ctx.beginPath();
                ctx.moveTo(enemy.x + enemy.width / 2, enemy.y + enemy.height);
                ctx.lineTo(enemy.x + enemy.width, enemy.y);
                ctx.lineTo(enemy.x + enemy.width / 2, enemy.y + 15);
                ctx.lineTo(enemy.x, enemy.y);
                ctx.closePath();
                ctx.fill();
                ctx.fillStyle = '#fff';
                ctx.fillRect(enemy.x + 15, enemy.y + 25, 8, 8);
                ctx.fillRect(enemy.x + 27, enemy.y + 25, 8, 8);
                ctx.fillStyle = '#ff0000';
                ctx.fillRect(enemy.x + 17, enemy.y + 27, 4, 4);
                ctx.fillRect(enemy.x + 29, enemy.y + 27, 4, 4);
            }
        }
        
        function drawParticles() {
            particles.forEach((p, index) => {
                ctx.fillStyle = `rgba(${p.r}, ${p.g}, ${p.b}, ${p.life})`;
                ctx.beginPath();
                ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
                ctx.fill();
                if (gameRunning) {
                    p.x += p.vx;
                    p.y += p.vy;
                    p.life -= 0.02;
                    if (p.life <= 0) particles.splice(index, 1);
                }
            });
        }
        
        function createExplosion(x, y, color) {
            for (let i = 0; i < 20; i++) {
                particles.push({
                    x: x, y: y,
                    vx: (Math.random() - 0.5) * 10,
                    vy: (Math.random() - 0.5) * 10,
                    size: Math.random() * 5 + 2,
                    life: 1,
                    r: color.r, g: color.g, b: color.b
                });
            }
        }
        
        function update() {
            if (!gameRunning) return;
            
            if (keys.left && player.x > 0) player.x -= player.speed;
            if (keys.right && player.x < canvas.width - player.width) player.x += player.speed;
            if (keys.up && player.y > 0) player.y -= player.speed;
            if (keys.down && player.y < canvas.height - player.height) player.y += player.speed;
            
            if (wingmen.length > 0) {
                wingmen[0].x = player.x - 50;
                wingmen[0].y = player.y + 20;
                if (wingmen.length > 1) {
                    wingmen[1].x = player.x + player.width + 10;
                    wingmen[1].y = player.y + 20;
                }
            }
            
            if (keys.space && player.bulletCooldown <= 0) {
                const cooldown = firePower === 3 ? 24 : (firePower === 2 ? 30 : 40);
                player.bullets.push({ x: player.x + player.width / 2, y: player.y, angle: 0 });
                
                if (firePower === 2) {
                    player.bullets.push({ x: player.x + player.width / 2, y: player.y, angle: -0.04 });
                    player.bullets.push({ x: player.x + player.width / 2, y: player.y, angle: 0.04 });
                }
                
                if (firePower >= 3) {
                    player.bullets.push({ x: player.x + player.width / 2, y: player.y, angle: -0.075 });
                    player.bullets.push({ x: player.x + player.width / 2, y: player.y, angle: 0.075 });
                }
                
                if (wingmen.length > 0) {
                    player.bullets.push({ x: wingmen[0].x + 2, y: wingmen[0].y, angle: -0.25 });
                    player.bullets.push({ x: wingmen[0].x + wingmen[0].width - 2, y: wingmen[0].y, angle: -0.25 });
                }
                if (wingmen.length > 1) {
                    player.bullets.push({ x: wingmen[1].x + 2, y: wingmen[1].y, angle: 0.25 });
                    player.bullets.push({ x: wingmen[1].x + wingmen[1].width - 2, y: wingmen[1].y, angle: 0.25 });
                }
                player.bulletCooldown = cooldown;
            }
            if (player.bulletCooldown > 0) player.bulletCooldown--;
            
            player.bullets.forEach((bullet, index) => {
                if (bullet.angle) {
                    bullet.x += Math.sin(bullet.angle) * 5;
                    bullet.y -= Math.cos(bullet.angle) * 5;
                } else {
                    bullet.y -= 5;
                }
                if (bullet.y < 0 || bullet.x < 0 || bullet.x > canvas.width) {
                    player.bullets.splice(index, 1);
                }
            });
            
            const bulletSpeed = 1.5;
            enemyBullets.forEach((bullet, index) => {
                bullet.y += bulletSpeed;
                if (bullet.y > canvas.height) {
                    enemyBullets.splice(index, 1);
                }
                
                player.bullets.forEach((pBullet, pIndex) => {
                    const dx = bullet.x - pBullet.x;
                    const dy = bullet.y - pBullet.y;
                    if (Math.abs(dx) < 10 && Math.abs(dy) < 10) {
                        enemyBullets.splice(index, 1);
                        player.bullets.splice(pIndex, 1);
                        createExplosion(bullet.x, bullet.y, {r: 255, g: 255, b: 0});
                    }
                });
                
                if (bullet.x > player.x && bullet.x < player.x + player.width &&
                    bullet.y > player.y && bullet.y < player.y + player.height) {
                    enemyBullets.splice(index, 1);
                    if (wingmen.length > 0) {
                        wingmen.pop();
                        document.getElementById('wingman').textContent = wingmen.length;
                        createExplosion(player.x + player.width / 2, player.y + player.height / 2, {r: 255, g: 200, b: 0});
                    } else {
                        createExplosion(player.x + player.width / 2, player.y + player.height / 2, {r: 0, g: 255, b: 136});
                        gameOver();
                    }
                }
            });
            
            const spawnRate = Math.max(15, 50 - level * 2);
            if (frames % spawnRate === 0) {
                const rand = Math.random();
                let enemyType = 'normal';
                if (rand < 0.3) enemyType = 'general';
                
                let showBlue = firePower < 3;
                let showRed = wingmen.length < 2;
                let transportType = null;
                
                if (showBlue && showRed) {
                    if (Math.random() < 0.5) transportType = 'blue';
                    else transportType = 'red';
                } else if (showBlue) {
                    transportType = 'blue';
                } else if (showRed) {
                    transportType = 'red';
                }
                
                if (transportType) {
                    enemies.push({
                        x: Math.random() * (canvas.width - 50),
                        y: -40,
                        width: 60,
                        height: 40,
                        speed: 0.3,
                        type: transportType
                    });
                } else {
                    enemies.push({
                        x: Math.random() * (canvas.width - 50),
                        y: -40,
                        width: 50,
                        height: 50,
                        speed: 0.3,
                        type: enemyType,
                        hp: enemyType === 'general' ? 3 : 1,
                        shootTimer: Math.random() * 80
                    });
                }
            }
            
            enemies.forEach((enemy, index) => {
                enemy.y += enemy.speed;
                
                enemy.shootTimer--;
                if (enemy.shootTimer <= 0) {
                    enemyBullets.push({
                        x: enemy.x + enemy.width / 2,
                        y: enemy.y + enemy.height,
                        isEnemy: true
                    });
                    enemy.shootTimer = 120 + Math.random() * 80;
                }
                
                if (enemy.y > canvas.height) {
                    enemies.splice(index, 1);
                }
                
                player.bullets.forEach((bullet, bIndex) => {
                    if (bullet.x > enemy.x && bullet.x < enemy.x + enemy.width &&
                        bullet.y > enemy.y && bullet.y < enemy.y + enemy.height) {
                        player.bullets.splice(bIndex, 1);
                        
                        if (enemy.type === 'blue' || enemy.type === 'red') {
                            createExplosion(enemy.x + enemy.width / 2, enemy.y + enemy.height / 2, 
                                enemy.type === 'blue' ? {r: 0, g: 100, b: 255} : {r: 255, g: 50, b: 50});
                            
                            if (enemy.type === 'blue') {
                                firePower = Math.min(3, firePower + 1);
                                document.getElementById('power').textContent = firePower;
                            } else if (enemy.type === 'red') {
                                if (wingmen.length < 2) {
                                    wingmen.push({
                                        x: player.x - 50,
                                        y: player.y + 20,
                                        width: player.width / 5,
                                        height: player.height / 5 * 0.8
                                    });
                                    document.getElementById('wingman').textContent = wingmen.length;
                                }
                            }
                            
                            enemies.splice(index, 1);
                            level = Math.floor(frames / 300) + 1;
                            document.getElementById('level').textContent = level;
                        } else {
                            enemy.hp--;
                            createExplosion(bullet.x, bullet.y, {r: 255, g: 200, b: 0});
                            if (enemy.hp <= 0) {
                                createExplosion(enemy.x + enemy.width / 2, enemy.y + enemy.height / 2, {r: 150, g: 50, b: 255});
                                enemies.splice(index, 1);
                                level = Math.floor(frames / 300) + 1;
                                document.getElementById('level').textContent = level;
                            }
                        }
                    }
                });
                
                if (enemy.x < player.x + player.width && enemy.x + enemy.width > player.x &&
                    enemy.y < player.y + player.height && enemy.y + enemy.height > player.y) {
                    if (wingmen.length > 0) {
                        wingmen.pop();
                        document.getElementById('wingman').textContent = wingmen.length;
                        createExplosion(player.x + player.width / 2, player.y + player.height / 2, {r: 255, g: 200, b: 0});
                        enemies.splice(index, 1);
                    } else {
                        createExplosion(player.x + player.width / 2, player.y + player.height / 2, {r: 0, g: 255, b: 136});
                        gameOver();
                    }
                }
            });
            
            frames++;
            
            if (frames % 60 === 0) {
                score = Math.floor((Date.now() - startTime) / 1000);
                document.getElementById('score').textContent = score;
            }
        }
        
        function draw() {
            ctx.fillStyle = '#000000';
            ctx.fillRect(0, 0, canvas.width, canvas.height);
            
            if (gameRunning) {
                drawPlayer();
                drawWingmen();
                player.bullets.forEach(drawBullet);
                enemyBullets.forEach(drawBullet);
                enemies.forEach(drawEnemy);
                drawParticles();
            }
            
            requestAnimationFrame(() => { update(); draw(); });
        }
        
        function startGame() {
            document.getElementById('startScreen').style.display = 'none';
            document.getElementById('gameOverScreen').style.display = 'none';
            
            player.x = 275;
            player.bullets = [];
            wingmen.length = 0;
            enemies = [];
            enemyBullets = [];
            particles = [];
            score = 0;
            level = 1;
            firePower = 1;
            startTime = Date.now();
            frames = 0;
            
            document.getElementById('score').textContent = '0';
            document.getElementById('level').textContent = '1';
            document.getElementById('power').textContent = '1';
            document.getElementById('wingman').textContent = '0';
            
            gameRunning = true;
        }
        
        function gameOver() {
            gameRunning = false;
            const survivalTime = Math.floor((Date.now() - startTime) / 1000);
            if (survivalTime > highScore) {
                highScore = survivalTime;
                localStorage.setItem('airplaneHighScore', highScore);
            }
            document.getElementById('finalScore').textContent = survivalTime;
            document.getElementById('highScore').textContent = highScore;
            document.getElementById('gameOverScreen').style.display = 'flex';
        }
        
        function showStartScreen() {
            document.getElementById('gameOverScreen').style.display = 'none';
            document.getElementById('startScreen').style.display = 'flex';
        }
        
        document.addEventListener('keydown', (e) => {
            if (e.key === 'ArrowLeft' || e.key === 'a' || e.key === 'A') keys.left = true;
            if (e.key === 'ArrowRight' || e.key === 'd' || e.key === 'D') keys.right = true;
            if (e.key === 'ArrowUp' || e.key === 'w' || e.key === 'W') keys.up = true;
            if (e.key === 'ArrowDown' || e.key === 's' || e.key === 'S') keys.down = true;
            if (e.key === ' ') { keys.space = true; e.preventDefault(); }
        });
        
        document.addEventListener('keyup', (e) => {
            if (e.key === 'ArrowLeft' || e.key === 'a' || e.key === 'A') keys.left = false;
            if (e.key === 'ArrowRight' || e.key === 'd' || e.key === 'D') keys.right = false;
            if (e.key === 'ArrowUp' || e.key === 'w' || e.key === 'W') keys.up = false;
            if (e.key === 'ArrowDown' || e.key === 's' || e.key === 'S') keys.down = false;
            if (e.key === ' ') keys.space = false;
        });
        
        draw();
    </script>
</body>
</html>
GAMEEOF

echo "安装完成！"
echo "访问 http://你的飞牛IP/飞机大战.html 即可游戏"
