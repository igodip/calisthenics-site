# PDF import fixtures

`bux-app-layout.json` records the expected logical output for the five-week,
four-day PDF used to validate the importer. It deliberately contains no client,
trainer, phone, email, or social-account data from the source document.

The source layout has seven columns (`ESERCIZI`, five week columns, and `NOTE`)
and does not draw a horizontal rule between every exercise. Both characteristics
are regression cases: the importer must detect columns from their headers and
derive exercise boundaries from the exercise-label positions.

The original PDF is intentionally not checked in because it contains personal
contact information. For manual verification, compare an authorized local copy
against the day codes, slot counts, scheduled-exercise count, and sample values
in the JSON fixture.
