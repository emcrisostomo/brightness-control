PROGRAM = BrightnessControl
DISTDIR = ./dist
DEPSDIR = ./deps
BINARIES = /tmp/Brightness\ Control.dst
DMGFILE = $(PROGRAM).dmg
PRODUCT = $(DISTDIR)/$(PROGRAM).pkg
COMPONENT = $(DEPSDIR)/$(PROGRAM)Component.pkg
COMPONENT_PFILE = $(PROGRAM).plist
DISTRIBUTION_FILE = distribution.dist
REQUIREMENTS = requirements.plist
LOGINCOMPONENTDIR = ~/Documents/github/EMCLoginItem
LOGINCOMPONENT = $(LOGINCOMPONENTDIR)/EMCLoginItemComponent.pkg

.PHONY : all
all : $(DISTDIR) $(DEPSDIR) $(PRODUCT) $(DMGFILE)
.PHONY : dmg
dmg : $(DMGFILE)

$(DISTDIR) :
	mkdir $(DISTDIR)

$(DEPSDIR) :
	mkdir $(DEPSDIR)

$(DMGFILE) : $(PRODUCT)
	hdiutil create -volname $(PROGRAM) -srcfolder $(DISTDIR) -ov $(DMGFILE)

$(PRODUCT) : $(BINARIES) $(REQUIREMENTS) $(LOGINCOMPONENT) $(COMPONENT_PFILE) $(COMPONENT) $(DISTRIBUTION_FILE)
	productbuild --distribution $(DISTRIBUTION_FILE) --resources . --package-path $(DEPSDIR) --package-path $(LOGINCOMPONENTDIR) $(PRODUCT)

$(BINARIES) :
	xcodebuild install

$(COMPONENT_PFILE) :
	@echo "Error: Missing component pfile."
	@echo "Create a component pfile with make compfiles."
	@exit 1

$(COMPONENT) : $(BINARIES) $(COMPONENT_PFILE)
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
distfiles : $(COMPONENT)
	productbuild --synthesize --product $(REQUIREMENTS) --package ../EMCLoginItem/EMCLoginItemComponent.pkg --package $(COMPONENT) $(DISTRIBUTION_FILE).new
	@echo "Edit the $(DISTRIBUTION_FILE).new template to create a suitable $(DISTRIBUTION_FILE) file."

.PHONY : compfiles
compfiles : $(BINARIES)
	pkgbuild --analyze --root $(BINARIES) $(COMPONENT_PFILE).new
	@echo "Edit the $(COMPONENT_PFILE).new template to create a suitable $(COMPONENT_PFILE) file."

.PHONY : clean
clean :
	-rm -f $(DMGFILE) $(PRODUCT) $(COMPONENT)
	-rm -rf $(BINARIES)

.PHONY : distclean
distclean :
	-rm -f $(DISTRIBUTION_FILE) $(DISTRIBUTION_FILE).new

.PHONY : compclean
compclean :
	-rm -f $(COMPONENT_PFILE) $(COMPONENT_PFILE).new
