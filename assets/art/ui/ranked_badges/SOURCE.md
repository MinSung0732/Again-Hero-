# Ranked match badge art

2026-10-22: generated with the built-in image_gen tool; all 18 designs approved by the user.

Naming is explicitly ascending: bronze_1 < bronze_2 < bronze_3 < bronze_4 < silver_1, and likewise through diamond_4 < demon_lord < hero. The number equals the count of bottom division jewels. Early generation prompts used the opposite IV/I convention; delivery names and src/data/ranked_badges.json supersede those draft labels. Do not reverse division numbers in consuming code or compare filenames lexicographically. Use the explicit sort_order and tier_order data.

Initial MMR: 1000. Hero is the server-authoritative top 100 among Demon Lord-qualified players; falling outside the top 100 returns to Demon Lord. Hero UI shows MMR and server rank. Tier MMR boundaries have not been specified and are null, not inferred. This commit supplies art and metadata only, not matchmaking/rating/UI logic.

PNG files are byte-identical to approved generated originals: 1254x1254 RGBA, transparent margins. They retain intermediate alpha edge values from generation; strict binary-alpha cleanup and in-game small-size/GPU review have not been performed. Use nearest texture sampling; do not preload all 18 large source images. Hashes and generator filenames are in the data manifest. No new character likenesses.

## Generation prompts

### 1. Final bronze_1 (original draft label: 브론즈 4)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
TIER DESIGN: Warm copper-bronze round-bottom shield, simple embossed angular anvil chevron, iron dark backing, small copper side tabs, earthy burnt-orange highlights. The most modest tier; no wings or crown.
DIVISION 4 design: precisely 1 small amber-orange inset jewel pip arranged symmetrically along the bottom trim. Ornament level 1 out of four within this tier. Keep the rim simple and restrained.
This is one individual emblem asset only.
```

### 2. Final bronze_2 (original draft label: 브론즈 3)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
TIER DESIGN: Warm copper-bronze round-bottom shield, simple embossed angular anvil chevron, iron dark backing, small copper side tabs, earthy burnt-orange highlights. The most modest tier; no wings or crown.
DIVISION 3 design: precisely 2 small amber-orange inset jewel pips arranged symmetrically along the bottom trim. Ornament level 2 out of four within this tier. A slightly reinforced rim and modest additional short side ornament.
This is one individual emblem asset only.
```

### 3. Final bronze_3 (original draft label: 브론즈 2)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
TIER DESIGN: Warm copper-bronze round-bottom shield, simple embossed angular anvil chevron, iron dark backing, small copper side tabs, earthy burnt-orange highlights. The most modest tier; no wings or crown.
DIVISION 2 design: precisely 3 small amber-orange inset jewel pips arranged symmetrically along the bottom trim. Ornament level 3 out of four within this tier. A slightly reinforced rim and modest additional short side ornament.
This is one individual emblem asset only.
```

### 4. Final bronze_4 (original draft label: 브론즈 1)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
TIER DESIGN: Warm copper-bronze round-bottom shield, simple embossed angular anvil chevron, iron dark backing, small copper side tabs, earthy burnt-orange highlights. The most modest tier; no wings or crown.
DIVISION 1 design: precisely 4 small amber-orange inset jewel pips arranged symmetrically along the bottom trim. Ornament level 4 out of four within this tier. Add the tier's strongest doubled rim and slightly fuller short side ornaments.
This is one individual emblem asset only.
```

### 5. Final silver_1 (original draft label: 실버 4)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
TIER DESIGN: Cool silver kite shield with a crescent-shaped silver crest and short feather-like steel side fins, navy inset, pale icy-metal edge highlights. More refined than bronze, still compact.
DIVISION 4 design: precisely 1 small pale blue inset jewel pip arranged symmetrically along the bottom trim. Ornament level 1 out of four within this tier. Keep the rim simple and restrained.
This is one individual emblem asset only.
```

### 6. Final silver_2 (original draft label: 실버 3)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
TIER DESIGN: Cool silver kite shield with a crescent-shaped silver crest and short feather-like steel side fins, navy inset, pale icy-metal edge highlights. More refined than bronze, still compact.
DIVISION 3 design: precisely 2 small pale blue inset jewel pips arranged symmetrically along the bottom trim. Ornament level 2 out of four within this tier. A slightly reinforced rim and modest additional short side ornament.
This is one individual emblem asset only.
```

