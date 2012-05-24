# ActionScript Diff Library

An ActionScript 3 implementation of a diff algorithm.

## Overview

This library provides an ActionScript 3 implementation of the Myer's diff algorithm.  This is a port from the Java implementation of the algorithm as is provided by the [google-diff-match-patch project](http://code.google.com/p/google-diff-match-patch/) written by Neil Fraser of Google.

This project was first mentioned in my blog post at http://blogs.adobe.com/charles/2011/12/diff-library-for-actionscript.html.

### Features

The ActionScript Diff Library supports the following features...

* Simple API to interact with the diff algorithm
* Returns diff boundaries of letters which have changed, and letters which haven't
* Pure AS3 implementation (no Flex SDK required)
* Documentation!

### Dependencies

* [as3corelib](https://github.com/mikechambers/as3corelib)

## Reference

### Usage

To use the library, simply drop in the SWC (or the source) into your project, along with the appropriate dependencies, and follow the usage below...

	var diffs:Array = new Diff().diff(beforeText.text, afterText.text);

The result that you get back is an Array of the different operations that it took to go from the original string to the modified string. You can easily use this to display the differences in whatever way you want.

### Demo

* Live demo: http://blogs.adobe.com/charles/2011/12/diff-library-for-actionscript.html
* Demo source: https://github.com/charlesbihis/sandbox/tree/master/actionscript/actionscript-diff-demo

### Documentation

You can find the full ASDocs for the project [here](http://charlesbihis.github.com/actionscript-diff/docs/).

### Relevant

* "An O(ND) Difference Algorithm and Its Variations" by Eugene W. Meyers (http://neil.fraser.name/software/diff_match_patch/myers.pdf)
* Google project google-diff-match-patch (http://code.google.com/p/google-diff-match-patch/)

## Author

* Created by Charles Bihis
* Website: [www.whoischarles.com](http://www.whoischarles.com)
* E-mail: [charles@whoischarles.com](mailto:charles@whoischarles.com)
* Twitter: [@charlesbihis](http://www.twitter.com/charlesbihis)

## License

The ActionScript Diff Library is licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).