# `tinyasync`

A minimal `dart:async` experiment.

In particular, this library is attempt to "re-imagine" the `dart:async` core
library _if_ it were built with minimalism in mind. Specifically, it tries to
provide most of the same APIs, or the capability to be extended to provide more
APIs, but also have both a small runtime footprint and cost.

> **NOTE**: The current implementation only runs on the web due to the fact
that it is impossible to implement the event loop entry-point and the `print`
command without a runtime, and the Dart VM's is tightly bound to `dart:async`.

Disclaimer: This is not an official Google or Dart project.

## Major changes
* `tinyasync` does not know anything about isolates, or `dart:isolate`.
* `tinyasync` strictly only uses `dart:core` and `package:js`.
* `Zone`'s `zoneValues` cannot contain `null` as a key.
* Most exceptions are developer-mode only (i.e. when `assert` is enabled).

### TODO
* [ ] Add `Completer`, `Future`.
* [ ] Add `Stream`, `StreamController`.

## Results
To view the benchmark results yourself:

```bash
$ git clone https://github.com/matanlurey/tinyasync.dart.git
$ pub build benchmark
$ dart tool/benchmark.dart
```

| Name                            | SDK (`dart:async`)  | Experiment (`package:tinyasync`) | Difference  |
| ------------------------------- | ------------------- | -------------------------------- | ----------- |
| (Root) scheduleMicrotask        | 64.2Kb              | 42.6Kb                           | **-21.6Kb** |
| (Fork) scheduleMicrotask        | 71.9Kb              | 49.1Kb                           | **-22.8Kb** |
| (Root) Timer.run                | 63.8Kb              | 42.9Kb                           | **-20.9Kb** |
| (Fork) Timer.run                | 71.8Kb              | 50.1Kb                           | **-21.7Kb** |

## References
* [Source code for `dart:async`](https://github.com/dart-lang/sdk/tree/master/sdk/lib/async)
* [Source code for `zone.js`](https://github.com/angular/zone.js/)

## Contributing
To run the size calculations, first run `pub build benchmark`, and then:

```bash
$ dart tool/benchmark.dart
```

To run the test cases using `dart2js`:

```bash
$ pub run test
```

Or using `dartdevc`:

```bash
$ pub serve test
$ pub run test --pub-serve 8080
```
