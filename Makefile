PROGRAM = BrightnessControl
BINARIES = /tmp/Brightness\ Control.dst
PRODUCT = $(PROGRAM).pkg
COMPONENT = $(PROGRAM)Component.pkg
COMPONENT_PFILE = $(PROGRAM).plist
DISTRIBUTION_FILE = distribution.dist
REQUIREMENTS = requirements.plist

all : $(PRODUCT)

$(PRODUCT) : $(BINARIES) $(REQUIREMENTS) ../EMCLoginItem/EMCLoginItemComponent.pkg $(COMPONENT_PFILE) $(COMPONENT) $(DISTRIBUTION_FILE)
	productbuild --distribution $(DISTRIBUTION_FILE) --resources . --package-path . --package-path ../EMCLoginItem $(PRODUCT)

$(BINARIES) :
	xcodebuild install

$(COMPONENT_PFILE) :
	@echo "Error: Missing component pfile."
	@echo "Create a component pfile with make compfiles."
	@exit 1

$(COMPONENT) :
	pkgbuild --root $(BINARIES) --component-plist $(COMPONENT_PFILE) $(COMPONENT)

$(DISTRIBUTION_FILE) :
	@echo "Error: Missing distribution file."
	@echo "Create a distribution file with make distfiles."
	@exit 1

.PHONY : usage
usage :
	@echo "Available targets."
	@echo
	@echo "all        Build the product package."
	@echo "clean      Clean all intermediate files but preserve package and distribution descriptors."
	@echo "compclean  Clean package descriptors."
	@echo "compfiles  Create new package descriptors."
	@echo "distclean  Clean distribution descriptors."
	@echo "distfiles  Create new distribution descriptors."
	@echo "usage      Prints this message."

.PHONY : distfiles
distfiles :
	productbuild --synthesize --product $(REQUIREMENTS) --package ../EMCLoginItem/EMCLoginItemComponent.pkg --package $(COMPONENT) $(DISTRIBUTION_FILE).new
	@echo "Edit the $(DISTRIBUTION_FILE).new template to create a suitable $(DISTRIBUTION_FILE) file."

.PHONY : compfiles
compfiles :
	pkgbuild --analyze --root $(BINARIES) $(COMPONENT_PFILE).new
	@echo "Edit the $(COMPONENT_PFILE).new template to create a suitable $(COMPONENT_PFILE) file."

.PHONY : clean
clean :
	-rm -f $(PRODUCT) $(COMPONENT)
	-rm -rf $(BINARIES)

.PHONY : distclean
distclean :
	-rm -f $(DISTRIBUTION_FILE)

.PHONY : compclean
compclean :
	-rm -f $(COMPONENT_PFILE)
