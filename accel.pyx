# cython: language_level=3

import chunk

CHUNK_WIDTH = 16
CHUNK_HEIGHT = 128
CHUNK_LENGTH = 16

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

def can_render_face(chunks, block_types, block_number, block_type, position):
	adj_number = fast_get_block_number(chunks, position)
	adj_type = block_types[adj_number]

	if not adj_type or adj_type.transparent:
		if block_type.glass and adj_number == block_number:
			return False

		return True

	return False
