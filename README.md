
# hubot-gocd

hubot-cron adds [GoCD](http://www.thoughtworks.com/products/go-continuous-delivery) monitoring support to hubot

[![Build Status](https://travis-ci.org/fbernitt/hubot-gocd.png?branch=master)](https://travis-ci.org/fbernitt/hubot-gocd)
 
## Installation

Add `hubot-gocd` to your package.json, run `npm install` and add hubot-gocd to `external-scripts.json`.

Add hubot-gocd to your `package.json` dependencies.

```
"dependencies": {
  "hubot-gocd": ">= 0.0.1"
}
```

Add `hubot-gocd` to `external-scripts.json`.

```
> cat external-scripts.json
> ["hubot-gocd"]
```

## Usage

```
folker> hubot build status
hubot> Good news, everyone! All green!
...
hubot> Whoops! some-pipeline :: unit-tests FAILED in #37!
...
folker> hubot build status
hubot> some-pipeline :: unit-tests(#37) is broken!
...
hubot> Good news, everyone! some-pipeline :: unit-tests is green again in #38!
```
