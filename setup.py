from distutils.core import setup
from Cython.Build import cythonize
import Cython.Compiler.Options

Cython.Compiler.Options.cimport_from_pyx = True

setup(
	ext_modules=cythonize(
		["fast.pyx", "entity.pyx", "collider.pyx", "entity_type.pyx", "chunk_common.pyx", "chunk.pyx", "subchunk.pyx"],
		compiler_directives={
			"language_level": 3,
			"profile": True,
		},
		annotate=True,
	)
)
