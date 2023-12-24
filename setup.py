from distutils.core import setup
from Cython.Build import cythonize

setup(
	ext_modules=cythonize(
		["accel.pyx", "entity.pyx", "collider.pyx", "entity_type.pyx"],
		compiler_directives={"language_level" : "3"}, annotate=True,
	)
)
