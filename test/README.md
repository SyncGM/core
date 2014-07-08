# SES Core Unit Tests

## Summary
These files provide all of the unit tests available for the [SES Core][core] script. This test suite has been provided for use with the [SES Test Case][testcase] script in order to provide verification that all of the features of the SES Core remain consistent regardless of future modifications (whether made by the original developers or third-parties).

## Usage
Place these files in the user-configured `TEST_DIR` directory as defined in the [SES Test Case][testcase] script. Once appropriately placed, ensure that `AUTO_RUN` is set to `true` in the configuration for Test Case and start the game in play-testing mode with the RGSS Console enabled through the RPG Maker VX Ace editor.

All of the tests should successfully pass if you are using a stable release of the SES Core; if any tests fail, please [open an issue][issues] and provide detailed information about the failure so that we may investigate any potential causes.

[core]:     https://github.com/sesvxace/core
[issues]:   https://github.com/sesvxace/core/issues/new
[testcase]: https://github.com/sesvxace/test-case