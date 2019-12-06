require 'spec_helper'

# A queue that will pause job execution if the pause_queue is set to true
class PausableQueue < PuppetLanguageServer::GlobalQueues::SingleInstanceQueue
  attr_accessor :pause_queue

  def initialize(max_queue_threads)
    super()
    @max_queue_threads = max_queue_threads
    @pause_queue = false
  end

  def max_queue_threads
    @max_queue_threads
  end

  def execute_job(_)
    super
    begin
      sleep 1 if pause_queue
    end while pause_queue
  end
end

describe 'PuppetLanguageServer::GlobalQueues::SingleInstanceQueueJob' do
  let(:key) { 'a key'}
  let(:subject) { PuppetLanguageServer::GlobalQueues::SingleInstanceQueueJob.new(key) }

  it 'has a method called key' do
    expect(subject).to respond_to(:key)
  end

  it 'returns the key' do
    expect(subject.key).to eq(key)
  end
end

describe 'PuppetLanguageServer::GlobalQueues::SingleInstanceQueue' do
  let(:subject) { PuppetLanguageServer::GlobalQueues::SingleInstanceQueue.new }

  describe '#max_queue_threads' do
    let(:job1) { PuppetLanguageServer::GlobalQueues::SingleInstanceQueueJob.new('single_job1') }
    let(:job2) { PuppetLanguageServer::GlobalQueues::SingleInstanceQueueJob.new('single_job2') }
    let(:job3) { PuppetLanguageServer::GlobalQueues::SingleInstanceQueueJob.new('single_job3') }
    let(:job4) { PuppetLanguageServer::GlobalQueues::SingleInstanceQueueJob.new('single_job4') }

    it 'has a method called max_queue_threads' do
      expect(subject).to respond_to(:max_queue_threads)
    end

    it 'executes the specified number of threads' do
      queue = PausableQueue.new(2)

      # Enqueue four jobs
      queue.pause_queue = true
      queue.enqueue_job(job1)
      queue.enqueue_job(job2)
      queue.enqueue_job(job3)
      queue.enqueue_job(job4)

      # Give the queue a few moments to start up
      sleep(2)

      # Because we have 2 job threads, the first two jobs will no longer be in the
      # queue, and jobs 3 and 4 should be
      # Note - using instance_variable_get isn't the greatest but it works
      internal_queue = queue.instance_variable_get(:@queue)
      expect(internal_queue.count).to eq(2)
      expect(internal_queue[0]).to be(job3)
      expect(internal_queue[1]).to be(job4)

      queue.pause_queue = false
      queue.drain_queue
    end
  end

  describe '#job_class' do
    it 'defaults to SingleInstanceQueueJob' do
     expect(subject.job_class).to eq(PuppetLanguageServer::GlobalQueues::SingleInstanceQueueJob)
    end
  end

  describe '#newjob' do
    it 'should create a new job object' do
      expect(subject.new_job('new_job_key')).is_a?(PuppetLanguageServer::GlobalQueues::SingleInstanceQueueJob)
      expect(subject.new_job('new_job_key').key).to eq('new_job_key')
    end
  end

  describe '#enqueue' do
    it 'should call enqueue_job with the new job object' do
      expect(subject).to receive(:enqueue_job).with(having_attributes(:key => 'test_enqueue'))
      subject.enqueue('test_enqueue')
      subject.drain_queue
    end
  end

  describe '#enqueue_job' do
    it 'raises if the job object is the wrong type' do
      expect{ subject.enqueue_job(Object.new) }.to raise_error(RuntimeError)
    end

    context 'with an empty queue' do
      let(:job) { PuppetLanguageServer::GlobalQueues::SingleInstanceQueueJob.new('single_job') }
      it 'should execute a new job only once' do
        expect(subject).to receive(:execute_job).with(job).once

        subject.enqueue_job(job)
        subject.drain_queue
      end
    end

    context 'with mulitple item in the queue' do
      let(:job1) { PuppetLanguageServer::GlobalQueues::SingleInstanceQueueJob.new('single_job1') }
      let(:job2) { PuppetLanguageServer::GlobalQueues::SingleInstanceQueueJob.new('single_job2') }
      let(:job3) { PuppetLanguageServer::GlobalQueues::SingleInstanceQueueJob.new('single_job3') }
      let(:job4) { PuppetLanguageServer::GlobalQueues::SingleInstanceQueueJob.new('single_job4') }

      before(:each) do
        subject.reset_queue([job1, job2, job3])
      end

      it 'enqueues jobs even if they\'re already procssing' do
        queue = PausableQueue.new(1)

        # Enqueue three jobs
        queue.pause_queue = true
        queue.enqueue_job(job1)
        queue.enqueue_job(job2)
        queue.enqueue_job(job3)

        # Give the queue a few moments to start up
        sleep(2)

        # Because we have 1 job threads, the first jos will no longer be in the
        # queue, and jobs 2, 3 and 4 should be
        # Note - using instance_variable_get isn't the greatest but it works
        internal_queue = queue.instance_variable_get(:@queue)
        expect(internal_queue.count).to eq(2)

        # Enqueue Job 1 again
        queue.enqueue_job(job1)

        # Job 1 should now be at the end of queue
        internal_queue = queue.instance_variable_get(:@queue)
        expect(internal_queue.count).to eq(3)
        expect(internal_queue[2]).to be(job1)

        queue.pause_queue = false
        queue.drain_queue
      end

      it 'should execute new jobs only once' do
        expect(subject).to receive(:execute_job).with(job1).once
        expect(subject).to receive(:execute_job).with(job2).once
        expect(subject).to receive(:execute_job).with(job3).once
        expect(subject).to receive(:execute_job).with(job4).once

        subject.enqueue_job(job4)
        subject.drain_queue
      end

      it 'should not execute jobs already in the queue' do
        expect(subject).to receive(:execute_job).with(job1).once
        expect(subject).to receive(:execute_job).with(job2).once
        expect(subject).to receive(:execute_job).with(job3).once

        subject.enqueue_job(job3)
        subject.drain_queue
      end

      it 'should execute all jobs even if they raise errors' do
        expect(subject).to receive(:execute_job).with(job1).once.and_raise('Job1 Error')
        expect(subject).to receive(:execute_job).with(job2).once.and_raise('Job2 Error')
        expect(subject).to receive(:execute_job).with(job3).once.and_raise('Job3 Error')

        subject.enqueue_job(job3)
        subject.drain_queue
      end
    end

  end

  describe '#execute' do
    it 'should call execute_job with the new job object' do
      expect(subject).to receive(:execute_job).with(having_attributes(:key => 'test_enqueue'))
      subject.execute('test_enqueue')
    end
  end

  describe '#execute_job' do
    it 'raises if the job object is the wrong type' do
      expect{ subject.execute_job(Object.new) }.to raise_error(RuntimeError)
    end
  end

  describe '#drain_queue' do
    # Does not need to be tested directly. It's used in other parts of this unit test file
  end

  describe '#reset_queue' do
    # Does not need to be tested directly. It's used in other parts of this unit test file
  end
end
