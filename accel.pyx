# cython: language_level=3

import chunk

def fast_get_block_number(self, position):
	x, y, z = position

	chunk_position = (
		x // chunk.CHUNK_WIDTH,
		y // chunk.CHUNK_HEIGHT,
		z // chunk.CHUNK_LENGTH)

	if not chunk_position in self.chunks:
		return 0

	x = int(x % chunk.CHUNK_WIDTH)
	y = int(y % chunk.CHUNK_HEIGHT)
	z = int(z % chunk.CHUNK_LENGTH)

	block_number = self.chunks[chunk_position].blocks[
		x * chunk.CHUNK_LENGTH * chunk.CHUNK_HEIGHT +
		z * chunk.CHUNK_HEIGHT +
		y]

	return block_number

def fast_is_opaque_block(self, position):
	# get block type and check if it's opaque or not
	# air counts as a transparent block, so test for that too

	block_type = self.block_types[fast_get_block_number(self, position)]

	if not block_type:
		return False

	return not block_type.transparent

def can_render_face(self, block_number, block_type, position):
	if not fast_is_opaque_block(self.world, position):
		if block_type.glass and fast_get_block_number(self.world, position) == block_number:
			return False

		return True

	return False
