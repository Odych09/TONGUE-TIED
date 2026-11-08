import json

# We can query all 162 cells using a simple script via godot-mcp-toolkit or parse the tscn
# Notice in level_11.tscn:
# tile_map_data = PackedByteArray("...")
# In Godot 4:
# In PackedByteArray:
# For each cell:
# 2 bytes X, 2 bytes Y
# 2 bytes source_id
# 2 bytes atlas_coords_x, 2 bytes atlas_coords_y
# 2 bytes alternative_tile
import base64, struct

with open('SCENES/LEVELS/level_11.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

import re
match = re.search(r'\[node name="TileMapLayer"[^\]]*\].*?tile_map_data = PackedByteArray\("([^"]+)"\)', text, re.DOTALL)
raw = base64.b64decode(match.group(1))

# Let's inspect the first 36 bytes:
# We know the first cell is (-1, 1) with src 6, atlas (0, 0), alt 0:
# (-1, 1) in int16 is 0xFFFF, 0x0001
# Let's search for 0xFFFF, 0x0001 in raw:
target = struct.pack('<hh', -1, 1)
idx = raw.find(target)
print("Found (-1, 1) at byte offset:", idx)
# Print the next 12 bytes from idx
print("Bytes:", [b for b in raw[idx:idx+12]])
x, y, src, ax, ay, alt = struct.unpack('<hhhhhh', raw[idx:idx+12])
print(f"Unpacked: x={x}, y={y}, src={src}, ax={ax}, ay={ay}, alt={alt}")
