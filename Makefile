APP_NAME = MarkKit
BUNDLE = $(APP_NAME).app
CONTENTS = $(BUNDLE)/Contents
MACOS = $(CONTENTS)/MacOS
RESOURCES = $(CONTENTS)/Resources

SWIFTC = swiftc
SWIFT_FILES = $(wildcard Sources/*.swift)
ARCH = $(shell uname -m)
SWIFT_FLAGS = -O -module-name MarkKit -target $(ARCH)-apple-macosx11.0

all: $(BUNDLE)

$(BUNDLE): $(SWIFT_FILES) Info.plist
	@mkdir -p $(MACOS)
	@mkdir -p $(RESOURCES)
	$(SWIFTC) $(SWIFT_FLAGS) $(SWIFT_FILES) -o $(MACOS)/$(APP_NAME)
	@cp Info.plist $(CONTENTS)/Info.plist
	@[ -f AppIcon.icns ] && cp AppIcon.icns $(RESOURCES)/AppIcon.icns || true
	@echo "Build complete. Run 'open $(BUNDLE)' to launch."

clean:
	rm -rf $(BUNDLE)

.PHONY: all clean
