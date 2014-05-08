all : BrightnessControl.pkg

BrightnessControl.pkg : /tmp/Brightness\ Control.dst requirements.plist ../EMCLoginItem/EMCLoginItemComponent.pkg BrightnessControl.plist BrightnessControlComponent.pkg distribution.dist
	productbuild --distribution distribution.dist --resources . --package-path . --package-path ../EMCLoginItem BrightnessControl.pkg

/tmp/Brightness\ Control.dst :
	xcodebuild install

BrightnessControl.plist :
	pkgbuild --analyze --root /tmp/Brightness\ Control.dst BrightnessControl.plist

BrightnessControlComponent.pkg :
	pkgbuild --root /tmp/Brightness\ Control.dst --component-plist BrightnessControl.plist BrightnessControlComponent.pkg

distribution.dist :
	productbuild --synthesize --product requirements.plist --package ../EMCLoginItem/EMCLoginItemComponent.pkg --package BrightnessControlComponent.pkg distribution.dist

.PHONY : clean
clean :
	-rm -f BrightnessControl.pkg BrightnessControlComponent.pkg
	-rm -rf /tmp/Brightness\ Control.dst

.PHONY : distclean
distclean :
	-rm -f distribution.dist BrightnessControl.plist
