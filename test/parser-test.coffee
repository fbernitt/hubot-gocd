# Copyright 2014 Folker Bernitt
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

fs = require 'fs'
xml2js = require 'xml2js'
chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'



expect = chai.expect
parser = require '../src/scripts/util/parser'

describe 'parser', ->

  it 'parses empty project', ->
    expect(parser.parse_cctray("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<Projects>\n</Projects>\n")).to.eql([])

  it 'parses single project', ->
    expect(parser.parse_cctray("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<Projects>\n<Project name=\"pixelated-user-agent :: unit-tests\" activity=\"Sleeping\" lastBuildStatus=\"Success\" lastBuildLabel=\"38\" lastBuildTime=\"2014-08-06T21:57:24\" webUrl=\"https://hypervisor.wazokazi.is:8154/go/pipelines/pixelated-user-agent/38/unit-tests/1\" />\n</Projects>\n"))
    .to.eql([{"name": "pixelated-user-agent :: unit-tests", "lastBuildStatus": "Success", "lastBuildLabel":"38"}])

  it 'parses multiple projects', ->
    expect(parser.parse_cctray("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<Projects>\n<Project name=\"pixelated-user-agent :: unit-tests\" activity=\"Sleeping\" lastBuildStatus=\"Success\" lastBuildLabel=\"38\" lastBuildTime=\"2014-08-06T21:57:24\" webUrl=\"https://hypervisor.wazokazi.is:8154/go/pipelines/pixelated-user-agent/38/unit-tests/1\" />\n<Project name=\"pixelated-user-agent :: integration-tests\" activity=\"Sleeping\" lastBuildStatus=\"Failure\" lastBuildLabel=\"17\" lastBuildTime=\"2014-08-06T21:57:24\" webUrl=\"https://hypervisor.wazokazi.is:8154/go/pipelines/pixelated-user-agent/38/unit-tests/1\" />\n</Projects>\n"))
    .to.eql([{"name": "pixelated-user-agent :: unit-tests", "lastBuildStatus": "Success", "lastBuildLabel":"38"}, {"name": "pixelated-user-agent :: integration-tests", "lastBuildStatus": "Failure", "lastBuildLabel":"17"}])

