pragma Singleton

import Quickshell
import qs.Pathway.providers

// Fans every provider's items into one ranked list, scored by fuzzy
// subsequence matching over name, subtitle and keywords.
Singleton {
    id: root

    // Providers are registered here; adding one is a single line.
    readonly property var providers: [AppsProvider, CommandsProvider]

    readonly property int emptyQueryLimit: 8

    // Case-folded match fields, rebuilt only when a provider's items change -
    // query() walks every desktop entry on each keystroke, so the lowercasing
    // must not happen there.
    readonly property var _index: root._buildIndex(root.all())

    function all() {
        let items = [];
        for (const p of root.providers) {
            if (p && p.items)
                items = items.concat(p.items);
        }
        return items;
    }

    function query(text, scope) {
        // A scope holds one provider's short, frequently-changing list, so its
        // index is built per call rather than cached - caching it would need
        // invalidation for no measurable gain at these sizes.
        const index = scope ? root._buildIndex(scope.items ?? []) : root._index;
        // The raw query is kept alongside the folded one to reward exact case.
        const raw = (text ?? "").trim();
        const q = raw.toLowerCase();

        if (q === "") {
            // A scoped provider already emits its own meaningful order (the
            // clipboard is newest-first), so re-ranking it would be wrong.
            if (scope)
                return index.map(e => e.item);

            // Empty query is the "recents" pane: frecency desc, then name asc.
            return index.map(e => e.item).sort((a, b) => {
                const d = Frecency.score(b.id) - Frecency.score(a.id);
                return d !== 0 ? d : (a.name ?? "").localeCompare(b.name ?? "");
            }).slice(0, root.emptyQueryLimit);
        }

        const scored = [];
        for (let i = 0; i < index.length; ++i) {
            const s = root._score(index[i], q, raw);
            if (s > 0)
                scored.push({
                    item: index[i].item,
                    score: s
                });
        }

        scored.sort((a, b) => {
            const d = b.score - a.score;
            // Frecency only breaks ties between equally good text matches.
            return d !== 0 ? d : Frecency.score(b.item.id) - Frecency.score(a.item.id);
        });

        return scored.map(e => e.item);
    }

    function _buildIndex(items) {
        const index = [];
        for (let i = 0; i < items.length; ++i) {
            const item = items[i];
            const name = item.name ?? "";
            const subtitle = item.subtitle ?? "";
            const source = item.keywords ?? [];
            const keywords = [];
            const keywordsLower = [];
            for (let k = 0; k < source.length; ++k) {
                const word = String(source[k]);
                keywords.push(word);
                keywordsLower.push(word.toLowerCase());
            }
            index.push({
                item: item,
                name: name,
                nameLower: name.toLowerCase(),
                subtitle: subtitle,
                subtitleLower: subtitle.toLowerCase(),
                keywords: keywords,
                keywordsLower: keywordsLower
            });
        }
        return index;
    }

    // Fields are ranked in disjoint integer bands and the match quality only
    // ever contributes a fraction of a band, so field precedence is structural:
    // no amount of tuning can let a keyword hit overtake a name hit, or a
    // scattered name hit overtake a name prefix.
    function _score(entry, q, raw) {
        const inName = root._quality(entry.name, entry.nameLower, q, raw);
        if (inName >= 0)
            return (entry.nameLower.startsWith(q) ? 4 : 3) + root._fraction(inName);

        const inSubtitle = root._quality(entry.subtitle, entry.subtitleLower, q, raw);
        if (inSubtitle >= 0)
            return 2 + root._fraction(inSubtitle);

        let best = -1;
        for (let i = 0; i < entry.keywords.length; ++i) {
            const k = root._quality(entry.keywords[i], entry.keywordsLower[i], q, raw);
            if (k > best)
                best = k;
        }
        return best >= 0 ? 1 + root._fraction(best) : 0;
    }

    // Squashes an unbounded quality into [0, 1) while staying monotonic, which
    // is what keeps the bands above from ever overlapping.
    function _fraction(quality) {
        return quality / (quality + 48);
    }

    // Greedy left-to-right subsequence walk. Returns -1 when `q` is not a
    // subsequence of `lower`, otherwise a quality >= 0. `text` is the original
    // casing of `lower`, used for the CamelCase and exact-case signals.
    function _quality(text, lower, q, raw) {
        const n = lower.length;
        const m = q.length;
        if (n < m)
            return -1;

        // Weights are locals, not properties: this loop runs a few thousand
        // times per keystroke and property reads are not free.
        const startBonus = 20;
        const boundaryBonus = 12;
        const consecutiveBonus = 10;
        const caseBonus = 3;
        const gapPenalty = 2;
        const maxGapPenalty = 12;
        const lengthPenalty = 0.25;

        let score = 0;
        let qi = 0;
        let run = 0;
        let prev = -1;

        for (let i = 0; i < n; ++i) {
            if (lower.charCodeAt(i) !== q.charCodeAt(qi))
                continue;

            let bonus = 1;
            if (i === 0) {
                bonus += startBonus;
            } else {
                const before = lower.charCodeAt(i - 1);
                const separator = before === 32 || before === 45 || before === 95 || before === 46 || before === 47 || before === 58;
                // CamelCase boundary: this char differs from its folded form
                // while the one before it does not.
                const camel = text.charCodeAt(i) !== lower.charCodeAt(i) && text.charCodeAt(i - 1) === before;
                if (separator || camel)
                    bonus += boundaryBonus;
            }

            if (prev === i - 1) {
                run += 1;
                bonus += consecutiveBonus * run;
            } else {
                run = 1;
                // Distance skipped since the previous hit, or since the start
                // for the first one. Capped so one far-away char cannot sink an
                // otherwise tight match.
                const gap = prev >= 0 ? i - prev - 1 : i;
                bonus -= Math.min(gap * gapPenalty, maxGapPenalty);
            }

            if (text.charCodeAt(i) === raw.charCodeAt(qi))
                bonus += caseBonus;

            score += bonus;
            prev = i;
            qi += 1;
            if (qi === m)
                break;
        }

        if (qi < m)
            return -1;

        // Break near-ties towards the shorter candidate.
        score -= (n - m) * lengthPenalty;
        return score < 0 ? 0 : score;
    }
}
