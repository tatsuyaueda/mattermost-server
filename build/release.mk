
dist: | check-style test package

build-linux:
	@echo Build Linux amd64
	env GOOS=linux GOARCH=amd64 $(GO) install -i $(GOFLAGS) $(GO_LINKER_FLAGS) ./...

build-linux-arm:
	@echo Build Linux amd64
	env GOOS=linux GOARCH=arm $(GO) install -i $(GOFLAGS) $(GO_LINKER_FLAGS) ./...

build-osx: 
	@echo Build OSX amd64
	env GOOS=darwin GOARCH=amd64 $(GO) install -i $(GOFLAGS) $(GO_LINKER_FLAGS) ./...

build-windows: 
	@echo Build Windows amd64
	env GOOS=windows GOARCH=amd64 $(GO) install -i $(GOFLAGS) $(GO_LINKER_FLAGS) ./...

build-freebsd:
	@echo Build FreeBSD amd64
	env GOOS=freebsd GOARCH=amd64 $(GO) install -i $(GOFLAGS) $(GO_LINKER_FLAGS) ./...

build: build-linux build-linux-arm build-windows build-osx build-freebsd

build-client:
	@echo Building mattermost web app

	cd $(BUILD_WEBAPP_DIR) && $(MAKE) build

package:
	@ echo Packaging mattermost

	@# Remove any old files
	rm -Rf $(DIST_ROOT)

	@# Create needed directories
	mkdir -p $(DIST_PATH)/bin
	mkdir -p $(DIST_PATH)/logs

	@# Resource directories
	cp -RL config $(DIST_PATH)
	cp -RL fonts $(DIST_PATH)
	cp -RL templates $(DIST_PATH)
	cp -RL i18n $(DIST_PATH)

	@# Disable developer settings
	sed -i'' -e 's|"ConsoleLevel": "DEBUG"|"ConsoleLevel": "INFO"|g' $(DIST_PATH)/config/config.json
	sed -i'' -e 's|"SiteURL": "http://localhost:8065"|"SiteURL": ""|g' $(DIST_PATH)/config/config.json

	@# Reset email sending to original configuration
	sed -i'' -e 's|"SendEmailNotifications": true,|"SendEmailNotifications": false,|g' $(DIST_PATH)/config/config.json
	sed -i'' -e 's|"FeedbackEmail": "test@example.com",|"FeedbackEmail": "",|g' $(DIST_PATH)/config/config.json
	sed -i'' -e 's|"SMTPServer": "dockerhost",|"SMTPServer": "",|g' $(DIST_PATH)/config/config.json
	sed -i'' -e 's|"SMTPPort": "2500",|"SMTPPort": "",|g' $(DIST_PATH)/config/config.json

	@# Package webapp
	mkdir -p $(DIST_PATH)/client
	cp -RL $(BUILD_WEBAPP_DIR)/dist/* $(DIST_PATH)/client

	@# Help files
ifeq ($(BUILD_ENTERPRISE_READY),true)
	cp $(BUILD_ENTERPRISE_DIR)/ENTERPRISE-EDITION-LICENSE.txt $(DIST_PATH)
else
	cp build/MIT-COMPILED-LICENSE.md $(DIST_PATH)
endif
	cp NOTICE.txt $(DIST_PATH)
	cp README.md $(DIST_PATH)

	@# ----- PLATFORM SPECIFIC -----

	@# Make FreeBSD package
	@# Copy binary
ifeq ($(BUILDER_GOOS_GOARCH),"freebsd_amd64")
	cp $(GOPATH)/bin/mattermost $(DIST_PATH)/bin # from native bin dir, not cross-compiled
	cp $(GOPATH)/bin/platform $(DIST_PATH)/bin # from native bin dir, not cross-compiled
else
	cp $(GOPATH)/bin/freebsd_amd64/mattermost $(DIST_PATH)/bin # from cross-compiled bin dir
	cp $(GOPATH)/bin/freebsd_amd64/platform $(DIST_PATH)/bin # from cross-compiled bin dir
endif
	@# Package
	tar -C dist -czf $(DIST_PATH)-$(BUILD_TYPE_NAME)-freebsd-amd64.tar.gz mattermost
	@# Cleanup
	rm -f $(DIST_PATH)/bin/mattermost
	rm -f $(DIST_PATH)/bin/platform
	rm -f $(DIST_PATH)/prepackaged_plugins/*

	@# Make osx package
	@# Copy binary
ifeq ($(BUILDER_GOOS_GOARCH),"darwin_amd64")
	cp $(GOPATH)/bin/mattermost $(DIST_PATH)/bin # from native bin dir, not cross-compiled
	cp $(GOPATH)/bin/platform $(DIST_PATH)/bin # from native bin dir, not cross-compiled
else
	cp $(GOPATH)/bin/darwin_amd64/mattermost $(DIST_PATH)/bin # from cross-compiled bin dir
	cp $(GOPATH)/bin/darwin_amd64/platform $(DIST_PATH)/bin # from cross-compiled bin dir
endif
	@# Package
	tar -C dist -czf $(DIST_PATH)-$(BUILD_TYPE_NAME)-osx-amd64.tar.gz mattermost
	@# Cleanup
	rm -f $(DIST_PATH)/bin/mattermost
	rm -f $(DIST_PATH)/bin/platform

	@# Make windows package
	@# Copy binary
ifeq ($(BUILDER_GOOS_GOARCH),"windows_amd64")
	cp $(GOPATH)/bin/mattermost.exe $(DIST_PATH)/bin # from native bin dir, not cross-compiled
	cp $(GOPATH)/bin/platform.exe $(DIST_PATH)/bin # from native bin dir, not cross-compiled
else
	cp $(GOPATH)/bin/windows_amd64/mattermost.exe $(DIST_PATH)/bin # from cross-compiled bin dir
	cp $(GOPATH)/bin/windows_amd64/platform.exe $(DIST_PATH)/bin # from cross-compiled bin dir
endif
	@# Package
	cd $(DIST_ROOT) && zip -9 -r -q -l mattermost-$(BUILD_TYPE_NAME)-windows-amd64.zip mattermost && cd ..
	@# Cleanup
	rm -f $(DIST_PATH)/bin/mattermost.exe
	rm -f $(DIST_PATH)/bin/platform.exe

	@# Make linux amd64 package
	@# Copy binary
ifeq ($(BUILDER_GOOS_GOARCH),"linux_amd64")
	cp $(GOPATH)/bin/mattermost $(DIST_PATH)/bin # from native bin dir, not cross-compiled
	cp $(GOPATH)/bin/platform $(DIST_PATH)/bin # from native bin dir, not cross-compiled
else
	cp $(GOPATH)/bin/linux_amd64/mattermost $(DIST_PATH)/bin # from cross-compiled bin dir
	cp $(GOPATH)/bin/linux_amd64/platform $(DIST_PATH)/bin # from cross-compiled bin dir
endif
	@# Package
	tar -C dist -czf $(DIST_PATH)-$(BUILD_TYPE_NAME)-linux-amd64.tar.gz mattermost
	@# Don't clean up native package so dev machines will have an unzipped package available
	@#rm -f $(DIST_PATH)/bin/mattermost

	@# Make linux arm package
	@# Copy binary
ifeq ($(BUILDER_GOOS_GOARCH),"linux_arm")
	cp $(GOPATH)/bin/mattermost $(DIST_PATH)/bin # from native bin dir, not cross-compiled
	cp $(GOPATH)/bin/platform $(DIST_PATH)/bin # from native bin dir, not cross-compiled
else
	cp $(GOPATH)/bin/linux_arm/mattermost $(DIST_PATH)/bin # from cross-compiled bin dir
	cp $(GOPATH)/bin/linux_arm/platform $(DIST_PATH)/bin # from cross-compiled bin dir
endif
	@# Package
	tar -C dist -czf $(DIST_PATH)-$(BUILD_TYPE_NAME)-linux-arm.tar.gz mattermost
	@# Don't clean up native package so dev machines will have an unzipped package available
	@#rm -f $(DIST_PATH)/bin/mattermost
