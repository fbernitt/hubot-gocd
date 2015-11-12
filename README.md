
# hubot-gocd

hubot-gocd adds [GoCD](http://www.thoughtworks.com/products/go-continuous-delivery) monitoring support to hubot

[![Build Status](https://travis-ci.org/fbernitt/hubot-gocd.png?branch=master)](https://travis-ci.org/fbernitt/hubot-gocd)

## Description

This plugin enables hubot to react on GoCD build events as well as query the current build state of your projects.
It queries the cctray.xml status file every two minutes and if a build switched, e.g. from green to red, hubot announces it
to the defined chat channel.

## Installation and Setup

Add `hubot-gocd` to your package.json, run `npm install` and add hubot-gocd to `external-scripts.json`.

Add hubot-gocd to your `package.json` dependencies.

```
"dependencies": {
  "hubot-gocd": ">= 0.0.3"
}
```

Add `hubot-gocd` to `external-scripts.json`.

```
> cat external-scripts.json
> ["hubot-gocd"]
```

You need to specify the chat room to use for build events and the cctray.xml to use on startup:

    % HUBOT_GOCI_EVENT_NOTIFIER_ROOM="#roomname" \
      HUBOT_GOCI_CCTRAY_URL="http://my.goserver.example/cctray.xml" \
      bin/hubot

If your GoCD server requires authentication to access cctray.xml you can provide them by setting the environment variables:

      HUBOT_GOCD_USERNAME="username"
      HUBOT_GOCD_PASSWORD="password"

Preferably, create a user account with read-only access on GoCD for Hubot.

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
