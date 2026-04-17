# Example Retrospective Excerpts

These are condensed examples showing the target tone and structure. Drawn from real
retrospectives — adapted here as a portable style reference.

---

## Example: Opening (Tension First)

> There comes a moment in every measurement database's life when it has to confront an
> uncomfortable truth: the universe is full of things with numbers in their names.
>
> For nine major versions, the app lived in a world of pure alphabetic bliss. Elephants.
> Cats. Blue whales. Nice, clean, letter-only names that slid through regex validation like
> butter through a warm knife. Then someone tried to add a Boeing 747, and the whole house
> of cards — well, not *collapsed*, exactly. More like it politely declined.

**Why it works**: Starts with a problem, not a feature list. Anthropomorphizes the system.
Uses specific examples. Builds tension before revealing the solution.

---

## Example: Feature Section (Before/Change/Landing)

> ### Death of the Split Panel
>
> The Explore page used to be a split panel: entity list on the left, detail view on the
> right. Click an entity, see its relationships. On mobile, this required a "back" button
> to toggle between panels. It was functional. It was also the wrong pattern for a browsing page.
>
> The new version is a 3-column card grid. Each card shows an emoji, a name, and a
> relationship count badge. Click one, you go straight to the entity detail page.
>
> We deleted approximately 100 lines of panel toggle code and replaced them with... links.
> Sometimes the best refactor is removing an abstraction.

**Why it works**: "Before" establishes what was wrong. "Change" is specific (3-column, emoji,
badge). The closer ("replaced them with... links") lands with satisfying simplicity.

---

## Example: Bug/Mistake Section (Adventure, Not Failure)

> What went wrong: we looked up the *wrong entity*. For approximately 48 hours, the
> annotation was confidently displaying the "from" entity's absolute value, which meant
> "1 elephant is as heavy as 175 cats" was annotated with "≈ 4,000 kg" — the weight of
> the elephant you just mentioned, not the 175 cats you're supposedly contextualizing.
> A one-line fix (`fromEntity.id` → `toEntity.id`) and the sudden shame of shipping a
> feature whose sole purpose was accuracy, inaccurately.

**Why it works**: Specific about the mistake. Shows the actual code change. Self-deprecating
without being apologetic. The irony (accuracy feature, shipped inaccurately) is the punchline.

---

## Example: Small Win Section (Dignity for the Unglamorous)

> **Timer typing**: `NodeJS.Timeout` → `ReturnType<typeof setTimeout>`. The change is three
> words, but it means the EntityAutocomplete component no longer lies about its runtime
> environment. It runs in a browser. Browsers don't have `NodeJS`. Case closed.

**Why it works**: Elevates a tiny change into something worth reading. "Case closed" gives
a three-word fix the gravitas of a legal ruling.

---

## Example: By the Numbers

> - **9** canonical measures (was 6)
> - **~50** total entities (was 40)
> - **1** centralized constants file (was 0)
> - **0** remaining `.or()` string interpolations in entity search (was 1)

**Why it works**: Bold numbers. "(was N)" shows direction. Mix of big and small. The "0"
stat celebrates something removed — often more satisfying than something added.

---

## Example: Closing Line

> Somewhere out there, someone is about to learn that an aircraft carrier costs roughly
> 95,500 bicycles. And honestly? That's what this is all for.

**Why it works**: Returns to the project's core purpose. A specific, delightful data point.
Ends on sincerity after pages of wit.
