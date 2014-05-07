all : BrightnessControl.pkg

BrightnessControl.pkg : /tmp/Brightness\ Control.dst requirements.plist EMCLoginItem.plist EMCLoginItemComponent.pkg BrightnessControl.plist BrightnessControlComponent.pkg distribution.dist
	productbuild --distribution distribution.dist --resources . --package-path . BrightnessControl.pkg

/tmp/Brightness\ Control.dst :
	xcodebuild install

EMCLoginItem.plist :
	pkgbuild --analyze --root /tmp/EMCLoginItem.dst EMCLoginItem.plist

EMCLoginItemComponent.pkg :
	pkgbuild --root /tmp/EMCLoginItem.dst --component-plist EMCLoginItem.plist EMCLoginItemComponent.pkg

BrightnessControl.plist :
	pkgbuild --analyze --root /tmp/Brightness\ Control.dst BrightnessControl.plist

BrightnessControlComponent.pkg :
	pkgbuild --root /tmp/Brightness\ Control.dst --component-plist BrightnessControl.plist BrightnessControlComponent.pkg

distribution.dist :
	productbuild --synthesize --product requirements.plist --package EMCLoginItemComponent.pkg --package BrightnessControlComponent.pkg distribution.dist

clean :
	-rm -f BrightnessControl.pkg EMCLoginItemComponent.pkg BrightnessControlComponent.pkg
	-rm -rf /tmp/Brightness\ Control.dst

distclean :
	-rm -f distribution.dist EMCLoginItem.plist BrightnessControl.plist
