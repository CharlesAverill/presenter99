from PIL import Image
import numpy as np
from sklearn.cluster import KMeans
import os

BLOCK_SIZE = 8
NUM_CHARS = 32
SCREEN_COLS = 32
SCREEN_ROWS = 24

def image_to_monochrome(path):
    # Convert to grayscale and dither
    img = Image.open(path).convert('L')
    img = img.resize((SCREEN_COLS*BLOCK_SIZE, SCREEN_ROWS*BLOCK_SIZE), Image.LANCZOS)
    img = img.convert('1')
    return np.array(img, dtype=np.uint8)

def split_blocks(img):
    h_blocks = img.shape[0] // BLOCK_SIZE
    w_blocks = img.shape[1] // BLOCK_SIZE
    blocks = []
    for by in range(h_blocks):
        for bx in range(w_blocks):
            block = img[by*BLOCK_SIZE:(by+1)*BLOCK_SIZE, bx*BLOCK_SIZE:(bx+1)*BLOCK_SIZE]
            blocks.append(block)
    return blocks, h_blocks, w_blocks

def flatten_blocks(blocks):
    return np.array([blk.flatten() for blk in blocks], dtype=np.float32)

def map_blocks_to_chars(blocks, cluster_centers):
    ascii_map = []
    for blk in blocks:
        blk_flat = blk.flatten()
        distances = np.sum((cluster_centers - blk_flat)**2, axis=1)
        idx = np.argmin(distances)
        ascii_map.append(idx)
    return ascii_map

def render_image(blocks_map, cluster_centers, h_blocks, w_blocks):
    img_h = h_blocks * BLOCK_SIZE
    img_w = w_blocks * BLOCK_SIZE
    out_img = np.zeros((img_h, img_w), dtype=np.uint8)

    # Convert cluster centers to 0/255 pixels
    char_blocks = []
    for c in cluster_centers:
        blk = (c.reshape(BLOCK_SIZE, BLOCK_SIZE) > 0.5).astype(np.uint8) * 255
        char_blocks.append(blk)

    # Render each block
    for by in range(h_blocks):
        for bx in range(w_blocks):
            idx = by * w_blocks + bx
            char_idx = blocks_map[idx]
            out_img[by*BLOCK_SIZE:(by+1)*BLOCK_SIZE,
                    bx*BLOCK_SIZE:(bx+1)*BLOCK_SIZE] = char_blocks[char_idx]
    return Image.fromarray(out_img, mode='L')

from itertools import groupby

def rle(data):
    return [(key, len(list(group))) for key, group in groupby(data)]

def split_rle_runs_to_rows(rle_runs, row_width=32):
    rows = []
    current_row = []
    cols = 0

    for code, count in rle_runs:
        while count > 0:
            space_left = row_width - cols
            use = min(count, space_left)
            current_row.append((code, use))
            cols += use
            count -= use

            if cols == row_width:
                rows.append(current_row)
                current_row = []
                cols = 0

    if current_row:
        rows.append(current_row)

    return rows

def generate_bigimg_data(cluster_centers, blocks_map, h_blocks, w_blocks, fn, start_hex=0x80):
    char_hex_map = {}
    for i, c in enumerate(cluster_centers):
        blk = (c.reshape(8,8) > 0.5).astype(int)
        hex_rows = []
        for row in blk:
            byte = 0
            for bit in row:
                byte = (byte << 1) | bit
            hex_rows.append(f"{byte:02X}")
        char_hex_map[start_hex + i] = ''.join(hex_rows)

    bigimg_data = [f'DATA "BIGIMG", {NUM_CHARS}, "{fn}"']
    for code in range(start_hex, start_hex + NUM_CHARS):
        bigimg_data.append(f'DATA "{char_hex_map[code]}"')

    flat_codes = [start_hex + blocks_map[by * w_blocks + bx]
                  for by in range(h_blocks)
                  for bx in range(w_blocks)]

    rle_runs = rle(flat_codes)

    row_aligned_runs = split_rle_runs_to_rows(rle_runs, row_width=w_blocks)

    for row in row_aligned_runs:
        line_buffer = []
        line_length = 0
        for code, count in row:
            entry = f"{code},{count}"
            add_len = len(entry) + (1 if line_buffer else 0)
            if line_length + add_len > 76:
                bigimg_data.append('DATA ' + ','.join(line_buffer))
                line_buffer = [entry]
                line_length = len(entry)
            else:
                if line_buffer:
                    line_length += 1  # comma
                line_buffer.append(entry)
                line_length += len(entry)
        if line_buffer:
            bigimg_data.append('DATA ' + ','.join(line_buffer))

    return bigimg_data


if __name__ == "__main__":
    import sys
    if len(sys.argv) < 3:
        print("Usage: python3 imgconverter.py [image] [basic start line] num_chars?")
        sys.exit(1)

    basic_start_line = int(sys.argv[2])
    if len(sys.argv) >= 4:
        NUM_CHARS=int(sys.argv[3])

    img = image_to_monochrome(sys.argv[1])
    blocks, h_blocks, w_blocks = split_blocks(img)
    blocks_flat = flatten_blocks(blocks)

    # K-means to find the best NUM_CHARS characters
    kmeans = KMeans(n_clusters=NUM_CHARS, random_state=0, n_init=10)
    kmeans.fit(blocks_flat)
    cluster_centers = kmeans.cluster_centers_

    # Map each block to nearest cluster
    blocks_map = map_blocks_to_chars(blocks, cluster_centers)

    # Render
    out_img = render_image(blocks_map, cluster_centers, h_blocks, w_blocks)
    out_img.show()

    data_lines = generate_bigimg_data(cluster_centers, blocks_map, h_blocks, w_blocks, os.path.basename(sys.argv[1]))
    with open(sys.argv[1][:sys.argv[1].rindex(".")] + ".bas", "w") as file:
        file.writelines([f"{basic_start_line + i} {line}\n" for i, line in enumerate(data_lines)])

