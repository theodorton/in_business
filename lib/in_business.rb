require 'ostruct'
require 'active_support/core_ext'

module InBusiness

  @holidays = []
  @hours = OpenStruct.new

  def self.holidays
    @holidays
  end

  def self.holidays=(array)
    @holidays = array
  end

  def self.hours
    @hours
  end

  def self.hours=(hash)
    @hours = OpenStruct.new(hash)
  end

  def self.reset
    # Used for clearing the state of InBusiness between specs
    @holidays = []
    @hours = OpenStruct.new
    true
  end

  def self.open?(datetime=DateTime.now)

    # If this is included in the list of holidays, return false
    return false if is_holiday?(datetime)

    # Check if we're open
    return true if open_on?(datetime.wday, datetime.strftime("%H:%M"))

    false # It's not open, so it must be closed ;)
  end

  def self.closed?(datetime=DateTime.now)
    !open?(datetime)
  end

  def self.is_holiday?(date=DateTime.now)
    @holidays.include? date.to_date
  end

  # Maps values of [DateTime/Date/Time]#wday to English days
  def self.days
    {
      "0" => "sunday",
      "1" => "monday",
      "2" => "tuesday",
      "3" => "wednesday",
      "4" => "thursday",
      "5" => "friday",
      "6" => "saturday"
    }
  end

  private

  def self.open_on?(wday, hour_min_string)
    # Check if we're open according to todays opening hours
    day_string    = days[wday.to_s]
    opening_hours = @hours.send(day_string)

    # There are opening hours for today
    if opening_hours
      if opening_hours.begin < opening_hours.end
        # Normal hours
        return true if opening_hours.include? hour_min_string
      else
        # Overnight hours
        return true if skewed_hours(opening_hours).include? hour_min_string
      end
    end

    # Get opening hours for yesterday
    day_string    = days[((wday-1)%7).to_s]
    opening_hours = @hours.send(day_string)

    # Use the opening hours for yesterday if present and overnight
    if opening_hours
      if opening_hours.begin >= opening_hours.end
        # Overnight hours
        hour_min_string = add_24_hours_to_string(hour_min_string)
        return true if skewed_hours(opening_hours).include? hour_min_string
      end
    end
    return false
  end

  def self.skewed_hours(opening_hours)
    opening_hours.begin..add_24_hours_to_string(opening_hours.end)
  end

  def self.add_24_hours_to_string(hour_min_string)
    hour = Integer(hour_min_string[0..1])
    hour += 24
    min  = hour_min_string[-2..-1]
    "#{hour}:#{min}"
  end
end
