#  Count White Pixels

See https://stackoverflow.com/a/58513549/1271826

This is quick-and-dirty example of using `concurrentPerform` to parallelize a `for` loop.

This will let the user select an image from their photo library and it will count how many white pixels there are. There are three implementations of this counting algorithm:

1. Simple, single-threaded, nested `for` loop;
2. Simple, multi-threaded implementation, replacing outer `for` loop with `concurrentPerform`; and
3. A improved rendition of multi-threaded implementation that strides within `concurrentPerform` to try to balance amount of work done per thread (which is important in such a simple calculation).


See [`ImageProcessor.swift`](CountWhitePixels/Services/ImageProcessor.swift) for these three renditions.

Developed in Swift on Xcode 11.1 and Swift 5. But the basic ideas are equally applicable for different versions of Swift.

### License

Copyright &copy; 2019 Robert Ryan. All rights reserved.

<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-sa/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>.

--

23 October 2019
