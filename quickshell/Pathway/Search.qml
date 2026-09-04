pragma Singleton

import Quickshell
import qs.Pathway.providers

// Fans every provider's items into one ranked list.
//
// WAVE 0 PLACEHOLDER: substring matching only. Agent 5 replaces query()/_score()
// with real fuzzy subsequence scoring. The signature and the ResultItem contract
// are fixed - nothing outside this file should need to change.
Singleton {
    id: root

    // Providers are registered here; adding one is a single line.
    readonly property var providers: [AppsProvider]

    readonly property int emptyQueryLimit: 8

    function all() {
        let items = [];
        for (const p of root.providers) {
            if (p && p.items)
                items = items.concat(p.items);
        }
        return items;
    }

    function query(text) {
        const items = root.all();
        const q = (text ?? "").trim().toLowerCase();

        if (q === "") {
            // Empty query is the "recents" pane: frecency desc, then name asc.
            return items.slice().sort((a, b) => {
                const d = Frecency.score(b.id) - Frecency.score(a.id);
                return d !== 0 ? d : (a.name ?? "").localeCompare(b.name ?? "");
            }).slice(0, root.emptyQueryLimit);
        }

        const scored = [];
        for (const item of items) {
            const s = root._score(item, q);
            if (s > 0)
                scored.push({
                    item: item,
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

    function _score(item, q) {
        const name = (item.name ?? "").toLowerCase();
        if (name.startsWith(q))
            return 100 - name.length * 0.01;
        if (name.includes(q))
            return 50 - name.length * 0.01;

        const haystack = [item.subtitle ?? ""].concat(item.keywords ?? []).join(" ").toLowerCase();
        if (haystack.includes(q))
            return 10;

        return 0;
    }
}
