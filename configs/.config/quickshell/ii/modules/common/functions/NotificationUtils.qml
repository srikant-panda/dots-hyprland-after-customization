pragma Singleton
import Quickshell

Singleton {
    id: root
    /**
     * @param { string } summary 
     * @returns { string }
     */
    function findSuitableMaterialSymbol(summary = "") {
        const defaultType = 'chat';
        if (summary.length === 0) return defaultType;

        const keywordsToTypes = {
            'reboot': 'restart_alt',
            'record': 'screen_record',
            'battery': 'power',
            'power': 'power',
            'screenshot': 'screenshot_monitor',
            'welcome': 'waving_hand',
            'time': 'scheduleb',
            'installed': 'download',
            'configuration reloaded': 'reset_wrench',
            'unable': 'question_mark',
            "couldn't": 'question_mark',
            'config': 'reset_wrench',
            'update': 'update',
            'ai response': 'neurology',
            'control': 'settings',
            'upsca': 'compare',
            'music': 'queue_music',
            'install': 'deployed_code_update',
            'input': 'keyboard_alt',
            'preedit': 'keyboard_alt',
            'startswith:file': 'folder_copy', // Declarative startsWith check
        };

        const lowerSummary = summary.toLowerCase();

        for (const [keyword, type] of Object.entries(keywordsToTypes)) {
            if (keyword.startsWith('startswith:')) {
                const startsWithKeyword = keyword.replace('startswith:', '');
                if (lowerSummary.startsWith(startsWithKeyword)) {
                    return type;
                }
            } else if (lowerSummary.includes(keyword)) {
                return type;
            }
        }

        return defaultType;
    }

    /**
     * @param { number | string | Date } timestamp 
     * @returns { string }
     */
    function getFriendlyNotifTimeString(timestamp) {
        if (!timestamp) return '';
        const messageTime = new Date(timestamp);
        const now = new Date();
        const diffMs = now.getTime() - messageTime.getTime();

        // Less than 1 minute
        if (diffMs < 60000)
            return 'Now';

        // Same day - show relative time
        if (messageTime.toDateString() === now.toDateString()) {
            const diffMinutes = Math.floor(diffMs / 60000);
            const diffHours = Math.floor(diffMs / 3600000);

            if (diffHours > 0) {
                return `${diffHours}h`;
            } else {
                return `${diffMinutes}m`;
            }
        }

        // Yesterday
        if (messageTime.toDateString() === new Date(now.getTime() - 86400000).toDateString())
            return 'Yesterday';

        // Older dates
        return Qt.formatDateTime(messageTime, "MMMM dd");
    }

    function processNotificationBody(body, appName) {
        let processedBody = body
        
        // Clean Chromium-based browsers notifications - remove first line
        if (appName) {
            const lowerApp = appName.toLowerCase()
            const chromiumBrowsers = [
                "brave", "chrome", "chromium", "vivaldi", "opera", "microsoft edge"
            ]

            if (chromiumBrowsers.some(name => lowerApp.includes(name))) {
                const lines = body.split('\n\n')

                if (lines.length > 1 && lines[0].startsWith('<a')) {
                    processedBody = lines.slice(1).join('\n\n')
                }
            }
        }

        processedBody = processedBody.replace(/<img/gi, '\n\n<img');
        
        return processedBody
    }

    function isIgnoredYear(val) {
        return ["2023", "2024", "2025", "2026", "2027"].indexOf(val) !== -1;
    }

    /**
     * Auto-detects OTP / verification code in notification text.
     * @param { string } text
     * @returns { string } extracted code or empty string
     */
    function extractOtp(text) {
        if (!text) return "";
        const clean = text.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim();

        // Google G-123456
        const mGoogle = clean.match(/\b[Gg]-?([0-9]{4,8})\b/);
        if (mGoogle) return mGoogle[1];

        // 123-456 pattern when preceded/followed by otp/code
        const mHyphen = clean.match(/\b(?:otp|code|verification|passcode)\b[^\d]{1,20}([0-9]{3})-([0-9]{3})\b/i);
        if (mHyphen) return mHyphen[1] + mHyphen[2];

        // Label before: 'otp is 123456', 'verification code: 123456', 'login code 1234'
        const mLabel = clean.match(/\b(?:otp|one[- ]time[- ]password|passcode|verification\s+code|security\s+code|login\s+code|secret\s+code|auth\s+code|code|pin)\b\s*(?:is\s*)?[:=-]?\s*(?:is\s*)?([0-9]{4,8})\b/i);
        if (mLabel && !isIgnoredYear(mLabel[1])) return mLabel[1];

        // Word code: 'Uber code is 1234'
        const mWordCode = clean.match(/\b\w+\s+code\s*(?:is\s*)?[:=-]?\s*(?:is\s*)?([0-9]{4,8})\b/i);
        if (mWordCode && !isIgnoredYear(mWordCode[1])) return mWordCode[1];

        // Digits before: '123456 is your OTP / verification code'
        const mDigitsBefore = clean.match(/\b([0-9]{4,8})\b\s+is\s+(?:your\s+)?(?:\w+\s+){0,2}(?:otp|code|passcode|pin|verification|password|secret)\b/i);
        if (mDigitsBefore && !isIgnoredYear(mDigitsBefore[1])) return mDigitsBefore[1];

        // Action match: 'enter 123456 to verify'
        const mAction = clean.match(/\b(?:enter|use|input)\s+([0-9]{4,8})\s+(?:to\s+verify|to\s+confirm|for\s+verification|as\s+your|to\s+login)\b/i);
        if (mAction && !isIgnoredYear(mAction[1])) return mAction[1];

        // General OTP mention in message, search for standalone 4-8 digit numbers excluding bank accounts/amounts
        if (/\b(?:otp|verification|verify|passcode|two-step|2-step|authentication)\b/i.test(clean)) {
            const digitRegex = /\b([0-9]{4,8})\b/g;
            let match;
            const badTerms = ["a/c", "acct", "account", "card", "ending", "inr", "rs", "rs.", "$", "usd", "eur"];
            while ((match = digitRegex.exec(clean)) !== null) {
                const val = match[1];
                const start = match.index;
                const prefix = clean.substring(Math.max(0, start - 20), start).toLowerCase();
                let isBad = false;
                for (let i = 0; i < badTerms.length; i++) {
                    if (prefix.indexOf(badTerms[i]) !== -1) {
                        isBad = true;
                        break;
                    }
                }
                if (isBad || isIgnoredYear(val)) continue;
                return val;
            }
        }
        return "";
    }
}
