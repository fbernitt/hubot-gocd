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
cron = require 'cron'
chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect


describe 'goci', ->
  robot =
    goci =
      getSpy =
        httpSpy =

          beforeEach ->
            httpSpy = sinon.stub()
            httpSpy.returns(httpSpy)
            robot =
              respond: sinon.spy()
              hear: sinon.spy()
              send: sinon.spy()
              brain: sinon.spy()
              messageRoom: sinon.spy()
              http: httpSpy

            getSpy = sinon.stub().returns((callback)->
              callback? null, null, null)
            httpSpy.get = getSpy
            httpSpy.header = httpSpy
            httpSpy.headers = httpSpy
            robot.brain.data = {}
            robot.brain.on = sinon.spy()

            process.env.HUBOT_GOCI_CCTRAY_URL = 'http://localhost:1345/cctray.xml'
            process.env.HUBOT_GOCI_EVENT_NOTIFIER_ROOM = '#someroom'

            goci = require('../src/scripts/gocd')(robot)

  it 'should initialize robot brain', ->
    expect(robot.brain.data.gociProjects).to.eql({})

  it 'should initialize brain with cctray xml', ->
    fs.readFile __dirname + '/fixtures/cctray.xml', (err, data) ->
      getSpy.returns((callback)->
        callback? null, null, data)
      goci.updateBrain()
      expect(httpSpy).to.have.been.calledWith('http://localhost:1345/cctray.xml')
      expect(Object.keys(robot.brain.data.gociProjects).length).to.equal(11)

  it 'should not raise an error if fetching file failed', ->
    getSpy.returns((callback)->
      callback? 'some error', null, null)
    goci.updateBrain()
    expect(Object.keys(robot.brain.data.gociProjects).length).to.equal(0)

  it 'should cope with invalid xml data', ->
    getSpy.returns((callback)->
      callback? null, null, 'some invalid data')
    goci.updateBrain()

  it 'should fetch and compare deltas', ->
    robot.brain.data.gociProjects['pixelated-user-agent :: functional-tests'] = { "name": "pixelated-user-agent :: functional-tests", "lastBuildStatus": "Success", "lastBuildLabel": "37"}
    robot.brain.data.gociProjects["pixelated-user-agent :: unit-tests"] = { "name": "pixelated-user-agent :: unit-tests", "lastBuildStatus": "Failure", "lastBuildLabel": "37"}

    fs.readFile __dirname + '/fixtures/cctray.xml', (err, data) ->
      getSpy.returns((callback)->
        callback? null, null, data)
      goci.fetchAndCompare robot, (changes) ->
        expect(changes).to.eql([
          {"name": "pixelated-user-agent :: unit-tests", "type": "Fixed", "lastBuildLabel": "38"}
          {"name": "pixelated-user-agent :: functional-tests", "type": "Failed", "lastBuildLabel": "38"}
        ])

  it 'registers a respond listener for build status message', ->
    expect(robot.respond).to.have.been.calledWith(/build status/i)

  it 'says all green if all builds are green', ->
    msg =
      send: sinon.spy()

    robot.brain.data.gociProjects['pixelated-user-agent :: functional-tests'] = { "name": "pixelated-user-agent :: functional-tests", "lastBuildStatus": "Success", "lastBuildLabel": "37"}
    robot.brain.data.gociProjects["pixelated-user-agent :: unit-tests"] = { "name": "pixelated-user-agent :: unit-tests", "lastBuildStatus": "Success", "lastBuildLabel": "37"}

    goci.buildStatus(msg)

    expect(msg.send).to.have.been.calledOnce
    expect(msg.send).to.have.been.calledWith("Good news, everyone! All green!")

  it 'says broken builds if at least one is read', ->
    msg =
      send: sinon.spy()

    robot.brain.data.gociProjects['pixelated-user-agent :: functional-tests'] = { "name": "pixelated-user-agent :: functional-tests", "lastBuildStatus": "Success", "lastBuildLabel": "37"}
    robot.brain.data.gociProjects["pixelated-user-agent :: unit-tests"] = { "name": "pixelated-user-agent :: unit-tests", "lastBuildStatus": "Failure", "lastBuildLabel": "37"}

    goci.buildStatus(msg)

    expect(msg.send).to.have.been.calledWith("pixelated-user-agent :: unit-tests(#37) is broken!")
    expect(msg.send).to.have.been.calledOnce

  it 'starts a cronjob', ->
    cronJob =
      start: sinon.spy()
    sinon.stub(cron, "CronJob").returns(cronJob);

    goci.startCronJob(robot)

    expect(cron.CronJob).to.have.been.calledWith('0 */2 * * * *')
    expect(cronJob.start).to.have.been.called

  it 'announces builds that switched state to chat room', ->
    robot.brain.data.gociProjects['pixelated-user-agent :: functional-tests'] = { "name": "pixelated-user-agent :: functional-tests", "lastBuildStatus": "Success", "lastBuildLabel": "37"}
    robot.brain.data.gociProjects["pixelated-user-agent :: unit-tests"] = { "name": "pixelated-user-agent :: unit-tests", "lastBuildStatus": "Failure", "lastBuildLabel": "37"}
    process.env.HUBOT_GOCI_EVENT_NOTIFIER_ROOM = '#someroom'

    fs.readFile __dirname + '/fixtures/cctray.xml', (err, data) ->
      getSpy.returns((callback)->
        callback? null, null, data)
      goci.cronTick(robot)

      expect(robot.messageRoom).to.have.been.calledWith("#someroom", "Whoops! pixelated-user-agent :: functional-tests FAILED in #38)!")
      expect(robot.messageRoom).to.have.been.calledWith("#someroom", "Good news, everyone! pixelated-user-agent :: unit-tests is green again in #38)!")

  it 'updates brain each cron tick', ->
    robot.brain.data.gociProjects['pixelated-user-agent :: functional-tests'] = { "name": "pixelated-user-agent :: functional-tests", "lastBuildStatus": "Success", "lastBuildLabel": "37"}
    robot.brain.data.gociProjects['pixelated-user-agent :: unit-tests'] = { "name": "pixelated-user-agent :: unit-tests", "lastBuildStatus": "Failure", "lastBuildLabel": "37"}

    fs.readFile __dirname + '/fixtures/cctray.xml', (err, data) ->
      getSpy.returns((callback)->
        callback? null, null, data)
      goci.cronTick(robot)

      expect(robot.brain.data.gociProjects['pixelated-user-agent :: functional-tests'].lastBuildStatus).to.equal('Failure')
      expect(robot.brain.data.gociProjects['pixelated-user-agent :: unit-tests'].lastBuildStatus).to.equal('Success')

  it 'should use auth headers in cctray request if username and password are provided', ->
    process.env.HUBOT_GOCD_USERNAME = "someuser"
    process.env.HUBOT_GOCD_PASSWORD = "some password"
    fs.readFile __dirname + '/fixtures/cctray.xml', (err, data) ->
      getSpy.returns((callback)->
        callback? null, null, data)
      goci.updateBrain()
      expect(httpSpy.header).to.have.been.calledWith('http://localhost:1345/cctray.xml')
      expect(Object.keys(robot.brain.data.gociProjects).length).to.equal(11)
