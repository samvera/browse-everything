module BrowseEverythingHelper

  def array_to_hidden_fields(array,key)
    fields = array.to_query(key).split(Rack::Utils::DEFAULT_SEP).collect do |pair|
      key,value=pair.split('=', 2).map { |str| Rack::Utils.unescape(str) }
      hidden_field_tag(key,value)
    end
    fields.join("\n").html_safe
  end

  def is_acceptable?(file)
    acceptable = params[:accept] || '*/*'
    acceptable_types = acceptable.split(/,\s*/)
    acceptable_types << 'application/x-directory'
    acceptable_types.any? { |type| Rack::Mime.match?(file.type, type) }
  end
end
