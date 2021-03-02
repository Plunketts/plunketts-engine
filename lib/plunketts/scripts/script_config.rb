module Plunketts::ScriptConfig

  @values = {
      category_icons: {},
      report_type_icons: {}
  }

  @script_run_options = []

  @values.keys.each do |key|
    define_singleton_method "#{key}=" do |val|
      @values[key] = val
    end
    define_singleton_method key do
      @values[key]
    end
  end

  def self.category_options
    @values[:category_icons].map do |k, v|
      [k.to_s.titleize, v, k]
    end
  end

  def self.report_type_options
    @values[:report_type_icons].map do |k, v|
      [k.to_s.titleize, v, k]
    end
  end

  def self.run_options
    options = {}
    @script_run_options.each do |opt|
      options[opt.key] = {
        key: opt[:key],
        title: opt[:title],
        values: opt[:lambda].call
      }
    end
  end

  def self.add_run_option(script_run_field, field_name, lambda)
    @script_run_options.append({:key => script_run_field, :title => field_name, lambda: lambda})
  end

end