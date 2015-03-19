module ThreeScale
  module Backend
    module Stats
      module Keys
        module_function

        extend Backend::StorageKeyHelpers

        # @note The { ... } is the key tag. See redis docs for more info
        # about key tags.
        def service_key_prefix(service_id)
          "stats/{service:#{service_id}}"
        end

        # @note For backwards compatibility, the key is called cinstance.
        # It will be eventually renamed to application.
        def application_key_prefix(prefix, application_id)
          "#{prefix}/cinstance:#{application_id}"
        end

        def applications_key_prefix(prefix)
          "#{prefix}/cinstances"
        end

        # @note For backwards compatibility, the key is called uinstance.
        # It will be eventually renamed to user.
        def user_key_prefix(prefix, user_id)
          "#{prefix}/uinstance:#{user_id}"
        end

        def metric_key_prefix(prefix, metric_id)
          "#{prefix}/metric:#{metric_id}"
        end

        def response_code_key_prefix(prefix, response_code)
          "#{prefix}/response_code:#{response_code}"
        end

        def usage_value_key(application, metric_id, period, time)
          service_key = service_key_prefix(application.service_id)
          app_key     = application_key_prefix(service_key, application.id)
          metric_key  = metric_key_prefix(app_key, metric_id)

          encode_key(counter_key(metric_key, period, time))
        end

        def user_usage_value_key(user, metric_id, period, time)
          service_key = service_key_prefix(user.service_id)
          user_key    = user_key_prefix(service_key, user.username)
          metric_key  = metric_key_prefix(user_key, metric_id)

          encode_key(counter_key(metric_key, period, time))
        end

        def counter_key(prefix, granularity, timestamp)
          key = "#{prefix}/#{granularity}"
          if granularity != :eternity
            key += ":#{timestamp.beginning_of_cycle(granularity).to_compact_s}"
          end

          key
        end

        def changed_keys_bucket_key(bucket)
          "keys_changed:#{bucket}"
        end

        def changed_keys_key
          "keys_changed_set"
        end

        def failed_save_to_storage_stats_key
          "stats:failed"
        end

        def failed_save_to_storage_stats_at_least_once_key
          "stats:failed_at_least_once"
        end

        def transaction_metric_keys(transaction, metric_id)
          service_key     = service_key_prefix(transaction.service_id)
          application_key = application_key_prefix(service_key,
                                                   transaction.application_id)

          keys = {
            service:     metric_key_prefix(service_key, metric_id),
            application: metric_key_prefix(application_key, metric_id),
          }

          if transaction.user_id
            user_key = user_key_prefix(service_key, transaction.user_id)
            keys.merge!(user: metric_key_prefix(user_key, metric_id))
          end

          keys
        end

        def transaction_response_code_keys(transaction, response_code)
          response_code = transaction.response_code
          service_key     = service_key_prefix(transaction.service_id)
          application_key = application_key_prefix(service_key,
                                                   transaction.application_id)

          keys = {
            service:     response_code_key_prefix(service_key, response_code),
            application: response_code_key_prefix(application_key, response_code)
          }

          if transaction.user_id
            user_key = user_key_prefix(service_key, transaction.user_id)
            keys.merge!(user: response_code_key_prefix(user_key, response_code))
          end

          keys
        end

      end
    end
  end
end
