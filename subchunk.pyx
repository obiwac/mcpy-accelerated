import chunk

cdef int CHUNK_WIDTH = chunk.CHUNK_WIDTH
cdef int CHUNK_HEIGHT = chunk.CHUNK_HEIGHT
cdef int CHUNK_LENGTH = chunk.CHUNK_LENGTH

cdef int C_SUBCHUNK_WIDTH  = 4
cdef int C_SUBCHUNK_HEIGHT = 4
cdef int C_SUBCHUNK_LENGTH = 4

SUBCHUNK_WIDTH = C_SUBCHUNK_WIDTH
SUBCHUNK_HEIGHT = C_SUBCHUNK_HEIGHT
SUBCHUNK_LENGTH = C_SUBCHUNK_LENGTH

def get_block_number(chunks, position):
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

cdef bint can_render_face(parent_blocks, chunks, block_types, int block_number, block_type, int x_, int y_, int z_):
	cdef int x = x_ % CHUNK_WIDTH
	cdef int y = y_ % CHUNK_HEIGHT
	cdef int z = z_ % CHUNK_LENGTH

	cdef int adj_number

	# get_block_number is relatively slow, but we can just index the chunk directly if we know we're not on the edges of it

	if x == 0 or x == CHUNK_WIDTH - 1 or y == 0 or y == CHUNK_HEIGHT - 1 or z == 0 or z == CHUNK_LENGTH - 1:
		adj_number = get_block_number(chunks, (x_, y_, z_))

	else:
		adj_number = parent_blocks[
			x * CHUNK_LENGTH * CHUNK_HEIGHT +
			z * CHUNK_HEIGHT +
			y]

	adj_type = block_types[adj_number]

	if not adj_type or adj_type.transparent: # TODO getting transparent attribute of adjacent block incurs a lot of overhead
		if block_type.glass and adj_number == block_number: # rich compare between adj_number and block_number prevented
			return False

		return True

	return False

def update_mesh(self):
	self.mesh_data = []
	self.mesh_index_counter = 0
	self.mesh_indices = []

	def add_face(face):
		vertex_positions = block_type.vertex_positions[face]
		tex_coords = block_type.tex_coords[face]
		shading_values = block_type.shading_values[face]

		data = [0.] * (4 * 7)
		cdef int i

		for i in range(4):
			data[i * 7 + 0] = vertex_positions[i * 3 + 0] + x
			data[i * 7 + 1] = vertex_positions[i * 3 + 1] + y
			data[i * 7 + 2] = vertex_positions[i * 3 + 2] + z

			data[i * 7 + 3] = tex_coords[i * 3 + 0]
			data[i * 7 + 4] = tex_coords[i * 3 + 1]
			data[i * 7 + 5] = tex_coords[i * 3 + 2]

			data[i * 7 + 6] = shading_values[i]
		
		self.mesh_data.extend(data)

		cdef int[6] indices = [0, 1, 2, 0, 2, 3]

		for i in range(6):
			indices[i] += self.mesh_index_counter
		
		self.mesh_indices.extend(indices)
		self.mesh_index_counter += 4

	chunks = self.world.chunks
	block_types = self.world.block_types
	parent_blocks = self.parent.blocks

	cdef int slx = self.local_position[0]
	cdef int sly = self.local_position[1]
	cdef int slz = self.local_position[2]

	cdef int sx = self.position[0]
	cdef int sy = self.position[1]
	cdef int sz = self.position[2]

	cdef int x, y, z
	cdef int parent_lx, parent_ly, parent_lz
	cdef int block_number
	cdef int local_x, local_y, local_z

	for local_x in range(C_SUBCHUNK_WIDTH):
		for local_y in range(C_SUBCHUNK_HEIGHT):
			for local_z in range(C_SUBCHUNK_LENGTH):
				parent_lx = slx + local_x
				parent_ly = sly + local_y
				parent_lz = slz + local_z

				block_number = parent_blocks[
					parent_lx * CHUNK_LENGTH * CHUNK_HEIGHT +
					parent_lz * CHUNK_HEIGHT +
					parent_ly]

				if block_number:
					block_type = block_types[block_number]

					x = sx + local_x
					y = sy + local_y
					z = sz + local_z

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

class Subchunk:
	def __init__(self, parent, subchunk_position):
		self.parent = parent
		self.world = self.parent.world

		self.subchunk_position = subchunk_position

		self.local_position = (
			self.subchunk_position[0] * C_SUBCHUNK_WIDTH,
			self.subchunk_position[1] * C_SUBCHUNK_HEIGHT,
			self.subchunk_position[2] * C_SUBCHUNK_LENGTH)

		self.position = (
			self.parent.position[0] + self.local_position[0],
			self.parent.position[1] + self.local_position[1],
			self.parent.position[2] + self.local_position[2])

		# mesh variables

		self.mesh_data = []
		self.mesh_index_counter = 0
		self.mesh_indices = []
	
	def update_mesh(self):
		update_mesh(self)
