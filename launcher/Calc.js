.pragma library

// Small expression evaluator for the launcher's calculator mode.
// Recursive descent, no eval(). Supports + - * / % ^ **, parentheses, hex (0x..),
// constants (pi, e, tau) and common functions.

const FUNCS = {
    sqrt: Math.sqrt, cbrt: Math.cbrt, abs: Math.abs,
    sin: Math.sin, cos: Math.cos, tan: Math.tan,
    asin: Math.asin, acos: Math.acos, atan: Math.atan,
    ln: Math.log, log: Math.log10, log2: Math.log2, exp: Math.exp,
    floor: Math.floor, ceil: Math.ceil, round: Math.round,
    min: Math.min, max: Math.max
};
const CONSTS = { pi: Math.PI, e: Math.E, tau: Math.PI * 2 };

function tokenize(src) {
    const out = [];
    let i = 0;
    while (i < src.length) {
        const c = src[i];
        if (/\s/.test(c)) { i++; continue; }
        let m = /^0x[0-9a-f]+/i.exec(src.slice(i));
        if (!m) m = /^(\d+\.?\d*|\.\d+)(e[+-]?\d+)?/i.exec(src.slice(i));
        if (m) { out.push({ t: "num", v: Number(m[0]) }); i += m[0].length; continue; }
        m = /^[a-z_][a-z0-9_]*/i.exec(src.slice(i));
        if (m) { out.push({ t: "id", v: m[0].toLowerCase() }); i += m[0].length; continue; }
        if (src.startsWith("**", i)) { out.push({ t: "op", v: "^" }); i += 2; continue; }
        if ("+-*/%^(),×÷".indexOf(c) >= 0) {
            out.push({ t: "op", v: c === "×" ? "*" : (c === "÷" ? "/" : c) });
            i++;
            continue;
        }
        throw new Error("Unexpected '" + c + "'");
    }
    return out;
}

function evaluate(src) {
    try {
        const toks = tokenize(src);
        if (toks.length === 0)
            return { ok: false, empty: true, error: "" };
        let p = 0;
        function peek() { return toks[p]; }
        function eat(v) {
            if (peek() && peek().t === "op" && peek().v === v) { p++; return true; }
            return false;
        }

        function expr() {
            let v = term();
            for (;;) {
                if (eat("+")) v += term();
                else if (eat("-")) v -= term();
                else return v;
            }
        }
        function term() {
            let v = unary();
            for (;;) {
                if (eat("*")) v *= unary();
                else if (eat("/")) v /= unary();
                else if (eat("%")) v %= unary();
                else return v;
            }
        }
        function unary() {
            if (eat("-")) return -unary();
            if (eat("+")) return unary();
            return power();
        }
        function power() {
            const base = atom();
            return eat("^") ? Math.pow(base, unary()) : base;
        }
        function atom() {
            const t = peek();
            if (!t) throw new Error("Unexpected end");
            if (t.t === "num") { p++; return t.v; }
            if (t.t === "id") {
                p++;
                if (eat("(")) {
                    const args = [];
                    if (!eat(")")) {
                        do { args.push(expr()); } while (eat(","));
                        if (!eat(")")) throw new Error("Missing ')'");
                    }
                    const f = FUNCS[t.v];
                    if (!f) throw new Error("Unknown function " + t.v);
                    return f.apply(null, args);
                }
                if (t.v in CONSTS) return CONSTS[t.v];
                throw new Error("Unknown name " + t.v);
            }
            if (eat("(")) {
                const v = expr();
                if (!eat(")")) throw new Error("Missing ')'");
                return v;
            }
            throw new Error("Unexpected '" + t.v + "'");
        }

        const value = expr();
        if (p < toks.length)
            throw new Error("Unexpected '" + toks[p].v + "'");
        if (!isFinite(value))
            throw new Error("Not a finite number");
        return { ok: true, value: value, text: format(value), hex: hex(value), bin: bin(value) };
    } catch (e) {
        return { ok: false, empty: false, error: String(e.message || e) };
    }
}

function format(v) {
    if (Number.isInteger(v) && Math.abs(v) < 1e15)
        return String(v);
    return String(parseFloat(v.toPrecision(12)));
}

function isWhole(v) { return Number.isInteger(v) && v >= 0 && v <= 9007199254740991; }

function hex(v) { return isWhole(v) ? "0x" + v.toString(16).toUpperCase() : ""; }

function bin(v) {
    if (!isWhole(v) || v > 4294967295) return "";
    const s = v.toString(2);
    const pad = (4 - s.length % 4) % 4;
    return ("0".repeat(pad) + s).replace(/(.{4})(?=.)/g, "$1 ");
}
