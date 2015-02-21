module Fluent
  class FormatOutput < Output
    Fluent::Plugin.register_output('format', self)

    config_param :tag, :string
    config_param :include_original_fields, :bool, :default => true
    config_param :time_format, :string, :default => "%d/%b/%Y:%H:%M:%S %z"

    CONF_KEYS = %w{type tag include_original_fields time_format}

    def configure(conf)
      super

      @fields = {}
      conf.each do |k, v|
        unless CONF_KEYS.include?(k)
          @fields[k] = v
        end
      end
    end

    def emit(tag, es, chain)
      es.each do |time, record|
        Engine.emit(@tag, time, format_record(record))
      end

      chain.next
    end

    private

    def format_record(record)
      result = {}

      if @include_original_fields
        result.merge!(record)
      end

      @fields.each do |k, v|
        new_v = v
        new_v = new_v.gsub(/%{(.+?)}/).each { record[$1] }
        new_v = new_v.gsub(/%t{(.+?)}/).each { format_time(record[$1], @time_format) }
        result[k] = new_v
      end

      return result
    end

    def format_time(timestamp, format)
      if (!timestamp.is_a? Numeric)
        return ""
      end
      t = Time.at(timestamp)
      return t.strftime format
    end
  end
end