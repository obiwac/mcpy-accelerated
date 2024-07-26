# mcpy-accelerated

MCPY with performance-sensitive code replaced with C routines.
This is based on the [code from episode 13](https://github.com/obiwac/python-minecraft-clone/pull/57).

Installing dependencies:

```console
poetry install --no-root
```

Installing dev devependencies:

```console
poetry install --no-root --with dev
```

Building:

```console
poetry run python setup.py build_ext --inplace
```

**TODO**: This should really just be `poetry run build`.

Running:

```console
poetry run python main.py
```
