from distutils.core import setup
from Cython.Build import cythonize
import Cython.Compiler.Options

Cython.Compiler.Options.cimport_from_pyx = True

setup(
	ext_modules=cythonize(
		[
			"src/chunk/fast.pyx",
			"src/entity/entity.pyx",
			"src/physics/collider.pyx",
			"src/entity/entity_type.pyx",
			"src/chunk/chunk_common.pyx",
			"src/chunk/chunk.pyx",
			"src/chunk/subchunk.pyx",
		],
		compiler_directives={
			"language_level": 3,
			"profile": True,
		},
		annotate=True,
	)
)
