.pragma library

const functions = {
    sqrt: Math.sqrt,
    cbrt: Math.cbrt,
    abs: Math.abs,
    round: Math.round,
    floor: Math.floor,
    ceil: Math.ceil,
    ln: Math.log,
    log: Math.log10,
    log2: Math.log2,
    exp: Math.exp,
    sin: Math.sin,
    cos: Math.cos,
    tan: Math.tan,
    asin: Math.asin,
    acos: Math.acos,
    atan: Math.atan
};

const constants = {
    pi: Math.PI,
    π: Math.PI,
    e: Math.E,
    tau: 2 * Math.PI
};

function tokenize(src) {
    const tokens = [];
    let i = 0;
    while (i < src.length) {
        const ch = src[i];
        if (/\s/.test(ch)) {
            i++;
            continue;
        }
        const num = src.slice(i).match(/^(\d[\d_]*(\.\d*)?|\.\d+)([eE][+-]?\d+)?/);
        if (num) {
            tokens.push({ type: "num", value: parseFloat(num[0].replace(/_/g, "")) });
            i += num[0].length;
            continue;
        }
        const word = src.slice(i).match(/^[a-zA-Zπ][a-zA-Z0-9]*/);
        if (word) {
            tokens.push({ type: "word", value: word[0].toLowerCase() });
            i += word[0].length;
            continue;
        }
        if (src.startsWith("**", i)) {
            tokens.push({ type: "op", value: "^" });
            i += 2;
            continue;
        }
        const op = { "×": "*", "·": "*", "÷": "/", "−": "-" }[ch] ?? ch;
        if ("+-*/^%!(),".includes(op)) {
            tokens.push({ type: "op", value: op });
            i++;
            continue;
        }
        throw new Error(`Unexpected ${ch}`);
    }
    return tokens;
}

function factorial(n) {
    if (n < 0 || !Number.isInteger(n) || n > 170)
        throw new Error("Bad factorial");
    let r = 1;
    for (let k = 2; k <= n; k++)
        r *= k;
    return r;
}

// Percent follows calculator rules: `a + b%` and `a - b%` adjust a by b percent
// of itself, anywhere else `b%` is b / 100.
function parse(tokens) {
    let pos = 0;
    const peek = () => tokens[pos];
    const isOp = v => peek()?.type === "op" && peek().value === v;
    const startsOperand = t => t && (t.type === "num" || t.type === "word" || t.value === "(");

    function expression() {
        let left = term().value;
        while (isOp("+") || isOp("-")) {
            const op = tokens[pos++].value;
            const right = term();
            const delta = right.percent ? left * right.value : right.value;
            left = op === "+" ? left + delta : left - delta;
        }
        return left;
    }

    function term() {
        let first = unary();
        let value = first.value;
        let percent = first.percent;
        for (;;) {
            if (isOp("*") || isOp("/") || (isOp("%") && startsOperand(tokens[pos + 1]))) {
                const op = tokens[pos++].value;
                const right = unary().value;
                value = op === "*" ? value * right : op === "/" ? value / right : value % right;
            } else if (startsOperand(peek())) {
                value *= unary().value;
            } else {
                break;
            }
            percent = false;
        }
        return { value, percent };
    }

    function unary() {
        if (isOp("-") || isOp("+")) {
            const sign = tokens[pos++].value === "-" ? -1 : 1;
            const inner = unary();
            return { value: sign * inner.value, percent: inner.percent };
        }
        return power();
    }

    function power() {
        const base = postfix();
        if (isOp("^")) {
            pos++;
            return { value: Math.pow(base.value, unary().value), percent: false };
        }
        return base;
    }

    function postfix() {
        let value = primary();
        let percent = false;
        for (;;) {
            if (isOp("!")) {
                pos++;
                value = factorial(value);
            } else if (isOp("%") && !startsOperand(tokens[pos + 1])) {
                pos++;
                value /= 100;
                percent = true;
            } else {
                return { value, percent };
            }
        }
    }

    function primary() {
        const t = tokens[pos++];
        if (!t)
            throw new Error("Unexpected end");
        if (t.type === "num")
            return t.value;
        if (t.type === "op" && t.value === "(") {
            const v = expression();
            if (!isOp(")"))
                throw new Error("Missing )");
            pos++;
            return v;
        }
        if (t.type === "word") {
            if (functions[t.value] && isOp("(")) {
                pos++;
                const v = expression();
                if (!isOp(")"))
                    throw new Error("Missing )");
                pos++;
                return functions[t.value](v);
            }
            if (t.value in constants)
                return constants[t.value];
        }
        throw new Error(`Unexpected ${t.value}`);
    }

    const result = expression();
    if (pos !== tokens.length)
        throw new Error("Trailing input");
    return result;
}

function format(value) {
    if (Math.abs(value) >= 1e15 || (value !== 0 && Math.abs(value) < 1e-9))
        return value.toExponential(6).replace(/\.?0+e/, "e");
    const rounded = Number(value.toPrecision(12));
    const [int, frac] = String(Math.abs(rounded)).split(".");
    const grouped = int.replace(/\B(?=(\d{3})+(?!\d))/g, " ");
    return (rounded < 0 ? "-" : "") + grouped + (frac ? "." + frac : "");
}

// The answer to `src` if it is a calculation, else null. A bare number or
// constant is not a calculation, so typing "2048" still searches apps.
function evaluate(src) {
    const text = (src ?? "").trim().replace(/^=\s*/, "");
    if (text === "" || !/[\d.)πa-z]/i.test(text))
        return null;
    let tokens;
    try {
        tokens = tokenize(text);
    } catch (e) {
        return null;
    }
    const calculation = tokens.some(t => t.type === "op" && t.value !== "(" && t.value !== ")" && t.value !== ",") || tokens.some(t => t.type === "word" && functions[t.value]) || tokens.filter(t => t.type === "num" || t.type === "word").length > 1;
    if (!calculation)
        return null;
    try {
        const value = parse(tokens);
        if (!isFinite(value))
            return null;
        return { value: value, text: format(value), copy: String(Number(value.toPrecision(12))) };
    } catch (e) {
        return null;
    }
}

// The value of `src` whether or not it is a calculation, else null.
function value(src) {
    try {
        const v = parse(tokenize((src ?? "").trim()));
        return isFinite(v) ? v : null;
    } catch (e) {
        return null;
    }
}
