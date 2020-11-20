#!/usr/bin/env ruby
require 'fileutils'
require 'xcodeproj'

##########################
# Helpers
##########################

def replace_in_file(filepath, pattern, replacement)
  contents = File.read(filepath)
  File.open(filepath, "w") do |file|
    file.puts contents.gsub(pattern, replacement)
  end
end

def replace_framework(example, objc_path, swift_path)
  project_path = "#{example}/RealmExamples.xcodeproj"
  replace_in_file("#{project_path}/project.pbxproj",
                  /lastKnownFileType = wrapper.framework; path = Realm.framework; sourceTree = BUILT_PRODUCTS_DIR;/,
                  "lastKnownFileType = wrapper.xcframework; name = Realm.xcframework; path = \"#{objc_path}/Realm.xcframework\"; sourceTree = \"<group>\";")
  replace_in_file("#{project_path}/project.pbxproj",
                  /lastKnownFileType = wrapper.framework; path = RealmSwift.framework; sourceTree = BUILT_PRODUCTS_DIR;/,
                  "lastKnownFileType = wrapper.xcframework; name = RealmSwift.xcframework; path = \"#{swift_path}/RealmSwift.xcframework\"; sourceTree = \"<group>\";")
  replace_in_file("#{project_path}/project.pbxproj",
                  /(Realm|RealmSwift).framework/, "\\1.xcframework")
end

##########################
# Script
##########################

base_examples = [
  "examples/ios/objc",
  "examples/osx/objc",
  "examples/tvos/objc",
  "examples/ios/swift",
  "examples/tvos/swift",
]

xcode_versions = %w(11.3 11.4.1 11.7 12.0 12.1 12.2)

# Make a copy of each Swift example for each Swift version.
base_examples.each do |example|
  if example =~ /\/swift$/
    xcode_versions.each do |xcode_version|
      FileUtils.cp_r example, "#{example}-#{xcode_version}"
    end
    FileUtils.rm_r example
  end
end

# Update the paths to the prebuilt frameworks
replace_framework('examples/ios/objc', '../../../ios-static', '')
replace_framework('examples/osx/objc', '../../..', '')
replace_framework('examples/tvos/objc', '../../..', '')

xcode_versions.each do |xcode_version|
  replace_framework("examples/ios/swift-#{xcode_version}", '../../..', "../../../swift-#{xcode_version}")
  replace_framework("examples/tvos/swift-#{xcode_version}", '../../..', "../../../swift-#{xcode_version}")
end

# Update Playground imports and instructions

xcode_versions.each do |xcode_version|
  playground_file = "examples/ios/swift-#{xcode_version}/GettingStarted.playground/Contents.swift"
  replace_in_file(playground_file, 'choose RealmSwift', 'choose PlaygroundFrameworkWrapper')
  replace_in_file(playground_file,
                  "import Foundation\n",
                  "import Foundation\nimport PlaygroundFrameworkWrapper // only necessary to use a binary release of Realm Swift in this playground.\n")
end

