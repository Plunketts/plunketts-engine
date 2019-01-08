
EMAIL_SPLIT_REGEX = /[\s,;]+/

SLUG_REGEX = /([[:lower:]]|[0-9]+-?[[:lower:]])(-[[:lower:]0-9]+|[[:lower:]0-9])*/

# add values here that should always be upcased when displayed to the user
UPCASE_VALUES = %w(cod csr html pdf ach eft)

# these shouldn't be upcased, even though they're only two characters
UPCASE_BLACKLIST = %w(at by to is or)

PRETTY_DATE_FORMAT = '%B %e, %Y'
PRETTY_TIME_FORMAT = '%Y-%m-%d %l:%M %p'
SHORT_DATE_FORMAT = '%m/%d/%y'

# needed to parse WKB geo points
if defined? RGeo
  RGEO_FACTORY = RGeo::Geographic.spherical_factory(
      wkb_parser: {support_ewkb: true}, wkb_generator: {hex_format: true, emit_ewkb_srid: true})
else
  RGEO_FACTORY = nil
end

class String

  def uncapitalize
    self[0, 1].downcase + self[1..-1]
  end

  def slugify
    self.strip.split(/\s+/).join('_').gsub(/[^\w\-\.]/, '').downcase
  end

  def parse_postgres_array
    self.gsub('{', '').gsub('}', '').gsub('"', '').split(',')
  end

  def is_float?
    !!Float(self) rescue false
  end

  def is_true?
    %w(true 1).index self.downcase.strip
  end

  def smart_strip
    self.strip.gsub(/\A[[:space:]]+/, '').gsub(/[[:space:]]+\z/, '')
  end

  def smart_title
    if (self.length<3 and !UPCASE_BLACKLIST.index(self)) or UPCASE_VALUES.index(self)
      self.upcase
    else
      self.titleize
    end
  end

  def parse_geo_point
    if self.index('POINT')
      self.gsub('POINT (', '').gsub(')', '').strip.split(' ').map(&:to_f)
    else
      RGEO_FACTORY.parse_wkb self
    end
  end

end


class Float

  def to_ms
    (self*1000).round(1)
  end

end


class Array

  # wraps each element in single quotes, joins them with commas, and wraps the whole thing in parentheses
  def to_postgres_array
    '(' + self.map{|a| "'#{a}'"}.join(',') + ')'
  end

  def mean
    self.sum / self.size.to_f
  end

end


class Hash

  # creates a new hash with all keys as symbols
  def symbolize
    h = {}
    self.each do |k, v|
      h[k.to_sym] = v
    end
    h
  end
end