### 7. Final silver_3 (original draft label: 실버 2)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
TIER DESIGN: Cool silver kite shield with a crescent-shaped silver crest and short feather-like steel side fins, navy inset, pale icy-metal edge highlights. More refined than bronze, still compact.
DIVISION 2 design: precisely 3 small pale blue inset jewel pips arranged symmetrically along the bottom trim. Ornament level 3 out of four within this tier. A slightly reinforced rim and modest additional short side ornament.
This is one individual emblem asset only.
```

### 8. Final silver_4 (original draft label: 실버 1)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
TIER DESIGN: Cool silver kite shield with a crescent-shaped silver crest and short feather-like steel side fins, navy inset, pale icy-metal edge highlights. More refined than bronze, still compact.
DIVISION 1 design: precisely 4 small pale blue inset jewel pips arranged symmetrically along the bottom trim. Ornament level 4 out of four within this tier. Add the tier's strongest doubled rim and slightly fuller short side ornaments.
This is one individual emblem asset only.
```

### 9. Final gold_1 (original draft label: 골드 4)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
TIER DESIGN: Rich golden shield, a small central five-point angular sun-star crest, deep burgundy inset, elegant short laurel-like golden side ornaments, bright warm yellow edge pixels. Prestigious but below diamond.
DIVISION 4 design: precisely 1 small ruby-red inset jewel pip arranged symmetrically along the bottom trim. Ornament level 1 out of four within this tier. Keep the rim simple and restrained.
This is one individual emblem asset only.
```

### 10. Final gold_2 (original draft label: 골드 3)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
TIER DESIGN: Rich golden shield, a small central five-point angular sun-star crest, deep burgundy inset, elegant short laurel-like golden side ornaments, bright warm yellow edge pixels. Prestigious but below diamond.
DIVISION 3 design: precisely 2 small ruby-red inset jewel pips arranged symmetrically along the bottom trim. Ornament level 2 out of four within this tier. A slightly reinforced rim and modest additional short side ornament.
This is one individual emblem asset only.
```

### 11. Final gold_3 (original draft label: 골드 2)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
TIER DESIGN: Rich golden shield, a small central five-point angular sun-star crest, deep burgundy inset, elegant short laurel-like golden side ornaments, bright warm yellow edge pixels. Prestigious but below diamond.
DIVISION 2 design: precisely 3 small ruby-red inset jewel pips arranged symmetrically along the bottom trim. Ornament level 3 out of four within this tier. A slightly reinforced rim and modest additional short side ornament.
This is one individual emblem asset only.
```

### 12. Final gold_4 (original draft label: 골드 1)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
TIER DESIGN: Rich golden shield, a small central five-point angular sun-star crest, deep burgundy inset, elegant short laurel-like golden side ornaments, bright warm yellow edge pixels. Prestigious but below diamond.
DIVISION 1 design: precisely 4 small ruby-red inset jewel pips arranged symmetrically along the bottom trim. Ornament level 4 out of four within this tier. Add the tier's strongest doubled rim and slightly fuller short side ornaments.
This is one individual emblem asset only.
```

### 13. Final diamond_1 (original draft label: 다이아몬드 4)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
TIER DESIGN: Faceted pale-cyan diamond crystal set in a polished platinum angular shield, dark-blue inset, compact geometric crystal-wing side ornaments, icy-white edge pixels. Strong crystalline silhouette, no soft glow.
DIVISION 4 design: precisely 1 small cyan inset jewel pip arranged symmetrically along the bottom trim. Ornament level 1 out of four within this tier. Keep the rim simple and restrained.
This is one individual emblem asset only.
```

### 14. Final diamond_2 (original draft label: 다이아몬드 3)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
TIER DESIGN: Faceted pale-cyan diamond crystal set in a polished platinum angular shield, dark-blue inset, compact geometric crystal-wing side ornaments, icy-white edge pixels. Strong crystalline silhouette, no soft glow.
DIVISION 3 design: precisely 2 small cyan inset jewel pips arranged symmetrically along the bottom trim. Ornament level 2 out of four within this tier. A slightly reinforced rim and modest additional short side ornament.
This is one individual emblem asset only.
```

