#https://github.com/miyagawa/hubot-cron/blob/master/src/index.coffee

cron = require('cron')
_ = require('underscore')

cctrayUrl = process.env.HUBOT_GOCI_CCTRAY_URL

if not cctrayUrl?
  console.warn("hubot-goci is not setup to fetch cctray.xml from a url (HUBOT_GOCI_CCTRAY_URL) is empty")


parser = require './util/parser'

parseData = (robot, callback) ->
  cctrayUrl = process.env.HUBOT_GOCI_CCTRAY_URL
  robot.http(cctrayUrl)
  .get() (err, res, body) ->
    if not err
      try
        projects = parser.parse_cctray(body)
        callback? projects
      catch e
        if e instanceof TypeError
          console.warn("Invalid xml data fetched from #{cctrayUrl}")
        else
          throw e
    else
      console.warn("Failed to fetch data from #{cctrayUrl}")

fetchAndCompareData = (robot, callback) ->
  parseData robot, (projects) ->
    changes = []
    for project in projects
      previous = robot.brain.data.gociProjects[project.name]
      if previous and previous.lastBuildStatus != project.lastBuildStatus
        changedStatus = if "Success" == project.lastBuildStatus then "Fixed" else "Failed"
        changes.push {"name": project.name, "type": changedStatus, "lastBuildLabel": project.lastBuildLabel}
    callback? changes

startCronJob = (robot) ->
  job = new cron.CronJob("0/2 * * * *", ->
    fetchAndCompareData robot, (changes) ->
      room = process.env["HUBOT_GITHUB_EVENT_NOTIFIER_ROOM"]
      for change in changes
        if "Fixed" == change.type
          robot.messageRoom room, "Good news, everyone! #{change.name} is green again in ##{change.lastBuildLabel})!"
        else if "Failed" == change.type
          robot.messageRoom room, "Whoops! #{change.name} FAILED in ##{change.lastBuildLabel})!"
  )
  job.start()

buildStatus = (robot) ->
  failed = false
  for project in _.values(robot.brain.data.gociProjects)
    if "Failure" == project.lastBuildStatus
      failed = true
      robot.send "#{project.name}(##{project.lastBuildLabel}) is broken!"
  if not failed
    robot.send "Good news, everyone! All green!"

module.exports = (robot) ->
  robot.brain.data.gociProjects or= { }

  robot.brain.on 'loaded', ->
    robot.initializeBrain()
    startCronJob(robot)

  robot.respond /build status/i, (msg) ->
    buildStatus(robot)

  initializeBrain: () ->
    parseData robot, (projects) ->
      robot.brain.data.gociProjects[project.name] = project for project in projects


  fetchAndCompare: (callback) ->
    fetchAndCompareData robot, callback

  buildStatus: () ->
    buildStatus(robot)

  startCronJob: () ->
    startCronJob(robot)
