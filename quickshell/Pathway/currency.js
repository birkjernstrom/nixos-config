.pragma library

.import "calc.js" as Calc

const defaults = ["SEK", "USD", "EUR"];

const aliases = {
    "kr": "SEK",
    "kronor": "SEK",
    "krona": "SEK",
    "$": "USD",
    "dollar": "USD",
    "dollars": "USD",
    "€": "EUR",
    "euro": "EUR",
    "euros": "EUR",
    "£": "GBP",
    "pound": "GBP",
    "pounds": "GBP",
    "¥": "JPY",
    "yen": "JPY",
    "nok": "NOK",
    "dkk": "DKK"
};

// Strict, for a bare `<amount> <unit>` with no target: only aliases, the
// defaults, or a code typed in capitals, so "top 10" is not Tongan paʻanga.
function code(word, rates, strict) {
    const raw = (word ?? "").trim();
    const w = raw.toLowerCase();
    const c = aliases[w] ?? w.toUpperCase();
    if (rates[c] === undefined)
        return null;
    if (strict && !aliases[w] && !defaults.includes(c) && raw !== c)
        return null;
    return c;
}

function format(value) {
    const digits = Math.abs(value) < 1 ? 4 : 2;
    const [int, frac] = Math.abs(value).toFixed(digits).split(".");
    return (value < 0 ? "-" : "") + int.replace(/\B(?=(\d{3})+(?!\d))/g, " ") + "." + frac;
}

function source(text, rates, strict) {
    const unit = "([$€£¥]|[a-zA-Z]+)";
    const prefix = text.match(new RegExp(`^${unit}\\s*(.+)$`));
    if (prefix) {
        const from = code(prefix[1], rates, strict);
        const amount = from ? Calc.value(prefix[2]) : null;
        if (amount !== null)
            return { amount, from };
    }
    const suffix = text.match(new RegExp(`^(.+?)\\s*${unit}$`));
    if (suffix) {
        const from = code(suffix[2], rates, strict);
        const amount = from ? Calc.value(suffix[1]) : null;
        if (amount !== null)
            return { amount, from };
    }
    return null;
}

// `1456 SEK in USD`, `$40 to sek`, `€12.5`, `(200 + 10%) eur as sek`. Returns
// one { name, subtitle, copy } per target currency, or [] if `src` is not a
// conversion.
function convert(src, rates) {
    const text = (src ?? "").trim();
    if (text === "" || !rates || Object.keys(rates).length === 0)
        return [];

    let left = text;
    let targets = null;
    const m = text.match(/^(.+?)\s+(?:in|to|as|into|=|->|→)\s+([$€£¥]|[a-zA-Z]+)$/i);
    if (m) {
        const to = code(m[2], rates);
        if (!to)
            return [];
        left = m[1];
        targets = [to];
    }

    const from = source(left, rates, targets === null);
    if (!from)
        return [];

    targets = targets ?? defaults.filter(c => c !== from.from);
    return targets.map(to => {
        const value = from.amount / rates[from.from] * rates[to];
        const unit = rates[to] / rates[from.from];
        return {
            name: `${format(value)} ${to}`,
            subtitle: `${Calc.format(from.amount)} ${from.from}  ·  1 ${from.from} = ${format(unit)} ${to}`,
            copy: value.toFixed(Math.abs(value) < 1 ? 4 : 2)
        };
    });
}