### 15. Final diamond_3 (original draft label: 다이아몬드 2)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
TIER DESIGN: Faceted pale-cyan diamond crystal set in a polished platinum angular shield, dark-blue inset, compact geometric crystal-wing side ornaments, icy-white edge pixels. Strong crystalline silhouette, no soft glow.
DIVISION 2 design: precisely 3 small cyan inset jewel pips arranged symmetrically along the bottom trim. Ornament level 3 out of four within this tier. A slightly reinforced rim and modest additional short side ornament.
This is one individual emblem asset only.
```

### 16. Final diamond_4 (original draft label: 다이아몬드 1)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
TIER DESIGN: Faceted pale-cyan diamond crystal set in a polished platinum angular shield, dark-blue inset, compact geometric crystal-wing side ornaments, icy-white edge pixels. Strong crystalline silhouette, no soft glow.
DIVISION 1 design: precisely 4 small cyan inset jewel pips arranged symmetrically along the bottom trim. Ornament level 4 out of four within this tier. Add the tier's strongest doubled rim and slightly fuller short side ornaments.
This is one individual emblem asset only.
```

### 17. Final demon_lord (original draft label: 마왕)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
TOP TIER DESIGN: DEMON LORD, a regal obsidian shield with a large deep-amethyst jewel core, two swept black-purple horns forming a crown, dark steel and violet rim, subtle crimson inset details, short compact bat-wing ornaments. Majestic strategic ruler motif, strongest silhouette so far, no skull and no character portrait. No bottom division pips because this rank has no subdivisions. Controlled bright purple pixel highlights, no fuzzy aura. ONE individual emblem only.
```

### 18. Final hero (original draft label: 용사 · 마왕 등급 상위 100명)

```text
Use case: stylized-concept. Asset type: ONE individual ranked-match emblem icon for the Korean pixel-art fantasy mobile game "Again, Hero?".
Create exactly ONE emblem, centered, isolated on a genuinely transparent background PNG. Square canvas. The emblem occupies approximately 68 percent of canvas width and height, with generous transparent margins. Front-facing, bilateral symmetry, fixed centered anchor.
Art direction: authentic carefully clustered 2D pixel art, designed on a consistent approximately 96x96 logical pixel grid enlarged with hard nearest-neighbor pixel edges. Crisp square pixel clusters, dark 2-pixel outline, restrained 4-tone ramps per material, selective bright metal edge pixels, chunky legible silhouette that reads at 48px. Premium fantasy rank insignia, charming but serious, matching a pixel-art demon-lord-versus-hero game. Absolutely no smooth illustration, 3D render, blur, antialiasing, gradients, soft bloom, blurry glow, photographic texture, lettering, numerals, labels, UI panels, watermark, ground shadow or additional icons. Real transparent background, never checkerboard baked into pixels.
The entire rank collection uses a consistent central shield, compact base, balanced horizontal ornaments, dark near-black outline, upper-left pixel highlights. Higher ranks feel progressively more prestigious. Small bottom inset jewel pips encode division: IV has ONE jewel pip, III TWO, II THREE, I FOUR. Keep the tier's core silhouette and materials consistent; higher divisions add only modest layered edging and ornament. Do not draw the division text.
HIGHEST TIER DESIGN: HERO, server top-100 apex badge, a brilliant upright platinum holy sword with a vivid azure crystal in its guard, centered on a white-gold shield. Compact symmetrical white feather wings and a gold crown-shaped halo crest, sapphire-blue accents, highest prestige in the set. Heroic and noble, clearly visually above the obsidian horned demon-lord rank. Distinctive chunky silhouette; no character portrait. No bottom division pips. No MMR value, no ranking number, no "100", no words; live values will be UI text outside the icon. Sparkle represented only by a few crisp opaque pixel clusters, never bloom. ONE individual emblem only.
```
