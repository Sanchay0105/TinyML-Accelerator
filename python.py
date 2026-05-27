import numpy as np

# ─── Option A: synthetic random data ───────────────────────────────────────────

def generate_synthetic_data(seed=42):
    rng = np.random.default_rng(seed)
    input_fm    = rng.integers(-128, 127, size=(8, 8),  dtype=np.int8)
    weights     = rng.integers(-16,   16, size=(3, 3),  dtype=np.int8)
    bias        = rng.integers(-256, 256, size=(1,),    dtype=np.int32)
    scale_shift = 4
    return input_fm, weights, bias, scale_shift


# ─── Option B: MNIST trained weights ───────────────────────────────────────────

def get_mnist_weights():
    import tensorflow as tf
    import cv2

    (x_train, y_train), (x_test, y_test) = tf.keras.datasets.mnist.load_data()
    x_train = x_train.astype(np.float32) / 255.0
    x_train = x_train[..., np.newaxis]

    model = tf.keras.Sequential([
        tf.keras.layers.Conv2D(1, (3, 3), activation='relu', use_bias=True,
                               input_shape=(28, 28, 1), padding='valid'),
        tf.keras.layers.Flatten(),
        tf.keras.layers.Dense(10, activation='softmax'),
    ])
    model.compile(optimizer='adam',
                  loss='sparse_categorical_crossentropy',
                  metrics=['accuracy'])
    model.fit(x_train, y_train, epochs=3, batch_size=128, verbose=1)

    float_weights = model.layers[0].get_weights()[0]   # (3,3,1,1)
    float_bias    = model.layers[0].get_weights()[1]   # (1,)

    w_scale      = np.max(np.abs(float_weights)) / 127.0
    weights_int8 = np.clip(
        np.round(float_weights / w_scale), -128, 127
    ).astype(np.int8)
    weights_int8 = weights_int8[:, :, 0, 0]           # (3,3)

    b_scale    = np.max(np.abs(float_bias)) / (2**15)
    bias_int32 = np.clip(
        np.round(float_bias / b_scale), -(2**31), 2**31 - 1
    ).astype(np.int32)

    (_, _), (x_test, _) = tf.keras.datasets.mnist.load_data()
    sample     = x_test[0].astype(np.float32) / 255.0
    sample_8x8 = cv2.resize(sample, (8, 8))
    input_int8 = np.clip(
        np.round(sample_8x8 * 255 - 128), -128, 127
    ).astype(np.int8)

    scale_shift = 4
    return input_int8, weights_int8, bias_int32, scale_shift


# ─── Core arithmetic ───────────────────────────────────────────────────────────

def int8_conv2d_standard(input_fm, kernel, bias, scale_shift):
    H, W   = input_fm.shape
    KH, KW = kernel.shape
    OH     = H - KH + 1
    OW     = W - KW + 1

    output = np.zeros((OH, OW), dtype=np.int8)

    for i in range(OH):
        for j in range(OW):
            patch = input_fm[i:i+KH, j:j+KW].astype(np.int32)
            k32   = kernel.astype(np.int32)

            acc = int(np.sum(patch * k32))   
            acc += int(bias[0])
            acc  = acc >> scale_shift         # arithmetic right shift
            acc  = max(-128, min(127, acc))   # saturate
            acc  = max(0, acc)                # ReLU

            output[i, j] = np.int8(acc)

    return output


def int8_conv2d_depthwise(input_fm_3ch, kernels_3ch, biases, scale_shift):
    C, H, W   = input_fm_3ch.shape
    _, KH, KW = kernels_3ch.shape
    OH        = H - KH + 1
    OW        = W - KW + 1

    output = np.zeros((C, OH, OW), dtype=np.int8)

    for c in range(C):
        for i in range(OH):
            for j in range(OW):
                patch = input_fm_3ch[c, i:i+KH, j:j+KW].astype(np.int32)
                k32   = kernels_3ch[c].astype(np.int32)

                acc = int(np.sum(patch * k32))
                acc += int(biases[c])
                acc  = acc >> scale_shift
                acc  = max(-128, min(127, acc))
                acc  = max(0, acc)

                output[c, i, j] = np.int8(acc)

    return output


