TARGET=main
LATEX=latexmk
BUILD_DIR=build

all: $(BUILD_DIR)/$(TARGET).pdf

$(BUILD_DIR)/$(TARGET).pdf: $(TARGET).tex | $(BUILD_DIR)
	$(LATEX) -output-directory=$(BUILD_DIR) -pdflua $(TARGET).tex

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean
