// ==UserScript==
// @name          Konmeo22132
// @namespace     bypass.vip
// @version       1.0.0
// @description   Bypass
// @author        Konmeo22132
// @match         *://loot-link.com/*
// @match         *://linkvertise.com/*/*
// @downloadURL   https://raw.githubusercontent.com/bypass-vip/userscript/master/bypass-vip.user.js
// @updateURL     https://raw.githubusercontent.com/bypass-vip/userscript/master/bypass-vip.user.js
// @homepageURL   https://bypass.vip
// @icon          https://cdn.discordapp.com/avatars/887855290479935578/0bd76351f33c4eeedf799b368390b93c.webp
// @run-at        document-start
// ==/UserScript==

(async () => {
    const config = {
        time: 10,
        key: ''   
    };

    const originalCreateElement = document.createElement.bind(document);
    document.createElement = function(elementName) {
        const element = originalCreateElement(elementName);
        if (elementName.toLowerCase() === 'script') {
            element.setAttribute('type', 'text/plain');
        }
        return element;
    };

    document.documentElement.innerHTML = `<html><head><title>BYPASS.VIP USERSCRIPT</title><link rel="stylesheet" href="https:///bypass.vip/assets/css/styles.css"></head><body class="userscript"><h1>bypass.vip userscript</h1><h2>redirecting...</h2></body></html>`;

    const urlParams = new URLSearchParams(window.location.search);
    const redirectUrl = urlParams.get('redirect');

    if (redirectUrl && redirectUrl.includes('https://flux.li/android/external/main.php')) {
        document.body.innerHTML = `<h1>bypass.vip userscript</h1><h2>Fluxus implements some extra security checks to detect bypasses so we can't automatically redirect you.</h2><h3><a href="${redirectUrl}">Click here to redirect</a></h3>`;
        return;
    } else if (redirectUrl) {
        location.href = redirectUrl;
        return;
    }

    location.href = `https://bypass.vip/userscript.html?url=${encodeURIComponent(location.href)}&time=${config.time}&key=${config.key}`;
})();