# ─── Hex conversion helpers ────────────────────────────────────────────────────

def to_hex8(val):
    """INT8 value → 2-char uppercase hex (two's complement)."""
    return format(np.uint8(val), '02X')

def to_hex32(val):
    """INT32 value → 8-char uppercase hex (two's complement)."""
    return format(np.uint32(val), '08X')


# ─── .mem file export ──────────────────────────────────────────────────────────

def export_mem_files(input_fm, weights, bias, output_ref, prefix=""):
    # input feature map — 64 lines (8×8), each 2-char hex
    with open(f"{prefix}input.mem", "w") as f:
        for row in input_fm:
            for val in row:
                f.write(to_hex8(val) + "\n")

    # kernel weights — 9 lines (3×3), each 2-char hex
    with open(f"{prefix}weights.mem", "w") as f:
        for row in weights:
            for val in row:
                f.write(to_hex8(val) + "\n")

    # bias — 1 line, 8-char hex (single INT32 word)
    # Weight_Buf loads this as logic [31:0] std_bias_word[0:0]
    with open(f"{prefix}bias.mem", "w") as f:
        f.write(to_hex32(bias[0]) + "\n")

    # golden reference output — 36 lines (6×6), each 2-char hex
    with open(f"{prefix}output_ref.mem", "w") as f:
        for row in output_ref:
            for val in row:
                f.write(to_hex8(val) + "\n")

    print(f"Exported: {prefix}input.mem  "
          f"{prefix}weights.mem  "
          f"{prefix}bias.mem  "
          f"{prefix}output_ref.mem")


def export_depthwise_mem_files(input_3ch, kernels_3ch, biases, output_ref):
    C = input_3ch.shape[0]

    # dw input — C×64 lines
    with open("dw_input.mem", "w") as f:
        for c in range(C):
            for row in input_3ch[c]:
                for val in row:
                    f.write(to_hex8(val) + "\n")

    # dw kernels — C×9 lines
    with open("dw_weights.mem", "w") as f:
        for c in range(C):
            for row in kernels_3ch[c]:
                for val in row:
                    f.write(to_hex8(val) + "\n")

    # dw biases — C lines, each 8-char hex (one INT32 word per channel)
    # Weight_Buf loads this as logic [31:0] dw_bias_words[0:MAX_CH-1]
    with open("dw_bias.mem", "w") as f:
        for val in biases:
            f.write(to_hex32(val) + "\n")

    # dw output reference — C×36 lines
    with open("dw_output_ref.mem", "w") as f:
        for c in range(C):
            for row in output_ref[c]:
                for val in row:
                    f.write(to_hex8(val) + "\n")

    print("Exported: dw_input.mem  dw_weights.mem  "
          "dw_bias.mem  dw_output_ref.mem")


# ─── Address map print ─────────────────────────────────────────────────────────

def print_address_map(output_ref, prefix=""):
    OH, OW = output_ref.shape
    print(f"\nMemory address map for {prefix}output_ref.mem:")
    print(f"{'addr':>5}  {'[row][col]':>10}  {'value':>6}  {'hex':>4}")
    print("-" * 32)
    for i in range(OH):
        for j in range(OW):
            addr = i * OW + j
            val  = output_ref[i, j]
            print(f"{addr:>5}  [{i}][{j}]      {int(val):>6}  {to_hex8(val):>4}")


# ─── Verification printout ─────────────────────────────────────────────────────

def print_summary(input_fm, weights, bias, output_ref,
                  scale_shift, label="Standard"):
    print(f"\n{'='*52}")
    print(f"  {label} conv reference")
    print(f"{'='*52}")
    print(f"Input shape   : {input_fm.shape}   dtype={input_fm.dtype}")
    print(f"Kernel shape  : {weights.shape}    dtype={weights.dtype}")
    print(f"Bias          : {bias}   dtype={bias.dtype}")
    print(f"Scale shift   : {scale_shift} bits")
    print(f"Output shape  : {output_ref.shape}   dtype={output_ref.dtype}")
    print(f"\nInput feature map:\n{input_fm}")
    print(f"\nKernel:\n{weights}")
    print(f"\nOutput (after bias + requant + ReLU):\n{output_ref}")
    print(f"\nOutput range  : [{output_ref.min()}, {output_ref.max()}]")


