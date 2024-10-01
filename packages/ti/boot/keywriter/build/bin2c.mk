$(KEYWRITER_APP_DIR)/main.c: soc/$(SOC)/tifs_keywriter.h

soc/$(SOC)/tifs_keywriter.h: tifs_bin/$(SOC)/ti-fs-keywriter.bin
	gcc $(SCI_CLIENT_TOOLS_BIN2C_DIR)/bin2c.c -o $(BIN2C_EXE)
	if [ -f $(BIN2C_EXE) ]; then \
		while lsof $(BIN2C_EXE) >/dev/null 2>&1; do \
			echo "Waiting for $(BIN2C_EXE) to be released..."; \
			sleep 1; \
		done; \
	fi
	$(BIN2C_EXE) $(SIGNED_SYSFW_BIN) $(KEYWRITER_APP_DIR)/soc/$(SOC)/tifs_keywriter.h TIFS_KEYWRITER_BIN

$(GEN_BIN2C_EXE):
# Ensure the file is not in use before removing it
	if [ -f $(BIN2C_EXE) ]; then \
		while lsof $(BIN2C_EXE) >/dev/null 2>&1; do \
			echo "Waiting for $(BIN2C_EXE) to be released..."; \
			sleep 1; \
		done; \
		rm -f $(BIN2C_EXE); \
	fi
	gcc $(SCI_CLIENT_TOOLS_BIN2C_DIR)/bin2c.c -o $(BIN2C_EXE)
	chmod +x $(BIN2C_EXE)
