from distutils.core import setup
from Cython.Build import cythonize

setup(
	ext_modules=cythonize(
		["fast.pyx", "entity.pyx", "collider.pyx", "entity_type.pyx", "chunk.py", "subchunk.pyx"],
		compiler_directives={
			"language_level": 3,
			"profile": True,
		},
		annotate=True,
	)
)
