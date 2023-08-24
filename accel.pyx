import chunk

def fast_get_block_number(self, position):
    x, y, z = position

    chunk_position = (
        x // chunk.CHUNK_WIDTH,
        y // chunk.CHUNK_HEIGHT,
        z // chunk.CHUNK_LENGTH)

    if not chunk_position in self.chunks:
        return 0

    pos = (
        int(x % chunk.CHUNK_WIDTH),
        int(y % chunk.CHUNK_HEIGHT),
        int(z % chunk.CHUNK_LENGTH))

    block_number = self.chunks[chunk_position].get_block(*pos)
    return block_number
