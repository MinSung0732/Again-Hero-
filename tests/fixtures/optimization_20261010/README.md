# Optimization baseline fixtures

Source revision: `1d5ad4cedbadc72ea52c2c342946d75dcee96fe7`.

These four `.gd.txt` fixtures are the original production scripts, with only
`class_name` declarations removed so tests can reload them beside their current
counterparts without registering duplicate global classes. Runtime code is unchanged.

They support deterministic AI, metrics, spatial-query and popup regression checks.
The exact original files, including `class_name`, are in
`docs/optimization/20261010/before_after.zip`. Do not import fixtures as production code.
