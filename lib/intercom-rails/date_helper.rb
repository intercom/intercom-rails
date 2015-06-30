module IntercomRails
  class DateHelper
    def self.convert_dates_to_unix_timestamps(object)
      return Hash[object.map { |k, v| [k, convert_dates_to_unix_timestamps(v)] }] if object.is_a?(Hash)
      return object.to_i if object.is_a?(Time) || object.is_a?(DateTime)
      return object.to_time.to_i if object.is_a(Date)
      object
    end
  end
end
