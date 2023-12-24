# cython: language_level=3

import chunk

cdef int CHUNK_WIDTH = 16
cdef int CHUNK_HEIGHT = 128
cdef int CHUNK_LENGTH = 16

def fast_get_block_number(chunks, position):
	x, y, z = position

	chunk_position = (
		x // CHUNK_WIDTH,
		y // CHUNK_HEIGHT,
		z // CHUNK_LENGTH)

	if not chunk_position in chunks:
		return 0

	x = x % CHUNK_WIDTH
	y = y % CHUNK_HEIGHT
	z = z % CHUNK_LENGTH

	block_number = chunks[chunk_position].blocks[
		x * CHUNK_LENGTH * CHUNK_HEIGHT +
		z * CHUNK_HEIGHT +
		y]

	return block_number

def fast_is_opaque_block(self, position):
	block_type = self.block_types[fast_get_block_number(self, position)]

	if not block_type:
		return False

	return not block_type.transparent

cdef can_render_face(parent_blocks, chunks, block_types, block_number, block_type, int x_, int y_, int z_):
	cdef int x = x_ % CHUNK_WIDTH
	cdef int y = y_ % CHUNK_HEIGHT
	cdef int z = z_ % CHUNK_LENGTH

	if x == 0 or x == CHUNK_WIDTH - 1 or y == 0 or y == CHUNK_HEIGHT - 1 or z == 0 or z == CHUNK_LENGTH - 1:
		adj_number = fast_get_block_number(chunks, (x_, y_, z_))

	else:
		adj_number = parent_blocks[
			x * CHUNK_LENGTH * CHUNK_HEIGHT +
			z * CHUNK_HEIGHT +
			y]

	adj_type = block_types[adj_number]

	if not adj_type or adj_type.transparent:
		if block_type.glass and adj_number == block_number:
			return False

		return True

	return False

SUBCHUNK_WIDTH  = 4
SUBCHUNK_HEIGHT = 4
SUBCHUNK_LENGTH = 4

def fast_update_mesh(self):
	self.mesh_vertex_positions = []
	self.mesh_tex_coords = []
	self.mesh_shading_values = []

	self.mesh_index_counter = 0
	self.mesh_indices = []

	def add_face(face):
		vertex_positions = block_type.vertex_positions[face].copy()

		for i in range(4):
			vertex_positions[i * 3 + 0] += x
			vertex_positions[i * 3 + 1] += y
			vertex_positions[i * 3 + 2] += z
		
		self.mesh_vertex_positions.extend(vertex_positions)

		indices = [0, 1, 2, 0, 2, 3]

		for i in range(6):
			indices[i] += self.mesh_index_counter
		
		self.mesh_indices.extend(indices)
		self.mesh_index_counter += 4

		self.mesh_tex_coords.extend(block_type.tex_coords[face])
		self.mesh_shading_values.extend(block_type.shading_values[face])

	chunks = self.world.chunks
	block_types = self.world.block_types
	parent_blocks = self.parent.blocks

	cdef int x, y, z

	for local_x in range(SUBCHUNK_WIDTH):
		for local_y in range(SUBCHUNK_HEIGHT):
			for local_z in range(SUBCHUNK_LENGTH):
				parent_lx = self.local_position[0] + local_x
				parent_ly = self.local_position[1] + local_y
				parent_lz = self.local_position[2] + local_z

				block_number = self.parent.blocks[
					parent_lx * CHUNK_LENGTH * CHUNK_HEIGHT +
					parent_lz * CHUNK_HEIGHT +
					parent_ly]

				if block_number:
					block_type = self.world.block_types[block_number]

					x = self.position[0] + local_x
					y = self.position[1] + local_y
					z = self.position[2] + local_z

					# if block is cube, we want it to check neighbouring blocks so that we don't uselessly render faces
					# if block isn't a cube, we just want to render all faces, regardless of neighbouring blocks
					# since the vast majority of blocks are probably anyway going to be cubes, this won't impact performance all that much; the amount of useless faces drawn is going to be minimal

					if block_type.is_cube:
						if can_render_face(parent_blocks, chunks, block_types, block_number, block_type, x + 1, y, z): add_face(0)
						if can_render_face(parent_blocks, chunks, block_types, block_number, block_type, x - 1, y, z): add_face(1)
						if can_render_face(parent_blocks, chunks, block_types, block_number, block_type, x, y + 1, z): add_face(2)
						if can_render_face(parent_blocks, chunks, block_types, block_number, block_type, x, y - 1, z): add_face(3)
						if can_render_face(parent_blocks, chunks, block_types, block_number, block_type, x, y, z + 1): add_face(4)
						if can_render_face(parent_blocks, chunks, block_types, block_number, block_type, x, y, z - 1): add_face(5)
					
					else:
						for i in range(len(block_type.vertex_positions)):
							add_face(i)
