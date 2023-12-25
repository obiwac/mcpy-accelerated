import chunk
import subchunk

cdef int CHUNK_WIDTH = chunk.CHUNK_WIDTH
cdef int CHUNK_HEIGHT = chunk.CHUNK_HEIGHT
cdef int CHUNK_LENGTH = chunk.CHUNK_LENGTH

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
