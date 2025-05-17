import math

def generate_sine_wave(samples):
    wave = []
    for n in range(samples):
        radian = 2 * math.pi * n / samples
        value = 128 + 127 * math.sin(radian)
        wave.append(min(255, max(0, round(value))))
    return wave

def generate_clock_wave(samples):
    half = samples // 2
    return [0xFF if i < half else 0x00 for i in range(samples)]

def generate_triangle_wave(samples):
    wave = []
    half = samples // 2
    for n in range(samples):
        if n < half:
            value = (n / (half - 1)) * 255
        else:
            value = 255 - ((n - half) / (half - 1)) * 255
        wave.append(round(value))
    return wave

def generate_sawtooth_wave(samples):
    return [round((i / (samples - 1)) * 255) for i in range(samples)]

def main():
    samples = 4096
    waveforms = [
        generate_sine_wave(samples),
        generate_clock_wave(samples),
        generate_triangle_wave(samples),
        generate_sawtooth_wave(samples)
    ]
    
    with open('wave_gen.dat', 'w') as f:
        for wave in waveforms:
            for value in wave:
                f.write(f"{value:02X}\n")

if __name__ == "__main__":
    main()