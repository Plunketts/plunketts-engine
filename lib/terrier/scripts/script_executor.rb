require 'terrier/io/csv_io'

class ScriptExecutor
  # Doesn't need to be Loggable, it already has all the methods

  attr_reader :cache, :each_count, :each_total, :log_lines
  attr_accessor :me, :params

  def should_soft_destroy
    true
  end

  def initialize(script, cache=nil, params=nil)
    @script = script
    @cache = cache
    @each_count = 0
    @each_total = 0
    @field_values = {}
    @log_lines = []
    @params = params
  end

  def set_field_values(values)
    @field_values = ActiveSupport::HashWithIndifferentAccess.new @script.compute_field_values(values)
  end

  # returns a ScriptRun object describing the run
  def init_run
    script_run = ScriptRun.new script_id: @script.id, status: 'running', created_at: Time.now, duration: 0

    if script_run.respond_to?(:fields)
      script_run.fields = @field_values
    end

    script_run
  end

  # actually executes the script
  def run(script_run, stream)
    @stream = stream
    t = Time.now
    begin
      escaped_body = @script.body.gsub('\"', '"')
      if @stream
        @stream.write '['
      end
      eval(escaped_body, binding, 'script', 1)
      if @stream
        @stream.write '{}]'
      end
      script_run.status = 'success'

      script_run.duration = Time.now - t
      if @script.persisted? # we can't save the run if it's a temporary script
        script_run.write_log @log_lines.join("\n")
      end
      true
    rescue => ex
      line = ex.backtrace[0].split(':')[1].to_i
      write_raw 'error', "Error on line #{line}: #{ex.message}"
      script_run.status = 'error'
      script_run.exception = ex.message
      script_run.backtrace = ex.backtrace.join("\n")
      script_run.duration = Time.now - t
      @log_lines << ex.message
      error ex
      ex.backtrace[0..10].each do |line|
        @log_lines << line
        write_raw 'error', line
      end
      false
    ensure
      @stream.close if @stream
    end
  end

  def write_raw(type, body, extra={})
    return unless @stream
    extra[:type] = type
    extra[:body] = CGI.escapeHTML(body)
    @stream.write(extra.to_json + ',')
  end

  def puts(message)
    write_raw 'print', message.to_s
    Rails.logger.debug "(ScriptExecutor) #{message}"
    @log_lines << message.to_s
  end

  def log(level, message)
    write_raw level, message.to_s
    s = "#{level.upcase}: #{message}"
    level = 'info' if level == 'success'
    Rails.logger.send level, "(ScriptExecutor) #{s}"
    @log_lines << s
  end

  # make it work like a logger
  %w(debug info warn success).each do |level|
    define_method level do |message|
      log level, message
    end
  end

  def error(ex)
    if ex.is_a? Exception
      log 'error', ex.message
      if ex.backtrace
        ex.backtrace[0..6].each do |line|
          log 'error', line
        end
      end
    else
      log 'error', ex.to_s
    end
  end

  def puts_count(message='')
    puts "[#{@each_count} of #{@each_total}] #{message}"
  end

  def dump_xls(data, rel_path, options={})
    abs_path = CsvIo.save_xls data, rel_path, options
    write_raw 'file', CsvIo.abs_to_rel_path(abs_path)
    puts "Wrote #{data.count} records to #{rel_path}"
  end

  def dump_csv(data, rel_path, options={})
    abs_path = CsvIo.save data, rel_path
    write_raw 'file', CsvIo.abs_to_rel_path(abs_path)
    puts "Wrote #{data.count} records to #{rel_path}"
  end

  def puts_file(path)
    if path.index(Rails.root.to_s)
      path = CsvIo.abs_to_rel_path path
    end
    write_raw 'file', path
    file_name = File.basename path
    puts "Showing #{file_name}"
  end

  def get_field(name)
    @field_values[name]
  end

  def get_params
    @params
  end

  def each(collection)
    @each_total = collection.count
    @each_count = 0
    result = collection.map do |item|
      @each_count += 1
      yield item
    end
    @each_count = 0
    @each_total = 0
    result
  end

  def read_input(name=nil)
    if name && name.length > 0
      input = @script.script_inputs.where(name: name).first
      unless input
        raise "No input named '#{name}'"
      end
      input.read
    else # default to the first input
      input = @script.script_inputs.first
      unless input
        raise 'This script does not have any inputs!'
      end
      input.read
    end
  end

  def parse_dollars(dollars)
    if dollars.instance_of? String
      dollars = dollars.to_f
    end
    return 0 if dollars.nil? || dollars==0
    (dollars * 100).round.to_i # fix floating point truncating error
  end

  def format_cents(cents)
    "$#{'%.2f' % (cents / 100.0).round(2)}"
  end

  def email_recipients
    if Rails.env == 'production'
      if @script.email_recipients.blank?
        raise 'No e-mail recipients for this script!'
      end
      @script.email_recipients
    else
      ['clypboardtesting@gmail.com']
    end
  end

  def raw_sql(query)
    ActiveRecord::Base.connection.execute(query).to_a
  end

  # passes options nearly directly to ReportsMailer#custom
  # :to will be replaced with the testing email in non-production, but :cc will not
  def send_email(options)
    to_address = options[:to]
    if to_address.blank?
      raise 'Must specify a :to option'
    end
    unless Rails.env == 'production'
      options[:to] = 'clypboardtesting@gmail.com'
    end

    ReportsMailer.custom(options).deliver
    puts "Sent e-mail to #{to_address}: '#{options[:subject]}'"
  end

end