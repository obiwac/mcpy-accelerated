import ctypes
import array
import math

import pyglet.gl as gl

from libc.stdlib cimport malloc, free

# define these first because subchunk depends on them

CHUNK_WIDTH = 16
CHUNK_HEIGHT = 128
CHUNK_LENGTH = 16

import subchunk
from subchunk cimport SubchunkMeshData

"""
import pyglet.gl.glx as glx

ctypedef void (*glBufferData_t)(int target, int size, void* data, int usage)
"""

cdef class ChunkMeshData:
	cdef size_t data_count
	cdef float* data

	cdef size_t index_count
	cdef int* indices

	@property
	def index_count(self):
		return self.index_count

cdef send_mesh_data_to_gpu(self): # pass mesh data to gpu
	cdef ChunkMeshData mesh_data = self.mesh_data

	if not mesh_data.index_count:
		return

	"""
	name = ctypes.cast(ctypes.pointer(ctypes.create_string_buffer(b"glBufferData")), ctypes.POINTER(ctypes.c_ubyte))
	cdef glBufferData_t glBufferData = <glBufferData_t><size_t>glx.glXGetProcAddress(name)
	"""

	gl.glBindVertexArray(self.vao)

	gl.glBindBuffer(gl.GL_ARRAY_BUFFER, self.vbo)
	gl.glBufferData(
		gl.GL_ARRAY_BUFFER,
		mesh_data.data_count * sizeof(mesh_data.data[0]),
		ctypes.cast(<size_t>mesh_data.data, ctypes.POINTER(gl.GLfloat)),
		gl.GL_STATIC_DRAW)

	f = ctypes.sizeof(gl.GLfloat)
	
	gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, 7 * f, 0 * f)
	gl.glVertexAttribPointer(1, 3, gl.GL_FLOAT, gl.GL_FALSE, 7 * f, 3 * f)
	gl.glVertexAttribPointer(2, 1, gl.GL_FLOAT, gl.GL_FALSE, 7 * f, 6 * f)

	gl.glEnableVertexAttribArray(0)
	gl.glEnableVertexAttribArray(1)
	gl.glEnableVertexAttribArray(2)

	gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, self.ibo)
	gl.glBufferData(
		gl.GL_ELEMENT_ARRAY_BUFFER,
		mesh_data.index_count * sizeof(mesh_data.indices[0]),
		ctypes.cast(<size_t>mesh_data.indices, ctypes.POINTER(gl.GLuint)),
		gl.GL_STATIC_DRAW)

cdef update_mesh(self, ChunkMeshData mesh_data):
	# combine all the small subchunk meshes into one big chunk mesh

	cdef int target_data_count = 0
	cdef int target_index_count = 0

	cdef SubchunkMeshData subchunk_mesh_data

	for subchunk in self.subchunks.values():
		subchunk_mesh_data = subchunk.mesh_data

		target_data_count += subchunk_mesh_data.data_count
		target_index_count += subchunk_mesh_data.index_count

	mesh_data.data_count = 0
	mesh_data.data = <float*>malloc(target_data_count * sizeof(mesh_data.data[0]))

	mesh_data.index_count = 0
	mesh_data.indices = <int*>malloc(target_index_count * sizeof(mesh_data.indices[0]))

	cdef size_t i

	for subchunk_position in self.subchunks:
		subchunk = self.subchunks[subchunk_position]
		subchunk_mesh_data = subchunk.mesh_data

		mesh_data.data[mesh_data.data_count: mesh_data.data_count + subchunk_mesh_data.data_count] = subchunk_mesh_data.data
		mesh_data.data_count += subchunk_mesh_data.data_count

		for i in range(subchunk_mesh_data.index_count):
			mesh_data.indices[mesh_data.index_count + i] = subchunk_mesh_data.indices[i] + mesh_data.index_count // 6 * 4

		mesh_data.index_count += subchunk_mesh_data.index_count

	# send the full mesh data to the GPU and free the memory used client-side (we don't need it anymore)
	# don't forget to save the length of 'self.mesh_indices' before freeing

	send_mesh_data_to_gpu(self)

	free(mesh_data.data)
	free(mesh_data.indices)

