require 'spec_helper'

describe Travis::Notification::Instrument::Task::Hipchat do
  include Support::ActiveRecord
  include Travis::Testing::Stubs

  let(:payload)   { Travis::Api.data(build, :for => 'event', :version => 'v0') }
  let(:task)      { Travis::Task::Hipchat.new(payload, :targets => %w(token@room)) }
  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:event)     { publisher.events[1] }

  before :each do
    Travis::Notification.publishers.replace([publisher])
    Travis::Features.stubs(:active?).returns(false)
    Repository.stubs(:find).returns(stub('repo'))
    Url.stubs(:shorten).returns(url)
    task.stubs(:process)
    task.run
  end

  it 'publishes a payload' do
    event.except(:payload).should == {
      :message => "travis.task.hipchat.run:completed",
      :uuid => Travis.uuid
    }
    event[:payload].except(:payload).should == {
      :msg => 'Travis::Task::Hipchat#run for #<Build id=1>',
      :repository => 'svenfuchs/minimal',
      :object_id => 1,
      :object_type => 'Build',
      :targets => %w(token@room),
      :message => [
        'svenfuchs/minimal#2 (master - 62aae5f : Sven Fuchs): the build has passed',
        'Change view: https://github.com/svenfuchs/minimal/compare/master...develop',
        'Build details: http://travis-ci.org/svenfuchs/minimal/builds/1'
      ]
    }
    event[:payload][:payload].should_not be_nil
  end
end