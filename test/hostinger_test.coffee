chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'hubot-hostinger', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/hostinger')(@robot)

  it 'registers a respond listener for hostinger ping', ->
    expect(@robot.respond).to.have.been.calledWith(/hostinger ping/i)