class Chunk:
	def __init__(self, world, chunk_position):
		self.world = world
		
		self.modified = False
		self.chunk_position = chunk_position

		self.position = (
			self.chunk_position[0] * CHUNK_WIDTH,
			self.chunk_position[1] * CHUNK_HEIGHT,
			self.chunk_position[2] * CHUNK_LENGTH)
		
		self.blocks = [0 for _ in range(CHUNK_WIDTH * CHUNK_HEIGHT * CHUNK_LENGTH)]
		self.subchunks = {}
		
		for x in range(int(CHUNK_WIDTH / subchunk.SUBCHUNK_WIDTH)):
			for y in range(int(CHUNK_HEIGHT / subchunk.SUBCHUNK_HEIGHT)):
				for z in range(int(CHUNK_LENGTH / subchunk.SUBCHUNK_LENGTH)):
					self.subchunks[(x, y, z)] = subchunk.Subchunk(self, (x, y, z))

		# mesh variables

		self.mesh_data = ChunkMeshData()

		# create VAO, VBO, and IBO

		self.vao = gl.GLuint(0)
		gl.glGenVertexArrays(1, self.vao)
		gl.glBindVertexArray(self.vao)

		self.vbo = gl.GLuint(0)
		gl.glGenBuffers(1, self.vbo)

		self.ibo = gl.GLuint(0)
		gl.glGenBuffers(1, self.ibo)

	def get_block(self, x, y, z):
		return self.blocks[
			x * CHUNK_LENGTH * CHUNK_HEIGHT +
			z * CHUNK_HEIGHT +
			y]

	def set_block(self, x, y, z, block):
		self.blocks[
			x * CHUNK_LENGTH * CHUNK_HEIGHT +
			z * CHUNK_HEIGHT +
			y] = block

	def update_subchunk_meshes(self):
		for subchunk_position in self.subchunks:
			subchunk = self.subchunks[subchunk_position]
			subchunk.update_mesh()

	def update_at_position(self, position):
		x, y, z = position

		lx = int(x % subchunk.SUBCHUNK_WIDTH )
		ly = int(y % subchunk.SUBCHUNK_HEIGHT)
		lz = int(z % subchunk.SUBCHUNK_LENGTH)

		clx, cly, clz = self.world.get_local_position(position)

		sx = math.floor(clx / subchunk.SUBCHUNK_WIDTH)
		sy = math.floor(cly / subchunk.SUBCHUNK_HEIGHT)
		sz = math.floor(clz / subchunk.SUBCHUNK_LENGTH)

		self.subchunks[(sx, sy, sz)].update_mesh()

		def try_update_subchunk_mesh(subchunk_position):
			if subchunk_position in self.subchunks:
				self.subchunks[subchunk_position].update_mesh()

		if lx == subchunk.SUBCHUNK_WIDTH - 1: try_update_subchunk_mesh((sx + 1, sy, sz))
		if lx == 0: try_update_subchunk_mesh((sx - 1, sy, sz))

		if ly == subchunk.SUBCHUNK_HEIGHT - 1: try_update_subchunk_mesh((sx, sy + 1, sz))
		if ly == 0: try_update_subchunk_mesh((sx, sy - 1, sz))

		if lz == subchunk.SUBCHUNK_LENGTH - 1: try_update_subchunk_mesh((sx, sy, sz + 1))
		if lz == 0: try_update_subchunk_mesh((sx, sy, sz - 1))

	def update_mesh(self):
		update_mesh(self, self.mesh_data)

	def draw(self):
		if not self.mesh_data.index_count:
			return
		
		gl.glBindVertexArray(self.vao)

		gl.glDrawElements(
			gl.GL_TRIANGLES,
			self.mesh_data.index_count,
			gl.GL_UNSIGNED_INT,
			None)
