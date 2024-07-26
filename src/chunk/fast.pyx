from src.chunk.chunk_common cimport CChunk
from src.chunk.chunk_common cimport C_CHUNK_WIDTH, C_CHUNK_HEIGHT, C_CHUNK_LENGTH

def get_block_number(chunks, position):
	x, y, z = position

	chunk_position = (
		x // C_CHUNK_WIDTH,
		y // C_CHUNK_HEIGHT,
		z // C_CHUNK_LENGTH)

	if not chunk_position in chunks:
		return 0

	x = x % C_CHUNK_WIDTH
	y = y % C_CHUNK_HEIGHT
	z = z % C_CHUNK_LENGTH

	cdef CChunk c_chunk = chunks[chunk_position].c

	block_number = c_chunk.blocks[
		x * C_CHUNK_LENGTH * C_CHUNK_HEIGHT +
		z * C_CHUNK_HEIGHT +
		y]

	return block_number
