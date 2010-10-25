# Garth Snyder, garth@garthsnyder.com 10/21/2010
# Ruby Mendicant University 2011/T1 Entrance Exam, revised version
# 
# Requires Ruby 1.9. Is there a way to declare this in code?

require 'set'
require 'csv'

MeetingTime = Struct.new(:day, :time)

class ClassScheduler < Hash # MeetingTime -> set of students

  def initialize(fname)
    super()
    CSV.foreach(fname, {:headers => :true}) do |row|
      row.drop(1).each do |header, field|
        field.split(", ").each do |time|
          (self[MeetingTime.new(header, time)] ||= Set.new) << row["Name"]
        end
      end
    end
  end
  
  def best_meeting_times
    times_by_day = keys.group_by(&:day).values
    times_by_day[0].product(*times_by_day[1..-1]).max_by do |meeting_times|
      students = values_at(*meeting_times)
      [students.reduce(:|).size, students.reduce(:&).size]
    end
  end

end

scheduler = ClassScheduler.new("student_availability.csv")
best_times = scheduler.best_meeting_times

# Write roster files
best_times.each do |meeting_time|
  roster_fname = meeting_time.day.downcase.sub(/ .*/, "-roster.txt")
  open(roster_fname, "w") do |roster|
    roster.puts meeting_time.time, $/
    roster.puts scheduler[meeting_time].to_a.join($/)
  end
end

# Warn about any unschedulable students
unserved = scheduler.values.reduce(:|) - scheduler.values_at(*best_times).reduce(:|)
if !unserved.empty? 
  STDERR << "Warning: the following students could not be scheduled: "
  STDERR << unserved.to_a.join(", ") << $/
end
