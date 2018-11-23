class MultiLogger

  attr_accessor :use_stdout, :use_rails, :stream

  def initialize(prefix, opts={})
    @prefix = prefix
    @use_stdout = opts[:use_stdout] || true
    @use_rails = opts[:use_rails] || true
  end

  def stream_response(response)
    response.headers["Content-Type"] = "application/json"
    @stream = response.stream
    @stream.write '['
  end

  def close_stream
    return unless @stream
    @stream.write '{}]'
    @stream.close
  end

  def info(message)
    log 'info', message
  end

  def warn(message)
    log 'warn', message
  end

  def separator(message)
    log 'separator', message
  end

  def error(ex)
    message = ex.message
    ex.backtrace[0..10].each do |line|
      message += "\n#{line}"
    end
    log 'error', message
  end

  def log(level, message)
    time = Time.now.strftime(PRETTY_TIME_FORMAT)
    if level == 'separator'
      s = "#{@prefix} :: ==== #{message} ===="
    else
      s = "#{@prefix} #{level.upcase} :: #{message}"
    end
    if @use_rails
      Rails.logger.debug s
    end
    if @use_stdout
      puts s
      $stdout.flush
    end
    if @stream
      chunk = {
          level: level,
          message: CGI.escapeHTML(message),
          time: time,
          prefix: @prefix
      }
      @stream.write "#{Oj.dump(chunk)},"
      # @stream.write "\n\n"
    end
  end
end