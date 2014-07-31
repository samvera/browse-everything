module BrowseEverythingHelper

  def array_to_hidden_fields(array,key)
    fields = array.to_query(key).split(Rack::Utils::DEFAULT_SEP).collect do |pair|
      key,value=pair.split('=', 2).map { |str| Rack::Utils.unescape(str) }
      hidden_field_tag(key,value)
    end
    fields.join("\n").html_safe
  end

  # Extracted from Rack::Mime 1.5.2 for use with earlier versions
  # of Rack/Rails
  def mime_match?(value, matcher)
    v1, v2 = value.split('/', 2)
    m1, m2 = matcher.split('/', 2)

    if m1 == '*'
      if m2.nil? || m2 == '*'
        return true
      elsif m2 == v2
        return true
      else
        return false
      end
    end

    return false if v1 != m1

    return true if m2.nil? || m2 == '*'

    m2 == v2
  end

  def is_acceptable?(file)
    acceptable = params[:accept] || '*/*'
    acceptable_types = acceptable.split(/,\s*/)
    acceptable_types << 'application/x-directory'
    acceptable_types.any? { |type| mime_match?(file.type, type) }
  end
end
