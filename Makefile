all : BrightnessControl.pkg

BrightnessControl.pkg : /tmp/Brightness\ Control.dst requirements.plist ../EMCLoginItem/EMCLoginItemComponent.pkg BrightnessControl.plist BrightnessControlComponent.pkg distribution.dist
	productbuild --distribution distribution.dist --resources . --package-path . --package-path ../EMCLoginItem BrightnessControl.pkg

/tmp/Brightness\ Control.dst :
	xcodebuild install

BrightnessControl.plist :
	@echo "Error: Missing component pfile."
	@echo "Create a component pfile with make compfiles."
	@exit 1

BrightnessControlComponent.pkg :
	pkgbuild --root /tmp/Brightness\ Control.dst --component-plist BrightnessControl.plist BrightnessControlComponent.pkg

distribution.dist :
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
	productbuild --synthesize --product requirements.plist --package ../EMCLoginItem/EMCLoginItemComponent.pkg --package BrightnessControlComponent.pkg distribution.dist.new
	@echo "Edit the distribution.dist.new template to create a suitable distribution.dist file."

.PHONY : compfiles
compfiles :
	pkgbuild --analyze --root /tmp/Brightness\ Control.dst BrightnessControl.plist.new
	@echo "Edit the BrightnessControl.plist.new template to create a suitable BrightnessControl.plist file."

.PHONY : clean
clean :
	-rm -f BrightnessControl.pkg BrightnessControlComponent.pkg
	-rm -rf /tmp/Brightness\ Control.dst

.PHONY : distclean
distclean :
	-rm -f distribution.dist 

.PHONY : compclean
compclean :
	-rm -f BrightnessControl.plist
