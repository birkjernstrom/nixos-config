.pragma library

function escape(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

function inline(text, c) {
    const codes = [];
    let s = text.replace(/`([^`]+)`/g, (_, code) => {
        codes.push(code);
        return `\u0000${codes.length - 1}\u0000`;
    });
    s = escape(s);
    s = s.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, (_, label, url) => `<a href="${url}" style="color:${c.link}; text-decoration:none; font-weight:600;">${label}</a>`);
    s = s.replace(/(^|[\s(])(https?:\/\/[^\s<)]*[^\s<).,;:!?])/g, (_, pre, url) => `${pre}<a href="${url}" style="color:${c.link}; text-decoration:none; font-weight:600;">${url.replace(/^https?:\/\//, "")}</a>`);
    s = s.replace(/\*\*([^*]+)\*\*|__([^_]+)__/g, (_, a, b) => `<span style="font-weight:600; color:${c.strong};">${a ?? b}</span>`);
    s = s.replace(/(^|[^*\w])\*([^*\s][^*]*)\*/g, "$1<i>$2</i>");
    s = s.replace(/(^|\W)_([^_\s][^_]*)_(?=\W|$)/g, "$1<i>$2</i>");
    s = s.replace(/~~([^~]+)~~/g, "<s>$1</s>");
    return s.replace(/\u0000(\d+)\u0000/g, (_, i) => `<span style="font-family:'${c.mono}'; background-color:${c.codeBg}; color:${c.code};">&nbsp;${escape(codes[+i])}&nbsp;</span>`);
}

function cells(row) {
    return row.trim().replace(/^\||\|$/g, "").split("|").map(cell => cell.trim());
}

// c: { fg, dim, strong, link, code, codeBg, rule, mono }
function toHtml(md, c) {
    const lines = md.replace(/\r/g, "").split("\n");
    const out = [];
    const para = `margin-top:0; margin-bottom:12px; line-height:145%;`;
    let i = 0;

    while (i < lines.length) {
        const line = lines[i];

        if (line.trim() === "") {
            i++;
            continue;
        }

        if (/^\s*```/.test(line)) {
            const code = [];
            i++;
            while (i < lines.length && !/^\s*```/.test(lines[i]))
                code.push(lines[i++]);
            i++;
            out.push(`<table width="100%" cellpadding="10" style="margin-top:2px; margin-bottom:16px; background-color:${c.codeBg};"><tr><td><pre style="font-family:'${c.mono}'; color:${c.code}; margin:0;">${escape(code.join("\n"))}</pre></td></tr></table>`);
            continue;
        }

        const heading = line.match(/^(#{1,6})\s+(.*)$/);
        if (heading) {
            const size = heading[1].length <= 2 ? "125%" : "110%";
            out.push(`<p style="margin-top:6px; margin-bottom:8px; font-size:${size}; font-weight:600; color:${c.strong};">${inline(heading[2], c)}</p>`);
            i++;
            continue;
        }

        if (/^\s*([-*_])(\s*\1){2,}\s*$/.test(line)) {
            out.push(`<table width="100%" cellpadding="0" style="margin-top:4px; margin-bottom:16px;"><tr><td height="1" style="background-color:${c.rule};"></td></tr></table>`);
            i++;
            continue;
        }

        if (/^\s*\|.*\|\s*$/.test(line) && i + 1 < lines.length && /^\s*\|?[\s:|-]+\|?\s*$/.test(lines[i + 1])) {
            const head = cells(line);
            i += 2;
            const rows = [];
            while (i < lines.length && /^\s*\|.*\|\s*$/.test(lines[i]))
                rows.push(cells(lines[i++]));
            const th = head.map(h => `<td style="padding:6px 14px 6px 0; font-weight:600; color:${c.dim};">${inline(h, c)}</td>`).join("");
            const tr = rows.map(r => `<tr>${r.map(d => `<td style="padding:6px 14px 6px 0; border-top:1px solid ${c.rule};">${inline(d, c)}</td>`).join("")}</tr>`).join("");
            out.push(`<table cellspacing="0" cellpadding="0" style="margin-bottom:12px; line-height:135%;"><tr>${th}</tr>${tr}</table>`);
            continue;
        }

        if (/^\s*>/.test(line)) {
            const quote = [];
            while (i < lines.length && /^\s*>/.test(lines[i]))
                quote.push(lines[i++].replace(/^\s*>\s?/, ""));
            out.push(`<table cellspacing="0" cellpadding="0" style="margin-top:4px; margin-bottom:12px;"><tr><td width="3" style="background-color:${c.rule};"></td><td style="padding-left:12px; color:${c.dim}; line-height:145%;">${inline(quote.join(" "), c)}</td></tr></table>`);
            continue;
        }

        if (/^\s*([-*+]|\d+[.)])\s+/.test(line)) {
            const items = [];
            while (i < lines.length) {
                const m = lines[i].match(/^(\s*)([-*+]|\d+[.)])\s+(.*)$/);
                if (m) {
                    items.push({
                        depth: Math.floor(m[1].replace(/\t/g, "  ").length / 2),
                        marker: /\d/.test(m[2]) ? `${parseInt(m[2])}.` : (m[1].length > 0 ? "◦" : "•"),
                        text: m[3]
                    });
                    i++;
                } else if (lines[i].trim() !== "" && /^\s+/.test(lines[i]) && items.length > 0) {
                    items[items.length - 1].text += " " + lines[i++].trim();
                } else {
                    break;
                }
            }
            items.forEach((item, n) => out.push(`<table cellspacing="0" cellpadding="0" style="margin-left:${item.depth * 20}px; margin-bottom:${n === items.length - 1 ? 12 : 0}px;"><tr><td width="18" align="right" valign="top" style="color:${c.dim}; padding-right:8px; line-height:145%;">${item.marker}</td><td style="line-height:145%;">${inline(item.text, c)}</td></tr></table>`));
            continue;
        }

        const text = [];
        while (i < lines.length && lines[i].trim() !== "" && !/^\s*(```|#{1,6}\s|>|\||([-*+]|\d+[.)])\s+)/.test(lines[i]))
            text.push(lines[i++].trim());
        if (text.length === 0)
            text.push(lines[i++].trim());
        out.push(`<p style="${para}">${inline(text.join(" "), c)}</p>`);
    }

    return `<div style="color:${c.fg};">${out.join("")}</div>`;
}
