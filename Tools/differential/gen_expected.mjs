// Generates expected.json: for each mini-notation line in corpus.txt, the
// haps of cycles 0..2 from the actual JS strudel implementation.
// Usage: node gen_expected.mjs <strudel-repo> <corpus.txt> <out.json>
import { readFileSync, writeFileSync } from 'fs';
import { pathToFileURL } from 'url';

const [repo, corpusPath, outPath] = process.argv.slice(2);
const { mini } = await import(pathToFileURL(`${repo}/packages/mini/mini.mjs`));

const corpus = readFileSync(corpusPath, 'utf8').split('\n').filter(l => l.trim());
const out = {};
for (const line of corpus) {
  try {
    const haps = mini(line).sortHapsByPart().queryArc(0, 2);
    out[line] = haps.map(h => ({
      whole: h.whole ? [h.whole.begin.show(), h.whole.end.show()] : null,
      part: [h.part.begin.show(), h.part.end.show()],
      value: h.value,
    }));
  } catch (e) {
    out[line] = { error: String(e.message) };
  }
}
writeFileSync(outPath, JSON.stringify(out, null, 1));
console.log(`wrote ${Object.keys(out).length} entries to ${outPath}`);
