OBJCOPY = objcopy
7Z      = 7z

ESP_DIR = /efi
GRMLEFI = grml/grml.efi
EFISTUB = /usr/lib/systemd/boot/efi/linuxx64.efi.stub

GRML_SUFFIX  = small
GRML_VERSION = 2020.06
GRML_ISO     = grml64-$(GRML_SUFFIX)_$(GRML_VERSION).iso
GRML_VMLINUZ = vmlinuz
GRML_INITRD  = initrd
GRML_ROOTFS  = grml/rootfs.squashfs
GRML_OSREL   = os-release
CMDLINE      = apm=power-off boot=live live-media-path=/grml/ nomce net.ifnames=0
CMDLINE_FILE = cmdline.txt

.PHONY: all
all: $(GRMLEFI) $(GRML_ROOTFS)

.INTERMEDIATE: $(GRML_VMLINUZ)
$(GRML_VMLINUZ): $(GRML_ISO)
	$(7Z) e -aoa $(GRML_ISO) boot/grml64$(GRML_SUFFIX)/$@ && touch $@

.INTERMEDIATE: $(GRML_INITRD)
$(GRML_INITRD): $(GRML_ISO)
	$(7Z) e -aoa $(GRML_ISO) boot/grml64$(GRML_SUFFIX)/initrd.img && touch initrd.img
	mv initrd.img $@

$(GRML_ROOTFS): $(GRML_ISO) | $(dir $(GRML_ROOTFS))
	$(7Z) e -aoa $(GRML_ISO) live/grml64-$(GRML_SUFFIX)/grml64-$(GRML_SUFFIX).squashfs && touch grml64-$(GRML_SUFFIX).squashfs
	mv grml64-$(GRML_SUFFIX).squashfs $@

.INTERMEDIATE: $(GRML_OSREL)
$(GRML_OSREL): $(GRML_ROOTFS)
	$(7Z) e -aoa $(GRML_ROOTFS) usr/lib/$@ && touch $@

.INTERMEDIATE: $(CMDLINE_FILE)
$(CMDLINE_FILE):
	echo '$(CMDLINE)' > $@

$(GRMLEFI): \
	$(GRML_OSREL) $(CMDLINE_FILE) $(GRML_VMLINUZ) $(GRML_INITRD) \
	$(GRML_ROOTFS) $(EFISTUB) | $(dir $(GRMLEFI))
	$(OBJCOPY) \
		--add-section .osrel="$(GRML_OSREL)" --change-section-vma .osrel=0x20000 \
		--add-section .cmdline="$(CMDLINE_FILE)" --change-section-vma .cmdline=0x30000 \
		--add-section .linux="$(GRML_VMLINUZ)" --change-section-vma .linux=0x2000000 \
		--add-section .initrd="$(GRML_INITRD)" --change-section-vma .initrd=0x3000000 \
		"$(EFISTUB)" "$(GRMLEFI)"

%/:
	mkdir $@

.PHONY: clean
clean:
	-rm -r grml

.PHONY: install
install: $(GRMLEFI) $(GRML_ROOTFS) | $(ESP_DIR)/grml/
	install $(GRMLEFI) $(ESP_DIR)/grml/grml.efi
	install $(GRML_ROOTFS) $(ESP_DIR)/grml/rootfs.squashfs