# ─── Manual single-pixel verification ─────────────────────────────────────────

def verify_single_pixel(input_fm, weights, bias, scale_shift,
                        row=0, col=0, label=""):
    patch = input_fm[row:row+3, col:col+3].astype(np.int32)
    k32   = weights.astype(np.int32)

    mac_sum   = int(np.sum(patch * k32))
    after_bias = mac_sum + int(bias[0])
    after_shift = after_bias >> scale_shift
    after_clip  = max(-128, min(127, after_shift))
    after_relu  = max(0, after_clip)

    print(f"\nManual trace for output[{row}][{col}] {label}:")
    print(f"  Patch:\n{patch}")
    print(f"  MAC sum         : {mac_sum}")
    print(f"  After bias add  : {after_bias}  (bias={int(bias[0])})")
    print(f"  After >>shift   : {after_shift}  (shift={scale_shift})")
    print(f"  After clip      : {after_clip}")
    print(f"  After ReLU      : {after_relu}  ← this must match RTL output")

    return after_relu


# ─── Main ──────────────────────────────────────────────────────────────────────

if __name__ == "__main__":

    # ── Standard conv, synthetic data ─────────────────────────────────────────
    print("\nGenerating standard conv test vectors...")
    input_fm, weights, bias, scale_shift = generate_synthetic_data(seed=42)
    output_ref = int8_conv2d_standard(input_fm, weights, bias, scale_shift)

    print_summary(input_fm, weights, bias, output_ref,
                  scale_shift, label="Standard (synthetic)")
    export_mem_files(input_fm, weights, bias, output_ref)
    print_address_map(output_ref)

    # Manual pixel trace — use output[0][0] to cross-check RTL
    verify_single_pixel(input_fm, weights, bias, scale_shift,
                        row=0, col=0, label="(top-left pixel)")

    # Also trace output[0][2] which was nonzero in your earlier run
    verify_single_pixel(input_fm, weights, bias, scale_shift,
                        row=0, col=2, label="(top row, col 2)")

    print("\n" + "="*52)

    # ── Depthwise conv, 3-channel synthetic ───────────────────────────────────
    print("\nGenerating depthwise conv test vectors...")
    rng         = np.random.default_rng(99)
    input_3ch   = rng.integers(-128, 127, size=(3, 8, 8), dtype=np.int8)
    kernels_3ch = rng.integers(-16,   16, size=(3, 3, 3), dtype=np.int8)
    biases_3ch  = rng.integers(-256, 256, size=(3,),      dtype=np.int32)

    dw_output = int8_conv2d_depthwise(
        input_3ch, kernels_3ch, biases_3ch, scale_shift=4
    )

    print_summary(input_3ch[0], kernels_3ch[0], biases_3ch[:1],
                  dw_output[0], 4, label="Depthwise ch0 (synthetic)")
    export_depthwise_mem_files(input_3ch, kernels_3ch, biases_3ch, dw_output)

    # Manual pixel trace for depthwise ch0
    verify_single_pixel(input_3ch[0], kernels_3ch[0], biases_3ch[:1],
                        scale_shift=4, row=0, col=0,
                        label="(depthwise ch0 top-left)")

    print("\n" + "="*52)
    print("\nAll .mem files generated successfully.")
    print("Copy all .mem files to your Vivado xsim working directory.")
    print("Then run simulation in Vivado.")

    # ── Option B: uncomment when TF is available ───────────────────────────────
    # print("\nGenerating MNIST-trained weight test vectors...")
    # input_fm, weights, bias, scale_shift = get_mnist_weights()
    # output_ref = int8_conv2d_standard(input_fm, weights, bias, scale_shift)
    # print_summary(input_fm, weights, bias, output_ref,
    #               scale_shift, label="Standard (MNIST)")
    # export_mem_files(input_fm, weights, bias, output_ref, prefix="mnist_")
    # verify_single_pixel(input_fm, weights, bias, scale_shift,
    #                     row=0, col=0, label="(MNIST top-left pixel)")
