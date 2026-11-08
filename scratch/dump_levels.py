import base64
import struct
import re

def dump_scene(path):
    print(f"\n==================== {path} ====================")
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()

    # Find player position
    p_match = re.search(r'\[node name="Player".*?position = Vector2\(([^)]+)\)', text, re.DOTALL)
    player_pos = None
    if p_match:
        px, py = map(float, p_match.group(1).split(','))
        player_pos = (int(round(px / 128.0)), int(round(py / 128.0)))
        print(f"Player at world ({px}, {py}) -> grid {player_pos}")

    # Find enemies
    enemies = []
    for em in re.finditer(r'\[node name="(Enemy\d*)".*?position = Vector2\(([^)]+)\)', text, re.DOTALL):
        name = em.group(1)
        ex, ey = map(float, em.group(2).split(','))
        epos = (int(round(ex/128.0)), int(round(ey/128.0)))
        enemies.append((name, epos))
        print(f"{name} at world ({ex}, {ey}) -> grid {epos}")

    # Decode TileMapLayer
    match = re.search(r'\[node name="TileMapLayer"[^\]]*\].*?tile_map_data = PackedByteArray\("([^"]+)"\)', text, re.DOTALL)
    if not match:
        print("No TileMapLayer found")
        return

    raw = base64.b64decode(match.group(1))
    
    tiles = {}
    min_x, max_x = 999, -999
    min_y, max_y = 999, -999
    
    # 2-byte header
    for i in range(2, len(raw) - 11, 12):
        chunk = raw[i:i+12]
        x, y, src, ax, ay, alt = struct.unpack('<hhhhhh', chunk)
        tiles[(x, y)] = (src, ax, ay, alt)
        min_x = min(min_x, x)
        max_x = max(max_x, x)
        min_y = min(min_y, y)
        max_y = max(max_y, y)
        
    print(f"Bounds: X: {min_x}..{max_x}, Y: {min_y}..{max_y} (Width: {max_x - min_x + 1}, Height: {max_y - min_y + 1})")
    
    char_map = {
        6: '#', # Wall
        1: 'B', # Pushable box
        2: '*', # Bug
        3: 'W', # Win (Lily Pad)
        4: 'X', # Frog Hazard (spikes on body)
        5: 'T', # Tongue Trap (spikes on tongue)
        7: '~', # Water
        8: '~', # Goop
    }
    
    for y in range(min_y, max_y + 1):
        row_str = ""
        for x in range(min_x, max_x + 1):
            if player_pos and (x, y) == player_pos:
                row_str += "P"
            elif (x, y) in tiles:
                src = tiles[(x, y)][0]
                row_str += char_map.get(src, '?')
            else:
                row_str += "."
        print(f"{y:3d} | {row_str}")

dump_scene('SCENES/LEVELS/level_11.tscn')
dump_scene('SCENES/LEVELS/level_13.tscn')
