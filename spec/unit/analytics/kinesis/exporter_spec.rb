require_relative '../../../spec_helper'

module ThreeScale
  module Backend
    module Analytics
      module Kinesis
        describe Exporter do
          subject { described_class }

          describe '.enable' do
            before { subject.disable }

            it 'makes .enabled? return true' do
              expect { subject.enable }.to change(subject, :enabled?).from(false).to(true)
            end
          end

          describe '.disable' do
            before { subject.enable }

            it 'makes .enabled? return false' do
              expect { subject.disable }.to change(subject, :enabled?).from(true).to(false)
            end
          end

          describe '.schedule_job' do
            context 'when kinesis is enabled' do
              before { subject.enable }

              context 'when there is at least one job already running' do
                let(:dist_lock) { double('dist_lock', lock: nil) }
                before { allow(subject).to receive(:dist_lock).and_return dist_lock }

                it 'does not schedule a kinesis job' do
                  expect(Resque).not_to receive(:enqueue)
                  subject.schedule_job
                end
              end

              context 'when there are not any jobs running' do
                let(:dist_lock) do
                  double('dist_lock', lock: '123', current_lock_key: '123', unlock: true)
                end
                before { allow(subject).to receive(:dist_lock).and_return dist_lock }

                it 'schedules a kinesis job' do
                  expect(Resque).to receive(:enqueue)
                  subject.schedule_job
                end
              end
            end

            context 'when kinesis is disabled' do
              before { subject.disable }

              it 'does not schedule a kinesis job' do
                expect(Resque).not_to receive(:enqueue)
                subject.schedule_job
              end
            end
          end

          describe '.flush_pending_events' do
            let(:kinesis_adapter) { double }

            before do
              allow(subject).to receive(:kinesis_adapter).and_return kinesis_adapter
            end

            context 'when kinesis is enabled' do
              before { subject.enable }

              context 'and there is at least one job already running' do
                let(:dist_lock) { double('dist_lock', lock: nil) }
                before { allow(subject).to receive(:dist_lock).and_return dist_lock }

                it 'does not flush the pending events' do
                  expect(kinesis_adapter).not_to receive(:flush)
                  subject.flush_pending_events
                end

                it 'returns 0' do
                  expect(subject.flush_pending_events).to be_zero
                end
              end

              context 'and there are not any jobs running' do
                let(:dist_lock) do
                  double('dist_lock', lock: '123', current_lock_key: '123', unlock: true)
                end
                before { allow(subject).to receive(:dist_lock).and_return dist_lock }

                let(:events_to_flush) { 5 }

                it 'flushes the pending events' do
                  expect(kinesis_adapter).to receive(:flush).and_return(events_to_flush)
                  subject.flush_pending_events
                end

                it 'returns the number of events flushed' do
                  expect(kinesis_adapter).to receive(:flush).and_return(events_to_flush)
                  expect(subject.flush_pending_events).to eq events_to_flush
                end
              end
            end

            context 'when kinesis is disabled' do
              before { subject.disable }

              it 'does not flush the pending events' do
                expect(kinesis_adapter).not_to receive(:flush)
                subject.flush_pending_events
              end

              it 'returns 0' do
                expect(subject.flush_pending_events).to be_zero
              end
            end
          end

          describe '.num_pending_events' do
            let(:kinesis_adapter) { double }
            let(:pending_events) { 2 }

            before do
              allow(subject).to receive(:kinesis_adapter).and_return kinesis_adapter
              allow(kinesis_adapter).to receive(:num_pending_events).and_return pending_events
            end

            it 'return the number of pending events' do
              expect(subject.num_pending_events).to eq pending_events
            end
          end
        end
      end
    end
  end
end
