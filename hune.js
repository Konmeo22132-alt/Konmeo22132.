(function() {
    'use strict';

    const config = {
        themeColor: '#4a6bdf',
        bubbleIcon: 'https://raw.githubusercontent.com/Konmeo22132-alt/Konmeo22132./refs/heads/main/IMG_0005.webp',
        autoBtnText: 'Mua máy miễn phí',
        autoBtnLink: 'https://discord.gg/fHdf4yXpVE',
        discordLink: 'https://discord.gg/ajTPkjY6tv',
        youtubeLink: 'https://www.youtube.com/@huneee205'
    };

    const IS_VSPHONE = location.hostname.includes("cloud.vsphone.com");

    const root = document.createElement('div');
    const shadow = root.attachShadow({ mode: 'open' });
    document.body.appendChild(root);

    shadow.innerHTML = `
    <style>
        :host {
            all: initial;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        #bubble {
            position: fixed; top: 20px; left: 15px; width: 50px; height: 50px; border-radius: 50%;
            background: none;
            background-image: url('${config.bubbleIcon}');
            background-size: 150%;
            background-repeat: no-repeat;
            background-position: center;
            cursor: pointer;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15); z-index: 9999; border: 2px solid white;
            transition: transform 0.2s;
        }
        #bubble:hover { transform: scale(1.05); }

        #overlay {
            position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
            background: rgba(0,0,0,0.5);
            display: none; justify-content: center; align-items: center; z-index: 9998;
        }
        #modal {
            width: 400px;
            background: transparent;
            border-radius: 16px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.2);
            overflow: hidden;
            animation: fadeIn 0.3s ease;
            position: fixed;
            top: 50%; left: 50%;
            transform: translate(-50%, -50%);
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translate(-50%, -60%); }
            to   { opacity: 1; transform: translate(-50%, -50%); }
        }

        #modal-header {
            background: rgba(74,107,223,0.92); color: white;
            padding: 16px; font-size: 18px; font-weight: bold;
            display: flex; justify-content: space-between; align-items: center;
            border-radius: 16px 16px 0 0;
            position: relative; z-index: 2;
        }

        #modal-content {
            padding: 20px;
            background: rgba(255,255,255,0.03);
            border-radius: 0 0 16px 16px;
            position: relative; z-index: 2;
            min-height: 320px;
        }

        #message {
            min-height: 20px; color: #e74c3c; font-size: 14px;
            margin-bottom: 12px; text-align: center;
        }

        textarea {
            width: 100%; height: 120px;
            padding: 10px; border: 1px solid #ddd; border-radius: 6px;
            resize: none; font-family: monospace;
            margin-bottom: 12px;
            background: rgba(255,255,255,0.14);
            color: ${IS_VSPHONE ? "black" : "white"};
        }

        .button-group {
            display: flex; gap: 8px; margin-bottom: 12px;
        }

        button {
            flex: 1; padding: 10px;
            border: none; border-radius: 6px;
            cursor: pointer; font-weight: 500;
            transition: all 0.2s; color: #fff;
        }
        #submit { background: #28a745; }
        #submit:hover { background: #218838; transform: scale(1.04); }
        #logout { background: #dc3545; }
        #logout:hover { background: #c82333; transform: scale(1.04); }

        #auto-trial {
            width: 100%; background: rgba(243,156,18,0.85);
            color: white; font-weight: bold;
            border-radius: 6px;
        }
        #auto-trial:hover { background: #e67e22; }

        #modal-footer {
            text-align: center; padding: 12px;
            font-size: 12px; color: #fff;
            background: rgba(74,107,223,0.08);
            border-top: 1px solid rgba(240,242,245,0.18);
            border-radius: 0 0 16px 16px;
        }

        #modal video.bg-video {
            position: absolute;
            top: 0; left: 0; width: 100%; height: 100%;
            object-fit: cover; opacity: 1;
            border-radius: 16px; pointer-events: none;
            z-index: 1;
        }

        #close-modal { cursor: pointer; font-size: 24px; user-select: none; }

        #social-menu {
            position: absolute;
            bottom: 16px; right: 16px;
            display: flex; gap: 10px;
            z-index: 10;
        }
        .social-icon {
            width: 36px; height: 36px; border-radius: 50%;
            display: flex; justify-content: center; align-items: center;
            cursor: pointer; box-shadow: 0 2px 8px rgba(0,0,0,0.2);
            transition: transform 0.2s;
        }
        .social-icon img {
            width: 22px; height: 22px;
        }
        .social-icon.discord {
            background: #5865F2;
        }
        .social-icon.youtube {
            background: #FF0000;
        }
        .social-icon:hover {
            transform: scale(1.2);
        }
    </style>

    <div id="bubble" title="HuneIPA icon"></div>

    <div id="overlay">
        <div id="modal">
            <video class="bg-video" autoplay loop muted playsinline
                src="https://github.com/Konmeo22132-alt/Konmeo22132./raw/refs/heads/main/bd565dcc0a556add0b0a0ed6b26d686e.mp4">
            </video>

            <div id="modal-header">
                <span>HuneIPA extensions - Konmeo22132 dep chai</span>
                <span id="close-modal">×</span>
            </div>

            <div id="modal-content">
                <div id="message"></div>
                <textarea id="input" placeholder='Nhập nội dung Localstorage tại đây...'></textarea>
                <div class="button-group">
                    <button id="submit">${IS_VSPHONE ? "Copy Token" : "Đăng nhập"}</button>
                    <button id="logout">${IS_VSPHONE ? "Copy Userid" : "Đăng xuất"}</button>
                </div>

                <!-- Nút "Mua máy miễn phí" luôn hiển thị cho cả 2 site -->
                <button id="auto-trial">${config.autoBtnText}</button>

                <div id="social-menu">
                    <div class="social-icon discord" id="discord-btn" title="Discord">
                        <img src="https://raw.githubusercontent.com/Konmeo22132-alt/Konmeo22132./refs/heads/main/discord.png" alt="Discord">
                    </div>
                    <div class="social-icon youtube" id="youtube-btn" title="YouTube">
                        <img src="https://raw.githubusercontent.com/Konmeo22132-alt/Konmeo22132./refs/heads/main/yt.png" alt="YouTube">
                    </div>
                </div>
            </div>

            <div id="modal-footer">
                Youtube: HuneIPA<br>
                <small>Ver: 0.0.1</small>
            </div>
        </div>
    </div>
    `;

    const bubble = shadow.getElementById('bubble');
    const overlay = shadow.getElementById('overlay');
    const closeModal = shadow.getElementById('close-modal');
    const txtInput = shadow.getElementById('input');
    const btnSubmit = shadow.getElementById('submit');
    const btnLogout = shadow.getElementById('logout');
    const btnAuto = shadow.getElementById('auto-trial');
    const message = shadow.getElementById('message');

    const btnDiscord = shadow.getElementById('discord-btn');
    const btnYouTube = shadow.getElementById('youtube-btn');

    bubble.onclick = () => overlay.style.display = 'flex';
    closeModal.onclick = () => overlay.style.display = 'none';
    overlay.addEventListener('click', e => { if (e.target === overlay) overlay.style.display = 'none'; });

    if (!IS_VSPHONE) {
        // ugphone
        btnSubmit.onclick = () => {
            const raw = txtInput.value.trim();
            if (!raw) return message.innerText = 'Vui lòng nhập JSON hợp lệ!';
            try {
                const parsed = JSON.parse(raw);
                localStorage.clear();
                if (parsed.userFloatInfo) delete parsed.userFloatInfo;
                for (let key in parsed) {
                    localStorage.setItem(key, typeof parsed[key] === 'object' ? JSON.stringify(parsed[key]) : parsed[key]);
                }
                message.innerText = 'Vui lòng chờ...';
                setTimeout(() => window.location.reload(), 800);
            } catch (e) {
                message.innerText = 'JSON không hợp lệ!';
            }
        };

        btnLogout.onclick = () => {
            localStorage.clear();
            message.innerText = 'Đang đăng xuất...';
            setTimeout(() => window.location.reload(), 800);
        };

        btnAuto.onclick = () => window.open(config.autoBtnLink, '_blank');
    } else {
        // vsphone
        btnAuto.textContent = "Đăng xuất"; // log out khoi vs

        const token = localStorage.getItem("token") || "token k ton tai, vui long dang nhap";
        const userid = localStorage.getItem("userId") || "k tim thay usedid, vui long thu lai";
        txtInput.value = `Token: ${token}\nUserid: ${userid}`;

        btnSubmit.onclick = () => {
            navigator.clipboard.writeText(token).then(() => {
                message.innerText = "Da copy token";
            });
        };

        btnLogout.onclick = () => {
            navigator.clipboard.writeText(userid).then(() => {
                message.innerText = "Đã copy userid";
            });
        };

        btnAuto.onclick = () => {
            localStorage.removeItem('token');
            message.innerText = 'Đã đăng xuất';
            setTimeout(() => window.location.reload(), 500);
        };
    }

    btnDiscord.onclick = () => window.open(config.discordLink, '_blank');
    btnYouTube.onclick = () => window.open(config.youtubeLink, '_blank');
})();
