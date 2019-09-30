require_relative '../spec_helper'

module ThreeScale
  module Backend
    # Tests are run only when redis.async = false. These tests only check
    # sentinels, which are not supported by the async client.
    describe QueueStorage do
      describe "#connection" do
        let(:configuration) { ThreeScale::Backend::Configuration::Loader.new }

        context 'when environment is development' do
          let(:environment) { 'development' }
          subject(:conn)    { QueueStorage.connection(environment, configuration) }

          it 'returns a non sentinel connection' do
            expect(is_sentinel?(conn)).to be false
          end
        end

        context 'when environment is production' do
          let(:environment) { 'production' }
          subject(:conn)    { QueueStorage.connection(environment, configuration) }

          context 'with a invalid configuration' do
            it 'returns an exception' do
              expect { conn }.to raise_error(StandardError)
            end
          end

          context 'with a valid configuration' do
            before do
              configuration.add_section(:queues, :master_name, :sentinels,
                                        :connect_timeout, :read_timeout, :write_timeout)
              configuration.queues.master_name = 'foo'
              configuration.queues.sentinels   = 'foo'
            end

            it 'returns a sentinel connection' do
              # This test only need to run when async.redis = false because the
              # async-client does not support sentinels.
              # I could not find a better place for the "if", because the
              # config is not initialized outside here.

              unless ThreeScale::Backend.configuration.redis.async
                expect(is_sentinel?(conn)).to be true
              end
            end
          end
        end
      end

      private

      def is_sentinel?(connection)
        connector = connection.instance_variable_get(:@inner)
                              .instance_variable_get(:@client)
                              .instance_variable_get(:@connector)

        connector.instance_of?(Redis::Client::Connector::Sentinel)
      end
    end
  end
end
