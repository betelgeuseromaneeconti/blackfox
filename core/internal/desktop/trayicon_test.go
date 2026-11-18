
package desktop

import (
	"bytes"
	"encoding/binary"
	"errors"
	"image/png"
	"runtime"
	"testing"
)

// TestTrayIcons checks all tray icons in PNG and ICO formats.
func TestTrayIcons(t *testing.T) {
	names := []string{
		iconRunning,
		iconRunningAsleep,
		iconSet,
		iconSetAsleep,
		iconWaiting,
		iconError,
		iconOff,
	}

	for _, name := range names {
		t.Run(name, func(t *testing.T) {
			// Read and decode the PNG icon.
			pngData, err := trayFiles.ReadFile("tray/" + name + ".png")
			if err != nil {
				t.Fatalf("read PNG: %v", err)
			}

			img, err := png.Decode(bytes.NewReader(pngData))
			if err != nil {
				t.Fatalf("decode PNG: %v", err)
			}

			bounds := img.Bounds()
			if bounds.Dx() != 32 || bounds.Dy() != 32 {
				t.Fatalf("PNG size = %v, want 32x32", bounds)
			}

			// The icon background must remain transparent.
			_, _, _, alpha := img.At(bounds.Min.X, bounds.Min.Y).RGBA()
			if alpha != 0 {
				t.Fatal("PNG top-left corner is not transparent")
			}

			// Make sure the image actually contains visible artwork.
			visiblePixels := 0

			for y := bounds.Min.Y; y < bounds.Max.Y; y++ {
				for x := bounds.Min.X; x < bounds.Max.X; x++ {
					_, _, _, a := img.At(x, y).RGBA()
					if a != 0 {
						visiblePixels++
					}
				}
			}

			if visiblePixels == 0 {
				t.Fatal("PNG contains no visible artwork")
			}

			// Read and validate the Windows ICO icon.
			ico, err := trayFiles.ReadFile("tray/" + name + ".ico")
			if err != nil {
				t.Fatalf("read ICO: %v", err)
			}

			if err := validateTrayICO(ico); err != nil {
				t.Fatalf("invalid ICO: %v", err)
			}

			// Verify that trayIcon selects the correct format.
			got := trayIcon(name)
			want := pngData

			if runtime.GOOS == "windows" {
				want = ico
			}

			if len(got) == 0 {
				t.Fatal("trayIcon returned an empty icon")
			}

			if !bytes.Equal(got, want) {
				t.Fatal("trayIcon returned the wrong platform icon")
			}
		})
	}
}

// validateTrayICO validates the ICO header, directory entries,
// image dimensions, and image data boundaries.
func validateTrayICO(data []byte) error {
	if len(data) < 6 {
		return errInvalidTrayICO
	}

	// ICO header: reserved = 0, type = 1.
	if !bytes.Equal(data[:4], []byte{0, 0, 1, 0}) {
		return errInvalidTrayICO
	}

	count := int(binary.LittleEndian.Uint16(data[4:6]))
	if count == 0 {
		return errInvalidTrayICO
	}

	directoryEnd := 6 + count*16
	if directoryEnd > len(data) {
		return errInvalidTrayICO
	}

	has32x32 := false

	for i := 0; i < count; i++ {
		start := 6 + i*16
		entry := data[start : start+16]

		width := int(entry[0])
		height := int(entry[1])

		// In ICO format, zero represents 256 pixels.
		if width == 0 {
			width = 256
		}
		if height == 0 {
			height = 256
		}

		if width == 32 && height == 32 {
			has32x32 = true
		}

		imageSize := int(binary.LittleEndian.Uint32(entry[8:12]))
		imageOffset := int(binary.LittleEndian.Uint32(entry[12:16]))

		if imageSize <= 0 ||
			imageOffset < directoryEnd ||
			imageOffset > len(data) ||
			imageSize > len(data)-imageOffset {
			return errInvalidTrayICO
		}
	}

	if !has32x32 {
		return errInvalidTrayICO
	}

	return nil
}

var errInvalidTrayICO = errors.New("invalid ICO file")
