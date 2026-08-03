#!/bin/sh

set -e

# ipa_post_processor for the main Telegram app.
#
# Why this exists: TelewhiteGlass is an Icon Composer .icon bundle listed in
# app_icons, so actool registers it as an alternate icon (primary_app_icon is
# "Telegram", so every other icon name becomes --alternate-app-icon) and writes
# it into the partial Info.plist. Immediately afterwards rules_apple runs
# tools/alticonstool/alticonstool.py, which does
#
#     plist_data["CFBundleIcons"]["CFBundleAlternateIcons"] = alticons_data
#
# a plain assignment, not a merge. alticons_data is built only from the .alticon
# PNG folders, so the TelewhiteGlass entry actool wrote is dropped. The artwork
# still compiles into Assets.car, but with no plist key iOS refuses the name and
# AppDelegate's setAlternateIconName("TelewhiteGlass") fails at runtime.
#
# Post-processors run before codesign (bundletool_experimental.py calls
# _post_process_bundle then _sign_bundle; process_and_sign.sh.template runs
# $POST_PROCESSOR then the signing lines), so editing Info.plist here is safe.
#
# The two bundletool paths pass different roots: process_and_sign.sh passes the
# work dir holding Payload/, while bundletool_experimental.py passes the bundle's
# parent directory. Handle both instead of assuming one.
#
# plutil is called by absolute path on purpose: bundletool_experimental.py spawns
# the post-processor with env={"TREE_ARTIFACT_OUTPUT": ...}, which replaces the
# environment and leaves no PATH.

PLUTIL=/usr/bin/plutil

app_dir=""
for candidate in "$1/Payload/Telegram.app" "$1/Telegram.app"; do
	if [ -d "$candidate" ]; then
		app_dir="$candidate"
		break
	fi
done

if [ -z "$app_dir" ]; then
	echo "RestoreTelewhiteGlassIcon: no Telegram.app under '$1'" >&2
	exit 1
fi

plist_path="$app_dir/Info.plist"

if [ ! -f "$plist_path" ]; then
	echo "RestoreTelewhiteGlassIcon: no Info.plist at '$plist_path'" >&2
	exit 1
fi

# Icon Composer bundles are keyed by CFBundleIconName (the .icon folder name),
# unlike .alticon PNG sets which use a CFBundleIconFiles array. See the upstream
# expectation in rules_apple test/starlark_tests/ios_application_resources_test.bzl:
#   "CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconName": "app_icon"
#
# plutil -insert fails when the leaf already exists, and -replace fails when it
# does not, so create the intermediate dicts tolerantly and try insert-then-replace
# for the leaf. That converges to the same value whether or not a future
# rules_apple starts emitting the key itself.
#
# Both CFBundleIcons and CFBundleIcons~ipad are expected to exist already:
# alticonstool.py indexes them directly, so it would have raised a KeyError
# otherwise. They are created tolerantly here only so this script never becomes
# the thing that breaks the build.
for icons_key in CFBundleIcons "CFBundleIcons~ipad"; do
	$PLUTIL -insert "${icons_key}" -dictionary "$plist_path" 2>/dev/null || true
	$PLUTIL -insert "${icons_key}.CFBundleAlternateIcons" -dictionary "$plist_path" 2>/dev/null || true
	$PLUTIL -insert "${icons_key}.CFBundleAlternateIcons.TelewhiteGlass" -dictionary "$plist_path" 2>/dev/null || true

	leaf="${icons_key}.CFBundleAlternateIcons.TelewhiteGlass.CFBundleIconName"
	$PLUTIL -insert "$leaf" -string "TelewhiteGlass" "$plist_path" 2>/dev/null \
		|| $PLUTIL -replace "$leaf" -string "TelewhiteGlass" "$plist_path"
done

echo "RestoreTelewhiteGlassIcon: registered TelewhiteGlass in $plist_path"
